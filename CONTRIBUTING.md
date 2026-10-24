# Contributing to Sique

Thank you for your interest in contributing to **Sique**! We are building an adherence-neutral, scientifically rigorous nutritional coaching system with uncompromising data sovereignty.

---

## 📜 Cleanroom & Originality Ground Rules

1. **Original Brand & IP**:
   - Sique is an independent, original product.
   - Never reference or use proprietary brand names, abbreviations, or derivative phrases from commercial competitors anywhere in user-facing copy, code identifiers, comments, documentation, or commit messages.
2. **Adherence-Neutral Philosophy**:
   - Never introduce guilt-inducing UI elements (e.g., bright red warning rings when calories exceed a goal, negative streak counters, or punitive calorie adjustments).
   - Human metabolism is modeled strictly as an open thermodynamic system.

---

## 🏗️ Architectural Guidelines

1. **Clean Architecture**:
   - **Domain Layer (`lib/domain/`)**: Pure Dart only. Zero dependencies on Flutter UI or database engines. Immutable data structures and algorithmic purity.
   - **Data Layer (`lib/data/`)**: Modular DAOs, SQLite database migrations, and hardware sync adapters.
   - **Presentation Layer (`lib/presentation/`)**: Riverpod 2 state notifiers and Cupertino/Apple HIG tactile widgets.
2. **Code Maintainability Standards**:
   - **800-Line Ceiling**: Every source file in `lib/` must remain strictly under 800 lines.
   - **Function Length**: Keep functions small ($<50$ lines) and focused on a single responsibility.
   - **Immutability**: Always use immutable models (`@immutable` classes with `copyWith`). Never mutate data structures in-place.
   - **No Silent Failures**: Never write empty `catch (_)` blocks. Log error details and surface actionable, user-friendly messages.

---

## 🧪 Testing & Verification Requirements

Before submitting a Pull Request, all automated checks must pass cleanly:

1. **Run Static Analysis**:
   ```bash
   flutter analyze
   ```
   Must output `No issues found!`.
2. **Run All Tests**:
   ```bash
   flutter test
   ```
   All tests (unit, widget, algorithmic simulations, and adversarial stress tests) must pass 100% green.
3. **Format Check**:
   ```bash
   dart format --output=none --set-exit-if-changed .
   ```
   Zero files should need formatting.

---

## 📦 Pull Request Process

1. Fork the repository and create your branch from `main`:
   ```bash
   git checkout -b feat/your-feature-name
   ```
2. Commit your changes following the [Conventional Commits](https://www.conventionalcommits.org/) specification:
   - `feat(domain): add adaptive protein scaling`
   - `fix(data): handle zero-byte database initialization`
   - `test(algorithms): add Monte Carlo water shock scenario`
3. Push to your fork and submit a Pull Request targeting `main`.
4. Ensure your PR description details the motivation, testing evidence, and any architectural trade-offs.
