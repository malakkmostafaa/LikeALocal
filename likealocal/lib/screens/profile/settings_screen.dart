import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  final AppUser user;

  const SettingsScreen({
    super.key,
    required this.user,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserService _userService = UserService();
  
  late bool chatEnabled;
  late bool notificationsEnabled;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    chatEnabled = widget.user.chatEnabled;
    notificationsEnabled = widget.user.notificationsEnabled;
  }

  Future<void> _updateSettings() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _userService.updateCurrentUser({
        'chatEnabled': chatEnabled,
        'notificationsEnabled': notificationsEnabled,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD96B41);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                "Preferences",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Notifications Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SwitchListTile(
                  title: const Text(
                    "Enable Notifications",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text("Receive updates and alerts"),
                  activeColor: primaryColor,
                  value: notificationsEnabled,
                  onChanged: (val) {
                    setState(() {
                      notificationsEnabled = val;
                    });
                    _updateSettings(); // auto save
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Chats Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SwitchListTile(
                  title: const Text(
                    "Enable Chats",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text("Allow others to message you"),
                  activeColor: primaryColor,
                  value: chatEnabled,
                  onChanged: (val) {
                    setState(() {
                      chatEnabled = val;
                    });
                    _updateSettings(); // auto save
                  },
                ),
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
                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
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
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            ),
        ],
      ),
    );
  }
}
