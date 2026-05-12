import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'mock_payment_screen.dart';

class SubscriptionPlansScreen extends StatelessWidget {
  final AppUser user;

  const SubscriptionPlansScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD96B41);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          "Plans & Upgrades",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.star_rounded, size: 60, color: Color(0xFFFFB800)),
            const SizedBox(height: 16),
            const Text(
              "Unlock Unlimited Access",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Choose the plan that fits your travel style and explore without limits.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // FREE PLAN CARD
            _buildPlanCard(
              title: "Free Tier",
              price: "\$0",
              duration: "forever",
              features: [
                "Up to 5 Custom Pins",
                "Basic Profile Customization",
                "Standard Discovery Reach",
              ],
              isCurrentPlan: !user.isPremium,
              buttonText: "Current Plan",
              onTap: null,
              color: Colors.grey.shade300,
              textColor: Colors.black87,
            ),

            const SizedBox(height: 24),

            // PREMIUM PLAN CARD
            _buildPlanCard(
              title: "Premium Plus",
              price: "\$4.99",
              duration: "per month",
              features: [
                "Unlimited Custom Pins",
                "Advanced Discovery Reach",
                "Priority Review Boosting",
                "Exclusive Profile Badge",
              ],
              isCurrentPlan: user.isPremium,
              buttonText: user.isPremium ? "Active Subscription" : "Upgrade to Premium",
              onTap: user.isPremium ? null : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MockPaymentScreen(),
                  ),
                );
              },
              color: primaryColor,
              textColor: Colors.white,
              isFeatured: true,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String duration,
    required List<String> features,
    required bool isCurrentPlan,
    required String buttonText,
    required VoidCallback? onTap,
    required Color color,
    required Color textColor,
    bool isFeatured = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isFeatured ? color : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isFeatured ? color : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: isFeatured
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isFeatured)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
              ),
              child: const Text(
                "RECOMMENDED",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        duration,
                        style: TextStyle(
                          fontSize: 16,
                          color: isFeatured ? Colors.white70 : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ...features.map((feature) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: isFeatured ? Colors.white : color,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          feature,
                          style: TextStyle(
                            fontSize: 15,
                            color: isFeatured ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFeatured ? Colors.white : Colors.grey.shade200,
                    foregroundColor: isFeatured ? color : Colors.grey.shade600,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
