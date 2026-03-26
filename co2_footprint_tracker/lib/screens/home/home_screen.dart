import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/navigation_provider.dart';
import '../activity/add_activity_screen.dart';
import '../auth/login_screen.dart';
import '../gamification/gamification_screen.dart';
import '../community/community_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/leaderboard_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<Widget> _screens = [
    const HomeDashboard(),
    const AddActivityScreen(),
    const CommunityScreen(),
    const LeaderboardScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBody: true, // Important for the curved bar to show background properly
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: currentIndex,
        height: 55,
        items: const [
          Icon(Icons.home_rounded, size: 30, color: Colors.white),
          Icon(Icons.add_rounded, size: 30, color: Colors.white),
          Icon(Icons.people_rounded, size: 30, color: Colors.white),
          Icon(Icons.leaderboard_rounded, size: 30, color: Colors.white),
          Icon(Icons.person_rounded, size: 30, color: Colors.white),
        ],
        color: Colors.green.shade700,
        buttonBackgroundColor: Colors.green.shade700,
        backgroundColor: Colors.transparent, // Background of the gap
        animationCurve: Curves.easeInOutBack,
        animationDuration: const Duration(milliseconds: 350),
        onTap: (index) => ref.read(navigationProvider.notifier).setIndex(index),
        letIndexChange: (index) => true,
      ),
    );
  }
}

class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDocumentProvider);
    final activitiesAsync = ref.watch(userActivitiesProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: userAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('User Error: $err')),
          data: (userModel) => activitiesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Activity Error: $err')),
            data: (activities) {
              // Calculate Today's footprint
              double todayFootprint = 0.0;
              double transportFootprint = 0.0;
              double foodFootprint = 0.0;
              double energyFootprint = 0.0;
              
              final now = DateTime.now();
              for (var activity in activities) {
                final activityDate = activity.createdAt.toDate();
                if (activityDate.year == now.year && 
                    activityDate.month == now.month && 
                    activityDate.day == now.day) {
                  todayFootprint += activity.co2Kg;
                  
                  if (activity.activityType == 'transport') {
                    transportFootprint += activity.co2Kg;
                  } else if (activity.activityType == 'food') {
                    foodFootprint += activity.co2Kg;
                  } else if (activity.activityType == 'energy') {
                    energyFootprint += activity.co2Kg;
                  }
                }
              }

              final firebaseUser = FirebaseAuth.instance.currentUser;
              final displayName = (userModel?.displayName?.isNotEmpty == true)
                  ? userModel!.displayName!
                  : ((firebaseUser?.email?.isNotEmpty == true) ? firebaseUser!.email!.split('@')[0] : 'Eco Warrior');
              final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

              final points = userModel?.points ?? 0;
              final streak = userModel?.streak ?? 0;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // 1. Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Hello,', style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade600)),
                                    Text(
                                      displayName,
                                      style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (val) async {
                                  if (val == 'logout') {
                                    await ref.read(authControllerProvider.notifier).logout();
                                    if (context.mounted) {
                                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
                                    }
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  PopupMenuItem(
                                    value: 'logout', 
                                    child: Row(
                                      children: [
                                        const Icon(Icons.logout, color: Colors.red, size: 20),
                                        const SizedBox(width: 8),
                                        Text('Logout', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w600)),
                                      ],
                                    )
                                  ),
                                ],
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.green.shade100,
                                  backgroundImage: userModel?.photoUrl != null ? NetworkImage(userModel!.photoUrl!) : null,
                                  child: userModel?.photoUrl == null 
                                      ? Text(initial, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.green.shade800)) 
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GamificationScreen())),
                            child: Row(
                              children: [
                                Expanded(child: _buildHeaderMetricCard(
                                  icon: Icons.local_fire_department,
                                  color: Colors.orange,
                                  value: streak.toString(),
                                  label: 'Day Streak',
                                )),
                                const SizedBox(width: 15),
                                Expanded(child: _buildHeaderMetricCard(
                                  icon: Icons.star_rounded,
                                  color: Colors.amber,
                                  value: points.toString(),
                                  label: 'Points',
                                )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 2. Body
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildMainFootprintCard(todayFootprint),
                          const SizedBox(height: 24),
                          _buildCategoryBreakdown(todayFootprint, transportFootprint, foodFootprint, energyFootprint),
                          const SizedBox(height: 24),
                          _buildQuickTips(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildHeaderMetricCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color.withValues(alpha: 0.9),
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainFootprintCard(double todayFootprint) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.eco, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                "Today's Footprint",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                todayFootprint.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  "kg CO₂",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(double total, double transport, double food, double energy) {
    final tPct = total > 0 ? transport / total : 0.0;
    final fPct = total > 0 ? food / total : 0.0;
    final ePct = total > 0 ? energy / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emissions by Category',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _buildCategoryItem('Transport', '${transport.toStringAsFixed(1)} kg', tPct, Colors.blue),
          const SizedBox(height: 16),
          _buildCategoryItem('Food', '${food.toStringAsFixed(1)} kg', fPct, Colors.orange),
          const SizedBox(height: 16),
          _buildCategoryItem('Energy', '${energy.toStringAsFixed(1)} kg', ePct, Colors.green),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String category, String amount, double percentage, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            category == 'Transport' ? Icons.directions_car
            : category == 'Food' ? Icons.restaurant
            : Icons.bolt,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: color.withValues(alpha: 0.1),
                  color: color,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          amount,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickTips() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'AI Suggestion',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Try using public transport instead of driving for your next commute. You could save up to 2.4 kg of CO₂!',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.blue.shade900,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// end of file