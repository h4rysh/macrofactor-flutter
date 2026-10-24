# Privacy & Data Sovereignty Policy

**Sique** is designed around a fundamental architecture of personal data sovereignty and strict local isolation.

## 1. Local-Only Health & Nutrition Data
- **Food Logs & Nutrition**: All meal logs, portion sizes, customized recipes, and nutritional aggregations are stored exclusively in your device's local SQLite database.
- **Scale Weight Logs & History**: All body weight readings (both manual and synchronized from Google Health Connect) remain strictly on your local device.
- **Expenditure History & Metabolic State**: Mathematical Kalman filter states, trend weights, and daily expenditure estimates are computed on-device and stored locally in SQLite.
- **No Cloud Sync of Health Data**: Health, weight, and food log data are **never** uploaded to, synchronized with, or backed up on any remote server or cloud service. If you clear app storage or uninstall the application without exporting your data, local records cannot be recovered.

## 2. Authentication & Account Credentials
- Authentication is handled exclusively through standard Firebase Authentication services (Email/Password and Google OAuth).
- Only account identity metadata (user ID, email address, display name) is maintained by the authentication provider.
- Health records, dietary logs, and physiological metrics are never transmitted to the authentication provider.

## 3. Google Health Connect Integration
- When granted permission by the user, Sique interacts with Android Health Connect to read exercise session records and smart scale body weight readings.
- Reading data from Health Connect is done purely locally on the user's device.
- Sique does not write to or alter external health platforms unless explicitly configured, and never transmits synced data off the device.

## 4. Data Export & Deletion
- **Data Export**: Users can export their entire local database to standard JSON and CSV files at any time via the Settings & Data Management screen.
- **Local Data Erasure**: Users can permanently wipe all local database tables, cached preferences, and logs using the "Delete All Data" control in settings.
- **Account Deletion**: Users may delete their authentication account directly from within the application, requiring provider-aware re-authentication to prevent accidental loss.
