import 'package:flutter/material.dart';
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

  final List<String> interests = [
    'Food',
    'Cafés',
    'Hidden Gems',
    'Art',
    'Nature',
    'Nightlife',
    'Shopping',
    'History',
  ];

  final Set<String> selectedInterests = {};

  Future<void> signUp() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      showMessage('Please fill all fields');
      return;
    }

    if (passwordController.text.length < 6) {
      showMessage('Password must be at least 6 characters');
      return;
    }

    setState(() => isLoading = true);

    try {
      await _authService.signUp(
        name: nameController.text,
        email: emailController.text,
        password: passwordController.text,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      showMessage('Signup failed. Email may already be used.');
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
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Join the community of local explorers',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: nameController,
                  decoration: inputDecoration('Your full name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: inputDecoration('Email'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  decoration: inputDecoration('Password').copyWith(
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
                const Text(
                  'Your Interests',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: interests.map((interest) {
                    final selected = selectedInterests.contains(interest);

                    return ChoiceChip(
                      label: Text(interest),
                      selected: selected,
                      selectedColor: mainColor.withOpacity(0.2),
                      onSelected: (_) {
                        setState(() {
                          selected
                              ? selectedInterests.remove(interest)
                              : selectedInterests.add(interest);
                        });
                      },
                    );
                  }).toList(),
                ),
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
                        : const Text(
                            'Create Account',
                            style: TextStyle(fontSize: 16),
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
