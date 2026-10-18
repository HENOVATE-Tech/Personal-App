class AppConstants {
  static const String appName = 'Personal Life OS';
  static const String appVersion = '2.0.0';
  static const String schemaVersion = '1.0.0';

  // Locale & Timezone Defaults
  static const String defaultLocale = 'en_NG';
  static const String defaultTimezone = 'Africa/Lagos';
  static const String defaultCurrency = 'NGN';
  static const String defaultCurrencySymbol = '₦';

  // Workspaces
  static const String workspacePersonalId = 'ws-personal';
  static const String workspaceBemsId = 'ws-bems-group';
  static const String workspaceHenovateId = 'ws-henovate';

  // Recovery Engine Constants
  static const int maxActiveRecoveryCards = 3;
  static const int defaultNeglectedThresholdDays = 3;

  // Health Constants
  static const int minRecommendedSleepHours = 5;

  // File & Storage Limits
  static const int maxAttachmentBytes = 15 * 1024 * 1024; // 15MB
}
