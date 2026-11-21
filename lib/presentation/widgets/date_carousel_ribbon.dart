import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import 'animated_primitives.dart';

/// Signature Sique Horizontal Date Carousel Ribbon.
/// Renders the `< Today >` header and the circular day badges.
class DateCarouselRibbon extends StatelessWidget {
  const DateCarouselRibbon({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.leading,
    this.trailing,
    this.now,
    this.loggedDates = const {},
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Widget? leading;
  final Widget? trailing;
  final DateTime? now;
  final Set<String> loggedDates;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatHeaderDate(DateTime date, DateTime currentNow) {
    if (_isSameDay(date, currentNow)) {
      return 'Today';
    }
    if (_isSameDay(date,
        DateTime(currentNow.year, currentNow.month, currentNow.day - 1))) {
      return 'Yesterday';
    }
    if (_isSameDay(date,
        DateTime(currentNow.year, currentNow.month, currentNow.day + 1))) {
      return 'Tomorrow';
    }
    return DateFormat('EEE, MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final currentNow = now ?? DateTime.now();

    // Generate a 7-day window centered around selectedDate (calendar math is DST-safe)
    final days = List.generate(7, (i) {
      final offset = i - 3;
      return DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day + offset,
      );
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Authentic Sique Top Navigation Bar:
        // [ ≡ ]          < Today ▾ >          [ ☰ ]
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              leading ?? const SizedBox(width: 40),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 26),
                        color: AppTheme.textSecondary,
                        tooltip: 'Previous day',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        onPressed: () {
                          AppHaptics.selectionClick();
                          onDateSelected(
                            DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day - 1,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () async {
                          AppHaptics.selectionClick();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: AppTheme.activeBlue,
                                    surface: AppTheme.cardSurface,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) onDateSelected(picked);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.0, 0.15),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                              child: Text(
                                _formatHeaderDate(selectedDate, currentNow),
                                key: ValueKey(selectedDate),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.3,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.arrow_drop_down_rounded,
                              color: AppTheme.textSecondary,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, size: 26),
                        color: AppTheme.textSecondary,
                        tooltip: 'Next day',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        onPressed: () {
                          AppHaptics.selectionClick();
                          onDateSelected(
                            DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day + 1,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              trailing ?? const SizedBox(width: 40),
            ],
          ),
        ),

        // Carousel of 7 Day Pills (e.g. M 12, T 13, W 14...)
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: days.map((day) {
              final isSelected = _isSameDay(day, selectedDate);
              final isToday = _isSameDay(day, currentNow);
              final dayInitial =
                  DateFormat('E').format(day)[0]; // 'M', 'T', 'W'...
              final dayNumber = day.day.toString();

              return Semantics(
                button: true,
                selected: isSelected,
                label:
                    '${DateFormat('EEEE, MMMM d').format(day)}${isSelected ? ', selected' : ''}${isToday ? ', today' : ''}',
                child: AppleBouncy(
                  scaleDown: 0.94,
                  onTap: () {
                    AppHaptics.lightImpact();
                    onDateSelected(day);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 48,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.activeBlue.withValues(alpha: 0.16)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.activeBlue
                            : (isToday
                                ? AppTheme.cardBorder
                                : Colors.transparent),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayInitial,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppTheme.activeBlue
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dayNumber,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? AppTheme.textPrimary
                                  : (isToday
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: loggedDates.contains(
                                      DateFormat('yyyy-MM-dd').format(day))
                                  ? (isSelected
                                      ? AppTheme.activeBlue
                                      : AppTheme.calories)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
