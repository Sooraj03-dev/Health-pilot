/// Dart model for the `sleep_sessions` Supabase table.
///
/// Table schema:
///   id               uuid        PK  (server-generated)
///   user_id          uuid        FK → profiles(user_id)
///   sleep_start      timestamptz
///   sleep_end        timestamptz
///   duration_minutes int
///   recorded_at      timestamptz (server-generated default)
class SleepSession {
  final String? id;
  final String userId;
  final DateTime sleepStart;
  final DateTime sleepEnd;
  final int durationMinutes;
  final DateTime? recordedAt;

  const SleepSession({
    this.id,
    required this.userId,
    required this.sleepStart,
    required this.sleepEnd,
    required this.durationMinutes,
    this.recordedAt,
  });

  factory SleepSession.fromJson(Map<String, dynamic> json) {
    return SleepSession(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      sleepStart: DateTime.parse(json['sleep_start'] as String),
      sleepEnd: DateTime.parse(json['sleep_end'] as String),
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      recordedAt: json['recorded_at'] != null
          ? DateTime.parse(json['recorded_at'] as String)
          : null,
    );
  }

  /// JSON map for **inserting** a new row. Server fields (`id`, `recorded_at`)
  /// are intentionally omitted.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'sleep_start': sleepStart.toIso8601String(),
      'sleep_end': sleepEnd.toIso8601String(),
      'duration_minutes': durationMinutes,
    };
  }

  @override
  String toString() =>
      'SleepSession(userId: $userId, start: $sleepStart, '
      'end: $sleepEnd, duration: ${durationMinutes}min)';
}
