import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  final AppUser user;

  const SettingsScreen({super.key, required this.user});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserService _userService = UserService();

  late bool chatEnabled;
  late bool notificationsEnabled;
  int? chatStartHour;
  int? chatEndHour;
  bool isLoading = false;

  static const _primary = Color(0xFFE26D45);
  static const _bg = Color(0xFFF8F6F3);

  @override
  void initState() {
    super.initState();
    chatEnabled = widget.user.chatEnabled;
    notificationsEnabled = widget.user.notificationsEnabled;
    chatStartHour = widget.user.chatStartHour;
    chatEndHour = widget.user.chatEndHour;
  }

  Future<void> _save(Map<String, dynamic> fields) async {
    setState(() => isLoading = true);
    try {
      await _userService.updateCurrentUser(fields);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = TimeOfDay(
      hour: isStart ? (chatStartHour ?? 9) : (chatEndHour ?? 22),
      minute: 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: _primary),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        chatStartHour = picked.hour;
      } else {
        chatEndHour = picked.hour;
      }
    });

    await _save({
      'chatStartHour': chatStartHour,
      'chatEndHour': chatEndHour,
    });
  }

  Future<void> _clearHours() async {
    setState(() {
      chatStartHour = null;
      chatEndHour = null;
    });
    await _save({'chatStartHour': null, 'chatEndHour': null});
  }

  String _formatHour(int? hour) {
    if (hour == null) return 'Not set';
    final period = hour < 12 ? 'AM' : 'PM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h:00 $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Settings',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Preferences',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Notifications
              _SettingsCard(
                child: SwitchListTile(
                  title: const Text('Enable Notifications',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Receive updates and alerts'),
                  activeColor: _primary,
                  value: notificationsEnabled,
                  onChanged: (val) {
                    setState(() => notificationsEnabled = val);
                    _save({'notificationsEnabled': val});
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Chat toggle
              _SettingsCard(
                child: SwitchListTile(
                  title: const Text('Enable Chats',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Allow others to message you'),
                  activeColor: _primary,
                  value: chatEnabled,
                  onChanged: (val) {
                    setState(() => chatEnabled = val);
                    _save({'chatEnabled': val});
                  },
                ),
              ),

              if (chatEnabled) ...[
                const SizedBox(height: 16),

                // Available hours
                _SettingsCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded,
                                color: _primary, size: 20),
                            const SizedBox(width: 8),
                            const Text('Available hours',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                            const Spacer(),
                            if (chatStartHour != null || chatEndHour != null)
                              TextButton(
                                onPressed: _clearHours,
                                child: const Text('Clear',
                                    style: TextStyle(color: Colors.red)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Only allow messages during these hours. Leave unset to allow anytime.',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _TimePickerButton(
                                label: 'From',
                                value: _formatHour(chatStartHour),
                                onTap: () => _pickTime(isStart: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TimePickerButton(
                                label: 'Until',
                                value: _formatHour(chatEndHour),
                                onTap: () => _pickTime(isStart: false),
                              ),
                            ),
                          ],
                        ),
                        if (chatStartHour != null && chatEndHour != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Messages only accepted ${_formatHour(chatStartHour)} – ${_formatHour(chatEndHour)}',
                              style: const TextStyle(
                                  color: _primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // Logout
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await AuthService().logout();
                    if (context.mounted) {
                      Navigator.of(context)
                          .popUntil((route) => route.isFirst);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                    side: BorderSide(color: Colors.red.shade400),
                  ),
                  icon: Icon(Icons.logout, color: Colors.red.shade400),
                  label: Text('Logout',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade400)),
                ),
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(
                child: CircularProgressIndicator(color: _primary),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimePickerButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFE26D45);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3EC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primary.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 15, color: primary),
                const SizedBox(width: 6),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: primary,
                        fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}