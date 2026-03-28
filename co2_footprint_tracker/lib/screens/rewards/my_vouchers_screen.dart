import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/voucher_provider.dart';
import '../../models/user_voucher_model.dart';

const _kBg = Color(0xFFF8FAFC);
const _kCardShadow = [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 4))];

class MyVouchersScreen extends ConsumerWidget {
  const MyVouchersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myVouchersAsync = ref.watch(myVouchersProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text('My Vouchers', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.black87)),
      ),
      body: myVouchersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (vouchers) {
          if (vouchers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_rounded, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No vouchers yet!', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text('Redeem your points for rewards to see them here.', style: GoogleFonts.inter(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: vouchers.length,
            itemBuilder: (context, index) {
              return _RedeemedVoucherCard(userVoucher: vouchers[index]);
            },
          );
        },
      ),
    );
  }
}

class _RedeemedVoucherCard extends StatelessWidget {
  final UserVoucher userVoucher;
  const _RedeemedVoucherCard({required this.userVoucher});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy').format(userVoucher.redeemedAt.toDate());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userVoucher.title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text('Redeemed: $dateStr', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Dash line separator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(
                30, 
                (index) => Expanded(
                  child: Container(
                    height: 1, 
                    color: index.isEven ? Colors.grey.shade300 : Colors.transparent
                  )
                )
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('VOUCHER CODE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: userVoucher.voucherCode));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voucher code copied to clipboard!')));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          userVoucher.voucherCode,
                          style: GoogleFonts.robotoMono(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green.shade800, letterSpacing: 3),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.copy_rounded, color: Colors.grey.shade600, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
