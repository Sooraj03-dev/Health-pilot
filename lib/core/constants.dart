/// ──────────────────────────────────────────────
/// Health Pilot – App-wide constants
/// ──────────────────────────────────────────────

// ── Supabase table names ──
const String kHealthMetricsTable = 'health_metrics';

// ── Polling ──
const Duration kVitalsPollInterval = Duration(seconds: 30);

// ── Normal vital ranges (for status indicators) ──
class VitalRanges {
  VitalRanges._();

  // Heart Rate (bpm)
  static const double hrLow = 60;
  static const double hrHigh = 100;
  static const double hrCriticalLow = 50;
  static const double hrCriticalHigh = 120;

  // SpO2 (%)
  static const double spo2Normal = 95;
  static const double spo2Low = 90;
}

/// Status classification for vital readings.
enum VitalStatus { normal, warning, critical }

VitalStatus heartRateStatus(double bpm) {
  if (bpm < VitalRanges.hrCriticalLow || bpm > VitalRanges.hrCriticalHigh) {
    return VitalStatus.critical;
  }
  if (bpm < VitalRanges.hrLow || bpm > VitalRanges.hrHigh) {
    return VitalStatus.warning;
  }
  return VitalStatus.normal;
}

VitalStatus spo2Status(double pct) {
  if (pct < VitalRanges.spo2Low) return VitalStatus.critical;
  if (pct < VitalRanges.spo2Normal) return VitalStatus.warning;
  return VitalStatus.normal;
}
