import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:like_a_local/models/user_model.dart';
import 'package:like_a_local/screens/profile/edit_profile_screen.dart';
import 'package:like_a_local/services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    const primaryColor = Color(0xFFD96B41);
    const backgroundColor = Color(0xFFF8F6F3);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {
            // LOADING
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // NO USER
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text("User not found"),
              );
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;

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
                  // =========================
                  // TOP BAR
                  // =========================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Profile",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.settings_outlined,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // =========================
                  // USER SECTION
                  // =========================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PROFILE IMAGE
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: primaryColor.withOpacity(0.12),
                        backgroundImage: user.profileImageUrl.isNotEmpty
                            ? NetworkImage(
                                user.profileImageUrl,
                              )
                            : null,
                        child: user.profileImageUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 46,
                                color: primaryColor,
                              )
                            : null,
                      ),

                      const SizedBox(width: 18),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // NAME + BADGE
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (user.isSuperUser)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF1D6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.workspace_premium,
                                          size: 16,
                                          color: Color(0xFFE5A11A),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          "Super User",
                                          style: TextStyle(
                                            color: Color(0xFFE5A11A),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // BIO
                            Text(
                              user.bio,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                color: Colors.grey.shade700,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // JOINED
                            Text(
                              joinedText,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // =========================
                  // STATS
                  // =========================
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

                  // =========================
                  // EDIT PROFILE BUTTON
                  // =========================
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(user: user),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        side: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: primaryColor,
                      ),
                      label: const Text(
                        "Edit Profile",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  // =========================
                  // PREFERENCES
                  // =========================
                  const Text(
                    "Preferences",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: user.preferences.map((pref) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          pref,
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // =========================
                  // BADGES
                  // =========================
                  const Text(
                    "Badges",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: user.badges.map((badge) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1D6),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Color(0xFFE5A11A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 40),

                  // =========================
                  // LOGOUT BUTTON
                  // =========================
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await AuthService().logout();
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        side: BorderSide(
                          color: Colors.red.shade400,
                        ),
                      ),
                      icon: Icon(
                        Icons.logout,
                        color: Colors.red.shade400,
                      ),
                      label: Text(
                        "Logout",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
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

  // =========================
  // STAT CARD
  // =========================
  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // MONTH NAME
  // =========================
  static String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month];
  }
}
