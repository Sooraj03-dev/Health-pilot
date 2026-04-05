import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:health_pilot/core/constants.dart';
import 'package:health_pilot/providers/health_provider.dart';
import 'package:health_pilot/services/watch_service.dart';
import 'package:health_pilot/widgets/loading_shimmer.dart';
import 'package:health_pilot/widgets/vitals_card.dart';

/// Composite widget that shows Heart Rate and SpO₂ cards side-by-side,
/// with shimmer loading, Health Connect permission banner, and a
/// "last updated" footer.
class VitalsWidget extends ConsumerWidget {
  const VitalsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vitals = ref.watch(vitalsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text(
                'Your Vitals',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              // Refresh button
              _RefreshButton(
                isLoading: vitals.isLoading,
                onPressed: () => ref.read(vitalsProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Health Connect permission banner ──
        if (vitals.permissionStatus == HealthPermissionStatus.denied)
          _PermissionBanner(
            onRequest: () =>
                ref.read(vitalsProvider.notifier).requestHealthPermissions(),
          ),

        // ── Cards or shimmer ──
        if (vitals.isLoading && vitals.metric == null)
          const VitalsShimmer()
        else if (vitals.error != null && vitals.metric == null)
          _ErrorCard(error: vitals.error!)
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 180,
              child: Row(
                children: [
                  // Heart Rate card
                  Expanded(
                    child: VitalsCard(
                      label: 'Heart Rate',
                      unit: 'bpm',
                      value: vitals.metric?.heartRate,
                      icon: Icons.favorite_rounded,
                      gradientStart: const Color(0xFFFF6B6B),
                      gradientEnd: const Color(0xFFEE5A24),
                      status: vitals.metric?.heartRate != null
                          ? heartRateStatus(vitals.metric!.heartRate!)
                          : VitalStatus.normal,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // SpO₂ card
                  Expanded(
                    child: VitalsCard(
                      label: 'SpO₂',
                      unit: '%',
                      value: vitals.metric?.spo2,
                      icon: Icons.bloodtype_rounded,
                      gradientStart: const Color(0xFF54A0FF),
                      gradientEnd: const Color(0xFF2E86DE),
                      status: vitals.metric?.spo2 != null
                          ? spo2Status(vitals.metric!.spo2!)
                          : VitalStatus.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Last updated ──
        if (vitals.metric != null)
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 12),
            child: _LastUpdated(recordedAt: vitals.metric!.recordedAt),
          ),
      ],
    );
  }
}

// ─── Sub-widgets ────────────────────────────────────────────────────────────────

class _RefreshButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _RefreshButton({required this.isLoading, required this.onPressed});

  @override
  State<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<_RefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void didUpdateWidget(_RefreshButton old) {
    super.didUpdateWidget(old);
    if (widget.isLoading) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: IconButton(
        icon: const Icon(Icons.refresh_rounded, size: 22),
        color: const Color(0xFF6B6B8D),
        onPressed: widget.isLoading ? null : widget.onPressed,
        tooltip: 'Refresh vitals',
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  final VoidCallback onRequest;
  const _PermissionBanner({required this.onRequest});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Material(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onRequest,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.health_and_safety_rounded,
                    color: Color(0xFFFF9800),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connect Health Data',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tap to grant Health Connect access',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B6B8D),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFFF9800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFCDD2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFEF5350), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFD32F2F),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LastUpdated extends StatelessWidget {
  final DateTime recordedAt;
  const _LastUpdated({required this.recordedAt});

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          'Updated ${_formatTime(recordedAt)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
