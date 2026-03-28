import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/voucher_service.dart';
import '../models/voucher_model.dart';
import '../models/user_voucher_model.dart';
import 'auth_provider.dart';

// 1. Service Provider
final voucherServiceProvider = Provider<VoucherService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return VoucherService(firestore);
});

// 2. Available Vouchers Provider
final availableVouchersProvider = FutureProvider<List<Voucher>>((ref) async {
  final service = ref.read(voucherServiceProvider);
  // Optional: Auto-seed dummy data if empty
  await service.seedDummyVouchersIfEmpty();
  return await service.getActiveVouchers();
});

// 3. User's Redeemed Vouchers Provider
final myVouchersProvider = StreamProvider<List<UserVoucher>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value([]);
  
  final service = ref.read(voucherServiceProvider);
  return service.getUserVouchers(user.uid);
});

// 4. Action Controller for redemptions
class VoucherActionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> redeem(Voucher voucher) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      state = AsyncError(Exception('User not logged in'), StackTrace.current);
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(voucherServiceProvider);
      await service.redeemVoucher(user.uid, voucher);
    });
  }
}

final voucherActionProvider = AsyncNotifierProvider<VoucherActionController, void>(VoucherActionController.new);
