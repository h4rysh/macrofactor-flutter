import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

/// Signature MacroFactor Horizontal Date Carousel Ribbon.
/// Renders the `< Today >` header and the circular day badges.
class DateCarouselRibbon extends StatelessWidget {
  const DateCarouselRibbon({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.leading,
    this.trailing,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Widget? leading;
  final Widget? trailing;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatHeaderDate(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Today';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    if (_isSameDay(date, now.add(const Duration(days: 1)))) return 'Tomorrow';
    return DateFormat('EEE, MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Generate a 7-day window centered or ending around today/selectedDate
    final days = List.generate(7, (i) {
      return selectedDate.subtract(Duration(days: 3 - i));
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Authentic MacroFactor Top Navigation Bar:
        // [ ≡ ]          < Today ▾ >          [ ☰ ]
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              leading ?? const SizedBox(width: 40),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 26),
                    color: AppTheme.textSecondary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => onDateSelected(
                      selectedDate.subtract(const Duration(days: 1)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () async {
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
                        Text(
                          _formatHeaderDate(selectedDate),
                          style: const TextStyle(
                            fontFamily: 'MacroSans',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.3,
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
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => onDateSelected(
                      selectedDate.add(const Duration(days: 1)),
                    ),
                  ),
                ],
              ),
              trailing ?? const SizedBox(width: 40),
            ],
          ),
        ),

        // Carousel of 7 Day Pills (e.g. M 12, T 13, W 14...)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: days.map((day) {
              final isSelected = _isSameDay(day, selectedDate);
              final isToday = _isSameDay(day, now);
              final dayInitial = DateFormat('E').format(day)[0]; // 'M', 'T', 'W'...
              final dayNumber = day.day.toString();

              return GestureDetector(
                onTap: () => onDateSelected(day),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 44,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.cardElevated
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.activeBlue
                          : (isToday ? AppTheme.cardBorder : Colors.transparent),
                      width: isSelected ? 2.2 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayInitial,
                        style: TextStyle(
                          fontFamily: 'MacroSans',
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
                          fontFamily: 'MacroSans',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? AppTheme.textPrimary
                              : (isToday
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary),
                        ),
                      ),
                    ],
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
