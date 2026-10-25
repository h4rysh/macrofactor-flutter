import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/models/food_models.dart';

void main() {
  group('FTS5 Hardening & Hostile Query Immunity Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.inMemory();

      // Seed with representative Indian food items
      db.insertFood(
        const FoodItem(
          id: 1,
          uuid: 'uuid_1',
          name: 'Whole Wheat Phulka / Roti',
          category: 'Breads & Flatbreads',
          region: 'North',
          caloriesPer100g: 240.0,
          proteinPer100g: 8.5,
          carbsPer100g: 49.0,
          fatPer100g: 1.2,
          fiberPer100g: 7.5,
          iconSvg: 'grain',
          source: 'ICMR-NIN IFCT 2017',
          aliases: 'chapati roti phulka',
          isVerified: true,
        ),
      );

      db.insertFood(
        const FoodItem(
          id: 2,
          uuid: 'uuid_2',
          name: 'Paneer Butter Masala',
          category: 'Vegetarian Curries',
          region: 'North',
          caloriesPer100g: 220.0,
          proteinPer100g: 7.5,
          carbsPer100g: 8.0,
          fatPer100g: 18.0,
          fiberPer100g: 2.0,
          iconSvg: 'dairy',
          source: 'Recipe Estimate',
          aliases: 'cottage cheese makhani',
          isVerified: false,
        ),
      );

      db.insertFood(
        const FoodItem(
          id: 3,
          uuid: 'uuid_3',
          name: 'Dal Tadka',
          category: 'Dals & Lentils',
          region: 'Pan-Indian',
          caloriesPer100g: 115.0,
          proteinPer100g: 5.8,
          carbsPer100g: 15.2,
          fatPer100g: 3.5,
          fiberPer100g: 4.2,
          iconSvg: 'veg',
          source: 'Recipe Estimate',
          aliases: 'yellow dal toor dal fry',
          isVerified: false,
        ),
      );
    });

    tearDown(() {
      db.close();
    });

    final hostileQueries = [
      '*',
      '**',
      '***',
      '"',
      '""',
      '"""',
      'AND',
      'OR',
      'NOT',
      'NEAR',
      'NEAR/2',
      'AND AND AND',
      'OR OR OR',
      'NOT NOT',
      '-roti',
      'roti -oil',
      '+roti',
      'roti:paneer',
      'roti (paneer)',
      '{roti}',
      '[roti]',
      'roti^2',
      '---',
      "roti's",
      'roti"paneer',
      '  ',
      '',
    ];

    for (final hostile in hostileQueries) {
      test('Hostile query "$hostile" does not crash FTS5 and executes safely',
          () {
        expect(() => db.searchFoods(hostile), returnsNormally);
        final results = db.searchFoods(hostile);
        expect(results, isA<List<FoodItem>>());
      });

      test(
          'searchFoodsAsync with hostile query "$hostile" executes safely off-thread',
          () async {
        final results = await db.searchFoodsAsync(hostile);
        expect(results, isA<List<FoodItem>>());
      });
    }

    test('Rank ordering surfaces highest relevance item first', () {
      final results = db.searchFoods('roti');
      expect(results, isNotEmpty);
      expect(results.first.name, contains('Roti'));
    });

    test('Food item preserves isVerified and source distinction', () {
      final roti = db.getFoodById(1);
      expect(roti, isNotNull);
      expect(roti!.isVerified, isTrue);
      expect(roti.source, equals('ICMR-NIN IFCT 2017'));

      final paneer = db.getFoodById(2);
      expect(paneer, isNotNull);
      expect(paneer!.isVerified, isFalse);
      expect(paneer.source, equals('Recipe Estimate'));
    });
  });
}
