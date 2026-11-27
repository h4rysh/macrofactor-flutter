import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/widgets/food/quick_add_macros_sheet.dart';
import 'package:sique/presentation/widgets/sique_bouncy.dart';
import '../../domain/models/food_models.dart';
import '../theme/app_theme.dart';
import '../widgets/apple_sheet_grabber.dart';
import 'food_search_screen.dart';
import 'weight_log_modal.dart';

/// Quick actions bottom sheet triggered by the center '+' navigation button.
/// Refactored into a high-craft 2+3 obsidian bento grid layout.
class QuickActionsSheet extends StatelessWidget {
  const QuickActionsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuickActionsSheet(),
    );
  }

  MealType _mealTypeForHour(int hour) {
    if (hour < 11) return MealType.breakfast;
    if (hour < 16) return MealType.lunch;
    if (hour < 21) return MealType.dinner;
    return MealType.snacks;
  }

  (DateTime, DateTime, String) _resolveSelectedDateAndTime(
      BuildContext context) {
    final now = DateTime.now();
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final clockNow = container.read(clockProvider)();
      final dateStr = container.read(selectedDateProvider);
      final parsed = DateTime.tryParse(dateStr) ?? clockNow;
      final loggedAt = DateTime(
        parsed.year,
        parsed.month,
        parsed.day,
        clockNow.hour,
        clockNow.minute,
        clockNow.second,
      );
      return (parsed, loggedAt, dateStr);
    } catch (_) {
      return (now, now, DateFormat('yyyy-MM-dd').format(now));
    }
  }

  void _handleCopyYesterday(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final now = container.read(clockProvider)();
      final selectedDateStr = container.read(selectedDateProvider);
      final selectedDate = DateTime.tryParse(selectedDateStr) ?? now;
      final yesterday = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day - 1,
      );
      final yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);

      final count = container
          .read(dailyFoodLogsProvider.notifier)
          .copyFromDate(yesterdayStr);

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? 'Copied $count ${count == 1 ? 'meal' : 'meals'} from yesterday'
                : 'No meals logged yesterday to copy',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to copy yesterday’s meals. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleDayNote(BuildContext context) {
    final (_, _, selectedDateStr) = _resolveSelectedDateAndTime(context);
    final navigator = Navigator.of(context);
    navigator.pop();

    showModalBottomSheet(
      context: navigator.context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DayNoteSheet(date: selectedDateStr),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: 'Close sheet',
                      hint: 'Double tap to dismiss',
                      button: true,
                      onTap: () => Navigator.pop(context),
                      child: const AppleSheetGrabber(
                          margin: EdgeInsets.only(bottom: 8)),
                    ),
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Top Row: 2 Large Hero Bento Tiles
                    Row(
                      children: [
                        Expanded(
                          child: _buildHeroBentoTile(
                            context: context,
                            icon: Icons.search_rounded,
                            title: 'Search Food / Add to Plate',
                            subtitle: 'Log meals & items',
                            color: AppTheme.calories,
                            onTap: () {
                              final (_, loggedAt, _) =
                                  _resolveSelectedDateAndTime(context);
                              final nav = Navigator.of(context);
                              nav.pop();
                              nav.push(
                                FoodSearchScreen.route(
                                  mealType: _mealTypeForHour(loggedAt.hour),
                                  initialLoggedAt: loggedAt,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildHeroBentoTile(
                            context: context,
                            icon: Icons.monitor_weight_outlined,
                            title: 'Log Scale Weight',
                            subtitle: 'Daily morning weigh-in',
                            color: AppTheme.trendWeight,
                            onTap: () {
                              Navigator.pop(context);
                              WeightLogModal.show(context);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Bottom Row: 3 Compact Bento Tiles
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactBentoTile(
                            context: context,
                            icon: Icons.flash_on_rounded,
                            title: 'Quick Add Calories',
                            color: AppTheme.fat,
                            onTap: () {
                              final (selectedDate, loggedAt, _) =
                                  _resolveSelectedDateAndTime(context);
                              final nav = Navigator.of(context);
                              nav.pop();
                              QuickAddMacrosSheet.show(
                                nav.context,
                                date: selectedDate,
                                mealType: _mealTypeForHour(loggedAt.hour),
                                loggedAt: loggedAt,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildCompactBentoTile(
                            context: context,
                            icon: Icons.content_copy_rounded,
                            title: 'Copy Yesterday',
                            color: AppTheme.carbs,
                            onTap: () => _handleCopyYesterday(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildCompactBentoTile(
                            context: context,
                            icon: Icons.note_alt_outlined,
                            title: 'Day Note',
                            color: AppTheme.protein,
                            onTap: () => _handleDayNote(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBentoTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: SiqueBouncy(
        onTap: () {
          AppHaptics.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardElevated,
            borderRadius: AppRadii.lgBorderRadius,
            border: Border.all(color: AppTheme.cardBorder, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: AppRadii.mdBorderRadius,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
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
      ),
    );
  }

  Widget _buildCompactBentoTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: title,
      child: SiqueBouncy(
        onTap: () {
          AppHaptics.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.cardElevated,
            borderRadius: AppRadii.lgBorderRadius,
            border: Border.all(color: AppTheme.cardBorder, width: 0.8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: AppRadii.mdBorderRadius,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal bottom sheet for logging or editing reflections, hunger, or energy for [date].
class DayNoteSheet extends ConsumerStatefulWidget {
  const DayNoteSheet({super.key, required this.date});
  final String date;

  @override
  ConsumerState<DayNoteSheet> createState() => _DayNoteSheetState();
}

class _DayNoteSheetState extends ConsumerState<DayNoteSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final db = ref.read(databaseProvider);
    final existing = db.diaryToolsDao.getDayNote(widget.date) ??
        db.getSetting('day_note:${widget.date}', '');
    _controller = TextEditingController(text: existing);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveNote() {
    final text = _controller.text.trim();
    final db = ref.read(databaseProvider);
    db.diaryToolsDao.saveDayNote(widget.date, text);
    ref.read(foodLogsRevisionProvider.notifier).state++;
    final messenger = ScaffoldMessenger.of(context);

    Navigator.pop(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(text.isEmpty ? 'Day note cleared' : 'Day note saved'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(widget.date);
    } catch (_) {
      parsedDate = DateTime.now();
    }
    final formattedDate = DateFormat('EEEE, MMM d').format(parsedDate);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppleSheetGrabber(
                        margin: EdgeInsets.only(bottom: 12)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Day Note',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: AppTheme.textSecondary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controller,
                      maxLines: 4,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'How did your energy, hunger, recovery, or workouts feel today?',
                        hintStyle: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: AppTheme.cardElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppTheme.cardBorder,
                            width: 0.8,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppTheme.cardBorder,
                            width: 0.8,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppTheme.activeBlue,
                            width: 1.2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SiqueBouncy(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: AppTheme.cardElevated,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppTheme.cardBorder,
                                  width: 0.8,
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SiqueBouncy(
                            onTap: _saveNote,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Text(
                                  'Save Note',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF09090B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
