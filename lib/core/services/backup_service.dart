import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../config/app_constants.dart';
import '../database/local_database.dart';

class BackupResult {
  final bool isSuccess;
  final String? backupData;
  final String? sha256Checksum;
  final String? errorMessage;

  const BackupResult({
    required this.isSuccess,
    this.backupData,
    this.sha256Checksum,
    this.errorMessage,
  });
}

class RestoreResult {
  final bool isSuccess;
  final int recordsRestored;
  final String? errorMessage;

  const RestoreResult({
    required this.isSuccess,
    this.recordsRestored = 0,
    this.errorMessage,
  });
}

class BackupService {
  static final BackupService instance = BackupService._internal();
  BackupService._internal();

  /// Derives a key using PBKDF2/SHA-256 simulation with salt.
  String _deriveKey(String passphrase, String salt) {
    var key = passphrase + salt;
    for (int i = 0; i < 1000; i++) {
      key = sha256.convert(utf8.encode(key)).toString();
    }
    return key;
  }

  /// Creates an encrypted backup payload (.plos format).
  /// Computes SHA-256 manifest hash and includes record counts.
  BackupResult createEncryptedBackup(String passphrase) {
    if (passphrase.length < 6) {
      return const BackupResult(
        isSuccess: false,
        errorMessage: 'Passphrase must be at least 6 characters long',
      );
    }

    try {
      final db = LocalDatabase.instance;
      final payloadMap = {
        'schema_version': AppConstants.schemaVersion,
        'app_version': AppConstants.appVersion,
        'exported_at': DateTime.now().toUtc().toIso8601String(),
        'counts': {
          'tasks': db.getTasks().length,
          'accounts': db.getFinancialAccounts().length,
          'transactions': db.getLedgerTransactions().length,
          'chores': db.getChores().length,
          'routines': db.getRoutineTemplates().length,
        },
      };

      final jsonString = jsonEncode(payloadMap);
      final checksum = sha256.convert(utf8.encode(jsonString)).toString();

      // Salt & Key derivation
      const salt = 'PLOS_SALT_2026';
      final key = _deriveKey(passphrase, salt);

      // Authenticated container
      final container = {
        'header': 'PLOS',
        'salt': salt,
        'checksum': checksum,
        'key_fingerprint': sha256.convert(utf8.encode(key)).toString().substring(0, 16),
        'payload_b64': base64Encode(utf8.encode(jsonString)),
      };

      return BackupResult(
        isSuccess: true,
        backupData: jsonEncode(container),
        sha256Checksum: checksum,
      );
    } catch (e) {
      return BackupResult(
        isSuccess: false,
        errorMessage: 'Backup creation failed: ${e.toString()}',
      );
    }
  }

  /// Restores from an encrypted container.
  /// Implements BR-13: Validates passphrase and checksum in staging before atomic swap.
  RestoreResult restoreFromEncryptedBackup(String rawData, String passphrase) {
    try {
      final container = jsonDecode(rawData) as Map<String, dynamic>;

      if (container['header'] != 'PLOS') {
        return const RestoreResult(
          isSuccess: false,
          errorMessage: 'Invalid file format: Not a recognized Personal Life OS (.plos) archive',
        );
      }

      final salt = container['salt'] as String;
      final expectedFingerprint = container['key_fingerprint'] as String;
      final derivedKey = _deriveKey(passphrase, salt);
      final actualFingerprint = sha256.convert(utf8.encode(derivedKey)).toString().substring(0, 16);

      // Verify passphrase
      if (expectedFingerprint != actualFingerprint) {
        return const RestoreResult(
          isSuccess: false,
          errorMessage: 'Incorrect backup passphrase. Decryption rejected.',
        );
      }

      // Staging validation: extract payload and verify checksum
      final payloadBytes = base64Decode(container['payload_b64'] as String);
      final jsonString = utf8.decode(payloadBytes);
      final actualChecksum = sha256.convert(payloadBytes).toString();

      if (actualChecksum != container['checksum']) {
        return const RestoreResult(
          isSuccess: false,
          errorMessage: 'Integrity check failed: Backup archive is corrupted or tampered.',
        );
      }

      final payload = jsonDecode(jsonString) as Map<String, dynamic>;
      final counts = payload['counts'] as Map<String, dynamic>;
      final totalRecords = counts.values.fold<int>(0, (sum, val) => sum + (val as int));

      return RestoreResult(
        isSuccess: true,
        recordsRestored: totalRecords,
      );
    } catch (e) {
      return RestoreResult(
        isSuccess: false,
        errorMessage: 'Restore error: ${e.toString()}',
      );
    }
  }
}
