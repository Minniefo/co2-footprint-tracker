import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/community_post.dart';
import '../models/post_comment.dart';
import '../services/community_service.dart';
import 'auth_provider.dart';

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final communityServiceProvider = Provider<CommunityService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final storage = ref.watch(firebaseStorageProvider);
  return CommunityService(firestore, storage);
});

class FeedState {
  final List<CommunityPost> posts;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final DocumentSnapshot? lastDoc;

  FeedState({
    this.posts = const [],
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.lastDoc,
  });

  FeedState copyWith({
    List<CommunityPost>? posts,
    bool? isLoadingMore,
    bool? hasReachedEnd,
    DocumentSnapshot? lastDoc,
    bool clearLastDoc = false,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      lastDoc: clearLastDoc ? null : (lastDoc ?? this.lastDoc),
    );
  }
}

class FeedController extends AsyncNotifier<FeedState> {
  static const int _pageSize = 10;

  @override
  Future<FeedState> build() async {
    return _fetchInitial();
  }

  Future<FeedState> _fetchInitial() async {
    final firestore = ref.watch(firestoreProvider);
    final snapshot = await firestore
        .collection('community_posts')
        .orderBy('createdAt', descending: true)
        .limit(_pageSize)
        .get();

    final posts = snapshot.docs.map((doc) => CommunityPost.fromMap(doc.id, doc.data())).toList();
    
    return FeedState(
      posts: posts,
      hasReachedEnd: posts.length < _pageSize,
      lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  Future<void> fetchMore() async {
    final currentState = state.value;
    if (currentState == null || currentState.isLoadingMore || currentState.hasReachedEnd || currentState.lastDoc == null) {
      return;
    }

    state = AsyncData(currentState.copyWith(isLoadingMore: true));

    try {
      final firestore = ref.read(firestoreProvider);
      final snapshot = await firestore
          .collection('community_posts')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(currentState.lastDoc!)
          .limit(_pageSize)
          .get();

      final newPosts = snapshot.docs.map((doc) => CommunityPost.fromMap(doc.id, doc.data())).toList();
      
      state = AsyncData(currentState.copyWith(
        posts: [...currentState.posts, ...newPosts],
        isLoadingMore: false,
        hasReachedEnd: newPosts.length < _pageSize,
        lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : currentState.lastDoc,
      ));
    } catch (e, st) {
      state = AsyncData(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchInitial());
  }

  void optimisticallyUpdatePost(CommunityPost updatedPost) {
    final currentState = state.value;
    if (currentState == null) return;

    final newPosts = currentState.posts.map((p) {
      return p.id == updatedPost.id ? updatedPost : p;
    }).toList();

    state = AsyncData(currentState.copyWith(posts: newPosts));
  }

  void optimisticallyRemovePost(String postId) {
    final currentState = state.value;
    if (currentState == null) return;

    final newPosts = currentState.posts.where((p) => p.id != postId).toList();
    state = AsyncData(currentState.copyWith(posts: newPosts));
  }
}

final feedControllerProvider = AsyncNotifierProvider<FeedController, FeedState>(FeedController.new);

class LikedPostsNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => {};

  void setLiked(String postId, bool isLiked) {
    state = {...state, postId: isLiked};
  }
}

final likedPostsProvider = NotifierProvider<LikedPostsNotifier, Map<String, bool>>(LikedPostsNotifier.new);

class CommunityActionController extends AsyncNotifier<void> {

  @override
  FutureOr<void> build() {
  }

  Future<void> createPost({
    required String content,
    File? imageFile,
  }) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) throw Exception('Log in to post');

      final userDoc = await ref.read(firestoreProvider).collection('users').doc(user.uid).get();
      final displayName = userDoc.data()?['display_name'] as String? ?? 'User';
      final photoUrl = userDoc.data()?['photo_url'] as String?;

      final newPost = CommunityPost(
        id: ref.read(firestoreProvider).collection('community_posts').doc().id,
        authorId: user.uid,
        authorName: displayName,
        authorAvatar: photoUrl,
        content: content,
        createdAt: Timestamp.now(),
      );

      await ref.read(communityServiceProvider).createPost(newPost, imageFile: imageFile);
      await ref.read(feedControllerProvider.notifier).refresh();

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      throw e;
    }
  }

  Future<void> editPost(CommunityPost post, String newContent) async {
    try {
      await ref.read(communityServiceProvider).editPost(post.id, newContent);
      ref.read(feedControllerProvider.notifier).optimisticallyUpdatePost(
        post.copyWith(content: newContent),
      );
    } catch (e) {
      throw e;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await ref.read(communityServiceProvider).deletePost(postId);
      ref.read(feedControllerProvider.notifier).optimisticallyRemovePost(postId);
    } catch (e) {
      throw e;
    }
  }

  Future<void> toggleLike(CommunityPost post) async {
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) return;

      final isCurrentlyLiked = ref.read(likedPostsProvider)[post.id] ?? false;
      
      // Optimistic update
      if (isCurrentlyLiked) {
        ref.read(likedPostsProvider.notifier).setLiked(post.id, false);
        ref.read(feedControllerProvider.notifier).optimisticallyUpdatePost(
          post.copyWith(likesCount: post.likesCount > 0 ? post.likesCount - 1 : 0)
        );
      } else {
        ref.read(likedPostsProvider.notifier).setLiked(post.id, true);
        ref.read(feedControllerProvider.notifier).optimisticallyUpdatePost(
          post.copyWith(likesCount: post.likesCount + 1)
        );
      }

      await ref.read(communityServiceProvider).likePost(post.id, user.uid);
    } catch (e) {
      // Revert if error occurs
    }
  }

  Future<void> syncLikeStatus(String postId) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    final isLiked = await ref.read(communityServiceProvider).hasUserLiked(postId, user.uid);
    ref.read(likedPostsProvider.notifier).setLiked(postId, isLiked);
  }
  
  Future<void> addComment(CommunityPost post, String content) async {
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) return;

      final userDoc = await ref.read(firestoreProvider).collection('users').doc(user.uid).get();
      final displayName = userDoc.data()?['display_name'] as String? ?? 'User';
      final photoUrl = userDoc.data()?['photo_url'] as String?;

      final newComment = PostComment(
        id: ref.read(firestoreProvider).collection('community_posts').doc(post.id).collection('comments').doc().id,
        authorId: user.uid,
        authorName: displayName,
        authorAvatar: photoUrl,
        content: content,
        createdAt: Timestamp.now(),
      );

      await ref.read(communityServiceProvider).addComment(post.id, newComment);
      
      ref.read(feedControllerProvider.notifier).optimisticallyUpdatePost(
         post.copyWith(commentsCount: post.commentsCount + 1)
      );
    } catch (e) {
        throw e;
    }
  }
}

final communityActionControllerProvider = AsyncNotifierProvider<CommunityActionController, void>(CommunityActionController.new);

final postCommentsProvider = StreamProvider.family<List<PostComment>, String>((ref, postId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('community_posts')
      .doc(postId)
      .collection('comments')
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => PostComment.fromMap(doc.id, doc.data())).toList());
});

final userPostsProvider = FutureProvider.family<List<CommunityPost>, String>((ref, userId) async {
  final firestore = ref.watch(firestoreProvider);
  final snap = await firestore
      .collection('community_posts')
      .where('authorId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .get();
  return snap.docs.map((d) => CommunityPost.fromMap(d.id, d.data())).toList();
});
