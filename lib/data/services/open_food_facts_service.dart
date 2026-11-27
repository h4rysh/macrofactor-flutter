import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:sique/data/local/dao/barcode_dao.dart';
import 'package:sique/domain/models/recipe_models.dart';

/// Offline-first barcode product lookup service backed by local SQLite
/// `barcode_cache` and lazy OpenFoodFacts API v2 network fallback.
class OpenFoodFactsService {
  OpenFoodFactsService({
    required BarcodeDao barcodeDao,
    http.Client? client,
  })  : _barcodeDao = barcodeDao,
        _client = client ?? http.Client();

  final BarcodeDao _barcodeDao;
  final http.Client _client;

  static const Duration _requestTimeout = Duration(seconds: 5);
  static const Duration _cacheTtl = Duration(days: 30);

  void close() {
    _client.close();
  }

  /// Resolves a scanned barcode string. Checks SQLite `barcode_cache` first;
  /// if missing or stale and device is online, queries OpenFoodFacts v2, caches locally,
  /// and returns the normalized product. Never throws on network loss.
  Future<BarcodeFoodProduct?> lookupBarcode(String rawBarcode) async {
    final normalized = _normalizeBarcode(rawBarcode);
    if (normalized == null) return null;

    // 1. Offline cache hit (within TTL)
    final cached = _barcodeDao.getByBarcode(normalized);
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _cacheTtl) {
      return cached;
    }

    // 2. Lazy network fetch with strict timeout
    try {
      final uri = Uri.https(
        'world.openfoodfacts.org',
        '/api/v2/product/$normalized.json',
        {'fields': 'product_name,brands,serving_quantity,nutriments'},
      );
      final response = await _client.get(
        uri,
        headers: const {
          'User-Agent': 'SiqueNutrition/3.1 (https://sique.app)',
          'Accept': 'application/json',
        },
      ).timeout(_requestTimeout);

      if (response.statusCode != 200 ||
          response.bodyBytes.length > 512 * 1024) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['status'] != 1) return null;

      final productMap = decoded['product'];
      if (productMap is! Map<String, dynamic>) return null;

      final rawName = (productMap['product_name'] as String?)?.trim() ?? '';
      if (rawName.isEmpty) return null;
      final safeName =
          rawName.length > 160 ? rawName.substring(0, 160) : rawName;

      final rawBrand = (productMap['brands'] as String?)?.trim();
      final safeBrand = rawBrand != null && rawBrand.isNotEmpty
          ? (rawBrand.length > 120 ? rawBrand.substring(0, 120) : rawBrand)
          : null;
      final nutriments = productMap['nutriments'];
      if (nutriments is! Map<String, dynamic>) return null;

      final protein = _readNum(nutriments, 'proteins_100g') ?? 0.0;
      final carbs = _readNum(nutriments, 'carbohydrates_100g') ?? 0.0;
      final fat = _readNum(nutriments, 'fat_100g') ?? 0.0;
      final fiber = _readNum(nutriments, 'fiber_100g') ?? 0.0;
      final kcal = _readNum(nutriments, 'energy-kcal_100g') ??
          ((protein * 4.0) + (carbs * 4.0) + (fat * 9.0));

      final servingG = _parseServingGrams(productMap['serving_quantity']);
      if (!kcal.isFinite ||
          !protein.isFinite ||
          !carbs.isFinite ||
          !fat.isFinite ||
          !fiber.isFinite ||
          !servingG.isFinite ||
          kcal < 0 ||
          kcal > 1000 ||
          protein < 0 ||
          protein > 100 ||
          carbs < 0 ||
          carbs > 100 ||
          fat < 0 ||
          fat > 100 ||
          fiber < 0 ||
          fiber > 100 ||
          servingG <= 0 ||
          servingG > 5000) {
        return null;
      }

      final product = BarcodeFoodProduct(
        barcode: normalized,
        foodName: safeName,
        brandName: safeBrand,
        servingSizeG: servingG,
        caloriesPer100g: kcal,
        proteinPer100g: protein,
        carbsPer100g: carbs,
        fatPer100g: fat,
        fiberPer100g: fiber,
        cachedAt: DateTime.now(),
      );

      _barcodeDao.upsertProduct(product);
      return product;
    } on TimeoutException catch (e) {
      developer.log(
        'OpenFoodFacts lookup timed out for $normalized',
        name: 'OpenFoodFactsService',
        error: e,
      );
      return null;
    } catch (e, st) {
      developer.log(
        'OpenFoodFacts lookup failed (offline or invalid payload)',
        name: 'OpenFoodFactsService',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  String? _normalizeBarcode(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'\s+'), '');
    if (trimmed.length < 4 || trimmed.length > 32) return null;
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(trimmed)) return null;
    return trimmed;
  }

  double? _readNum(Map<String, dynamic> map, String key) {
    final val = map[key];
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  double _parseServingGrams(Object? raw) {
    if (raw is num && raw.isFinite && raw > 0) return raw.toDouble();
    if (raw is String) {
      final match = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(raw);
      if (match != null) {
        final parsed = double.tryParse(match.group(1)!.replaceAll(',', '.'));
        if (parsed != null && parsed.isFinite && parsed > 0) return parsed;
      }
    }
    return 100.0;
  }
}
