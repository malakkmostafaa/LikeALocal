import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:like_a_local/models/user_model.dart';
import 'package:like_a_local/screens/profile/edit_profile_screen.dart';
import 'package:like_a_local/screens/profile/settings_screen.dart';
import 'package:like_a_local/screens/profile/super_user_screen.dart';
import 'package:like_a_local/screens/profile/subscription_plans_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../chat/ai_chat_screen.dart';
import '../explore/place_details_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F6F3),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final uid = currentUser.uid;

    const primaryColor = Color(0xFFD96B41);
    const backgroundColor = Color(0xFFF8F6F3);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(includeMetadataChanges: true),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_off_outlined,
                        size: 56,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Profile is being created...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'If this stays for more than a few seconds, log out and sign up again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              );
            }

            final userData =
                snapshot.data!.data() as Map<String, dynamic>;
            final user = AppUser.fromMap(userData);

            String joinedText = "Joined recently";
            if (user.createdAt != null) {
              joinedText =
                  "Joined ${_monthName(user.createdAt!.month)} ${user.createdAt!.year}";
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TOP BAR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Profile",
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SettingsScreen(user: user),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.settings_outlined),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // USER SECTION
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 46,
                              backgroundColor:
                                  primaryColor.withOpacity(0.12),
                              backgroundImage:
                                  user.profileImageUrl.isNotEmpty
                                      ? CachedNetworkImageProvider(
                                          user.profileImageUrl,
                                        )
                                      : null,
                              child: user.profileImageUrl.isEmpty
                                  ? const Icon(Icons.person,
                                      size: 46, color: primaryColor)
                                  : null,
                            ),
                            if (user.isSuperUser)
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: const Icon(
                                  Icons.workspace_premium,
                                  size: 18,
                                  color: Color(0xFFE5A11A),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(width: 20),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(user.name,
                                  style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900)),
                              if (user.bio.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(user.bio,
                                    style: TextStyle(
                                        color: Colors.grey.shade700)),
                              ],
                              const SizedBox(height: 12),
                              Text(
                                joinedText,
                                style: TextStyle(
                                    color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // STATS
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.place_outlined,
                          value: user.placesAdded.toString(),
                          label: "Places",
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.star_outline,
                          value: user.reviewsCount.toString(),
                          label: "Reviews",
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.bookmark_border,
                          value: user.pinsCount.toString(),
                          label: "Pins",
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // EDIT PROFILE BUTTON
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EditProfileScreen(user: user),
                      ),
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit Profile"),
                  ),

                  const SizedBox(height: 26),

                  // PREFERENCES
                  const Text("Preferences",
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: user.preferences.map((pref) {
                      return Chip(label: Text(pref));
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // SUPER USER SECTION
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SuperUserScreen(user: user),
                      ),
                    ),
                    child: _buildCard(
                      title: user.isSuperUser
                          ? "Super User Status"
                          : "Super User Progress",
                      subtitle: user.isSuperUser
                          ? "You have unlocked all perks!"
                          : "View badges and requirements",
                    ),
                  ),

                  const SizedBox(height: 20),

                  // PREMIUM SECTION
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SubscriptionPlansScreen(user: user),
                      ),
                    ),
                    child: _buildCard(
                      title: user.isPremium
                          ? "Premium Active"
                          : "Upgrade to Premium",
                      subtitle: user.isPremium
                          ? "You have unlimited pins"
                          : "Unlock unlimited features",
                    ),
                  ),

                  const SizedBox(height: 28),

                  // AI GUIDE BUTTON
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AiChatScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text("AI Local Guide"),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAEBE1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle),
        ],
      ),
    );
  }

  static String _monthName(int month) {
    const months = [
      '',
      'January','February','March','April',
      'May','June','July','August',
      'September','October','November','December',
    ];
    return months[month];
  }
}