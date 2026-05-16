import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import 'mock_payment_screen.dart';

import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class SubscriptionPlansScreen extends StatelessWidget {
  final AppUser user;

  const SubscriptionPlansScreen({
    super.key,
    required this.user,
  });

  static const Color backgroundColor = Color(0xFFF7F4EF);
  static const Color cardColor = Color(0xFFFFFBF7);
  static const Color primaryColor = Color(0xFFE26D45);
  static const Color softPrimary = Color(0xFFFFE6D8);
  static const Color textColor = Color(0xFF1F1F28);
  static const Color mutedText = Color(0xFF7A6D66);
  static const Color borderColor = Color(0xFFEEDDD2);
  static const Color goldColor = Color(0xFFE5A11A);

  @override
  Widget build(BuildContext context) {
    final liveUser = context.watch<UserProvider>().user ?? user;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        foregroundColor: textColor,
        title: const Text(
          'Plans & Upgrades',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PremiumHero(user: liveUser),
            const SizedBox(height: 22),
            const Text(
              'Choose your plan',
              style: TextStyle(
                color: textColor,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Start free, then upgrade when you want more flexibility.',
              style: TextStyle(
                color: mutedText,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            _PlanCard(
              title: 'Free',
              subtitle: 'For casual discovery',
              price: 'EGP 0',
              duration: 'forever',
              features: const [
                'Up to 5 saved pins',
                'Basic profile customization',
                'Explore public local places',
                'Standard discovery reach',
              ],
              isCurrentPlan: !liveUser.isPremium,
              buttonText: !liveUser.isPremium ? 'Current Plan' : 'Included',
              onTap: null,
              icon: Icons.explore_rounded,
              accentColor: mutedText,
            ),
            const SizedBox(height: 16),
            _PlanCard(
              title: 'Premium Plus',
              subtitle: 'For active local explorers',
              price: 'EGP 500',
              duration: 'monthly',
              features: const [
                'Unlimited saved pins',
                'Priority discovery boost',
                'Premium profile badge',
                'Advanced local recommendations',
                'Early access to new features',
              ],
              isCurrentPlan: liveUser.isPremium,
              buttonText: liveUser.isPremium
                  ? 'Active Subscription'
                  : 'Upgrade with Paymob',
              onTap: liveUser.isPremium
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PaymobLinkPaymentScreen(),
                        ),
                      );
                    },
              icon: Icons.workspace_premium_rounded,
              accentColor: primaryColor,
              isFeatured: true,
            ),
            const SizedBox(height: 22),
            const _PaymentNote(),
          ],
        ),
      ),
    );
  }
}

class _PremiumHero extends StatelessWidget {
  final AppUser user;

  const _PremiumHero({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final liveUser = context.watch<UserProvider>().user ?? user;
    final isPremium = liveUser.isPremium;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: SubscriptionPlansScreen.primaryColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: SubscriptionPlansScreen.primaryColor.withOpacity(0.24),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 120,
              color: Colors.white.withOpacity(0.10),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isPremium ? 'You’re Premium' : 'Unlock Premium',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isPremium
                    ? 'Your account already has unlimited access and premium discovery benefits.'
                    : 'Save more places, boost your discovery experience, and unlock advanced local features.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _HeroMiniStat(
                    icon: Icons.bookmark_rounded,
                    label: isPremium ? 'Unlimited pins' : 'More pins',
                  ),
                  const SizedBox(width: 10),
                  const _HeroMiniStat(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Better reach',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMiniStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroMiniStat({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: Colors.white.withOpacity(0.16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 15,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final String duration;
  final List<String> features;
  final bool isCurrentPlan;
  final String buttonText;
  final VoidCallback? onTap;
  final IconData icon;
  final Color accentColor;
  final bool isFeatured;

  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.duration,
    required this.features,
    required this.isCurrentPlan,
    required this.buttonText,
    required this.onTap,
    required this.icon,
    required this.accentColor,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardBorderColor = isFeatured
        ? SubscriptionPlansScreen.primaryColor.withOpacity(0.35)
        : SubscriptionPlansScreen.borderColor;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: SubscriptionPlansScreen.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: cardBorderColor,
          width: isFeatured ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isFeatured ? 0.055 : 0.028),
            blurRadius: isFeatured ? 20 : 12,
            offset: Offset(0, isFeatured ? 10 : 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isFeatured) const _RecommendedRibbon(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _PlanIcon(
                      icon: icon,
                      color: accentColor,
                      isFeatured: isFeatured,
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: SubscriptionPlansScreen.textColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              if (isCurrentPlan) ...[
                                const SizedBox(width: 8),
                                const _CurrentBadge(),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: SubscriptionPlansScreen.mutedText,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        color: SubscriptionPlansScreen.textColor,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        duration,
                        style: const TextStyle(
                          color: SubscriptionPlansScreen.mutedText,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: SubscriptionPlansScreen.borderColor,
                ),
                const SizedBox(height: 18),
                ...features.map((feature) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FeatureRow(
                      text: feature,
                      color: isFeatured
                          ? SubscriptionPlansScreen.primaryColor
                          : SubscriptionPlansScreen.mutedText,
                    ),
                  );
                }),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFeatured
                          ? SubscriptionPlansScreen.primaryColor
                          : const Color(0xFFEDEBE6),
                      foregroundColor: isFeatured
                          ? Colors.white
                          : SubscriptionPlansScreen.textColor,
                      disabledBackgroundColor: isFeatured
                          ? SubscriptionPlansScreen.primaryColor
                              .withOpacity(0.16)
                          : const Color(0xFFEDEBE6),
                      disabledForegroundColor:
                          SubscriptionPlansScreen.mutedText,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
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

class _RecommendedRibbon extends StatelessWidget {
  const _RecommendedRibbon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        color: SubscriptionPlansScreen.softPrimary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(27),
          topRight: Radius.circular(27),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: SubscriptionPlansScreen.primaryColor,
            size: 16,
          ),
          SizedBox(width: 6),
          Text(
            'MOST POPULAR',
            style: TextStyle(
              color: SubscriptionPlansScreen.primaryColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isFeatured;

  const _PlanIcon({
    required this.icon,
    required this.color,
    required this.isFeatured,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isFeatured
            ? SubscriptionPlansScreen.softPrimary
            : const Color(0xFFEDEBE6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        icon,
        color: color,
        size: 25,
      ),
    );
  }
}

class _CurrentBadge extends StatelessWidget {
  const _CurrentBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: SubscriptionPlansScreen.softPrimary,
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        'Current',
        style: TextStyle(
          color: SubscriptionPlansScreen.primaryColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  final Color color;

  const _FeatureRow({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: SubscriptionPlansScreen.textColor,
              fontSize: 14.2,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentNote extends StatelessWidget {
  const _PaymentNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SubscriptionPlansScreen.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: SubscriptionPlansScreen.borderColor,
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: SubscriptionPlansScreen.primaryColor,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Payments open through Paymob. In demo mode, premium is activated after you confirm payment completion.',
              style: TextStyle(
                color: SubscriptionPlansScreen.mutedText,
                height: 1.35,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
