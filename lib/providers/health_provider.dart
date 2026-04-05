import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:health_pilot/core/constants.dart';
import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/models/health_metric.dart';
import 'package:health_pilot/services/vitals_service.dart';
import 'package:health_pilot/services/watch_service.dart';

// ─── VitalsState ────────────────────────────────────────────────────────────────

/// Immutable state for the vitals feature.
class VitalsState {
  final HealthMetric? metric;
  final bool isLoading;
  final String? error;
  final HealthPermissionStatus permissionStatus;

  const VitalsState({
    this.metric,
    this.isLoading = true,
    this.error,
    this.permissionStatus = HealthPermissionStatus.unknown,
  });

  VitalsState copyWith({
    HealthMetric? metric,
    bool? isLoading,
    String? error,
    HealthPermissionStatus? permissionStatus,
    bool clearError = false,
    bool clearMetric = false,
  }) {
    return VitalsState(
      metric: clearMetric ? null : (metric ?? this.metric),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      permissionStatus: permissionStatus ?? this.permissionStatus,
    );
  }
}

// ─── VitalsNotifier ─────────────────────────────────────────────────────────────

/// Manages vitals data lifecycle:
/// 1. Checks Health Connect permissions on init.
/// 2. Fetches latest metric from Supabase.
/// 3. Subscribes to Supabase Realtime for live updates.
/// 4. Falls back to polling every 30 s if Realtime misses updates.
class VitalsNotifier extends StateNotifier<VitalsState> {
  final VitalsService _vitalsService;
  final HealthConnectService _healthService;
  Timer? _pollTimer;

  VitalsNotifier({
    VitalsService? vitalsService,
    HealthConnectService? healthService,
  })  : _vitalsService = vitalsService ?? VitalsService(),
        _healthService = healthService ?? HealthConnectService(),
        super(const VitalsState()) {
    _init();
  }

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> _init() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'Not authenticated',
      );
      return;
    }

    // 1. Check Health Connect permissions (non-blocking).
    _checkHealthPermissions();

    // 2. Fetch latest metric.
    await _fetchLatest(userId);

    // 3. Subscribe to Realtime.
    _vitalsService.subscribeToMetrics(
      userId: userId,
      onNewMetric: (metric) {
        if (mounted) {
          state = state.copyWith(metric: metric, isLoading: false, clearError: true);
        }
      },
    );

    // 4. Start polling fallback.
    _pollTimer = Timer.periodic(kVitalsPollInterval, (_) {
      _fetchLatest(userId);
    });
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> _fetchLatest(String userId) async {
    try {
      final metric = await _vitalsService.fetchLatestMetric(userId);
      if (mounted) {
        state = state.copyWith(
          metric: metric,
          isLoading: false,
          clearError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not load vitals: $e',
        );
      }
    }
  }

  /// Public method to manually refresh vitals.
  Future<void> refresh() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    await _fetchLatest(userId);
  }

  // ── Health Connect Permissions ────────────────────────────────────────────

  Future<void> _checkHealthPermissions() async {
    final status = await _healthService.checkPermissions();
    if (mounted) {
      state = state.copyWith(permissionStatus: status);
    }
  }

  /// Requests Health Connect permissions.  Call from the UI when the user
  /// taps the permission banner.
  Future<void> requestHealthPermissions() async {
    final status = await _healthService.requestPermissions();
    if (mounted) {
      state = state.copyWith(permissionStatus: status);
    }
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _pollTimer?.cancel();
    _vitalsService.dispose();
    super.dispose();
  }
}

// ─── Global Provider ────────────────────────────────────────────────────────────

final vitalsProvider = StateNotifierProvider<VitalsNotifier, VitalsState>(
  (ref) => VitalsNotifier(),
);
