import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/core/constants.dart';
import 'package:health_pilot/models/health_metric.dart';

/// Service that handles querying and subscribing to `health_metrics` in
/// Supabase.
///
/// Provides:
/// - One-shot fetch of the latest row for a user.
/// - Realtime subscription via Supabase Channels.
class VitalsService {
  RealtimeChannel? _channel;

  // ── One-shot Query ──────────────────────────────────────────────────────────

  /// Fetches the single most-recent health metric for [userId].
  ///
  /// Returns `null` if no rows exist yet.
  Future<HealthMetric?> fetchLatestMetric(String userId) async {
    final response = await supabase
        .from(kHealthMetricsTable)
        .select()
        .eq('user_id', userId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return HealthMetric.fromJson(response);
  }

  // ── Realtime Subscription ───────────────────────────────────────────────────

  /// Subscribes to INSERT events on `health_metrics` filtered to [userId].
  ///
  /// Calls [onNewMetric] with the parsed row each time a new one arrives.
  void subscribeToMetrics({
    required String userId,
    required void Function(HealthMetric metric) onNewMetric,
  }) {
    // Clean up any previous subscription.
    _channel?.unsubscribe();

    _channel = supabase
        .channel('vitals_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: kHealthMetricsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final newRow = payload.newRecord;
            if (newRow.isNotEmpty) {
              onNewMetric(HealthMetric.fromJson(newRow));
            }
          },
        )
        .subscribe();
  }

  // ── Cleanup ─────────────────────────────────────────────────────────────────

  /// Unsubscribes from the Realtime channel.
  Future<void> dispose() async {
    await _channel?.unsubscribe();
    _channel = null;
  }
}
