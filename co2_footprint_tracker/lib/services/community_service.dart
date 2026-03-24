import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/community_post.dart';
import '../models/post_comment.dart';

class CommunityService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CommunityService(this._firestore, this._storage);

  Future<void> createPost(CommunityPost post, {File? imageFile}) async {
    String? mediaUrl;

    if (imageFile != null) {
      final ref = _storage.ref().child('community_posts/${post.id}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = await ref.putFile(imageFile);
      mediaUrl = await uploadTask.ref.getDownloadURL();
    }

    final newPost = post.copyWith(mediaUrl: mediaUrl);
    await _firestore.collection('community_posts').doc(post.id).set(newPost.toMap());
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection('community_posts').doc(postId).delete();
  }

  Future<void> editPost(String postId, String newContent) async {
    await _firestore.collection('community_posts').doc(postId).update({
      'content': newContent,
    });
  }

  Future<void> likePost(String postId, String userId) async {
    final postRef = _firestore.collection('community_posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);
      
      if (likeDoc.exists) {
        // Unlike
        transaction.delete(likeRef);
        transaction.update(postRef, {
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        // Like
        transaction.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
        transaction.update(postRef, {
          'likesCount': FieldValue.increment(1),
        });
      }
    });
  }

  Future<void> addComment(String postId, PostComment comment) async {
    final postRef = _firestore.collection('community_posts').doc(postId);
    final commentRef = postRef.collection('comments').doc(comment.id);

    await _firestore.runTransaction((transaction) async {
      transaction.set(commentRef, comment.toMap());
      transaction.update(postRef, {
        'commentsCount': FieldValue.increment(1),
      });
    });
  }

  Future<void> repost(CommunityPost originalPost, String currentUserId, String currentUserName, String? currentUserAvatar) async {
    final newPostId = _firestore.collection('community_posts').doc().id;
    
    final targetOriginalPostId = originalPost.isRepost ? originalPost.originalPostId : originalPost.id;
    final targetOriginalAuthorName = originalPost.isRepost ? originalPost.originalAuthorName : originalPost.authorName;

    final repostDoc = CommunityPost(
      id: newPostId,
      authorId: currentUserId,
      authorName: currentUserName,
      authorAvatar: currentUserAvatar,
      content: '', // Reposts typically don't have their own content
      createdAt: Timestamp.now(),
      isRepost: true,
      originalPostId: targetOriginalPostId,
      originalAuthorName: targetOriginalAuthorName,
    );

    final parentRef = targetOriginalPostId != null 
      ? _firestore.collection('community_posts').doc(targetOriginalPostId)
      : null;
      
    final newPostRef = _firestore.collection('community_posts').doc(newPostId);

    await _firestore.runTransaction((transaction) async {
      transaction.set(newPostRef, repostDoc.toMap());
      if (parentRef != null) {
        transaction.update(parentRef, {
          'repostsCount': FieldValue.increment(1),
        });
      }
    });
  }

  Future<bool> hasUserLiked(String postId, String userId) async {
    final doc = await _firestore.collection('community_posts').doc(postId).collection('likes').doc(userId).get();
    return doc.exists;
  }
}
