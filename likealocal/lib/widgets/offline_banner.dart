import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/connectivity_provider.dart';

class OfflineBanner extends StatelessWidget {
  final Widget child;

  const OfflineBanner({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, childWidget) {
        final shouldShow = connectivity.hasCheckedConnection && connectivity.isOffline;

        return Column(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: shouldShow
                  ? const _SlimOfflineBanner(key: ValueKey('slim_offline_banner_visible'))
                  : const SizedBox.shrink(key: ValueKey('offline_banner_hidden')),
            ),
            Expanded(
              child: MediaQuery(
                // Remove the top padding from the rest of the app when the banner is visible
                // so we don't get double SafeAreas (one in the banner, one in the screen).
                data: MediaQuery.of(context).removePadding(removeTop: shouldShow),
                child: childWidget!,
              ),
            ),
          ],
        );
      },
      child: child,
    );
  }
}

class _SlimOfflineBanner extends StatelessWidget {
  const _SlimOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // A clean, slim banner that handles the top safe area correctly
    return Material(
      color: const Color(0xFFE26D45), // primaryColor
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'offline.message'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
