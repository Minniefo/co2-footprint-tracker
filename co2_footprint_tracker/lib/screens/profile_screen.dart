import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../screens/auth/login_screen.dart';
import '../screens/community/my_posts_screen.dart';
import '../screens/gamification/gamification_screen.dart';
import 'edit_profile_screen.dart';
import 'rewards/rewards_screen.dart';

const _kGreen = Color(0xFF2E7D32);
const _kBg = Color(0xFFF8FAFC);
const _kCardShadow = [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4))];

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDocumentProvider);
    final firebaseUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 22, color: Colors.black87)),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          final displayName = user?.displayName ?? firebaseUser?.displayName ?? 'Eco Warrior';
          final email = user?.email ?? firebaseUser?.email ?? '';
          final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                // ─── Header Card ───────────────────────────────────────────
                _sectionPad(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6))],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          backgroundImage: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty) ? CachedNetworkImageProvider(user!.photoUrl!) : null,
                          child: (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                              ? Text(initial, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white))
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(displayName, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(email, style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(user: user))),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // ─── Stats Row ─────────────────────────────────────────────
                _sectionPad(
                  child: Row(
                    children: [
                      Expanded(child: _StatCard(icon: Icons.eco_rounded, color: _kGreen, label: 'CO₂ Saved', value: '${(user?.totalCo2Kg ?? 0.0).toStringAsFixed(1)} kg')),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(icon: Icons.star_rounded, color: const Color(0xFFFF8F00), label: 'Points', value: '${user?.points ?? 0}')),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(icon: Icons.local_fire_department_rounded, color: const Color(0xFFE53935), label: 'Streak', value: '${user?.activeStreak ?? 0}d')),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ─── My Data ───────────────────────────────────────────────
                _SectionLabel(label: 'My Data'),
                _sectionPad(
                  child: _Card(
                    child: Column(
                      children: [
                        _NavTile(icon: Icons.military_tech_rounded, color: const Color(0xFFFF8F00), label: 'My Badges', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GamificationScreen()))),
                        _divider(),
                        _NavTile(icon: Icons.article_rounded, color: _kGreen, label: 'My Posts', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPostsScreen()))),
                        _divider(),
                        _NavTile(icon: Icons.wallet_giftcard_rounded, color: Colors.purple.shade600, label: 'Rewards & Vouchers', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsScreen()))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ─── Privacy Settings ──────────────────────────────────────
                if (user?.privacy != null) ...[
                  _SectionLabel(label: 'Privacy'),
                  _sectionPad(
                    child: _PrivacyCard(user: user!),
                  ),
                  const SizedBox(height: 8),
                ],

                // ─── Account ───────────────────────────────────────────────
                _SectionLabel(label: 'Account'),
                _sectionPad(
                  child: _Card(
                    child: Column(
                      children: [
                        _NavTile(
                          icon: Icons.person_outline_rounded,
                          color: Colors.blue.shade600,
                          label: 'Edit Profile',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(user: user))),
                        ),
                        _divider(),
                        _NavTile(
                          icon: Icons.logout_rounded,
                          color: Colors.red.shade500,
                          label: 'Logout',
                          labelColor: Colors.red.shade500,
                          onTap: () => _confirmLogout(context, ref),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log Out?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('You will be signed out of your account.', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.inter())),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Log Out', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
      }
    }
  }
}

// ─── Private helpers ────────────────────────────────────────────────────────

Widget _sectionPad({required Widget child}) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child);

Widget _divider() => const Divider(height: 1, indent: 56, endIndent: 0);

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 1.2)),
        ),
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: _kCardShadow),
        child: child,
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _kCardShadow,
        ),
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

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;
  const _NavTile({required this.icon, required this.color, required this.label, required this.onTap, this.labelColor});

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: labelColor ?? Colors.black87)),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
      );
}

class _PrivacyCard extends ConsumerWidget {
  final UserModel user;
  const _PrivacyCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacy = user.privacy!;
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: _kCardShadow),
      child: Column(
        children: [
          // Master toggle — Public Account
          _PrivacyToggle(
            icon: Icons.public_rounded,
            color: Colors.teal.shade600,
            label: 'Public Account',
            subtitle: 'Allow others to view your profile',
            value: privacy.isPublic,
            onChanged: (v) => ref.read(profileControllerProvider.notifier).updatePrivacy(
              isPublic: v,
              shareRank: privacy.shareRank,
              shareActivityDetails: privacy.shareActivityDetails,
            ),
          ),
          _divider(),
          // Sub-toggles (dimmed when account is private)
          Opacity(
            opacity: privacy.isPublic ? 1.0 : 0.45,
            child: Column(
              children: [
                _PrivacyToggle(
                  icon: Icons.leaderboard_rounded,
                  color: _kGreen,
                  label: 'Share Rank',
                  subtitle: 'Let others see your leaderboard rank',
                  value: privacy.shareRank,
                  onChanged: (v) => ref.read(profileControllerProvider.notifier).updatePrivacy(
                    isPublic: privacy.isPublic,
                    shareRank: v,
                    shareActivityDetails: privacy.shareActivityDetails,
                  ),
                ),
                _divider(),
                _PrivacyToggle(
                  icon: Icons.directions_car_rounded,
                  color: Colors.blue.shade600,
                  label: 'Share Activity Details',
                  subtitle: 'Let others see your logged activities',
                  value: privacy.shareActivityDetails,
                  onChanged: (v) => ref.read(profileControllerProvider.notifier).updatePrivacy(
                    isPublic: privacy.isPublic,
                    shareRank: privacy.shareRank,
                    shareActivityDetails: v,
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

class _PrivacyToggle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PrivacyToggle({required this.icon, required this.color, required this.label, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
        trailing: Switch.adaptive(value: value, onChanged: onChanged, activeThumbColor: _kGreen),
      );
}
