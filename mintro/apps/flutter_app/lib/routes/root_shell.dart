import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/learn/learn_screen.dart';
import '../screens/quests/quests_screen.dart';
import '../screens/ranks/ranks_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../widgets/mintro_bottom_nav.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    LearnScreen(),
    QuestsScreen(),
    RanksScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: _screens[_index],
        ),
      ),
      bottomNavigationBar: MintroBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
