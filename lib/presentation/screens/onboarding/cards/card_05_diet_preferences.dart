import 'package:flutter/material.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';
import 'package:sique/presentation/widgets/sique_frosted_chrome.dart';

/// Card 5: Diet & Nutrition Preferences (Diet type, Indian staples, protein preference, oil default).
class Card05DietPreferences extends StatefulWidget {
  const Card05DietPreferences({
    super.key,
    required this.initialDietType,
    required this.initialStaple,
    required this.initialProteinPref,
    required this.initialOilDefault,
    this.currentWeightKg = 75.0,
    required this.onPreferencesChanged,
    required this.onNext,
  });

  final String initialDietType;
  final String initialStaple;
  final ProteinPreference initialProteinPref;
  final String initialOilDefault;
  final double currentWeightKg;
  final void Function({
    required String dietType,
    required String staplePreference,
    required ProteinPreference proteinPreference,
    required String oilDefault,
  }) onPreferencesChanged;
  final VoidCallback onNext;

  @override
  State<Card05DietPreferences> createState() => _Card05DietPreferencesState();
}

class _Card05DietPreferencesState extends State<Card05DietPreferences> {
  late String _dietType;
  late String _staple;
  late ProteinPreference _proteinPref;
  late String _oilDefault;

  @override
  void initState() {
    super.initState();
    _dietType = widget.initialDietType;
    _staple = widget.initialStaple;
    _proteinPref = widget.initialProteinPref;
    _oilDefault = widget.initialOilDefault;
  }

  void _notifyUpdate() {
    widget.onPreferencesChanged(
      dietType: _dietType,
      staplePreference: _staple,
      proteinPreference: _proteinPref,
      oilDefault: _oilDefault,
    );
  }

  bool get _isVegan => _dietType == 'vegan';

