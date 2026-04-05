import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A shimmer placeholder that mirrors the VitalsWidget card layout.
///
/// Shown while the initial Supabase query is in-flight.
class VitalsShimmer extends StatelessWidget {
  const VitalsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE0E0E0),
      highlightColor: const Color(0xFFF5F5F5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(child: _ShimmerCard()),
            const SizedBox(width: 16),
            Expanded(child: _ShimmerCard()),
          ],
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon placeholder
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const Spacer(),
          // Value placeholder
          Container(
            width: 80,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          // Label placeholder
          Container(
            width: 60,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}
