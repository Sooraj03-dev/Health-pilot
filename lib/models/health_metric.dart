/// Data model for a single row in the `health_metrics` Supabase table.
class HealthMetric {
  final String id;
  final String userId;
  final double? heartRate;
  final double? spo2;
  final DateTime recordedAt;
  final DateTime createdAt;

  const HealthMetric({
    required this.id,
    required this.userId,
    this.heartRate,
    this.spo2,
    required this.recordedAt,
    required this.createdAt,
  });

  factory HealthMetric.fromJson(Map<String, dynamic> json) {
    return HealthMetric(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      heartRate: (json['heart_rate'] as num?)?.toDouble(),
      spo2: (json['spo2'] as num?)?.toDouble(),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'heart_rate': heartRate,
      'spo2': spo2,
      'recorded_at': recordedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  HealthMetric copyWith({
    String? id,
    String? userId,
    double? heartRate,
    double? spo2,
    DateTime? recordedAt,
    DateTime? createdAt,
  }) {
    return HealthMetric(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      heartRate: heartRate ?? this.heartRate,
      spo2: spo2 ?? this.spo2,
      recordedAt: recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'HealthMetric(id: $id, hr: $heartRate, spo2: $spo2, at: $recordedAt)';
}
