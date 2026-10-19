import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/local_database.dart';
import '../database/schema_models.dart';

class ApiHealthResult {
  final bool isHealthy;
  final String status;
  final String? service;
  final String? database;
  final String? timestamp;
  final String? error;

  const ApiHealthResult({
    required this.isHealthy,
    required this.status,
    this.service,
    this.database,
    this.timestamp,
    this.error,
  });

  factory ApiHealthResult.fromJson(Map<String, dynamic> json) {
    return ApiHealthResult(
      isHealthy: json['status'] == 'healthy',
      status: json['status'] as String? ?? 'unknown',
      service: json['service'] as String?,
      database: json['database'] as String?,
      timestamp: json['timestamp'] as String?,
      error: json['error'] as String?,
    );
  }

  factory ApiHealthResult.error(String err) {
    return ApiHealthResult(
      isHealthy: false,
      status: 'offline',
      error: err,
    );
  }
}

class ApiSyncResult {
  final bool isSuccess;
  final int recordsPushed;
  final int recordsPulled;
  final String? errorMessage;
  final DateTime timestamp;

  const ApiSyncResult({
    required this.isSuccess,
    this.recordsPushed = 0,
    this.recordsPulled = 0,
    this.errorMessage,
    required this.timestamp,
  });
}

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  /// Default production Render URL or fallback local address
  static const String defaultRenderUrl = 'https://personal-life-os-api.onrender.com';
  static const String localUrl = 'http://localhost:5000';

  String _baseUrl = localUrl;

  String get baseUrl => _baseUrl;

  void setBaseUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    _baseUrl = trimmed;
  }

  /// Check /health endpoint
  Future<ApiHealthResult> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return ApiHealthResult.fromJson(data);
      } else {
        return ApiHealthResult.error(
          'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return ApiHealthResult.error(e.toString());
    }
  }

  /// Check /api/sync/status
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/sync/status'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'status': 'error',
          'statusCode': response.statusCode,
          'message': response.body,
        };
      }
    } catch (e) {
      return {
        'status': 'offline',
        'error': e.toString(),
      };
    }
  }

  /// Push local data to the backend REST API
  Future<Map<String, dynamic>> pushData(
    Map<String, List<Map<String, dynamic>>> tables,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/sync/push'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'tables': tables}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Pull remote changes from the backend REST API
  Future<Map<String, dynamic>> pullData({DateTime? since}) async {
    try {
      var uri = Uri.parse('$_baseUrl/api/sync/pull');
      if (since != null) {
        uri = uri.replace(
          queryParameters: {'since': since.toUtc().toIso8601String()},
        );
      }

      final response = await http.get(uri).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Full 2-way sync with local database
  Future<ApiSyncResult> syncAll(LocalDatabase db) async {
    try {
      // 1. Gather all local entities to push
      final tasks = db.getTasks().map((t) => {
        'id': t.id,
        'workspace_id': t.workspaceId,
        'title': t.title,
        'next_action': t.nextAction,
        'importance': t.importance.name,
        'is_top_priority': t.isTopPriority,
        'is_completed': t.status == TaskStatus.completed,
        'completed_at': t.completedAt?.toIso8601String(),
        'scheduled_date': t.scheduledDate?.toIso8601String(),
        'duration_mins': t.estimateMinutes,
      }).toList();

      final accounts = db.getFinancialAccounts().map((a) => {
        'id': a.id,
        'name': a.name,
        'account_type': a.accountType.name,
        'currency': a.currency,
        'opening_balance_kobo': a.openingBalanceKobo,
        'balance_kobo': a.balanceKobo,
        'is_archived': a.isArchived,
      }).toList();

      final categories = db.getFinancialCategories().map((c) => {
        'id': c.id,
        'name': c.name,
        'type': c.type,
        'icon_name': c.iconName,
        'color_value': c.colorValue,
        'is_essential': c.isEssential,
      }).toList();

      final budgets = db.getBudgets().map((b) => {
        'id': b.id,
        'category_id': b.categoryId,
        'period_month_year': b.periodMonthYear,
        'allocated_kobo': b.allocatedKobo,
        'spent_kobo': b.spentKobo,
        'rollover_eligible': b.rolloverEligible,
      }).toList();

      final transactions = db.getLedgerTransactions().map((tx) => {
        'id': tx.id,
        'type': tx.type.name,
        'effective_at': tx.effectiveAt.toIso8601String(),
        'memo': tx.memo,
        'workspace_id': tx.workspaceId,
        'original_transaction_id': tx.originalTransactionId,
        'created_at': tx.createdAt.toIso8601String(),
      }).toList();

      final movements = db.getLedgerMovements().map((m) => {
        'id': m.id,
        'transaction_id': m.transactionId,
        'account_id': m.accountId,
        'category_id': m.categoryId,
        'amount_kobo': m.amountKobo,
        'currency': m.currency,
      }).toList();

      final smsAlerts = db.getSmsDebitAlerts().map((s) => {
        'id': s.id,
        'sender': s.sender,
        'raw_body': s.rawBody,
        'amount_kobo': s.amountKobo,
        'account_last4': s.accountLast4,
        'memo': s.memo,
        'is_debit': s.isDebit,
        'received_at': s.receivedAt.toIso8601String(),
        'suggested_category_id': s.suggestedCategoryId,
        'is_processed': s.isProcessed,
        'is_ignored': s.isIgnored,
      }).toList();

      final pushPayload = {
        'tasks': tasks,
        'financial_accounts': accounts,
        'financial_categories': categories,
        'budgets': budgets,
        'ledger_transactions': transactions,
        'ledger_movements': movements,
        'sms_debit_alerts': smsAlerts,
      };

      // 2. Push to backend
      final pushRes = await pushData(pushPayload);
      final int totalPushed = (pushRes['totalInsertedOrUpdated'] as int?) ?? 0;

      // 3. Pull remote updates
      final pullRes = await pullData();
      int totalPulled = 0;

      if (pullRes['success'] == true && pullRes['tables'] != null) {
        final tables = pullRes['tables'] as Map<String, dynamic>;

        // Merge remote tasks into local if not present
        if (tables['tasks'] != null) {
          final remoteTasks = tables['tasks'] as List;
          for (final row in remoteTasks) {
            final existing = db.getTasks().where((t) => t.id == row['id']).firstOrNull;
            if (existing == null) {
              db.upsertTask(
                Task(
                  id: row['id'] as String,
                  workspaceId: row['workspace_id'] as String? ?? 'ws-personal',
                  title: row['title'] as String,
                  nextAction: row['next_action'] as String? ?? '',
                  importance: TaskImportance.values.firstWhere(
                    (v) => v.name == row['importance'],
                    orElse: () => TaskImportance.medium,
                  ),
                  isTopPriority: row['is_top_priority'] as bool? ?? false,
                  status: (row['is_completed'] as bool? ?? false)
                      ? TaskStatus.completed
                      : TaskStatus.next,
                  completedAt: row['completed_at'] != null
                      ? DateTime.tryParse(row['completed_at'] as String)
                      : null,
                  scheduledDate: row['scheduled_date'] != null
                      ? DateTime.tryParse(row['scheduled_date'] as String)
                      : null,
                  estimateMinutes: (row['duration_mins'] as num?)?.toInt() ?? 30,
                  createdAt: DateTime.now(),
                ),
              );
              totalPulled++;
            }
          }
        }
      }

      return ApiSyncResult(
        isSuccess: true,
        recordsPushed: totalPushed,
        recordsPulled: totalPulled,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return ApiSyncResult(
        isSuccess: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }
}
