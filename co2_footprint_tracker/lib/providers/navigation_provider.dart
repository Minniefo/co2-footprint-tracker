import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier to manage the current active index of the bottom navigation bar.
class NavigationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final navigationProvider = NotifierProvider<NavigationNotifier, int>(NavigationNotifier.new);
