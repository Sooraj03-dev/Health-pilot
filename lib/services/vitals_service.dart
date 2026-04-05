import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/models/health_metric.dart';

/// Service for interacting with the `health_metrics` Supabase table.
///
/// Follows the singleton pattern used by [AuthService].
class VitalsService {
  VitalsService._internal();

  static final VitalsService _instance = VitalsService._internal();

  factory VitalsService() => _instance;

  RealtimeChannel? _channel;

  // ── Fetch ───────────────────────────────────────────────────────────────────

  /// Fetches the latest metric row for [userId].
  ///
  /// Returns `null` if no rows exist yet.
  Future<HealthMetric?> fetchLatestMetric(String userId) async {
    final data = await supabase
        .from('health_metrics')
        .select()
        .eq('user_id', userId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;
    return HealthMetric.fromJson(data);
  }

  // ── Insert ──────────────────────────────────────────────────────────────────

  /// Inserts a new metric row.
  Future<void> insertMetric(HealthMetric metric) async {
    await supabase.from('health_metrics').insert(metric.toJson());
  }

  // ── Realtime ────────────────────────────────────────────────────────────────

  /// Subscribes to INSERT events on `health_metrics` for [userId].
  ///
  /// Calls [onData] for each new row.
  void subscribeToMetrics({
    required String userId,
    required void Function(HealthMetric metric) onData,
  }) {
    _channel?.unsubscribe();

    _channel = supabase
        .channel('health_metrics_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'health_metrics',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final newRow = payload.newRecord;
            if (newRow.isNotEmpty) {
              onData(HealthMetric.fromJson(newRow));
            }
          },
        )
        .subscribe();
  }

  /// Cancels the Realtime subscription.
  void disposeSubscription() {
    _channel?.unsubscribe();
    _channel = null;
  }
}
