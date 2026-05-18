import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import 'onboarding_screen_2.dart';

class OnboardingScreen1 extends StatefulWidget {
  const OnboardingScreen1({super.key});

  @override
  State<OnboardingScreen1> createState() => _OnboardingScreen1State();
}

class _OnboardingScreen1State extends State<OnboardingScreen1> {
  final UserService _userService = UserService();

  final List<String> allPreferences = [
    'Food',
    'Cafés',
    'Hidden Gems',
    'Art',
    'Nature',
    'Nightlife',
    'Shopping',
    'History',
  ];

  final Set<String> selectedPreferences = {};
  double maxDistance = 10.0;
  int priceRange = 1;
  bool isLoading = false;

  Future<void> _nextStep() async {
    if (selectedPreferences.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('onboarding.select_one_interest'.tr())),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await _userService.updateCurrentUser({
        'preferences': selectedPreferences.toList(),
        'maxDistance': maxDistance,
        'priceRange': priceRange,
      });

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen2()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('common.error_prefix'.tr(namedArgs: {'error': e.toString()}))),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = Color(0xFFD45A38);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      const SizedBox(height: 10),
                      // Progress Bar
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: mainColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'onboarding.personalize_title'.tr(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'onboarding.personalize_subtitle'.tr(),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16, height: 1.4),
                      ),
                      const SizedBox(height: 30),

                      Text(
                        'onboarding.your_interests'.tr(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: allPreferences.map((pref) {
                          final isSelected = selectedPreferences.contains(pref);
                          return ChoiceChip(
                            label: Text(
                              pref,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: mainColor,
                            backgroundColor: Colors.white,
                            showCheckmark: false,
                            elevation: 0,
                            pressElevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? Colors.transparent : Colors.grey.shade300,
                              ),
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedPreferences.add(pref);
                                } else {
                                  selectedPreferences.remove(pref);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'onboarding.max_distance'.tr(),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  "${maxDistance.toInt()} km",
                                  style: const TextStyle(
                                    fontSize: 16, 
                                    fontWeight: FontWeight.bold,
                                    color: mainColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: mainColor,
                                inactiveTrackColor: Colors.grey.shade200,
                                thumbColor: mainColor,
                                overlayColor: mainColor.withOpacity(0.2),
                                trackHeight: 6,
                              ),
                              child: Slider(
                                value: maxDistance,
                                min: 1,
                                max: 100,
                                onChanged: (val) => setState(() => maxDistance = val),
                              ),
                            ),
                            const Divider(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'onboarding.price_range'.tr(),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  List.filled(priceRange, '\$').join(''),
                                  style: const TextStyle(
                                    fontSize: 16, 
                                    fontWeight: FontWeight.bold,
                                    color: mainColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: mainColor,
                                inactiveTrackColor: Colors.grey.shade200,
                                thumbColor: mainColor,
                                overlayColor: mainColor.withOpacity(0.2),
                                trackHeight: 6,
                                tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 4),
                                activeTickMarkColor: Colors.white.withOpacity(0.5),
                                inactiveTickMarkColor: mainColor.withOpacity(0.2),
                              ),
                              child: Slider(
                                value: priceRange.toDouble(),
                                min: 1,
                                max: 4,
                                divisions: 3,
                                onChanged: (val) => setState(() => priceRange = val.toInt()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD96B41), Color(0xFFE88A66)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD96B41).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: isLoading 
                        ? const SizedBox(
                            width: 24, 
                            height: 24, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                          )
                        : Text(
                            'common.continue_btn'.tr(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
        ),
      ),
    );
  }
}
