import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'explore/explore_screen.dart';
import 'add_place/add_place_screen.dart';
import 'game/game_screen.dart';
import 'map/map_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  final List<Widget> screens = const [
    ExploreScreen(),
    AddPlaceScreen(),
    MapScreen(),
    GameScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() => currentIndex = index);
        },
        selectedItemColor: const Color(0xFFE26D45),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.explore_rounded),
            label: 'nav.explore'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: 'nav.add'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.map_rounded),
            label: 'nav.map'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.sports_esports_rounded),
            label: 'nav.game'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_rounded),
            label: 'nav.profile'.tr(),
          ),
        ],
      ),
    );
  }
}
