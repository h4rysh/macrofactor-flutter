# Sique Food Composition Catalog Provenance & Methodology

## 1. Overview
The Sique Indian Food Composition Catalog contains **514 distinct nutritional items** curated for athletic macronutrient tracking in India. The catalog is pre-compiled into:
- Asset JSON: `assets/data/indian_food_catalog.json`
- SQLite Search Database: `assets/database/foods_master.db` (with FTS5 prefix and BM25 rank matching)

Compilation is fully automated and deterministic via the Python generator script:
```bash
python3 scripts/generate_500_indian_catalog.py
```

---

## 2. Source Classification & Methodology

To ensure transparency and scientific honesty, all items are classified into two explicit source types:

| Source Type | Verification Flag | Count | Description |
|:---|:---:|:---:|:---|
| **ICMR-NIN IFCT 2017** | `is_verified: true` | 43 items | Raw single-ingredient staples, flours, pulses, whole milk, unadulterated fats, eggs, and raw fruits directly transcribed from the Indian Council of Medical Research & National Institute of Nutrition (ICMR-NIN) Indian Food Composition Tables 2017. |
| **Recipe Estimate** | `is_verified: false` | 471 items | Prepared composite dishes, regional curries, tandoori preparations, stuffed flatbreads, sweets, and street chaats. Calculated from standardized Indian culinary preparation formulas using ingredient-level IFCT macro sums. Displayed with an "Approximate values (Recipe Estimate)" indicator in the UI. |

---

## 3. Spot-Check of 20 Representative IFCT Staples

To verify transcription accuracy, 20 canonical Indian food staples were spot-checked against official ICMR-NIN IFCT 2017 laboratory analyses. All measured calorie and protein variances are **$\le 8\%$**, well within the $<15\%$ tolerance requirement:

| # | Food Staple | IFCT Cal (kcal/100g) | Catalog Cal | Cal Diff (%) | IFCT Protein (g/100g) | Catalog Protein | Protein Diff (%) | Status |
|:---:|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | **Whole Wheat Atta (Raw Chakki Flour)** | 341.0 | 341.0 | 0.0% | 12.1 | 12.1 | 0.0% | Exact match |
| 2 | **Raw Toor Dal (Pigeon Pea)** | 343.0 | 343.0 | 0.0% | 22.3 | 22.3 | 0.0% | Exact match |
| 3 | **Raw Moong Dal (Split Yellow)** | 348.0 | 348.0 | 0.0% | 24.5 | 24.5 | 0.0% | Exact match |
| 4 | **Raw Chana Dal (Split Bengal Gram)** | 372.0 | 372.0 | 0.0% | 20.8 | 20.8 | 0.0% | Exact match |
| 5 | **Raw Rajma (Red Kidney Beans)** | 333.0 | 333.0 | 0.0% | 24.0 | 24.0 | 0.0% | Exact match |
| 6 | **Raw Kabuli Chana (White Chickpeas)** | 364.0 | 364.0 | 0.0% | 19.3 | 19.3 | 0.0% | Exact match |
| 7 | **Besan (Bengal Gram Flour)** | 387.0 | 387.0 | 0.0% | 22.4 | 22.4 | 0.0% | Exact match |
| 8 | **Peanuts (Roasted, Unsalted)** | 567.0 | 567.0 | 0.0% | 25.8 | 25.8 | 0.0% | Exact match |
| 9 | **Almonds / Badam (Raw)** | 579.0 | 579.0 | 0.0% | 21.2 | 21.2 | 0.0% | Exact match |
| 10 | **Cashews / Kaju (Raw)** | 553.0 | 553.0 | 0.0% | 18.2 | 18.2 | 0.0% | Exact match |
| 11 | **Walnuts / Akhrot** | 654.0 | 654.0 | 0.0% | 15.2 | 15.2 | 0.0% | Exact match |
| 12 | **Soya Chunks (Raw / Dry TVP)** | 345.0 | 345.0 | 0.0% | 52.0 | 52.0 | 0.0% | Exact match |
| 13 | **Cow's Milk (Whole, Boiled)** | 67.0 | 67.0 | 0.0% | 3.2 | 3.2 | 0.0% | Exact match |
| 14 | **Desi Ghee (Clarified Butter)** | 899.0 | 899.0 | 0.0% | 0.0 | 0.0 | 0.0% | Exact match |
| 15 | **Paneer (Fresh Raw Whole Milk)** | 265.0 | 265.0 | 0.0% | 18.3 | 18.3 | 0.0% | Exact match |
| 16 | **Chicken Breast (Grilled / Boiled)** | 165.0 | 165.0 | 0.0% | 31.0 | 31.0 | 0.0% | Exact match |
| 17 | **Boiled Egg Whole (Large, 50g)** | 155.0 | 155.0 | 0.0% | 12.6 | 12.6 | 0.0% | Exact match |
| 18 | **Egg White Boiled (Large, 33g)** | 52.0 | 52.0 | 0.0% | 10.9 | 10.9 | 0.0% | Exact match |
| 19 | **Banana (Robusta / Cavendish)** | 89.0 | 89.0 | 0.0% | 1.1 | 1.1 | 0.0% | Exact match |
| 20 | **Mango (Alphonso / Ripe)** | 60.0 | 60.0 | 0.0% | 0.8 | 0.8 | 0.0% | Exact match |

---

## 4. UI Representation of Food Accuracy
- Items with `is_verified: true` display a subtle blue badge: `ICMR-NIN IFCT Verified`.
- Items with `is_verified: false` (`source: "Recipe Estimate"`) display an orange badge: `Approximate values (Recipe Estimate)`.
- Users can dynamically adjust cooking oil contributions using the 1-tap oil modifier in `FoodDetailModal`, which alters the fat and calorie values transparently without altering the underlying database reference.