  @override
  Widget build(BuildContext context) {
    final oilCopy = _isVegan
        ? 'Standard (1 tbsp oil, ~120 kcal)'
        : 'Standard (1 tbsp ghee/oil, ~120 kcal)';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              const Text(
                'NUTRITION PREFERENCES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.activeBlue,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Diet, Staples & Protein',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Personalized for Indian culinary staples and macronutrient satiety preferences.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              // Section 1: Dietary Pattern
              const Text('Dietary Pattern',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildChoiceChip(
                      label: 'Pure Veg',
                      isSelected: _dietType == 'pure_veg',
                      onTap: () {
                        setState(() => _dietType = 'pure_veg');
                        _notifyUpdate();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildChoiceChip(
                      label: 'Eggetarian',
                      isSelected: _dietType == 'eggetarian',
                      onTap: () {
                        setState(() => _dietType = 'eggetarian');
                        _notifyUpdate();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildChoiceChip(
                      label: 'Non-Veg',
                      isSelected: _dietType == 'non_veg',
                      onTap: () {
                        setState(() => _dietType = 'non_veg');
                        _notifyUpdate();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildChoiceChip(
                      label: 'Vegan',
                      isSelected: _dietType == 'vegan',
                      onTap: () {
                        setState(() => _dietType = 'vegan');
                        _notifyUpdate();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Section 2: Indian Carbohydrate Staples
              const Text('Primary Indian Staple',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildChoiceChip(
                      label: 'Balanced',
                      isSelected: _staple == 'balanced',
                      onTap: () {
                        setState(() => _staple = 'balanced');
                        _notifyUpdate();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildChoiceChip(
                      label: 'Roti Primary',
                      isSelected: _staple == 'roti',
                      onTap: () {
                        setState(() => _staple = 'roti');
                        _notifyUpdate();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildChoiceChip(
                      label: 'Rice Primary',
                      isSelected: _staple == 'rice',
                      onTap: () {
                        setState(() => _staple = 'rice');
                        _notifyUpdate();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Section 3: Protein Preference
              const Text('Protein Preference',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              _buildProteinOption(
                pref: ProteinPreference.moderate,
                title:
                    'Moderate Protein · ${(widget.currentWeightKg * ProteinPreference.moderate.gramsPerKg).round()}g/day',
                subtitle:
                    '1.6 g/kg • Optimal for general health and balanced satiety',
              ),
              const SizedBox(height: 8),
              _buildProteinOption(
                pref: ProteinPreference.high,
                title:
                    'High Protein · ${(widget.currentWeightKg * ProteinPreference.high.gramsPerKg).round()}g/day (Recommended)',
                subtitle:
                    '2.0 g/kg • Maximum muscle preservation during fat loss & recovery',
              ),
              const SizedBox(height: 8),
              _buildProteinOption(
                pref: ProteinPreference.extraHigh,
                title:
                    'Extra High Protein · ${(widget.currentWeightKg * ProteinPreference.extraHigh.gramsPerKg).round()}g/day',
                subtitle:
                    '2.4 g/kg • Competitive strength athletes & high satiety cut',
              ),
              const SizedBox(height: 18),

              // Section 4: Default Cooking Oil Modifier
              const Text('Default Cooking Oil Allocation',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: AppRadii.lgBorderRadius,
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    _buildOilRadio(
                      slug: 'standard',
                      title: oilCopy,
                      subtitle: 'Standard Indian home meal preparation',
                    ),
                    const Divider(color: AppTheme.cardBorder, height: 16),
                    _buildOilRadio(
                      slug: 'light',
                      title: 'Light (1 tsp, ~40 kcal)',
                      subtitle: 'Minimal oil, air-fried, or measured spray',
                    ),
                    const Divider(color: AppTheme.cardBorder, height: 16),
                    _buildOilRadio(
                      slug: 'heavy',
                      title: 'Heavy (2 tbsp, ~240 kcal)',
                      subtitle:
                          'Rich curries, restaurant dishes, or festive prep',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),

        // Pinned sticky bottom CTA bar: guaranteed visible without scrolling
        SiqueFrostedChrome(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1-line macro preview strip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.cardElevated,
                      borderRadius: AppRadii.mdBorderRadius,
                      border:
                          Border.all(color: AppTheme.cardBorder, width: 0.5),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            'Protein: ${(widget.currentWeightKg * _proteinPref.gramsPerKg).round()}g/d',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.protein,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const Text(' • ',
                              style: TextStyle(color: AppTheme.textMuted)),
                          Text(
                            'Staple: ${_staple.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.carbs,
                            ),
                          ),
                          const Text(' • ',
                              style: TextStyle(color: AppTheme.textMuted)),
                          Text(
                            'Oil: ${_oilDefault.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.fat,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: AppleTactileCard(
                      key: const Key('onboarding_card_5_continue_btn'),
                      onTap: () {
                        AppHaptics.lightImpact();
                        _notifyUpdate();
                        widget.onNext();
                      },
                      backgroundColor: AppTheme.buttonBackground,
                      borderRadius: AppRadii.lg,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: const Center(
                        child: Text(
                          'Reveal your blueprint',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.buttonText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        AppHaptics.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.activeBlue.withValues(alpha: 0.15)
              : AppTheme.cardSurface,
          borderRadius: AppRadii.mdBorderRadius,
          border: Border.all(
            color: isSelected ? AppTheme.activeBlue : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppTheme.activeBlue : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildProteinOption({
    required ProteinPreference pref,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _proteinPref == pref;

    return AppleBouncy(
      onTap: () {
        AppHaptics.selectionClick();
        setState(() => _proteinPref = pref);
        _notifyUpdate();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.protein.withValues(alpha: 0.12)
              : AppTheme.cardSurface,
          borderRadius: AppRadii.lgBorderRadius,
          border: Border.all(
            color: isSelected ? AppTheme.protein : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.egg_alt_rounded,
              color: isSelected ? AppTheme.protein : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color:
                          isSelected ? AppTheme.protein : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.protein, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOilRadio({
    required String slug,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _oilDefault == slug;

    return GestureDetector(
      onTap: () {
        AppHaptics.selectionClick();
        setState(() => _oilDefault = slug);
        _notifyUpdate();
      },
      child: Container(
        color: Colors.transparent,
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: isSelected ? AppTheme.activeBlue : AppTheme.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
