import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:health_pilot/models/health_metric.dart';
import 'package:health_pilot/widgets/vitals_card.dart';

/// A self-contained widget that subscribes to the `health_metrics` table via
/// Supabase Realtime and displays the most recent heart rate and SpO2 for
/// a given patient.
///
/// Values animate on change via [AnimatedSwitcher] so the UI feels live
/// without jarring jumps. A pulsing green dot indicates the stream is active.
///
/// Usage:
/// ```dart
/// VitalsWidget(patientId: supabase.auth.currentUser!.id)
/// ```
class VitalsWidget extends StatefulWidget {
  /// The Supabase `user_id` (UUID string) to filter `health_metrics` by.
  final String patientId;

  const VitalsWidget({super.key, required this.patientId});

  @override
  State<VitalsWidget> createState() => _VitalsWidgetState();
}

class _VitalsWidgetState extends State<VitalsWidget>
    with SingleTickerProviderStateMixin {

  // Supabase Realtime stream — emits a new list whenever a row is inserted
  // or updated in health_metrics for this patient.
  late final Stream<List<Map<String, dynamic>>> _stream;

  // Current metric; null while waiting for the first event.
  HealthMetric? _latest;

  // Animation controller for the pulsing "live" indicator dot.
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();

    // Supabase Realtime stream — ordered newest-first, limit 1.
    _stream = Supabase.instance.client
        .from('health_metrics')
        .stream(primaryKey: ['id'])
        .eq('user_id', widget.patientId)
        .order('recorded_at', ascending: false)
        .limit(1);

    _stream.listen((rows) {
      if (!mounted) return;
      setState(() {
        _latest = rows.isEmpty ? null : HealthMetric.fromJson(rows.first);
      });
    });

    // Pulsing dot animation
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header with live indicator ───────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'LIVE VITALS',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              // Pulsing dot — visible only when we have live data
              if (_latest != null)
                FadeTransition(
                  opacity: _pulseAnim,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E9B7F),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Cards row ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.0)
                          .animate(animation),
                      child: child,
                    ),
                  ),
                  child: VitalsCard(
                    key: ValueKey<double?>(_latest?.heartRate),
                    label: 'HEART RATE BPM',
                    numericValue: _latest?.heartRate,
                    unit: '',
                    borderColor: Colors.red.shade400,
                    iconData: Icons.favorite,
                    dataPoints: const [],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.0)
                          .animate(animation),
                      child: child,
                    ),
                  ),
                  child: VitalsCard(
                    key: ValueKey<double?>(_latest?.spo2),
                    label: 'SPO2 LEVEL',
                    numericValue: _latest?.spo2,
                    unit: '%',
                    borderColor: Colors.blue.shade600,
                    iconData: Icons.water_drop,
                    dataPoints: const [],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
