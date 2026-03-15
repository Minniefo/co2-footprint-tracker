import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../widgets/badge_item.dart';

class GamificationScreen extends ConsumerWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateChangesProvider);
    final user = userAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: Text('Please log in'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCard(context, ref, user.uid),
                  const SizedBox(height: 24),
                  const Text(
                    'Badges',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildBadgesGrid(context, ref),
                  const SizedBox(height: 24),
                  const Text(
                    'Recent Points History',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildPointsHistory(context, ref),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCard(BuildContext context, WidgetRef ref, String userId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: FutureBuilder(
        future: ref.read(firestoreProvider).collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          int points = 0;
          int streak = 0;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data();
            points = data?['points'] as int? ?? 0;
            streak = data?['streak'] as int? ?? 0;
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('Points', points.toString(), Icons.stars),
              Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.5)),
              _buildStatColumn('Day Streak', streak.toString(), Icons.local_fire_department),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesGrid(BuildContext context, WidgetRef ref) {
    final allBadgesAsync = ref.watch(allBadgesProvider);
    final userBadgesAsync = ref.watch(userBadgesProvider);

    return allBadgesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error loading badges: $err'),
      data: (allBadges) {
        if (allBadges.isEmpty) {
          return const Center(child: Text('No badges available yet.'));
        }

        return userBadgesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Error loading your badges: $err'),
          data: (userBadges) {
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: allBadges.length,
              itemBuilder: (context, index) {
                final badge = allBadges[index];
                
                // Check if user has this badge
                final userBadgeIndex = userBadges.indexWhere((ub) => ub.badgeId == badge.badgeId);
                final isGranted = userBadgeIndex != -1;
                final grantedAt = isGranted ? userBadges[userBadgeIndex].grantedAt.toDate() : null;

                return BadgeItem(
                  badge: badge,
                  isGranted: isGranted,
                  grantedAt: grantedAt,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPointsHistory(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(pointHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error loading history: $err'),
      data: (history) {
        if (history.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No points earned yet. Log activities to start earning!'),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final tx = history[index];
            final date = tx.createdAt.toDate();
            
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: const Icon(Icons.add, color: Colors.green),
              ),
              title: Text(tx.reason),
              subtitle: Text('${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}'),
              trailing: Text(
                '+${tx.amount}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
