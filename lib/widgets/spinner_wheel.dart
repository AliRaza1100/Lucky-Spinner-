import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_data.dart';
import '../utils/app_colors.dart';

class SpinnerWheel extends StatefulWidget {
  final List<Option> options;
  final List<Color> segmentColors;
  final int targetIndex;
  final bool isSpinning;
  final VoidCallback onSpinComplete;

  const SpinnerWheel({
    super.key,
    required this.options,
    required this.segmentColors,
    required this.targetIndex,
    required this.isSpinning,
    required this.onSpinComplete,
  });

  @override
  State<SpinnerWheel> createState() => _SpinnerWheelState();
}

class _SpinnerWheelState extends State<SpinnerWheel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentAngle = 0;
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller);
  }

  @override
  void didUpdateWidget(SpinnerWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning && !oldWidget.isSpinning) {
      _spin();
    }
  }

  void _spin() {
    _hasCompleted = false;
    final n = widget.options.length;
    final segmentAngle = (2 * pi) / n;

    // ── Precise stop calculation ──────────────────────────────────────────
    // The wheel is drawn so segment[i] starts at: i*segmentAngle - pi/2
    // The pointer is at the TOP of the wheel (angle = 0 in screen coords,
    // which is -pi/2 in standard math coords).
    //
    // For segment[targetIndex] to sit EXACTLY under the pointer we need
    // the wheel rotation R such that:
    //   segment_center_after_rotation == pointer_angle
    //   (i*segA + segA/2 - pi/2) + R == -pi/2   (mod 2π)
    //   R == -(i*segA + segA/2)                  (mod 2π)
    //
    // We add a small random offset (±30% of half-segment) so the needle
    // lands visibly inside the segment, not always dead-center.
    final rng = Random();
    final jitter = (rng.nextDouble() - 0.5) * segmentAngle * 0.5;
    final targetRotation =
        (-(widget.targetIndex * segmentAngle + segmentAngle / 2) + jitter) %
            (2 * pi);

    // Normalise to [0, 2π)
    final normalised =
        targetRotation < 0 ? targetRotation + 2 * pi : targetRotation;

    // How much MORE we need to rotate from current position
    final currentNorm = _currentAngle % (2 * pi);
    double delta = normalised - currentNorm;
    if (delta <= 0) delta += 2 * pi; // always spin forward

    // 6–9 full extra rotations for realistic deceleration
    final extraSpins = (6 + rng.nextInt(4)) * 2 * pi;
    final endAngle = _currentAngle + extraSpins + delta;

    _animation = Tween<double>(begin: _currentAngle, end: endAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.duration = const Duration(milliseconds: 5000);
    _controller.reset();
    _controller.forward().then((_) {
      if (!mounted) return;
      _currentAngle = endAngle % (2 * pi);
      if (!_hasCompleted) {
        _hasCompleted = true;
        widget.onSpinComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        return SizedBox(
          width: 320,
          height: 320,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow
              Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withAlpha(80),
                      blurRadius: 36,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
              // Gold ring
              Container(
                width: 318,
                height: 318,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.secondary.withAlpha(200),
                    width: 4,
                  ),
                ),
              ),
              // Spinning wheel
              Transform.rotate(
                angle: _animation.value,
                child: CustomPaint(
                  size: const Size(306, 306),
                  painter: _WheelPainter(
                    options: widget.options,
                    colors: widget.segmentColors,
                  ),
                ),
              ),
              // Center hub
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFCCCCCC)],
                  ),
                  border: Border.all(color: AppColors.secondary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(120),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🎯', style: TextStyle(fontSize: 26)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Wheel Painter ────────────────────────────────────────────────────────────

class _WheelPainter extends CustomPainter {
  final List<Option> options;
  final List<Color> colors;

  _WheelPainter({required this.options, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final n = options.length;
    final segAngle = (2 * pi) / n;

    final fillPaint  = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white.withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < n; i++) {
      final start = i * segAngle - pi / 2;
      fillPaint.color = colors[i % colors.length];

      // Slightly lighter shade on alternate segments for depth
      if (i % 2 == 1) {
        final c = colors[i % colors.length];
        fillPaint.color = Color.fromARGB(
          (c.a * 255).round().clamp(0, 255),
          ((c.r * 255).round() + 20).clamp(0, 255),
          ((c.g * 255).round() + 20).clamp(0, 255),
          ((c.b * 255).round() + 20).clamp(0, 255),
        );
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start, segAngle, true, fillPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start, segAngle, true, borderPaint,
      );

      // ── Label ──────────────────────────────────────────────────────────
      final mid = start + segAngle / 2;
      final tr  = radius * 0.64;
      final tx  = center.dx + tr * cos(mid);
      final ty  = center.dy + tr * sin(mid);

      canvas.save();
      canvas.translate(tx, ty);
      canvas.rotate(mid + pi / 2);

      // White pill background for readability
      final pillW = 52.0;
      final pillH = 44.0;
      final pillRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -2), width: pillW, height: pillH),
        const Radius.circular(8),
      );
      canvas.drawRRect(
        pillRect,
        Paint()..color = Colors.black.withAlpha(60),
      );

      // Emoji
      final ep = TextPainter(
        text: TextSpan(text: options[i].emoji, style: const TextStyle(fontSize: 20)),
        textDirection: TextDirection.ltr,
      )..layout();
      ep.paint(canvas, Offset(-ep.width / 2, -ep.height - 2));

      // Name
      final lp = TextPainter(
        text: TextSpan(
          text: options[i].name,
          style: GoogleFonts.fredoka(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      lp.paint(canvas, Offset(-lp.width / 2, 3));

      canvas.restore();
    }

    // Outer white border
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) {
    if (old.options.length != options.length) return true;
    for (int i = 0; i < colors.length; i++) {
      if (old.colors[i] != colors[i]) return true;
    }
    return false;
  }
}
