# Sique Release & Deployment Verification

## Release Summary
- **Application Name**: Sique
- **Package / Application ID**: `com.h4rysh.sique`
- **Version**: `2.0.0` (Build `20`)
- **Release Target**: Android 8.0+ (API Level 26+), iOS 14.0+
- **Artifact**: `build/app/outputs/bundle/release/app-release.aab`
- **Artifact Size**: `75.0 MB`
- **SHA-256 Checksum**: `82d1eac2a9d5311233e05e4086a4a3fb08f4cccea87fa78824317975ad59cea3`

---

## Production Verification Checklist

| Gate | Requirement | Result |
| :--- | :--- | :---: |
| **Static Analysis** | `flutter analyze --fatal-infos` | **0 issues** |
| **Test Suite** | `flutter test` across all unit, widget, and simulation suites | **577 / 577 Passed** |
| **Code Formatting** | `dart format --output=none --set-exit-if-changed .` | **Clean (0 changed)** |
| **Release Build** | `flutter build appbundle --release` | **Success (86.6s)** |
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

### Assemble Release Bundle
```bash
flutter build appbundle --release
```

### Verify Release Checksum
```bash
shasum -a 256 build/app/outputs/bundle/release/app-release.aab
```

---

## 🔑 One-Time Release Keystore Setup & Hardening

Release builds for Sique require cryptographic signing and explicitly forbid falling back to debug keys.

### 1. Generating a Production Upload Keystore (Local)
Run `keytool` to generate a dedicated RSA keypair:
```bash
keytool -genkey -v -keystore release.keystore \
  -alias sique-release \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storetype JKS
```

### 2. Local Signing Configuration (`key.properties`)
Create `android/key.properties` (this file is ignored by git and must never be committed):
```properties
storePassword=<YOUR_KEYSTORE_PASSWORD>
keyPassword=<YOUR_KEY_PASSWORD>
keyAlias=sique-release
storeFile=release.keystore
```
Place `release.keystore` inside `android/app/` or `android/`.

### 3. CI/CD Release Signing Secrets (GitHub Actions)
For automated release builds triggered by `v*` tags, configure the following repository secrets in GitHub:
- `KEYSTORE_BASE64`: The Base64 encoded contents of your `.keystore` file (`base64 -i release.keystore | tr -d '\n'`).
- `KEYSTORE_PASSWORD`: The keystore password.
- `KEY_ALIAS`: The key alias (e.g., `sique-release`).
- `KEY_PASSWORD`: The private key password.

> [!IMPORTANT]
> If any of these four secrets are missing, the GitHub Actions release workflow terminates with an exit code of 1. Gradle aborts the build if release signing keys are absent, preventing accidental distribution of debug-signed binaries.
