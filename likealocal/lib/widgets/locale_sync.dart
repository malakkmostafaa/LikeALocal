import 'package:flutter/material.dart';

/// Placeholder wrapper for cross-device language sync.
///
/// Originally listened to `users/{uid}.language` in Firestore and applied
/// it to the app locale. That field is not currently on the AppUser model,
/// so this is a passthrough for now.
///
/// easy_localization still persists the user's language choice to
/// SharedPreferences via `saveLocale: true`, so the choice survives app
/// restarts on the same device.
///
/// To restore cross-device sync later:
///   1. Add `final String language;` back to AppUser.
///   2. Use `context.select<UserProvider, String>((p) => p.user?.language ?? '')`
///      and call `context.setLocale(Locale(userLang))` when it changes.
class LocaleSync extends StatelessWidget {
  const LocaleSync({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
