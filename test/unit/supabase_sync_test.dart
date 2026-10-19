import 'package:flutter_test/flutter_test.dart';
import 'package:personal_life_os/core/services/supabase_sync_service.dart';

void main() {
  group('Supabase PostgreSQL Cloud Synchronization Tests', () {
    test('Can verify connection to remote Supabase PostgreSQL instance', () async {
      final info = await SupabaseSyncService.instance.testConnection();
      expect(info['connected'], isTrue);
      expect(info['tableCount'], greaterThanOrEqualTo(20));
      expect(info['host'], 'db.actqetxmyfdmoqyykwxj.supabase.co');
    });

    test('Can perform idempotent push to Supabase PostgreSQL', () async {
      final res = await SupabaseSyncService.instance.pushToSupabase();
      expect(res.isSuccess, isTrue);
      expect(res.recordsPushed, greaterThan(0));
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
