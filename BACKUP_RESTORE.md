# BACKUP & ATOMIC RESTORE SPECIFICATION
## Personal Life OS (v2.0 Engineering Edition)

### 1. Backup Container Format
The backup archive (`.plos` container) is an authenticated, encrypted package structured as follows:

```
[4 Bytes Magic Header: "PLOS"]
[2 Bytes Format Version: 0x0001]
[16 Bytes Salt (Argon2id)]
[12 Bytes Nonce (AES-GCM)]
[Encrypted Payload (AES-256-GCM)]
  ├── manifest.json (Schema version, app version, table record counts, SHA-256 hashes)
  ├── database.sqlite (Raw or decrypted SQLite dump)
  ├── attachments/ (User receipts, note attachments)
  └── preferences.json (User settings excluding device-bound biometric keys)
[16 Bytes AES-GCM Authentication Tag]
```

### 2. Export Workflow
1. User navigates to `SCR-57 (Backup & Restore)` and triggers "Create Encrypted Backup".
2. User provides a strong backup passphrase.
3. Argon2id derives a 256-bit encryption key from the passphrase and cryptographically random salt.
4. SQLite performs a checkpoint `VACUUM INTO` a temporary staging file to ensure zero WAL fragmentation.
5. `BackupManifest` is generated with SHA-256 hashes of database, attachments, and schema version.
6. The archive is encrypted with AES-256-GCM and saved to the user's chosen location via the OS file save picker / share sheet.
7. Temporary staging files are shredded from disk immediately.

### 3. Atomic Restore Workflow (`BR-13`)
1. User selects a `.plos` backup file via the OS document picker.
2. User inputs the passphrase.
3. Verification Stage:
   - AES-GCM auth tag is verified; incorrect password fails immediately without altering existing data.
   - The archive is extracted into an isolated staging directory: `app_data/staging/restore_{timestamp}`.
   - SHA-256 checksums of the extracted database and attachment files are validated against `manifest.json`.
   - Schema compatibility check runs: if the backup is from a future major schema version, restore is rejected with an actionable warning.
4. Atomic Swap:
   - Active database connections are closed.
   - The current database is renamed to `app_database.sqlite.rollback`.
   - The staging database is moved to `app_database.sqlite`.
   - Attachment files are copied into the active attachments directory.
   - If any step fails, the rollback database is restored atomically.
   - `UserProfile` re-enrolls local device authentication (PIN/biometrics).
