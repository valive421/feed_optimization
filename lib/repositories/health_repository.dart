import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/health_status.dart';

class HealthRepository {
  HealthRepository(this._client);

  final SupabaseClient _client;

  Future<HealthCheckResult> checkConnection() async {
    try {
      await _client.from('posts').select('id').limit(1);
      return HealthCheckResult.connected();
    } catch (error) {
      return HealthCheckResult.error(error.toString());
    }
  }
}
