# Security Policy

## Supported Versions

We actively maintain and provide security updates for the current major release of **Sique**:

| Version | Supported          |
| ------- | ------------------ |
| 2.0.x   | :white_check_mark: |
| < 2.0.0 | :x:                |

---

## 🔒 Data Sovereignty & Local Storage Architecture

Sique is designed with an uncompromising local-first security architecture:

1. **Zero Cloud Ingestion of Personal Health Data**:
   - All nutritional intake records, body weight readings, and metabolic expenditure state estimations are strictly stored in local SQLite database files on the user's physical device.
   - The application does not transmit or back up personal health logs to any external cloud database.
2. **Provider-Aware Authentication**:
   - Identity verification is managed via standard OAuth (Google Sign-In) and Firebase Authentication through an abstract `AuthRepository`.
   - The user's account session token is cached locally in SQLite.
3. **Complete Local Data Wipe**:
   - Executing "Delete Account / Wipe All Data" triggers immediate purging of all local SQLite user tables (`food_logs`, `weight_logs`, `day_completions`, `user_account_session`, `app_settings`), resets `sqlite_sequence`, wipes `SharedPreferences`, and invalidates in-memory Riverpod provider state. The food catalog is preserved for subsequent guest sessions.

---

## Reporting a Vulnerability

If you discover a security vulnerability or sensitive information disclosure in Sique, please notify the maintainer privately:

- **Email**: `harrishgayathri@gmail.com`
- Please include:
  - Description of the vulnerability and potential attack vector.
  - Minimal reproducible example or steps to reproduce.
  - Affected platform (Android, iOS, etc.) and application version.

We strive to acknowledge receipt of security reports within 48 hours and release patches in an expedited manner. Please refrain from publicly disclosing the issue until a patch has been published.
