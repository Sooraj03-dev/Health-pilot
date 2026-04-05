import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Permission status for Health Connect integration.
enum HealthPermissionStatus {
  unknown,
  granted,
  denied,
  notAvailable,
}

/// Wraps the `health` package to request permissions and read vitals from
/// Health Connect (Android) or Apple Health (iOS).
///
/// On web / desktop this is a safe no-op — every method returns gracefully.
class HealthConnectService {
  HealthConnectService._internal();
  static final HealthConnectService _instance = HealthConnectService._internal();
  factory HealthConnectService() => _instance;

  final Health _health = Health();

  /// The data types we want to read.
  static const List<HealthDataType> _types = [
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_OXYGEN,
  ];

  static final List<HealthDataAccess> _permissions =
      _types.map((_) => HealthDataAccess.READ).toList();

  // ── Platform guard ────────────────────────────────────────────────────────

  bool get _isSupported =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  // ── Permission checks ─────────────────────────────────────────────────────

  /// Checks whether Health Connect permissions are already granted.
  Future<HealthPermissionStatus> checkPermissions() async {
    if (!_isSupported) return HealthPermissionStatus.notAvailable;

    try {
      final granted = await _health.hasPermissions(
            _types,
            permissions: _permissions,
          ) ??
          false;
      return granted
          ? HealthPermissionStatus.granted
          : HealthPermissionStatus.denied;
    } catch (e) {
      debugPrint('HealthConnect checkPermissions error: $e');
      return HealthPermissionStatus.notAvailable;
    }
  }

  /// Requests Health Connect permissions from the user.
  Future<HealthPermissionStatus> requestPermissions() async {
    if (!_isSupported) return HealthPermissionStatus.notAvailable;

    try {
      final granted = await _health.requestAuthorization(
        _types,
        permissions: _permissions,
      );
      return granted
          ? HealthPermissionStatus.granted
          : HealthPermissionStatus.denied;
    } catch (e) {
      debugPrint('HealthConnect requestPermissions error: $e');
      return HealthPermissionStatus.notAvailable;
    }
  }

  // ── Data reading ──────────────────────────────────────────────────────────

  /// Reads the latest heart rate and SpO2 from Health Connect.
  ///
  /// Returns a map with `heartRate` and `spo2` keys (nullable doubles).
  Future<Map<String, double?>> readLatestVitals() async {
    if (!_isSupported) return {'heartRate': null, 'spo2': null};

    try {
      final now = DateTime.now();
      final anHourAgo = now.subtract(const Duration(hours: 1));

      final data = await _health.getHealthDataFromTypes(
        types: _types,
        startTime: anHourAgo,
        endTime: now,
      );

      double? heartRate;
      double? spo2;

      for (final point in data) {
        final value = (point.value as NumericHealthValue).numericValue;
        if (point.type == HealthDataType.HEART_RATE) {
          heartRate ??= value.toDouble();
        } else if (point.type == HealthDataType.BLOOD_OXYGEN) {
          spo2 ??= value.toDouble();
        }
      }

      return {'heartRate': heartRate, 'spo2': spo2};
    } catch (e) {
      debugPrint('HealthConnect readLatestVitals error: $e');
      return {'heartRate': null, 'spo2': null};
    }
  }
}
