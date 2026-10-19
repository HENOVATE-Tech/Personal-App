import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../database/local_database.dart';
import '../database/schema_models.dart';
import '../utils/money_formatter.dart';

class SmsIngestionService {
  static final SmsIngestionService instance = SmsIngestionService._internal();
  SmsIngestionService._internal();

  static const _platform = MethodChannel('com.henovate.personallifeos/sms');
  static const _uuid = Uuid();

  /// Parse raw SMS text into a structured SmsDebitAlert
  static SmsDebitAlert? parseDebitAlert({
    required String sender,
    required String body,
    DateTime? timestamp,
  }) {
    final lower = body.toLowerCase();

    // 1. Check if message is a debit alert
    final isDebit = lower.contains('debit') ||
        lower.contains(' dr ') ||
        lower.contains('dr:') ||
        lower.contains(' dr|') ||
        lower.contains(' dr\n') ||
        lower.contains('dr.') ||
        lower.contains('spent') ||
        lower.contains('paid') ||
        lower.contains('withdrawn') ||
        lower.contains('purchase') ||
        lower.contains('transferred to');

    final isCredit = lower.contains('credit') ||
        lower.contains(' cr ') ||
        lower.contains('cr:') ||
        lower.contains('received from') ||
        lower.contains('deposited');

    if (!isDebit && !isCredit) {
      return null; // Not a banking alert
    }

    // 2. Extract Amount
    int? amountKobo;

    // Pattern 1: (NGN|₦|Amt|Amount|Debit of|spent|paid)\s*:?\s*(?:NGN|₦)?\s*([0-9,]+\.[0-9]{2}|[0-9,]+)
    final amountRegex1 = RegExp(
      r'(?:NGN|₦|Amt|Amount|Debit of|spent|paid)\s*[:\-]?\s*(?:NGN|₦)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    );
    // Pattern 2: ([0-9,]+\.[0-9]{2})\s*(?:DR|NGN|₦)
    final amountRegex2 = RegExp(
      r'([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)\s*(?:DR|NGN|₦)',
      caseSensitive: false,
    );

    final match1 = amountRegex1.firstMatch(body);
    if (match1 != null) {
      final rawNum = match1.group(1);
      if (rawNum != null) {
        amountKobo = _parseRawToKobo(rawNum);
      }
    }

    if (amountKobo == null || amountKobo <= 0) {
      final match2 = amountRegex2.firstMatch(body);
      if (match2 != null) {
        final rawNum = match2.group(1);
        if (rawNum != null) {
          amountKobo = _parseRawToKobo(rawNum);
        }
      }
    }

    if (amountKobo == null || amountKobo <= 0) {
      return null; // Could not parse amount
    }

    // 3. Extract Account / Card last 4 digits
    String? accountLast4;
    final maskedRegex = RegExp(r'[\*xX]+([0-9]{3,4})');
    final maskedMatch = maskedRegex.firstMatch(body);
    if (maskedMatch != null) {
      accountLast4 = maskedMatch.group(1);
    } else {
      final accRegex = RegExp(
        r'(?:Acc|Acct|Account|Card)\s*(?:No\.?)?\s*[:\-]?\s*([0-9]{3,4})',
        caseSensitive: false,
      );
      final accMatch = accRegex.firstMatch(body);
      if (accMatch != null) {
        accountLast4 = accMatch.group(1);
      }
    }

    // 4. Extract Description / Narration / Merchant
    String memo = 'Bank Debit';
    final descRegex = RegExp(
      r'(?:Desc|Details|Narration|Ref|at|to)\s*[:\-]?\s*([^|\n]+)',
      caseSensitive: false,
    );
    final descMatch = descRegex.firstMatch(body);
    if (descMatch != null && descMatch.group(1) != null) {
      memo = descMatch.group(1)!.trim();
      if (memo.length > 50) {
        memo = memo.substring(0, 50).trim();
      }
    } else {
      memo = '$sender transaction';
    }

    // 5. Suggest Category based on description
    final suggestedCategory = _suggestCategory(memo);

    return SmsDebitAlert(
      id: _uuid.v4(),
      sender: sender.toUpperCase(),
      rawBody: body,
      amountKobo: amountKobo,
      accountLast4: accountLast4,
      memo: memo,
      isDebit: isDebit,
      receivedAt: timestamp ?? DateTime.now(),
      suggestedCategoryId: suggestedCategory,
    );
  }

  static int? _parseRawToKobo(String raw) {
    try {
      final clean = raw.replaceAll(',', '').trim();
      final val = double.parse(clean);
      return (val * 100).round();
    } catch (_) {
      return null;
    }
  }

  static String _suggestCategory(String memo) {
    final lower = memo.toLowerCase();
    if (lower.contains('uber') ||
        lower.contains('bolt') ||
        lower.contains('fuel') ||
        lower.contains('mobil') ||
        lower.contains('total') ||
        lower.contains('conoil') ||
        lower.contains('petrol') ||
        lower.contains('transport')) {
      return 'cat-transport';
    }
    if (lower.contains('food') ||
        lower.contains('restaurant') ||
        lower.contains('chicken') ||
        lower.contains('dominos') ||
        lower.contains('pizza') ||
        lower.contains('grocer') ||
        lower.contains('supermarket') ||
        lower.contains('shoprite') ||
        lower.contains('spar') ||
        lower.contains('eat') ||
        lower.contains('bukka')) {
      return 'cat-food';
    }
    if (lower.contains('internet') ||
        lower.contains('mtn') ||
        lower.contains('airtel') ||
        lower.contains('glo') ||
        lower.contains('spectranet') ||
        lower.contains('electricity') ||
        lower.contains('eedc') ||
        lower.contains('ikedc') ||
        lower.contains('eko') ||
        lower.contains('power') ||
        lower.contains('utility')) {
      return 'cat-utilities';
    }
    if (lower.contains('church') ||
        lower.contains('tithe') ||
        lower.contains('offering') ||
        lower.contains('donation') ||
        lower.contains('charity')) {
      return 'cat-giving';
    }
    if (lower.contains('netflix') ||
        lower.contains('spotify') ||
        lower.contains('cinema') ||
        lower.contains('movie') ||
        lower.contains('club') ||
        lower.contains('lounge') ||
        lower.contains('game')) {
      return 'cat-entertainment'; // Non-essential
    }
    if (lower.contains('jumia') ||
        lower.contains('konga') ||
        lower.contains('amazon') ||
        lower.contains('zara') ||
        lower.contains('cloth') ||
        lower.contains('shoes') ||
        lower.contains('mall') ||
        lower.contains('pos purchase')) {
      return 'cat-shopping'; // Non-essential
    }
    return 'cat-food';
  }

  /// Check and request Android SMS permissions
  Future<bool> requestPermissions() async {
    try {
      final res = await _platform.invokeMethod<bool>('requestSmsPermissions');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Scan Android SMS inbox for recent bank debit alerts
  Future<List<SmsDebitAlert>> scanInboxForAlerts({int limit = 20}) async {
    try {
      final List<dynamic>? rawMessages = await _platform.invokeMethod<List<dynamic>>(
        'readRecentDebitAlerts',
        {'limit': limit},
      );

      if (rawMessages == null) return [];

      final List<SmsDebitAlert> alerts = [];
      for (final item in rawMessages) {
        if (item is Map) {
          final sender = item['sender']?.toString() ?? 'Bank';
          final body = item['body']?.toString() ?? '';
          final dateMillis = item['date'] as int?;
          final date = dateMillis != null
              ? DateTime.fromMillisecondsSinceEpoch(dateMillis)
              : DateTime.now();

          final alert = parseDebitAlert(
            sender: sender,
            body: body,
            timestamp: date,
          );
          if (alert != null) {
            alerts.add(alert);
            LocalDatabase.instance.addSmsDebitAlert(alert);
          }
        }
      }
      return alerts;
    } catch (e) {
      return [];
    }
  }

  /// Helper to simulate / test SMS alert ingestion in emulator or on-device
  static SmsDebitAlert simulateTestAlert({
    String sender = 'GTBank',
    int amountKobo = 1500000, // ₦15,000.00
    String memo = 'POS PURCHASE - MOBIL FILLING STATION',
    String? categoryId = 'cat-transport',
  }) {
    final alert = SmsDebitAlert(
      id: _uuid.v4(),
      sender: sender,
      rawBody: 'Debit: Amt: NGN ${MoneyFormatter.formatKobo(amountKobo).replaceAll('₦', '').trim()} | Acc: 014****567 | Desc: $memo | Date: ${DateTime.now()}',
      amountKobo: amountKobo,
      accountLast4: '4567',
      memo: memo,
      isDebit: true,
      receivedAt: DateTime.now(),
      suggestedCategoryId: categoryId ?? 'cat-transport',
    );

    LocalDatabase.instance.addSmsDebitAlert(alert);
    return alert;
  }
}
