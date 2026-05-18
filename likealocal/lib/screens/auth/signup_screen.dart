import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:like_a_local/screens/auth/onboarding_screen_1.dart';
import 'package:like_a_local/screens/main_navigation.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;

  Future<void> signUp() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      showMessage('auth.fill_all_fields'.tr());
      return;
    }

    if (passwordController.text.trim().length < 6) {
      showMessage('auth.password_too_short'.tr());
      return;
    }

    setState(() => isLoading = true);

    try {
      await _authService.signUp(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen1()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      showMessage(_friendlyAuthError(e));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _friendlyAuthError(Object error) {
    final message = error.toString();

    if (message.contains('email-already-in-use')) {
      return 'auth.email_in_use'.tr();
    }

    if (message.contains('invalid-email')) {
      return 'auth.invalid_email'.tr();
    }

    if (message.contains('weak-password')) {
      return 'auth.weak_password'.tr();
    }

    if (message.contains('network-request-failed')) {
      return 'auth.network_error'.tr();
    }

    return message;
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = Color(0xFFD45A38);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F4EF),
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                const SizedBox(height: 28),
                Text(
                  'auth.create_account'.tr(),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'auth.signup_subtitle'.tr(),
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: nameController,
                  decoration: inputDecoration('auth.full_name'.tr()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: inputDecoration('auth.email'.tr()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  decoration: inputDecoration('auth.password'.tr()).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        hidePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => hidePassword = !hidePassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 28),
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
                    onPressed: isLoading ? null : signUp,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'auth.create_account'.tr(),
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFEDEDE6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }
}
