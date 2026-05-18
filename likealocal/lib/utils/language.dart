import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../services/user_service.dart';

/// All languages the app supports. Add a new one in one place.
class AppLanguage {
  const AppLanguage({
    required this.locale,
    required this.flag,
    required this.translationKey,
  });

  final Locale locale;
  final String flag;
  final String translationKey;
}

const List<AppLanguage> supportedAppLanguages = [
  AppLanguage(
    locale: Locale('en'),
    flag: '🇬🇧',
    translationKey: 'language.english',
  ),
  AppLanguage(
    locale: Locale('ar'),
    flag: '🇪🇬',
    translationKey: 'language.arabic',
  ),
];

/// Updates the app locale AND mirrors the choice to Firestore so it
/// follows the user to other devices. easy_localization persists to
/// SharedPreferences automatically when `saveLocale: true` is set.
Future<void> changeAppLanguage(
  BuildContext context,
  Locale locale,
) async {
  await context.setLocale(locale);

  // Silently mirror to Firestore. A failure here shouldn't block the UI
  // change since SharedPreferences already has the new value.
  try {
    await UserService().updateCurrentUser({'language': locale.languageCode});
  } catch (_) {}
}
