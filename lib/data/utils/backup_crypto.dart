import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:cryptography/cryptography.dart';

/// Exception thrown when decrypting or parsing an encrypted `.sique.enc` archive.
class BackupCryptoException implements Exception {
  const BackupCryptoException(this.message);
  final String message;

  @override
  String toString() => 'BackupCryptoException: $message';
}

/// Password-protected AES-256-GCM encryption & PBKDF2-HMAC-SHA256 key derivation
/// for Sique portable full backups (`.sique.enc`).
class BackupCrypto {
  const BackupCrypto._();

  static const String envelopeFormat = 'sique_encrypted_backup';
  static const int currentEnvelopeVersion = 1;
  static const int defaultIterations = 100000;
  static const int minIterations = 10000;
  static const int maxIterations = 1000000;
  static const int minPasswordLength = 8;

  /// Returns true when [rawContent] is an AES-256-GCM Sique backup envelope.
  static bool isEncryptedEnvelope(String rawContent) {
    final trimmed = rawContent.trim();
    if (!trimmed.startsWith('{')) return false;
    try {
      final decoded = jsonDecode(trimmed);
      return decoded is Map<String, dynamic> &&
          decoded['format'] == envelopeFormat;
    } catch (_) {
      return false;
    }
  }

  /// Encrypts [plaintextJson] using PBKDF2-HMAC-SHA256 (100,000 iterations)
  /// and authenticated AES-256-GCM, returning a portable JSON envelope.
  static Future<String> encryptBackup({
    required String plaintextJson,
    required String password,
    int iterations = defaultIterations,
  }) async {
    if (password.length < minPasswordLength) {
      throw const BackupCryptoException(
        'Backup passphrase must be at least $minPasswordLength characters.',
      );
    }
    if (iterations < minIterations || iterations > maxIterations) {
      throw const BackupCryptoException(
        'PBKDF2 iteration count out of safe bounds.',
      );
    }

    final rng = math.Random.secure();
    final salt = List<int>.generate(16, (_) => rng.nextInt(256));

    return Isolate.run(() async {
      final kdf = Pbkdf2.hmacSha256(iterations: iterations, bits: 256);
      final derivedKey = await kdf.deriveKeyFromPassword(
        password: password,
        nonce: salt,
      );

      final cipher = AesGcm.with256bits();
      final nonce = cipher.newNonce();
      final secretBox = await cipher.encrypt(
        utf8.encode(plaintextJson),
        secretKey: derivedKey,
        nonce: nonce,
      );

      final envelope = <String, dynamic>{
        'format': envelopeFormat,
        'version': currentEnvelopeVersion,
        'kdf': 'pbkdf2-hmac-sha256',
        'iterations': iterations,
        'cipher': 'aes-256-gcm',
        'salt': base64Encode(salt),
        'nonce': base64Encode(secretBox.nonce),
        'ciphertext': base64Encode(secretBox.cipherText),
        'mac': base64Encode(secretBox.mac.bytes),
      };

      return const JsonEncoder.withIndent('  ').convert(envelope);
    });
  }

  /// Decrypts an `.sique.enc` JSON [envelopeJson] with [password].
  /// Throws [BackupCryptoException] on wrong password or tampered ciphertext.
  static Future<String> decryptBackup({
    required String envelopeJson,
    required String password,
  }) async {
    if (password.isEmpty) {
      throw const BackupCryptoException('Passphrase cannot be empty.');
    }

    final Map<String, dynamic> envelope;
    try {
      final decoded = jsonDecode(envelopeJson.trim());
      if (decoded is! Map<String, dynamic> ||
          decoded['format'] != envelopeFormat) {
        throw const BackupCryptoException(
          'Unrecognized encrypted backup format.',
        );
      }
      envelope = decoded;
    } on BackupCryptoException {
      rethrow;
    } catch (_) {
      throw const BackupCryptoException(
        'Encrypted backup file contains invalid JSON.',
      );
    }

    try {
      final version = (envelope['version'] as num?)?.toInt();
      if (version != currentEnvelopeVersion) {
        throw const BackupCryptoException(
          'Unsupported encrypted backup envelope version.',
        );
      }
      if (envelope['kdf'] != 'pbkdf2-hmac-sha256' ||
          envelope['cipher'] != 'aes-256-gcm') {
        throw const BackupCryptoException(
          'Unsupported backup encryption algorithm.',
        );
      }
      final rawIterations = envelope['iterations'];
      if (rawIterations is! num) {
        throw const BackupCryptoException('Missing KDF iteration count.');
      }
      final iterations = rawIterations.toInt();
      if (iterations < minIterations || iterations > maxIterations) {
        throw const BackupCryptoException(
          'Encrypted backup KDF iteration count out of allowed range.',
        );
      }

      final salt = base64Decode(envelope['salt'] as String);
      final nonce = base64Decode(envelope['nonce'] as String);
      final cipherText = base64Decode(envelope['ciphertext'] as String);
      final macBytes = base64Decode(envelope['mac'] as String);
      if (salt.length != 16 || nonce.length != 12 || macBytes.length != 16) {
        throw const BackupCryptoException(
          'Malformed cryptographic parameters in encrypted backup.',
        );
      }

      final clearBytes = await Isolate.run(() async {
        final kdf = Pbkdf2.hmacSha256(iterations: iterations, bits: 256);
        final derivedKey = await kdf.deriveKeyFromPassword(
          password: password,
          nonce: salt,
        );

        final cipher = AesGcm.with256bits();
        return cipher.decrypt(
          SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes)),
          secretKey: derivedKey,
        );
      });
      return utf8.decode(clearBytes);
    } on SecretBoxAuthenticationError {
      throw const BackupCryptoException(
        'Incorrect passphrase or tampered backup file.',
      );
    } catch (e) {
      if (e is BackupCryptoException) rethrow;
      throw const BackupCryptoException(
        'Unable to decrypt backup archive. Check passphrase or file integrity.',
      );
    }
  }
}
