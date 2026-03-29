import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/public_profile_provider.dart';
import '../models/user.dart';
import '../models/leaderboard_entry.dart';

const _kGreen = Color(0xFF2E7D32);
const _kBg = Color(0xFFF8FAFC);
const _kCardShadow = [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4))];

class PublicProfileScreen extends ConsumerWidget {
  final String uid;
  const PublicProfileScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(uid));
    final rankAsync = ref.watch(publicProfileRankProvider(uid));
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwnProfile = currentUid == uid;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: Text('Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.black87)),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _EmptyState(message: 'Profile not found'),
        data: (user) {
          if (user == null) return const _EmptyState(message: 'Profile not found');

          final privacy = user.privacy ?? PrivacySettings(shareRank: true, shareActivityDetails: false);
          final name = user.displayName ?? 'Eco Warrior';
          final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
          final isPublic = privacy.isPublic;
          // Own profile is always visible to self
          final showContent = isOwnProfile || isPublic;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                // ── Header ─────────────────────────────────────────────────
                _pad(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF43A047)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6))],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white24,
                          backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty) ? CachedNetworkImageProvider(user.photoUrl!) : null,
                          child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                              ? Text(initial, style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white))
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              if (!isPublic)
                                Row(children: [
                                  const Icon(Icons.lock_rounded, color: Colors.white70, size: 14),
                                  const SizedBox(width: 4),
                                  Text(isOwnProfile ? 'Private account (Visible to you)' : 'Private account', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                                ])
                              else
                                Row(children: [
                                  const Icon(Icons.public_rounded, color: Colors.white70, size: 14),
                                  const SizedBox(width: 4),
                                  Text('Public account', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                                ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Private gate ───────────────────────────────────────────
                if (!showContent) ...[
                  const SizedBox(height: 24),
                  _pad(
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: _kCardShadow),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                            child: Icon(Icons.lock_rounded, size: 40, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 16),
                          Text('This account is private', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87)),
                          const SizedBox(height: 8),
                          Text('This user has set their profile to private.', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // ── Stats row ─────────────────────────────────────────────
                  _pad(
                    child: Row(
                      children: [
                        Expanded(child: _StatCard(icon: Icons.eco_rounded, color: _kGreen, label: 'CO₂ Saved', value: '${(user.totalCo2Kg ?? 0).toStringAsFixed(1)} kg')),
                        const SizedBox(width: 10),
                        Expanded(child: _StatCard(icon: Icons.star_rounded, color: const Color(0xFFFF8F00), label: 'Points', value: '${user.points ?? 0}')),
                        const SizedBox(width: 10),
                        Expanded(child: _StatCard(icon: Icons.local_fire_department_rounded, color: const Color(0xFFE53935), label: 'Streak', value: '${user.activeStreak ?? 0}d')),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Rank card ─────────────────────────────────────────────
                  if (privacy.shareRank)
                    rankAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (entry) => entry != null
                          ? _pad(child: _RankCard(entry: entry))
                          : const SizedBox.shrink(),
                    ),

                  // ── Activity summary ──────────────────────────────────────
                  if (privacy.shareActivityDetails) ...[
                    const SizedBox(height: 4),
                    _pad(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: _kCardShadow),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                              child: const Icon(Icons.bar_chart_rounded, color: _kGreen, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Activity Summary', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(user.totalCo2Kg ?? 0).toStringAsFixed(1)} kg of CO₂ saved in total',
                                    style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],

                // ── Eco Lifestyle ──────────────────────────────────────────
                if (showContent && (user.country != null || user.homeType != null || user.dietType != null || user.householdSize != null || user.preferredTransport != null)) ...[
                  const SizedBox(height: 12),
                  _SectionLabel(label: 'Eco Lifestyle'),
                  _pad(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: _kCardShadow),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (user.country != null && user.country!.isNotEmpty)
                            _InfoRow(icon: Icons.public_rounded, title: 'Location', value: user.country!),
                          if (user.homeType != null && user.homeType!.isNotEmpty)
                            _InfoRow(icon: Icons.home_rounded, title: 'Home', value: _fmt(user.homeType)),
                          if (user.dietType != null && user.dietType!.isNotEmpty)
                            _InfoRow(icon: Icons.restaurant_menu_rounded, title: 'Diet', value: _fmt(user.dietType)),
                          if (user.householdSize != null)
                            _InfoRow(icon: Icons.people_rounded, title: 'Household', value: '${user.householdSize} ${user.householdSize == 1 ? 'person' : 'people'}'),
                          if (user.preferredTransport != null && user.preferredTransport!.isNotEmpty)
                            _InfoRow(icon: Icons.directions_car_rounded, title: 'Transport', value: _fmt(user.preferredTransport)),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // ── Share buttons (own profile only) ──────────────────────
                if (isOwnProfile) ...[
                  _SectionLabel(label: 'Share Your Progress'),
                  _pad(
                    child: Column(
                      children: [
                        _ShareButton(
                          icon: Icons.leaderboard_rounded,
                          label: 'Share My Rank',
                          onTap: () => rankAsync.whenData((entry) {
                            final rank = entry?.rank;
                            final text = rank != null
                                ? '🏆 I\'m ranked #$rank this week on CO₂ Tracker!\nEvery action counts 🌱 #CarbonFootprint'
                                : '🌱 I\'m tracking my carbon footprint on CO₂ Tracker! #CarbonFootprint';
                            Share.share(text);
                          }),
                        ),
                        const SizedBox(height: 10),
                        _ShareButton(
                          icon: Icons.eco_rounded,
                          label: 'Share My CO₂ Savings',
                          color: Colors.teal.shade600,
                          onTap: () {
                            final co2 = (user.totalCo2Kg ?? 0).toStringAsFixed(1);
                            Share.share(
                              '🌍 I\'ve saved $co2 kg of CO₂ using CO₂ Tracker!\nJoin me in reducing our carbon footprint 🌱 #ClimateAction',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Helpers ───────────────────────────────────────────────────────────────

Widget _pad({required Widget child}) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child);

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 1.2)),
        ),
      );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _StatCard({required this.icon, required this.color, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: _kCardShadow),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500), textAlign: TextAlign.center),
          ],
        ),
      );
}

class _RankCard extends StatelessWidget {
  final LeaderboardEntry entry;
  const _RankCard({required this.entry});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _kCardShadow,
          border: Border.all(color: _kGreen.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.leaderboard_rounded, color: _kGreen, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Weekly Rank', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87)),
                  Text('${entry.points} pts · ${entry.co2SavedKg.toStringAsFixed(1)} kg CO₂', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Text('#${entry.rank}', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 28, color: _kGreen)),
          ],
        ),
      );
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _ShareButton({required this.icon, required this.label, required this.onTap, this.color});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? _kGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: Icon(Icons.person_off_rounded, size: 48, color: Colors.grey.shade400)),
            const SizedBox(height: 16),
            Text(message, style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoRow({required this.icon, required this.title, required this.value});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF2E7D32).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87))),
          Text(value, style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

String _fmt(String? val) {
  if (val == null || val.isEmpty) return '';
  if (val == 'mixed') return 'Mixed';
  if (val == 'public_transport') return 'Public Transport';
  if (val == 'electric_vehicle') return 'Electric Vehicle';
  if (val == 'condo') return 'Condo';
  return val[0].toUpperCase() + val.substring(1);
}
