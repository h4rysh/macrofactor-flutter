import 'package:meta/meta.dart';
import 'package:macro_factor_app/domain/models/user_profile.dart';

/// Macronutrient distribution philosophy based on MacroFactor reverse-engineered styles.
enum MacroProgramStyle {
  balanced('Balanced', 'Moderate balance of carbs and healthy fats.'),
  lowFat('Low Fat', 'Maximizes carbohydrates for endurance & training glycogen.'),
  lowCarb('Low Carb', 'Reduces carbs to 20-25% while elevating dietary fats.'),
  keto('Ketogenic', 'Strict net carb restriction (<50g) with high fat intake.'),
  highProtein('High Protein', 'Elevated protein (2.4-2.8 g/kg) for aggressive deficits.');

  const MacroProgramStyle(this.displayName, this.description);
  final String displayName;
  final String description;
}

/// Day-to-day calorie allocation and shifting across the week.
enum DayAllocationType {
  even('Even', 'Identical calories and macros every day.'),
  shiftedWorkout('Workout Shifted', 'Higher calories & carbs on training days, lower on rest days.'),
  weekendShift('Weekend Boost', 'Higher calories Friday-Sunday for social dining & flexibility.'),
  custom('Custom', 'User-defined daily caloric targets.');

  const DayAllocationType(this.displayName, this.description);
  final String displayName;
  final String description;
}

/// Target macros for a specific day of the week.
@immutable
class DayMacroTarget {
  const DayMacroTarget({
    required this.dayOfWeek,
    required this.dayName,
    required this.isWorkoutDay,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });

  final int dayOfWeek; // 1 = Monday, 7 = Sunday (matching DateTime.monday..sunday)
  final String dayName; // 'Mon', 'Tue', etc.
  final bool isWorkoutDay;
  final double calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;

  MacroTarget toMacroTarget() {
    return MacroTarget(
      calories: calories,
      proteinGrams: proteinGrams,
      carbsGrams: carbsGrams,
      fatGrams: fatGrams,
    );
  }

  DayMacroTarget copyWith({
    int? dayOfWeek,
    String? dayName,
    bool? isWorkoutDay,
    double? calories,
    double? proteinGrams,
    double? carbsGrams,
    double? fatGrams,
  }) {
    return DayMacroTarget(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dayName: dayName ?? this.dayName,
      isWorkoutDay: isWorkoutDay ?? this.isWorkoutDay,
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
    );
  }

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'dayName': dayName,
        'isWorkoutDay': isWorkoutDay,
        'calories': calories,
        'proteinGrams': proteinGrams,
        'carbsGrams': carbsGrams,
        'fatGrams': fatGrams,
      };

  factory DayMacroTarget.fromJson(Map<String, dynamic> json) => DayMacroTarget(
        dayOfWeek: (json['dayOfWeek'] as num).toInt(),
        dayName: json['dayName'] as String,
        isWorkoutDay: json['isWorkoutDay'] as bool? ?? false,
        calories: (json['calories'] as num).toDouble(),
        proteinGrams: (json['proteinGrams'] as num).toDouble(),
        carbsGrams: (json['carbsGrams'] as num).toDouble(),
        fatGrams: (json['fatGrams'] as num).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayMacroTarget &&
          runtimeType == other.runtimeType &&
          dayOfWeek == other.dayOfWeek &&
          calories == other.calories &&
          proteinGrams == other.proteinGrams &&
          carbsGrams == other.carbsGrams &&
          fatGrams == other.fatGrams &&
          isWorkoutDay == other.isWorkoutDay;

  @override
  int get hashCode => Object.hash(
        dayOfWeek,
        calories,
        proteinGrams,
        carbsGrams,
        fatGrams,
        isWorkoutDay,
      );
}

/// Complete 7-day Coaching Program matching MacroFactor's reverse-engineered program structure.
@immutable
class WeeklyMacroProgram {
  const WeeklyMacroProgram({
    required this.id,
    required this.style,
    required this.mode,
    required this.allocationType,
    required this.workoutDays,
    required this.dailyAverageCalories,
    required this.days,
    required this.createdAt,
    required this.lastCheckInDate,
    this.checkInDayOfWeek = 1, // Default Monday
  });

  final String id;
  final MacroProgramStyle style;
  final ProgramMode mode;
  final DayAllocationType allocationType;
  final Set<int> workoutDays; // e.g. {1, 3, 5} for Mon, Wed, Fri
  final double dailyAverageCalories;
  final List<DayMacroTarget> days; // 7 days (index 0 = Mon, index 6 = Sun)
  final DateTime createdAt;
  final DateTime lastCheckInDate;
  final int checkInDayOfWeek; // 1 = Monday, 7 = Sunday

