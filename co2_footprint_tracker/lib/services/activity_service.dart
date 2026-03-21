import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity.dart';

class ActivityService {
  final FirebaseFirestore _firestore;

  ActivityService(this._firestore);

  Future<void> saveActivity(Activity activity) async {
    try {
      final activityRef = _firestore.collection('activities').doc(activity.id);
      final userRef = _firestore.collection('users').doc(activity.userId);

      await _firestore.runTransaction((transaction) async {
        // 1. Read user doc to get current total_co2_kg
        final userDoc = await transaction.get(userRef);
        final currentTotal = (userDoc.data()?['total_co2_kg'] as num?)?.toDouble() ?? 0.0;

        // 2. Perform writes
        transaction.set(activityRef, activity.toMap());
        transaction.set(userRef, {
          'total_co2_kg': currentTotal + activity.co2Kg,
        }, SetOptions(merge: true));
      });
    } catch (e) {
      throw Exception('Failed to save activity: $e');
    }
  }

  Future<List<Activity>> getUserActivities(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('activities')
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Activity.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user activities: $e');
    }
  }

  Stream<List<Activity>> streamUserActivities(String userId) {
    return _firestore
        .collection('activities')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Activity.fromMap(doc.id, doc.data()))
            .toList());
  }
}
