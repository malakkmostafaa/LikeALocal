import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';
import 'user_avatar.dart';

class PostUserHeader extends StatelessWidget {
  final String? userId;
  final String subtitle;
  final VoidCallback? onMorePressed;

  const PostUserHeader({
    Key? key,
    required this.userId,
    required this.subtitle,
    this.onMorePressed,
  }) : super(key: key);

  Future<AppUser?> _fetchUser() async {
    if (userId == null || userId!.isEmpty) return null;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data()!);
      }
    } catch (e) {
      debugPrint('Error fetching user for post header: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null || userId!.isEmpty) {
      return _buildHeader(context, null);
    }

    return FutureBuilder<AppUser?>(
      future: _fetchUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingHeader();
        }
        return _buildHeader(context, snapshot.data);
      },
    );
  }

  Widget _buildLoadingHeader() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey,
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text('common.loading'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          if (onMorePressed != null)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: onMorePressed,
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppUser? user) {
    const primaryColor = Color(0xFFE26D45);
    const lightPrimary = Color(0xFFFBE8DF);
    final name = user?.name.isNotEmpty == true ? user!.name : 'Local Explorer';
    final isSuperUser = user?.isSuperUser ?? false;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          UserAvatar(user: user, radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFF1F1F28),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSuperUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: lightPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium, size: 12, color: primaryColor),
                            SizedBox(width: 4),
                            Text(
                              'Super',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF777777),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onMorePressed != null)
            IconButton(
              icon: const Icon(Icons.more_horiz, color: Color(0xFF777777)),
              onPressed: onMorePressed,
            ),
        ],
      ),
    );
  }
}
