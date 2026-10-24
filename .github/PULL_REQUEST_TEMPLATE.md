## Description
Provide a concise explanation of the changes introduced in this PR and the problem they solve.

## Type of Change
- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 🧠 Algorithmic enhancement (Kalman filter, trend weight, coaching engine)
- [ ] ♻️ Refactoring / Architectural cleanup
- [ ] 📝 Documentation update

## Architectural Verification Checklist
- [ ] All modified or new source files in `lib/` are strictly **under 800 lines**.
- [ ] `FoodItem.calculateNutrition` is preserved as the single source of truth for food calculations.
- [ ] No personal health data is sent off-device (SQLite storage remains 100% sovereign).
- [ ] Cleanroom compliance: zero prohibited competitor terms in code, comments, or assets.

## Testing Evidence
- [ ] `flutter analyze` passes with **0 issues**.
- [ ] `flutter test` passes with **100% green status** (including Monte Carlo simulations).
- [ ] `dart format --output=none --set-exit-if-changed .` passes cleanly.

## Screenshots / Video (UI Changes)
If applicable, attach before/after screenshots or screen captures.
