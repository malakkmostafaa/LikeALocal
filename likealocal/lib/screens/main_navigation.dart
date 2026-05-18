import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/incoming_notification_service.dart';
import '../services/reminder_geofence_service.dart';
import 'home/home_screen.dart';
import 'explore/explore_screen.dart';
import 'add_place/add_place_screen.dart';
import 'map/map_screen.dart';
//import 'chat/chat_screen.dart';
import 'profile/profile_screen.dart';
import 'notifications/notifications_screen.dart';
import 'game/game_screen.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_bell.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  static const _primary = Color(0xFFE26D45);

  @override
  void initState() {
    super.initState();
    IncomingNotificationService.start();
    ReminderGeofenceService.syncFromFirestore();
  }

  @override
  void dispose() {
    IncomingNotificationService.stop();
    super.dispose();
  }

  final List<Widget> screens = const [
    ExploreScreen(),
    GameScreen(),
    AddPlaceScreen(),
    MapScreen(),
    //ChatScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Notification bell persists across all tabs via the AppBar overlay
      body: IndexedStack(
        // remove the Stack wrapper entirely
        index: currentIndex,
        children: screens,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        selectedItemColor: _primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports_rounded),
            label: 'Game',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            label: 'Map',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.chat_bubble_outline_rounded),
          //   label: 'Chats',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
