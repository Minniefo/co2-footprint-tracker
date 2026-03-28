import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/voucher_provider.dart';
import '../../models/voucher_model.dart';
import 'my_vouchers_screen.dart';

const _kBg = Color(0xFFF8FAFC);
const _kCardShadow = [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4))];

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vouchersAsync = ref.watch(availableVouchersProvider);
    final actionState = ref.watch(voucherActionProvider);

    // Listen to action state to show snackbars on success/error
    ref.listen<AsyncValue<void>>(
      voucherActionProvider,
      (_, state) {
        if (!state.isLoading && state.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red.shade800,
            ),
          );
        } else if (!state.isLoading && !state.hasError && state.hasValue) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voucher redeemed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text('Rewards', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 22, color: Colors.black87)),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyVouchersScreen())),
            icon: const Icon(Icons.wallet_giftcard_rounded, color: Colors.green),
            label: Text('My Vouchers', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.green)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: vouchersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading rewards: $err')),
        data: (vouchers) {
          if (vouchers.isEmpty) {
            return Center(
              child: Text(
                'No vouchers available right now.',
                style: GoogleFonts.inter(color: Colors.grey.shade600),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(availableVouchersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: vouchers.length,
              itemBuilder: (context, index) {
                final voucher = vouchers[index];
                return _VoucherCard(voucher: voucher, isProcessing: actionState.isLoading);
              },
            ),
          );
        },
      ),
    );
  }
}

class _VoucherCard extends ConsumerWidget {
  final Voucher voucher;
  final bool isProcessing;
  const _VoucherCard({required this.voucher, required this.isProcessing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _kCardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star_rounded, color: Colors.orange, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        voucher.title,
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${voucher.pointsRequired} Points',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              voucher.description,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isProcessing ? null : () => _confirmRedeem(context, ref, voucher),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: isProcessing 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        'Redeem Voucher',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRedeem(BuildContext context, WidgetRef ref, Voucher voucher) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Redeem Voucher?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          'This will deduct ${voucher.pointsRequired} points from your balance.',
          style: GoogleFonts.inter(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // close dialog
              ref.read(voucherActionProvider.notifier).redeem(voucher);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Confirm', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
