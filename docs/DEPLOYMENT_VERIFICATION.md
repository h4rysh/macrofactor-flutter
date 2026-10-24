# Sique Release & Deployment Verification

## Release Summary
- **Application Name**: Sique
- **Package / Application ID**: `com.h4rysh.sique`
- **Version**: `2.0.0` (Build `20`)
- **Release Target**: Android 8.0+ (API Level 26+), iOS 14.0+
- **Artifact**: `build/app/outputs/flutter-apk/app-release.apk`
- **Artifact Size**: `75.0 MB`
- **SHA-256 Checksum**: `82d1eac2a9d5311233e05e4086a4a3fb08f4cccea87fa78824317975ad59cea3`

---

## Production Verification Checklist

| Gate | Requirement | Result |
| :--- | :--- | :---: |
| **Static Analysis** | `flutter analyze --fatal-infos` | **0 issues** |
| **Test Suite** | `flutter test` across all unit, widget, and simulation suites | **577 / 577 Passed** |
| **Code Formatting** | `dart format --output=none --set-exit-if-changed .` | **Clean (0 changed)** |
| **Release Build** | `flutter build apk --release` | **Success (86.6s)** |
| **Cleanroom Audit** | Zero prohibited competitor strings across repository | **0 occurrences** |
| **Maintainability** | Soft ceiling $<800$ lines per file in `lib/` | **100% compliant** |
| **Data Sovereignty** | Zero personal health data transmitted off-device | **Verified (Local SQLite)** |

---

## Build Commands

### Clean Build
```bash
flutter clean
flutter pub get
```

### Static Analysis & Testing
```bash
flutter analyze
flutter test
```

### Assemble Release APK
```bash
flutter build apk --release
```

### Verify Release Checksum
```bash
shasum -a 256 build/app/outputs/flutter-apk/app-release.apk
```
