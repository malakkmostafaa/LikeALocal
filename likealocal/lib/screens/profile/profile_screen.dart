import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';

const List<String> kAvailableCategories = [
  'Culture',
  'Food',
  'Nature',
  'Shopping',
  'Adventure',
  'Nightlife'
];

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // --- THEMED EDIT DIALOG ---
  void _showEditProfileDialog(
      BuildContext context, AppUser user, UserService userService) {
    final nameController = TextEditingController(text: user.name);
    double localDistance = user.maxDistance;
    int localPrice = user.priceRange;
    List<String> localPrefs = List.from(user.preferences);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setPopupState) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.orange, primary: Colors.orange.shade400),
          ),
          child: AlertDialog(
            backgroundColor: const Color(0xFFF9F7F4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: const Text("Edit Profile & Preferences",
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Interests",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: kAvailableCategories.map((category) {
                      final isSelected = localPrefs.contains(category);
                      return FilterChip(
                        label: Text(category,
                            style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (selected) => setPopupState(() => selected
                            ? localPrefs.add(category)
                            : localPrefs.remove(category)),
                      );
                    }).toList(),
                  ),
                  const Divider(height: 40),
                  Text("Search Radius: ${localDistance.toInt()} km",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: localDistance,
                    min: 1,
                    max: 50,
                    onChanged: (val) =>
                        setPopupState(() => localDistance = val),
                  ),
                  const SizedBox(height: 10),
                  const Text("Price Level",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [1, 2, 3]
                        .map((level) => ChoiceChip(
                              label: Text("\$" * level),
                              selected: localPrice == level,
                              onSelected: (s) =>
                                  setPopupState(() => localPrice = level),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel",
                      style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: StadiumBorder()),
                onPressed: () async {
                  await userService.updateUser(user.uid, {
                    'name': nameController.text.trim(),
                    'preferences': localPrefs,
                    'maxDistance': localDistance,
                    'priceRange': localPrice,
                  });
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4), // Main Theme Background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Profile",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          StreamBuilder<AppUser?>(
            stream: userService.getCurrentUser(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.black),
                onPressed: () => _showEditProfileDialog(
                    context, snapshot.data!, userService),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<AppUser?>(
        stream: userService.getCurrentUser(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final user = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Identity Section
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.orange.shade100,
                        child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : "👤",
                            style: TextStyle(
                                fontSize: 40, color: Colors.orange.shade800)),
                      ),
                      const SizedBox(height: 16),
                      Text(user.name,
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.bold)),
                      Text(user.email,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(color: Colors.black12),
                const SizedBox(height: 24),

                // Interests Section
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("My Interests:",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold))),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.preferences
                        .map((pref) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.black12)),
                              child: Text(pref,
                                  style: const TextStyle(fontSize: 14)),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 32),

                // Settings Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10)
                      ]),
                  child: Column(
                    children: [
                      _buildInfoRow("Radius", "${user.maxDistance.toInt()} km",
                          Icons.map_outlined),
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: Color(0xFFF9F7F4))),
                      _buildInfoRow("Price Range", "\$" * user.priceRange,
                          Icons.payments_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Status & Stats Row
                Row(
                  children: [
                    Expanded(
                        child: _buildStatusCard(
                            user.pinsCount.toString(), "Pins")),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildStatusCard(
                            user.isSuperUser ? "Super" : "Standard", "Status")),
                  ],
                ),
                const SizedBox(height: 48),

                // Logout
                TextButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted)
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (r) => false);
                  },
                  icon: const Icon(Icons.logout,
                      color: Colors.redAccent, size: 20),
                  label: const Text("Logout",
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.orange.shade300),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatusCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ],
      ),
    );
  }
}
