import 'package:flutter/material.dart';

import 'package:health_pilot/core/constants.dart';

/// A single vital-metric card with gradient background, animated number
/// transition, icon, label, and a status indicator dot.
class VitalsCard extends StatelessWidget {
  final String label;
  final String unit;
  final double? value;
  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;
  final VitalStatus status;

  const VitalsCard({
    super.key,
    required this.label,
    required this.unit,
    required this.value,
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientStart, gradientEnd],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientEnd.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Icon + status row ──
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const Spacer(),
              _StatusDot(status: status),
            ],
          ),
          const Spacer(),

          // ── Animated value ──
          value != null
              ? AnimatedNumber(value: value!, unit: unit)
              : Text(
                  '--',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
          const SizedBox(height: 4),

          // ── Label ──
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AnimatedNumber ─────────────────────────────────────────────────────────────

/// Smoothly animates between old and new numeric values using
/// [TweenAnimationBuilder].
class AnimatedNumber extends StatelessWidget {
  final double value;
  final String unit;

  const AnimatedNumber({
    super.key,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              animatedValue.toStringAsFixed(0),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                unit,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── StatusDot ──────────────────────────────────────────────────────────────────

class _StatusDot extends StatelessWidget {
  final VitalStatus status;
  const _StatusDot({required this.status});

  Color get _color {
    switch (status) {
      case VitalStatus.normal:
        return const Color(0xFF2ED573);
      case VitalStatus.warning:
        return const Color(0xFFFFA502);
      case VitalStatus.critical:
        return const Color(0xFFFF4757);
    }
  }

  String get _label {
    switch (status) {
      case VitalStatus.normal:
        return 'Normal';
      case VitalStatus.warning:
        return 'Warning';
      case VitalStatus.critical:
        return 'Critical';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _color.withValues(alpha: 0.6),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
