import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/algorithms/coaching_engine.dart';
import 'package:sique/domain/models/macro_program.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/providers/app_providers.dart';

void main() {
  group('Target Propagation and Calorie Floor Guardrails', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase.inMemory();
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      db.close();
    });

    test(
        'Updating profile rate immediately propagates to active macro target program',
        () {
      final initialProfile = container.read(userProfileProvider);
      final initialProgram = container.read(weeklyMacroProgramProvider);
      final initialCalories = initialProgram.dailyAverageCalories;

      // Update weekly rate from -0.5% to -1.0% (steeper deficit)
      final updatedProfile = initialProfile.copyWith(
        weeklyRateOfChangePct: -1.0,
      );

      container
          .read(userProfileProvider.notifier)
          .updateProfile(updatedProfile);

      final newProgram = container.read(weeklyMacroProgramProvider);
      expect(newProgram.dailyAverageCalories, lessThan(initialCalories),
          reason:
              'A steeper deficit must immediately lower average daily calories');

      // Check persisted program in DB matches new program
      final savedDbProgram = db.getCoachingProgram();
      expect(savedDbProgram, isNotNull);
      expect(savedDbProgram!.dailyAverageCalories,
          equals(newProgram.dailyAverageCalories));
    });

    test('Updating protein preference immediately recalculates protein targets',
        () {
      final initialProfile = container.read(userProfileProvider);
      // Change from high (2.0 g/kg) to moderate (1.6 g/kg)
      final updatedProfile = initialProfile.copyWith(
        proteinPreference: ProteinPreference.moderate,
      );

      container
          .read(userProfileProvider.notifier)
          .updateProfile(updatedProfile);

      final newProgram = container.read(weeklyMacroProgramProvider);
      final monday = newProgram.days.firstWhere((d) => d.dayOfWeek == 1);
      // Moderate protein preference is 1.6 g/kg * 75kg = 120g
      expect(monday.proteinGrams, equals(120.0));
    });

    test(
        'Shifted workout day allocation strictly enforces calorieFloor on rest days',
        () {
      const lowExpenditureProfile = UserProfile(
        id: 'user_floor',
        name: 'Floor Tester',
        currentWeightKg: 60.0,
        targetWeightKg: 55.0,
        heightCm: 160.0,
        age: 30,
        isMale: false,
        goalType: GoalType.fatLoss,
        programMode: ProgramMode.coached,
        weeklyRateOfChangePct: -1.0,
        proteinPreference: ProteinPreference.moderate,
        calorieFloor: 1200.0,
        baselineExpenditureKcal: 1400.0,
      );

      // Raw deficit: 1400 - (60 * 0.01 * 1100) = 1400 - 660 = 740 -> clamped to 1200
      final program = CoachingEngine.buildWeeklyProgram(
        profile: lowExpenditureProfile,
        expenditureKcal: 1400.0,
        style: MacroProgramStyle.balanced,
        allocationType: DayAllocationType.shiftedWorkout,
        workoutDays: const {1, 3, 5},
      );

      for (final day in program.days) {
        expect(day.calories,
            greaterThanOrEqualTo(lowExpenditureProfile.calorieFloor),
            reason:
                'Day ${day.dayName} calories (${day.calories}) must be >= floor (${lowExpenditureProfile.calorieFloor})');
      }
    });

    test(
        'regenerateFromProfile preserves user customized checkInDayOfWeek and allocation preferences',
        () {
      final initialProfile = container.read(userProfileProvider);
      final customProgram = CoachingEngine.buildWeeklyProgram(
        profile: initialProfile,
        expenditureKcal: 2500.0,
        style: MacroProgramStyle.balanced,
        allocationType: DayAllocationType.weekendShift,
        workoutDays: const {1, 3, 5},
        checkInDayOfWeek: 3, // Wednesday
      );
      container
          .read(weeklyMacroProgramProvider.notifier)
          .updateProgram(customProgram);

      expect(container.read(weeklyMacroProgramProvider).checkInDayOfWeek,
          equals(3));

      // Trigger profile update which invokes regenerateFromProfile
      container.read(userProfileProvider.notifier).updateProfile(
            initialProfile.copyWith(weeklyRateOfChangePct: -0.8),
          );

      final regenerated = container.read(weeklyMacroProgramProvider);
      expect(regenerated.checkInDayOfWeek, equals(3));
      expect(
          regenerated.allocationType, equals(DayAllocationType.weekendShift));
    });
  });
}
