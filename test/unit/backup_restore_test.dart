import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_life_os/core/services/backup_service.dart';

void main() {
  group('Encrypted Backup & Atomic Staging Restore (BR-13, FR-ST-04, NFR-02)', () {
    late BackupService backupService;

    setUp(() {
      backupService = BackupService.instance;
    });

    test('FR-ST-04: Backup requires at least 6 character passphrase', () {
      final shortPass = backupService.createEncryptedBackup('12345');
      expect(shortPass.isSuccess, isFalse);
      expect(shortPass.errorMessage, contains('at least 6 characters'));
    });

    test('BR-13: Valid backup produces SHA-256 manifest hash and restores with correct passphrase', () {
      const passphrase = 'SuperSecurePassphrase2026!';
      final backup = backupService.createEncryptedBackup(passphrase);

      expect(backup.isSuccess, isTrue);
      expect(backup.sha256Checksum, isNotNull);
      expect(backup.sha256Checksum!.length, 64); // Valid SHA-256 string
      expect(backup.backupData, isNotNull);

      // Restore with correct passphrase
      final restoreResult = backupService.restoreFromEncryptedBackup(backup.backupData!, passphrase);
      expect(restoreResult.isSuccess, isTrue);
      expect(restoreResult.recordsRestored, greaterThan(0));
    });

    test('BR-13: Restore with incorrect passphrase fails immediately without data corruption', () {
      const correctPassphrase = 'CorrectPassword123';
      const wrongPassphrase = 'WrongPassword456';

      final backup = backupService.createEncryptedBackup(correctPassphrase);
      expect(backup.isSuccess, isTrue);

      final restoreResult = backupService.restoreFromEncryptedBackup(backup.backupData!, wrongPassphrase);
      expect(restoreResult.isSuccess, isFalse);
      expect(restoreResult.errorMessage, contains('Incorrect backup passphrase'));
    });

    test('BR-13: Tampered payload fails cryptographic integrity checksum check', () {
      const passphrase = 'MyMasterKey2026';
      final backup = backupService.createEncryptedBackup(passphrase);

      final container = jsonDecode(backup.backupData!) as Map<String, dynamic>;
      // Tamper with payload
      container['payload_b64'] = base64Encode(utf8.encode('{"tampered": true}'));
      final tamperedData = jsonEncode(container);

      final restoreResult = backupService.restoreFromEncryptedBackup(tamperedData, passphrase);
      expect(restoreResult.isSuccess, isFalse);
      expect(restoreResult.errorMessage, contains('Integrity check failed'));
    });
  });
}
