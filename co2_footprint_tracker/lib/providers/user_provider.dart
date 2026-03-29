import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../services/user_service.dart';
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

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(ref.watch(firestoreProvider));
});

class ProfileController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> updateDisplayName(String name) async {
    state = const AsyncLoading();
    try {
      final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
      if (uid == null) throw Exception('Not logged in');
      await ref.read(userServiceProvider).updateDisplayName(uid, name);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updatePrivacy({required bool isPublic, required bool shareRank, required bool shareActivityDetails}) async {
    state = const AsyncLoading();
    try {
      final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
      if (uid == null) throw Exception('Not logged in');
      await ref.read(userServiceProvider).updatePrivacy(uid, isPublic: isPublic, shareRank: shareRank, shareActivityDetails: shareActivityDetails);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateAdditionalDetails(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
      if (uid == null) throw Exception('Not logged in');
      await ref.read(userServiceProvider).updateAdditionalDetails(uid, data);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<String> uploadAvatar(File imageFile) async {
    state = const AsyncLoading();
    try {
      final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
      if (uid == null) throw Exception('Not logged in');
      final url = await ref.read(userServiceProvider).uploadAvatar(uid, imageFile);
      state = const AsyncData(null);
      return url;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final profileControllerProvider = AsyncNotifierProvider<ProfileController, void>(ProfileController.new);

