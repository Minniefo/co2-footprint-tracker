import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mapbox_service.dart';
import 'auth_provider.dart'; // Assuming this contains firestoreProvider

final mapboxServiceProvider = Provider<MapboxService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return MapboxService(firestore);
});
