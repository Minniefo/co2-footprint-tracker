import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore;

  UserService(this._firestore);

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

  Future<void> updatePrivacy(String userId, {required bool shareRank, required bool shareActivityDetails}) async {
    await _firestore.collection('users').doc(userId).update({
      'privacy': {
        'share_rank': shareRank,
        'share_activity_details': shareActivityDetails,
      },
    });
  }
}

