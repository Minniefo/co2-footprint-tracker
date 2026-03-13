import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity.dart';

class ActivityService {
  final FirebaseFirestore _firestore;

  ActivityService(this._firestore);

  Future<void> saveActivity(Activity activity) async {
    try {
      await _firestore
          .collection('activities')
          .doc(activity.id)
          .set(activity.toMap());
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
}
