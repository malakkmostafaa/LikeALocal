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
          const Expanded(child: Text('Loading...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
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
    final name = user?.name.isNotEmpty == true ? user!.name : 'Local Explorer';
    final isSuperUser = user?.isSuperUser ?? false;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          UserAvatar(user: user, radius: 20),
          const SizedBox(width: 8),
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSuperUser) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.stars, size: 16, color: Colors.amber),
                    ]
                  ],
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onMorePressed != null)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: onMorePressed,
            ),
        ],
      ),
    );
  }
}
