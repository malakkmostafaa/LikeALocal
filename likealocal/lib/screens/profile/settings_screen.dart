import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/language.dart';

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

  static const Color primaryColor = Color(0xFFD96B41);

  @override
  void initState() {
    super.initState();
    chatEnabled = widget.user.chatEnabled;
    notificationsEnabled = widget.user.notificationsEnabled;
  }

  Future<void> _updateSettings() async {
    setState(() => isLoading = true);
    try {
      await _userService.updateCurrentUser({
        'chatEnabled': chatEnabled,
        'notificationsEnabled': notificationsEnabled,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('settings.saved'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('settings.save_error'.tr(namedArgs: {'error': '$e'}))),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'settings.choose_language'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F1F28),
                  ),
                ),
                const SizedBox(height: 16),
                ...supportedAppLanguages.map((lang) {
                  final isSelected = context.locale == lang.locale;
                  return ListTile(
                    leading: Text(
                      lang.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      lang.translationKey.tr(),
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w900
                            : FontWeight.w600,
                        color: isSelected
                            ? primaryColor
                            : const Color(0xFF1F1F28),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_rounded, color: primaryColor)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await changeAppLanguage(context, lang.locale);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'settings.title'.tr(),
          style: const TextStyle(
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
              Text(
                'settings.preferences'.tr(),
                style: const TextStyle(
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
                  title: Text(
                    'settings.notifications_title'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('settings.notifications_subtitle'.tr()),
                  activeColor: primaryColor,
                  value: notificationsEnabled,
                  onChanged: (val) {
                    setState(() => notificationsEnabled = val);
                    _updateSettings();
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
                  title: Text(
                    'settings.chats_title'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('settings.chats_subtitle'.tr()),
                  activeColor: primaryColor,
                  value: chatEnabled,
                  onChanged: (val) {
                    setState(() => chatEnabled = val);
                    _updateSettings();
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Language Picker
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.language_rounded,
                    color: primaryColor,
                  ),
                  title: Text(
                    'settings.language_title'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('settings.language_subtitle'.tr()),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF777777),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  onTap: _showLanguagePicker,
                ),
              ),

              const SizedBox(height: 40),

              // Logout
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
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    side: BorderSide(color: Colors.red.shade400),
                  ),
                  icon: Icon(Icons.logout, color: Colors.red.shade400),
                  label: Text(
                    'settings.logout'.tr(),
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
