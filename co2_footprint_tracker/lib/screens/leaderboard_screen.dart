import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/leaderboard_provider.dart';
import '../models/leaderboard_entry.dart';
import 'public_profile_screen.dart';

const _kBg = Color(0xFFF8FAFC);
const _kGreen = Color(0xFF2E7D32);
const _kCardShadow = [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4))];

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(weeklyLeaderboardProvider);
    final weekLabel = ref.watch(currentWeekLabelProvider);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Leaderboard', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 22, color: Colors.black87)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _kGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(weekLabel, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _kGreen)),
            ),
          ),
        ],
      ),
      body: leaderboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: GoogleFonts.inter())),
        data: (entries) {
          if (entries.isEmpty) return _EmptyState();

          final top3 = entries.take(3).toList();
          final rest = entries.length > 3 ? entries.sublist(3) : <LeaderboardEntry>[];

          return RefreshIndicator(
            color: _kGreen,
            onRefresh: () async => ref.invalidate(weeklyLeaderboardProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // ── Podium top-3 ─────────────────────────────────────
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: _Podium(top3: top3, currentUid: currentUid),
                  ),

                  const SizedBox(height: 16),

                  // ── Section header ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text('Full Rankings', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87)),
                        const Spacer(),
                        Text('Resets every Sunday', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Table card ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _kCardShadow,
                      ),
                      child: Column(
                        children: [
                          // Table header row
                          _TableHeader(),

                          const Divider(height: 1),

                          // All entries
                          ...entries.asMap().entries.map((e) {
                            final index = e.key;
                            final entry = e.value;
                            final isLast = index == entries.length - 1;
                            final isCurrentUser = entry.userId == currentUid;
                            return Column(
                              children: [
                                _TableRow(
                                  entry: entry,
                                  isCurrentUser: isCurrentUser,
                                ),
                                if (!isLast) const Divider(height: 1, indent: 56),
                              ],
                            );
                          }),

                          // Pinned "my rank" footer if user is outside top list
                          if (currentUid != null && !entries.any((e) => e.userId == currentUid))
                            _OutsideRankFooter(uid: currentUid),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Podium ────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> top3;
  final String? currentUid;
  const _Podium({required this.top3, this.currentUid});

  @override
  Widget build(BuildContext context) {
    final first = top3.isNotEmpty ? top3[0] : null;
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (second != null)
          Expanded(child: _PodiumSlot(entry: second, label: '🥈', podiumColor: const Color(0xFF90A4AE), height: 80, isMe: second.userId == currentUid)),
        const SizedBox(width: 8),
        if (first != null)
          Expanded(child: _PodiumSlot(entry: first, label: '🥇', podiumColor: _kGreen, height: 112, isMe: first.userId == currentUid, large: true)),
        const SizedBox(width: 8),
        if (third != null)
          Expanded(child: _PodiumSlot(entry: third, label: '🥉', podiumColor: const Color(0xFFA1887F), height: 60, isMe: third.userId == currentUid)),
      ],
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final LeaderboardEntry entry;
  final String label;
  final Color podiumColor;
  final double height;
  final bool isMe;
  final bool large;
  const _PodiumSlot({required this.entry, required this.label, required this.podiumColor, required this.height, required this.isMe, this.large = false});

  @override
  Widget build(BuildContext context) {
    final double avatarRadius = large ? 26 : 20;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfileScreen(uid: entry.userId))),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: large ? 32 : 24)),
          const SizedBox(height: 6),
          CircleAvatar(
            radius: avatarRadius,
            backgroundImage: entry.photoUrl != null && entry.photoUrl!.isNotEmpty ? CachedNetworkImageProvider(entry.photoUrl!) : null,
            backgroundColor: podiumColor.withValues(alpha: 0.15),
            child: entry.photoUrl == null || entry.photoUrl!.isEmpty
                ? Text(
                    entry.displayName.isNotEmpty ? entry.displayName[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: podiumColor, fontSize: avatarRadius * 0.9),
                  )
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            entry.displayName,
            style: GoogleFonts.inter(fontSize: large ? 13 : 11, fontWeight: FontWeight.w700, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (isMe)
            Container(
              margin: const EdgeInsets.only(top: 3),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(8)),
              child: Text('You', style: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 6),
          Container(
            height: height,
            decoration: BoxDecoration(
              color: podiumColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${entry.points}', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: large ? 18 : 14, color: Colors.white)),
                Text('pts', style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withValues(alpha: 0.8))),
                const SizedBox(height: 2),
                Text('${entry.co2SavedKg.toStringAsFixed(1)}kg', style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withValues(alpha: 0.75))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Table ─────────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text('#', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.8), textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          Expanded(child: Text('USER', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.8))),
          SizedBox(width: 64, child: Text('CO₂', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.8), textAlign: TextAlign.center)),
          SizedBox(width: 60, child: Text('POINTS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.8), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;
  const _TableRow({required this.entry, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfileScreen(uid: entry.userId))),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        color: isCurrentUser ? _kGreen.withValues(alpha: 0.05) : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: isCurrentUser ? _kGreen.withValues(alpha: 0.12) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text('${entry.rank}', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: isCurrentUser ? _kGreen : Colors.grey.shade600)),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 20,
              backgroundImage: (entry.photoUrl != null && entry.photoUrl!.isNotEmpty) ? CachedNetworkImageProvider(entry.photoUrl!) : null,
              backgroundColor: isCurrentUser ? _kGreen.withValues(alpha: 0.15) : Colors.amber.withValues(alpha: 0.15),
              child: (entry.photoUrl == null || entry.photoUrl!.isEmpty)
                  ? Text(entry.displayName.isNotEmpty ? entry.displayName[0].toUpperCase() : '?', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: isCurrentUser ? _kGreen : Colors.amber.shade800))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Flexible(child: Text(entry.displayName, style: GoogleFonts.inter(fontWeight: isCurrentUser ? FontWeight.w800 : FontWeight.w600, fontSize: 14, color: isCurrentUser ? _kGreen : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (isCurrentUser) ...[
                    const SizedBox(width: 6),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(6)), child: Text('You', style: GoogleFonts.inter(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold))),
                  ],
                ],
              ),
            ),
            SizedBox(width: 64, child: Text('${entry.co2SavedKg.toStringAsFixed(1)} kg', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.center)),
            SizedBox(width: 60, child: Text('${entry.points}', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15, color: isCurrentUser ? _kGreen : Colors.black87), textAlign: TextAlign.right)),
          ],
        ),
      ),
    );
  }
}

class _OutsideRankFooter extends ConsumerWidget {
  final String uid;
  const _OutsideRankFooter({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _kGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: _kGreen, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text("You're not in the top 50 yet. Keep logging activities!", style: GoogleFonts.inter(fontSize: 13, color: _kGreen, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.leaderboard_rounded, size: 56, color: _kGreen),
          ),
          const SizedBox(height: 20),
          Text('No rankings yet!', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text('Log activities to appear on the leaderboard.', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
