import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/health_status.dart';
import '../repositories/health_repository.dart';

final appSupabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository(ref.read(appSupabaseClientProvider));
});

final supabaseHealthProvider = FutureProvider<HealthCheckResult>((ref) async {
  final repository = ref.read(healthRepositoryProvider);
  return repository.checkConnection();
});
