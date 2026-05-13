import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/user_model.dart';

class UserAvatar extends StatelessWidget {
  final AppUser? user;
  final double radius;

  const UserAvatar({
    Key? key,
    required this.user,
    this.radius = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final placeholder = const CircleAvatar(
      radius: 20,
      backgroundColor: Colors.grey,
      child: Icon(Icons.person, color: Colors.white),
    );

    if (user == null || (user?.profileImageUrl.isEmpty ?? true)) {
      return placeholder;
    }

    return CircleAvatar(
      radius: radius,
      backgroundImage: CachedNetworkImageProvider(user!.profileImageUrl),
      backgroundColor: Colors.transparent,
    );
  }
}
