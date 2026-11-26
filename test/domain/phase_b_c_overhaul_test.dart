import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/data/services/open_food_facts_service.dart';
import 'package:sique/data/utils/backup_codec.dart';
import 'package:sique/data/utils/backup_crypto.dart';
import 'package:sique/domain/models/body_measurement_entry.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/models/lifestyle_models.dart';
import 'package:sique/domain/models/recipe_models.dart';
import 'package:sique/domain/models/scale_weight_entry.dart';
import 'package:sique/domain/models/weekly_challenge_model.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/providers/plate_staging_provider.dart';
import 'package:sique/presentation/providers/recipes_providers.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  group('Phase B & C Overhaul Tests', () {
    late AppDatabase appDb;
    late ProviderContainer container;

    setUp(() {
      appDb = AppDatabase.inMemory();
      appDb.insertFood(const FoodItem(
        id: 101,
        uuid: 'f101',
        name: 'Boiled Egg',
        category: 'Eggs',
        region: 'Global',
        caloriesPer100g: 155,
        proteinPer100g: 13.0,
        carbsPer100g: 1.1,
        fatPer100g: 11.0,
        fiberPer100g: 0.0,
        iconSvg: 'i2.svg',
        source: 'Test',
        aliases: 'anda',
      ));
      appDb.insertFood(const FoodItem(
        id: 102,
        uuid: 'f102',
        name: 'Spinach Palak',
        category: 'Vegetables',
        region: 'Pan-Indian',
        caloriesPer100g: 23,
        proteinPer100g: 2.9,
        carbsPer100g: 3.6,
        fatPer100g: 0.4,
        fiberPer100g: 2.2,
        iconSvg: 'i2.svg',
        source: 'Test',
        aliases: 'palak',
      ));
      appDb.barcodeDao
          .upsertFoodNutrients(102, {1: 4.5, 5: 28.0}); // Iron + Vit C

      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(appDb),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      appDb.close();
    });

    test(
        'Master food catalog asset exceeds 2,500 foods with sparse micros & barcodes',
        () {
      final dbFile = File('assets/database/foods_master.db');
      expect(dbFile.existsSync(), isTrue);

      final masterDb = sqlite3.open(dbFile.path, mode: OpenMode.readOnly);
      try {
        final foodCount = masterDb
            .select('SELECT COUNT(*) AS cnt FROM foods;')
            .first['cnt'] as int;
        final barcodeCount = masterDb
            .select('SELECT COUNT(*) AS cnt FROM barcode_cache;')
            .first['cnt'] as int;
        final nutrientDefCount = masterDb
            .select('SELECT COUNT(*) AS cnt FROM nutrient_definitions;')
            .first['cnt'] as int;
        final nutrientFactCount = masterDb
            .select('SELECT COUNT(*) AS cnt FROM food_nutrients;')
            .first['cnt'] as int;

        expect(foodCount, greaterThanOrEqualTo(2500));
        expect(barcodeCount, greaterThanOrEqualTo(25));
        expect(nutrientDefCount, equals(36));
        expect(nutrientFactCount, greaterThan(5000));
      } finally {
        masterDb.dispose();
      }
    });

    test(
        'PlateStagingNotifier merges identical items, saves recipe, and batch commits',
        () {
      final egg = appDb.getFoodById(101)!;
      final spinach = appDb.getFoodById(102)!;

      final staging = container.read(plateStagingProvider.notifier);
      staging.addItem(
        egg,
        unit: const PortionUnit(
          id: 1,
          foodId: 101,
          unitName: '1 Egg (50g)',
          gramWeight: 50.0,
        ),
        quantity: 2.0,
      );
      staging.addItem(
        egg,
        unit: const PortionUnit(
          id: 1,
          foodId: 101,
          unitName: '1 Egg (50g)',
          gramWeight: 50.0,
        ),
        quantity: 1.0,
      );
      staging.addItem(
        spinach,
        unit: const PortionUnit(
          id: 2,
          foodId: 102,
          unitName: '100g Bowl',
          gramWeight: 100.0,
        ),
        quantity: 1.0,
      );

      final items = container.read(plateStagingProvider);
      expect(items.length, equals(2));
      expect(items.first.quantity, equals(3.0)); // merged 2 + 1 eggs

      final savedRecipe = staging.saveAsCustomRecipe(
        name: 'Spinach Omelette Base',
        servings: 2,
      );
      expect(savedRecipe, isNotNull);
      expect(savedRecipe!.ingredients.length, equals(2));
      expect(container.read(customRecipesProvider).length, equals(1));

      final now = DateTime(2026, 11, 25, 9, 0);
      container.read(selectedDateProvider.notifier).state = '2026-11-25';
      final loggedCount = staging.commitToLog(
        mealType: MealType.breakfast,
        loggedAt: now,
      );
      expect(loggedCount, equals(2));
      expect(container.read(plateStagingProvider), isEmpty);
      expect(container.read(dailyFoodLogsProvider).length, equals(2));
    });

    test('CustomRecipesNotifier supports Exploded Timeline Decomposition', () {
      final now = DateTime(2026, 11, 25, 13, 0);
      container.read(selectedDateProvider.notifier).state = '2026-11-25';

      final recipe = CustomRecipe(
        id: 'rec_explode_1',
        userId: appDb.currentUserId,
        name: 'Egg Spinach Bowl',
        servings: 2,
        totalWeightG: 300,
        createdAt: now,
        updatedAt: now,
        ingredients: const [
          RecipeIngredient(
            id: 'ing_1',
            recipeId: 'rec_explode_1',
            foodId: 101,
            foodName: 'Boiled Egg',
            servingQuantity: 4.0,
            unitName: '1 Egg (50g)',
            gramWeight: 200.0,
            calories: 310.0,
            protein: 26.0,
            carbs: 2.2,
            fat: 22.0,
            fiber: 0.0,
          ),
          RecipeIngredient(
            id: 'ing_2',
            recipeId: 'rec_explode_1',
            foodId: 102,
            foodName: 'Spinach Palak',
            servingQuantity: 1.0,
            unitName: '100g Bowl',
            gramWeight: 100.0,
            calories: 23.0,
            protein: 2.9,
            carbs: 3.6,
            fat: 0.4,
            fiber: 2.2,
          ),
        ],
      );

      final recipesNotifier = container.read(customRecipesProvider.notifier);
      recipesNotifier.saveRecipe(recipe);

      // Exploding 1 serving (half of 2-serving batch) logs 2 separate items at 50% weight
      final count = recipesNotifier.logRecipe(
        recipe: recipe,
        servings: 1.0,
        mealType: MealType.lunch,
        loggedAt: now,
        explodeIngredients: true,
      );
      expect(count, equals(2));

      final logs = container.read(dailyFoodLogsProvider);
      expect(logs.length, equals(2));
      expect(logs[0].gramWeight, closeTo(100.0, 0.01));
      expect(logs[1].gramWeight, closeTo(50.0, 0.01));
    });

    test(
        'OpenFoodFactsService caches HTTP hits in SQLite and handles offline failures',
        () async {
      var networkCalls = 0;
      final mockClient = MockClient((request) async {
        networkCalls++;
        if (request.url.path.contains('8909999000111')) {
          return http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'product_name': 'Sique Protein Crunch',
                'brands': 'Sique Labs',
                'serving_quantity': 40,
                'nutriments': {
                  'energy-kcal_100g': 410,
                  'proteins_100g': 30,
                  'carbohydrates_100g': 42,
                  'fat_100g': 12,
                  'fiber_100g': 6,
                },
              },
            }),
            200,
          );
        }
        return http.Response('{"status":0}', 404);
      });

      final service = OpenFoodFactsService(
        barcodeDao: appDb.barcodeDao,
        client: mockClient,
      );

      // First lookup hits network and caches to SQLite
      final first = await service.lookupBarcode('8909999000111');
      expect(first, isNotNull);
      expect(first!.foodName, equals('Sique Protein Crunch'));
      expect(networkCalls, equals(1));

      // Second lookup reads directly from SQLite barcode_cache (0 extra HTTP calls)
      final second = await service.lookupBarcode('8909999000111');
      expect(second, isNotNull);
      expect(networkCalls, equals(1));

      // Missing product returns null cleanly
      final missing = await service.lookupBarcode('0000000000000');
      expect(missing, isNull);
    });

    test(
        'BarcodeDao aggregates daily sparse micronutrient intake by logged grams',
        () {
      final now = DateTime(2026, 11, 25, 12, 30);
      container.read(selectedDateProvider.notifier).state = '2026-11-25';
      final spinach = appDb.getFoodById(102)!;

      container.read(dailyFoodLogsProvider.notifier).addEntry(
            food: spinach,
            portionUnit: const PortionUnit(
              id: 2,
              foodId: 102,
              unitName: '100g',
              gramWeight: 100.0,
            ),
            quantity: 2.0, // 200g -> 9.0 mg Iron, 56.0 mg Vit C
            mealType: MealType.lunch,
            oilModifier: OilModifier.standard,
            loggedAt: now,
          );

      final micros = container.read(dailyMicronutrientsProvider);
      expect(micros.length, equals(36));
      final iron = micros.firstWhere((m) => m.definition.slug == 'iron');
      final vitC = micros.firstWhere((m) => m.definition.slug == 'vitamin_c');
      expect(iron.consumedAmount, closeTo(9.0, 0.01));
      expect(vitC.consumedAmount, closeTo(56.0, 0.01));
    });

    test(
        'BackupCodec v6 & BackupCrypto AES-256-GCM roundtrip and reject wrong passphrases',
        () async {
      final now = DateTime(2026, 11, 25, 8, 0);
      final profile = defaultUserProfile.copyWith(
        reverseDietPacing: 'moderate',
        isInDietBreak: true,
        dailyWaterTargetMl: 3200,
      );
      final encoded = BackupCodec.encodeBackup(
        profile: profile,
        foodLogs: const [],
        weightLogs: [ScaleWeightEntry(date: now, weightKg: 74.2)],
        bodyMeasurements: [
          BodyMeasurementEntry(
            id: 'bm_v6',
            date: now,
            waistCm: 81.5,
            loggedAt: now,
          ),
        ],
        weeklyChallenges: [
          WeeklyChallengeModel(
            id: 'ch_v6',
            type: ChallengeType.hydrationHero,
            title: 'Hydration Baseline',
            description: '2.5L daily',
            targetMetric: 'hydration',
            targetValue: 5,
            currentValue: 2,
            unit: 'days',
            weekStartDate: now,
            weekEndDate: now.add(const Duration(days: 6)),
            createdAt: now,
          ),
        ],
        waterLogs: [
          WaterLog(date: '2026-11-25', amountMl: 500, loggedAt: now),
        ],
        fastingSessions: [
          FastingSession(
            id: 'fast_v6',
            protocol: FastingProtocol.f16_8,
            startTime: now,
            targetEndTime: now.add(const Duration(hours: 16)),
            state: 'completed',
          ),
        ],
        customRecipes: [
          CustomRecipe(
            id: 'rec_v6',
            userId: 'default_user',
            name: 'Oats Shake',
            servings: 1,
            totalWeightG: 300,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      final encrypted = await BackupCrypto.encryptBackup(
        plaintextJson: encoded,
        password: 'sique-strong-passphrase',
        iterations:
            10000, // Minimum safe KDF floor while keeping unit tests fast
      );
      expect(BackupCrypto.isEncryptedEnvelope(encrypted), isTrue);

      await expectLater(
        BackupCrypto.decryptBackup(
          envelopeJson: encrypted,
          password: 'wrong-passphrase',
        ),
        throwsA(isA<BackupCryptoException>()),
      );

      // Rejects tampered absurd iteration count (DoS protection)
      final parsedEnv = jsonDecode(encrypted) as Map<String, dynamic>;
      parsedEnv['iterations'] = 99999999;
      await expectLater(
        BackupCrypto.decryptBackup(
          envelopeJson: jsonEncode(parsedEnv),
          password: 'sique-strong-passphrase',
        ),
        throwsA(isA<BackupCryptoException>()),
      );

      final decrypted = await BackupCrypto.decryptBackup(
        envelopeJson: encrypted,
        password: 'sique-strong-passphrase',
      );
      final decoded = BackupCodec.decodeAndValidate(decrypted);
      expect(decoded.schemaVersion, equals(7));
      expect(decoded.profile!.reverseDietPacing, equals('moderate'));
      expect(decoded.profile!.isInDietBreak, isTrue);
      expect(decoded.profile!.dailyWaterTargetMl, equals(3200));
      expect(decoded.bodyMeasurements.length, equals(1));
      expect(decoded.weeklyChallenges.length, equals(1));
      expect(decoded.waterLogs.length, equals(1));
      expect(decoded.fastingSessions.length, equals(1));
      expect(decoded.customRecipes.length, equals(1));

      // Verify upsertFastingSession is idempotent across repeated restores
      appDb.fastingDao.upsertFastingSession(decoded.fastingSessions.first);
      appDb.fastingDao.upsertFastingSession(decoded.fastingSessions.first);
      expect(appDb.fastingDao.getRecentFasts().length, equals(1));
    });

    test(
        'Stale v5 4-column foods_ai trigger is dropped & recreated cleanly for v6 inserts',
        () {
      final upgradeDbRaw = sqlite3.openInMemory();
      upgradeDbRaw.execute('''
        CREATE TABLE foods (
          id INTEGER PRIMARY KEY, uuid TEXT, name TEXT, category TEXT, region TEXT,
          calories REAL, protein REAL, carbs REAL, fat REAL, fiber REAL, icon_svg TEXT,
          source TEXT, aliases TEXT, is_verified INTEGER NOT NULL DEFAULT 1
        );
        CREATE TABLE portion_units (
          id INTEGER PRIMARY KEY, food_id INTEGER, unit_name TEXT, gram_weight REAL, is_default INTEGER
        );
        CREATE VIRTUAL TABLE foods_fts USING fts5(name, category, region, aliases, content='foods', content_rowid='id');
        CREATE TRIGGER foods_ai AFTER INSERT ON foods BEGIN
          INSERT INTO foods_fts(rowid, name, category, region, aliases) VALUES (new.id, new.name, new.category, new.region, new.aliases);
        END;
        PRAGMA user_version = 5;
      ''');

      final upgradedAppDb = AppDatabase(upgradeDbRaw, isInMemory: true);
      upgradedAppDb.insertFood(const FoodItem(
        id: 2500,
        uuid: 'f2500',
        name: 'Sique Upgraded Food',
        category: 'Global Bowls',
        region: 'Global',
        caloriesPer100g: 120,
        proteinPer100g: 10,
        carbsPer100g: 15,
        fatPer100g: 2,
        fiberPer100g: 3,
        iconSvg: 'i2.svg',
        source: 'Test',
        aliases: 'bowl',
      ));
      expect(
          upgradedAppDb.getFoodById(2500)?.name, equals('Sique Upgraded Food'));
      upgradedAppDb.close();
    });
  });
}
