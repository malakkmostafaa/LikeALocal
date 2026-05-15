import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/connectivity_provider.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  static const Color primaryColor = Color(0xFFE26D45);
  static const Color bgColor = Color(0xFFFFFBF7);
  static const Color softPrimary = Color(0xFFFFE6D8);
  static const Color borderColor = Color(0xFFEEDDD2);
  static const Color textColor = Color(0xFF1F1F28);
  static const Color mutedText = Color(0xFF7A6D66);

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, child) {
        final shouldShow =
            connectivity.hasCheckedConnection && connectivity.isOffline;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: shouldShow
              ? const _OfflineBannerContent(
                  key: ValueKey('offline_banner_visible'),
                )
              : const SizedBox(
                  key: ValueKey('offline_banner_hidden'),
                  height: 0,
                ),
        );
      },
    );
  }
}

class _OfflineBannerContent extends StatelessWidget {
  const _OfflineBannerContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OfflineBanner.bgColor,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          decoration: const BoxDecoration(
            color: OfflineBanner.bgColor,
            border: Border(
              bottom: BorderSide(
                color: OfflineBanner.borderColor,
                width: 1,
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: OfflineBanner.softPrimary.withOpacity(0.55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: OfflineBanner.primaryColor.withOpacity(0.16),
              ),
            ),
            child: const Row(
              children: [
                _OfflineStatusIcon(),
                SizedBox(width: 10),
                Expanded(
                  child: _OfflineStatusText(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfflineStatusIcon extends StatelessWidget {
  const _OfflineStatusIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: OfflineBanner.bgColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: OfflineBanner.borderColor,
        ),
      ),
      child: const Icon(
        Icons.cloud_off_rounded,
        color: OfflineBanner.primaryColor,
        size: 18,
      ),
    );
  }
}

class _OfflineStatusText extends StatelessWidget {
  const _OfflineStatusText();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You’re offline',
          style: TextStyle(
            color: OfflineBanner.textColor,
            fontWeight: FontWeight.w900,
            fontSize: 13.5,
            height: 1.1,
          ),
        ),
        SizedBox(height: 3),
        Text(
          'Showing saved content. Uploads and reviews are paused.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: OfflineBanner.mutedText,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}
