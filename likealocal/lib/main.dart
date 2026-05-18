import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

import 'providers/auth_provider.dart' as app_auth;
import 'providers/chat_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/location_provider.dart';
import 'providers/pin_provider.dart';
import 'providers/place_provider.dart';
import 'providers/review_provider.dart';
import 'providers/trivia_provider.dart';
import 'providers/user_provider.dart';

import 'screens/auth/login_screen.dart';
import 'screens/main_navigation.dart';
import 'widgets/locale_sync.dart';
import 'widgets/offline_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      saveLocale: true,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => PlaceProvider()),
          ChangeNotifierProvider(create: (_) => ReviewProvider()),
          ChangeNotifierProvider(create: (_) => PinProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(create: (_) => TriviaProvider()),
          ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
          ChangeNotifierProvider(
            create: (_) => LocationProvider()..fetchLocation(),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color primaryColor = Color(0xFFE26D45);
  static const Color backgroundColor = Color(0xFFF7EFE8);
  static const Color cardColor = Color(0xFFFFFBF7);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LikeALocal',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundColor,
        fontFamily: null,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          surface: cardColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          elevation: 0,
          centerTitle: false,
          foregroundColor: Color(0xFF1F1F28),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF1F1F28),
          contentTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      // Offline banner globally + applies the signed-in user's saved language
      // across devices via LocaleSync.
      builder: (context, child) {
        return LocaleSync(
          child: OfflineBanner(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },

      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashLoadingScreen();
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const MainNavigation();
        }

        return const LoginScreen();
      },
    );
  }
}

class SplashLoadingScreen extends StatelessWidget {
  const SplashLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: MyApp.primaryColor,
        ),
      ),
    );
  }
}
