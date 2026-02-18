import 'package:flutter/material.dart';

class SwipeOverlay extends StatelessWidget {
  final double swipeProgress; // -1.0 (left/delete) to 1.0 (right/keep)

  const SwipeOverlay({super.key, required this.swipeProgress});

  @override
  Widget build(BuildContext context) {
    final opacity = swipeProgress.abs().clamp(0.0, 1.0);

    if (opacity < 0.05) return const SizedBox.shrink();

    final isKeep = swipeProgress > 0;
    final color = isKeep
        ? Colors.green.withValues(alpha: opacity * 0.4)
        : Colors.red.withValues(alpha: opacity * 0.4);
    final icon = isKeep ? Icons.favorite_rounded : Icons.delete_rounded;
    final label = isKeep ? 'KEEP' : 'DELETE';

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Opacity(
            opacity: opacity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 72, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
