import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  UserService(this._firestore) : _storage = FirebaseStorage.instance;

  /// Updates the user's display name and propagates the change to all their posts.
  Future<void> updateDisplayName(String userId, String newName) async {
    // 1. Update user document
    await _firestore.collection('users').doc(userId).update({
      'display_name': newName,
    });

    // 2. Find all posts by this user and batch-update authorName
    final postsSnap = await _firestore
        .collection('community_posts')
        .where('authorId', isEqualTo: userId)
        .get();

    if (postsSnap.docs.isEmpty) return;

    // Firestore batch is limited to 500 writes — split if needed
    const batchSize = 500;
    for (var i = 0; i < postsSnap.docs.length; i += batchSize) {
      final batch = _firestore.batch();
      final chunk = postsSnap.docs.skip(i).take(batchSize);
      for (final doc in chunk) {
        batch.update(doc.reference, {'authorName': newName});
      }
      await batch.commit();
    }
  }

  Future<void> updatePrivacy(String userId, {
    required bool isPublic,
    required bool shareRank,
    required bool shareActivityDetails,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'privacy': {
        'is_public': isPublic,
        'share_rank': shareRank,
        'share_activity_details': shareActivityDetails,
      },
    });
  }

  Future<void> updateAdditionalDetails(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  Future<void> setOnboardingComplete(String userId) async {
    await _firestore.collection('users').doc(userId).update({'needs_onboarding': false});
  }

  /// Uploads [imageFile] to Firebase Storage and saves the URL everywhere it's needed.
  Future<String> uploadAvatar(String userId, File imageFile) async {
    final storageRef = _storage.ref().child('users/$userId/avatar.jpg');
    final task = await storageRef.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await task.ref.getDownloadURL();

    // 1. Update user profile
    await _firestore.collection('users').doc(userId).update({'photo_url': url});

    // 2. Update current leaderboard entry so photo shows immediately
    final weekId = _currentWeekId();
    final leaderboardRef = _firestore
        .collection('leaderboard_weekly')
        .doc(weekId)
        .collection('entries')
        .doc(userId);
    leaderboardRef.set({'photo_url': url}, SetOptions(merge: true)).catchError((_) {});

    // 3. Update authorAvatar on all community posts by this user
    final postsSnap = await _firestore
        .collection('community_posts')
        .where('authorId', isEqualTo: userId)
        .get();
    if (postsSnap.docs.isNotEmpty) {
      const batchSize = 500;
      for (var i = 0; i < postsSnap.docs.length; i += batchSize) {
        final batch = _firestore.batch();
        final chunk = postsSnap.docs.skip(i).take(batchSize);
        for (final doc in chunk) {
          batch.update(doc.reference, {'authorAvatar': url});
        }
        await batch.commit();
      }
    }

    return url;
  }

  static String _currentWeekId() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    final weekNumber = ((dayOfYear - now.weekday + 10) / 7).floor();
    return '${now.year}_W${weekNumber.toString().padLeft(2, '0')}';
  }
}

