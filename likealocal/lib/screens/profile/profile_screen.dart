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
              return const Center(child: Text("User not found"));
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
                              builder: (_) => SettingsScreen(user: user)),
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 46,
                                backgroundColor:
                                    primaryColor.withOpacity(0.12),
                                backgroundImage:
                                    user.profileImageUrl.isNotEmpty
                                        ? CachedNetworkImageProvider(
                                            user.profileImageUrl)
                                        : null,
                                child: user.profileImageUrl.isEmpty
                                    ? const Icon(Icons.person,
                                        size: 46, color: primaryColor)
                                    : null,
                              ),
                            ),
                            if (user.isSuperUser)
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.workspace_premium,
                                      size: 18, color: Color(0xFFE5A11A)),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(width: 20),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(user.name,
                                  style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5)),
                              if (user.bio.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(user.bio,
                                    style: TextStyle(
                                        fontSize: 14,
                                        height: 1.4,
                                        color: Colors.grey.shade700)),
                              ],
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(joinedText,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600)),
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
                              color: primaryColor)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildStatCard(
                              icon: Icons.star_outline,
                              value: user.reviewsCount.toString(),
                              label: "Reviews",
                              color: primaryColor)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildStatCard(
                              icon: Icons.bookmark_border,
                              value: user.pinsCount.toString(),
                              label: "Pins",
                              color: primaryColor)),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // EDIT PROFILE BUTTON
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD96B41), Color(0xFFE88A66)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EditProfileScreen(user: user)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28)),
                      ),
                      icon: const Icon(Icons.edit_rounded, color: Colors.white),
                      label: const Text("Edit Profile",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5)),
                    ),
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
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(pref,
                            style: const TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // SUPER USER SECTION
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SuperUserScreen(user: user)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAEBE1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: primaryColor.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                              color: primaryColor.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.workspace_premium,
                                color: primaryColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.isSuperUser
                                      ? "Super User Status"
                                      : "Super User Progress",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.isSuperUser
                                      ? "You have unlocked all perks!"
                                      : "View badges and requirements",
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              size: 16, color: primaryColor),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // PREMIUM SUBSCRIPTION SECTION
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              SubscriptionPlansScreen(user: user)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: user.isPremium
                              ? primaryColor.withOpacity(0.5)
                              : Colors.grey.shade300,
                          width: user.isPremium ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: user.isPremium
                                  ? primaryColor.withOpacity(0.15)
                                  : Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.star_rounded,
                                color: user.isPremium
                                    ? primaryColor
                                    : Colors.grey.shade600,
                                size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.isPremium
                                      ? "Premium Active"
                                      : "Upgrade to Premium Plus",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: user.isPremium
                                          ? primaryColor
                                          : Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.isPremium
                                      ? "You have unlimited pins"
                                      : "Unlock unlimited pins & features",
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              size: 16,
                              color: user.isPremium
                                  ? primaryColor
                                  : Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // AI GUIDE BUTTON
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AiChatScreen()),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD85A30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome,
                              color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text('AI Local Guide',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // TEMP TEST BUTTON - remove before final submission
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PlaceDetailsScreen(
                          placeId: 'test_place_id',
                          placeName: 'Café Riche',
                          category: 'Cafés',
                          description:
                              'A legendary spot in downtown Cairo with amazing Turkish coffee and a century of history.',
                        ),
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Text('Test Place Details',
                            style:
                                TextStyle(fontWeight: FontWeight.w600)),
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
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  static String _monthName(int month) {
    const months = [
      '',
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];
    return months[month];
  }
}