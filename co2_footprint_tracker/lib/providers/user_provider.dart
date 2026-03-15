import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'auth_provider.dart';

final userDocumentProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value(null);

  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('users').doc(user.uid).snapshots().map((snapshot) {
    if (snapshot.exists && snapshot.data() != null) {
      return UserModel.fromMap(snapshot.data()!);
    }
    return null;
  });
});