  /// Total calories over the 7 days.
  double get weeklyTotalCalories =>
      days.fold<double>(0.0, (acc, d) => acc + d.calories);

  /// Retrieves target for a specific DateTime.
  DayMacroTarget targetForDate(DateTime date) {
    final weekday = date.weekday; // 1..7
    return days.firstWhere(
      (d) => d.dayOfWeek == weekday,
      orElse: () => days.first,
    );
  }

  WeeklyMacroProgram copyWith({
    String? id,
    MacroProgramStyle? style,
    ProgramMode? mode,
    DayAllocationType? allocationType,
    Set<int>? workoutDays,
    double? dailyAverageCalories,
    List<DayMacroTarget>? days,
    DateTime? createdAt,
    DateTime? lastCheckInDate,
    int? checkInDayOfWeek,
  }) {
    return WeeklyMacroProgram(
      id: id ?? this.id,
      style: style ?? this.style,
      mode: mode ?? this.mode,
      allocationType: allocationType ?? this.allocationType,
      workoutDays: workoutDays ?? this.workoutDays,
      dailyAverageCalories: dailyAverageCalories ?? this.dailyAverageCalories,
      days: days ?? this.days,
      createdAt: createdAt ?? this.createdAt,
      lastCheckInDate: lastCheckInDate ?? this.lastCheckInDate,
      checkInDayOfWeek: checkInDayOfWeek ?? this.checkInDayOfWeek,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'style': style.name,
        'mode': mode.name,
        'allocationType': allocationType.name,
        'workoutDays': workoutDays.toList(),
        'dailyAverageCalories': dailyAverageCalories,
        'days': days.map((d) => d.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'lastCheckInDate': lastCheckInDate.toIso8601String(),
        'checkInDayOfWeek': checkInDayOfWeek,
      };

  factory WeeklyMacroProgram.fromJson(Map<String, dynamic> json) =>
      WeeklyMacroProgram(
        id: json['id'] as String,
        style: MacroProgramStyle.values.firstWhere(
          (s) => s.name == json['style'],
          orElse: () => MacroProgramStyle.balanced,
        ),
        mode: ProgramMode.values.firstWhere(
          (m) => m.name == json['mode'],
          orElse: () => ProgramMode.coached,
        ),
        allocationType: DayAllocationType.values.firstWhere(
          (a) => a.name == json['allocationType'],
          orElse: () => DayAllocationType.even,
        ),
        workoutDays: (json['workoutDays'] as List<dynamic>?)
                ?.map((e) => (e as num).toInt())
                .toSet() ??
            const {1, 3, 5},
        dailyAverageCalories:
            (json['dailyAverageCalories'] as num).toDouble(),
        days: (json['days'] as List<dynamic>)
            .map((e) => DayMacroTarget.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastCheckInDate: DateTime.parse(json['lastCheckInDate'] as String),
        checkInDayOfWeek: (json['checkInDayOfWeek'] as num?)?.toInt() ?? 1,
      );
}

/// Record of an automated weekly metabolic coaching check-in.
@immutable
class CoachingCheckIn {
  const CoachingCheckIn({
    required this.id,
    required this.checkInDate,
    required this.previousCalories,
    required this.recommendedCalories,
    required this.expenditureKcal,
    required this.weightTrendKg,
    required this.isAccepted,
    required this.statusNote,
    required this.createdAt,
  });

  final String id;
  final DateTime checkInDate;
  final double previousCalories;
  final double recommendedCalories;
  final double expenditureKcal;
  final double weightTrendKg;
  final bool isAccepted;
  final String statusNote;
  final DateTime createdAt;

  double get calorieDelta => recommendedCalories - previousCalories;

  Map<String, dynamic> toJson() => {
        'id': id,
        'checkInDate': checkInDate.toIso8601String(),
        'previousCalories': previousCalories,
        'recommendedCalories': recommendedCalories,
        'expenditureKcal': expenditureKcal,
        'weightTrendKg': weightTrendKg,
        'isAccepted': isAccepted,
        'statusNote': statusNote,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CoachingCheckIn.fromJson(Map<String, dynamic> json) =>
      CoachingCheckIn(
        id: json['id'] as String,
        checkInDate: DateTime.parse(json['checkInDate'] as String),
        previousCalories: (json['previousCalories'] as num).toDouble(),
        recommendedCalories:
            (json['recommendedCalories'] as num).toDouble(),
        expenditureKcal: (json['expenditureKcal'] as num).toDouble(),
        weightTrendKg: (json['weightTrendKg'] as num).toDouble(),
        isAccepted: (json['isAccepted'] as bool?) ?? false,
        statusNote: json['statusNote'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
