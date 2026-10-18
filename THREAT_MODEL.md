# THREAT MODEL & PRIVACY DIRECTIVE
## Personal Life OS (v2.0 Engineering Edition)

### 1. Security & Privacy Philosophy
Personal Life OS is built on the principle of **radical owner sovereignty**:
- Zero telemetry, analytics SDKs, or cloud transmission by default (`NFR-01`).
- The application requires no remote account or internet connectivity to function (`NFR-09`).
- Sensitive owner data (passwords, journals, spiritual prayers, financial ledgers) is encrypted at rest using OS-backed keystores (`NFR-02`).

### 2. Threat Analysis Matrix

| Threat Vector | Risk Level | Mitigation Strategy | Implementation Details |
|---|---|---|---|
| **Lost or Stolen Device** | Critical | Database encryption at rest; local PIN / Biometric gate; secure memory wiping | AES-256-GCM authenticated encryption; PIN hash salted with Argon2id; inactivity timeout auto-lock. |
| **App-Switcher Snooping** | Medium | OS recent-app preview masking | System overlay obfuscates sensitive dashboard cards and balances when app is backgrounded (`SCR-01`, `FR-ST-03`). |
| **Notification Leakage** | High | Confidentiality toggles for notifications | Spiritual journal themes, prayer texts, and financial transaction amounts are excluded from lock screen notifications by default (`FR-SP-07`). |
| **Corrupted / Tampered Backup** | Critical | Authenticated encryption + manifest hashing | Backup files use Argon2id + AES-GCM; manifest includes SHA-256 integrity checksums; restored to isolated staging sandbox before active database replacement (`BR-13`). |
| **Malicious Attachments** | High | Strict file validation & path traversal protection | Disallow executable file types; enforce 15MB file size limit; store attachments in isolated app directory (`FR-JR-04`). |
| **Accidental Data Clearance** | High | Prominent onboarding warning + backup reminders | Explains to owner during onboarding (`FR-ON-02`) that without user-managed backups, device reset or data wipe causes unrecoverable data loss. |
| **Cross-Workspace Leakage** | High | Partitioned queries and domain boundaries | Repository queries strictly filter by `workspace_id`. Professional Bems/Henovate tasks and financial ledgers never commingle with personal records without explicit user transfer (`FR-WK-01`, `FR-FN-14`). |

### 3. Cryptographic Primitives
- **Key Derivation:** Argon2id (Memory: 64MB, Iterations: 3, Parallelism: 1) for user passphrases.
- **Symmetric Cipher:** AES-256-GCM (Galois/Counter Mode) providing both confidentiality and cryptographic integrity verification.
- **Secure Nonces:** 96-bit cryptographically secure pseudorandom nonces generated via platform secure random per encryption operation.
- **Key Storage:** Platform Keychain (iOS) and Android Keystore (Android) for device-bound database encryption keys.
