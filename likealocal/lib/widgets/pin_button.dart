import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pin_provider.dart';
import '../screens/profile/subscription_plans_screen.dart';
import '../services/pin_service.dart';
import '../services/user_service.dart';

/// A circular bookmark/pin button that stays in sync with Firestore.
///
/// Drop in anywhere a place is shown:
///
///   PinButton(placeId: place.id)
///
/// `onChanged` fires with the new pinned state — use it for analytics
/// (e.g. RecommendationService.trackSavePlace).
class PinButton extends StatefulWidget {
  const PinButton({
    super.key,
    required this.placeId,
    this.size = 38,
    this.iconSize = 21,
    this.activeColor = const Color(0xFFE26D45),
    this.inactiveColor = const Color(0xFF1F1F28),
    this.backgroundColor = Colors.white,
    this.elevated = true,
    this.onChanged,
  });

  final String placeId;
  final double size;
  final double iconSize;
  final Color activeColor;
  final Color inactiveColor;
  final Color backgroundColor;
  final bool elevated;
  final ValueChanged<bool>? onChanged;

  @override
  State<PinButton> createState() => _PinButtonState();
}

class _PinButtonState extends State<PinButton> {
  final UserService _userService = UserService();
  bool _busy = false;

  Future<void> _handleTap(bool currentlyPinned) async {
    if (_busy) return;

    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('pin.login_required'.tr())),
      );
      return;
    }

    setState(() => _busy = true);

    try {
      final nowPinned =
          await context.read<PinProvider>().togglePin(widget.placeId);
      widget.onChanged?.call(nowPinned);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nowPinned ? 'pin.saved'.tr() : 'pin.removed'.tr()),
          duration: const Duration(seconds: 1),
        ),
      );
    } on PinLimitReachedException {
      if (!mounted) return;
      await _showPinLimitDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('pin.error'.tr(namedArgs: {'error': e.toString()}))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showPinLimitDialog() async {
    final shouldUpgrade = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'pin.limit_title'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            'pin.limit_message'.tr(namedArgs: {'limit': PinService.freePinLimit.toString()}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('common.cancel'.tr()),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: widget.activeColor,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('common.upgrade'.tr()),
            ),
          ],
        );
      },
    );

    if (shouldUpgrade != true || !mounted) return;

    final user = await _userService.getCurrentUserOnce();
    if (user == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriptionPlansScreen(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: context.read<PinProvider>().isPinnedStream(widget.placeId),
      builder: (context, snapshot) {
        final isPinned = snapshot.data ?? false;
        final isLoading = _busy ||
            (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData);

        return InkWell(
          onTap: isLoading ? null : () => _handleTap(isPinned),
          customBorder: const CircleBorder(),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.backgroundColor.withOpacity(0.94),
              shape: BoxShape.circle,
              boxShadow: widget.elevated
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: isLoading
                ? Padding(
                    padding: EdgeInsets.all(widget.size / 4),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.activeColor,
                    ),
                  )
                : Icon(
                    isPinned
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: isPinned ? widget.activeColor : widget.inactiveColor,
                    size: widget.iconSize,
                  ),
          ),
        );
      },
    );
  }
}
