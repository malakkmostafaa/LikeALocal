import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      showMessage('auth.enter_email_password'.tr());
      return;
    }

    setState(() => isLoading = true);

    try {
      await _authService.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      // Rely on StreamBuilder in main.dart to show MainNavigation.
      // We just need to pop any overlay if LoginScreen wasn't the root.
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      showMessage(e.toString());
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = Color(0xFFD45A38);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: mainColor, size: 34),
                  const SizedBox(height: 12),
                  const Text(
                    'LikeALocal',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'auth.welcome_back'.tr(),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'auth.login_subtitle'.tr(),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'auth.email'.tr(),
                      filled: true,
                      fillColor: const Color(0xFFEDEDE6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: hidePassword,
                    decoration: InputDecoration(
                      hintText: 'auth.password'.tr(),
                      filled: true,
                      fillColor: const Color(0xFFEDEDE6),
                      suffixIcon: IconButton(
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => hidePassword = !hidePassword);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: isLoading ? null : login,
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : Text(
                              'auth.login'.tr(),
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('auth.no_account'.tr()),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'auth.sign_up'.tr(),
                          style: const TextStyle(
                            color: mainColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
