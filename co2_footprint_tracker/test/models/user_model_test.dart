import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co2_footprint_tracker/models/user.dart';

void main() {
  group('UserModel', () {
    test('activeStreak assumes 0 if there is no streak or lastActiveAt', () {
      final user = UserModel(
        email: 'test@example.com',
        streak: 0,
        lastActiveAt: null,
      );
      expect(user.activeStreak, 0);
      expect(user.isStreakAtRisk, false);
    });

    test('activeStreak remains valid if last action was today', () {
      final user = UserModel(
        email: 'test@example.com',
        streak: 5,
        lastActiveAt: Timestamp.fromDate(DateTime.now()),
      );
      expect(user.activeStreak, 5);
      expect(user.isStreakAtRisk, false);
    });

    test('activeStreak remains valid but is at risk if last action was yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final user = UserModel(
        email: 'test@example.com',
        streak: 10,
        lastActiveAt: Timestamp.fromDate(yesterday),
      );
      expect(user.activeStreak, 10);
      expect(user.isStreakAtRisk, true);
    });

    test('activeStreak instantly drops to 0 if last action was 2 days ago', () {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      final user = UserModel(
        email: 'test@example.com',
        streak: 15,
        lastActiveAt: Timestamp.fromDate(twoDaysAgo),
      );
      
      // Despite DB claiming a streak of 15, the frontend validation overrides it
      expect(user.streak, 15);
      expect(user.activeStreak, 0);
      expect(user.isStreakAtRisk, false); 
    });
  });
}
