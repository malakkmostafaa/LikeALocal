import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/user_service.dart';

class PaymobLinkPaymentScreen extends StatefulWidget {
  const PaymobLinkPaymentScreen({super.key});

  @override
  State<PaymobLinkPaymentScreen> createState() =>
      _PaymobLinkPaymentScreenState();
}

class _PaymobLinkPaymentScreenState extends State<PaymobLinkPaymentScreen> {
  final UserService _userService = UserService();

  bool _isLoading = false;

  static const String paymobPaymentLink = 'https://paymob.link/d6n23';

  Future<void> _openPaymobPaymentLink() async {
    final uri = Uri.parse(paymobPaymentLink);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('payment.could_not_open'.tr()),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('payment.could_not_open_dynamic'.tr(namedArgs: {'error': '$e'})),
        ),
      );
    }
  }

  Future<void> _markPaymentCompletedForDemo() async {
    setState(() => _isLoading = true);

    try {
      await _userService.updateCurrentUser({
        'isPremium': true,
      });

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  'payment.premium_activated'.tr(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'payment.demo_marked'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD96B41),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'payment.awesome'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('payment.could_not_activate'.tr(namedArgs: {'error': '$e'}))),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD96B41);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'payment.paymob_checkout'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F6F3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Premium Plus',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'For Life Subscription',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    Text(
                      'EGP 500',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.payment_rounded, color: primaryColor),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You will be redirected to Paymob’s secure payment page.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _openPaymobPaymentLink,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text(
                    'Open Paymob Payment Page',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _markPaymentCompletedForDemo,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: const BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryColor,
                          ),
                        )
                      : const Text(
                          'I completed payment',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Demo mode: payment verification is manual.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
