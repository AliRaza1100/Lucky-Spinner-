import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/prefs_helper.dart';
import 'onboarding_screen.dart';
import 'app_selector_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _wheelController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  final List<String> _icons = [
    '🍎', '🥭', '🍌', '🍊', '🍇',
    '🦁', '🐶', '🐱', '🐘', '🐵',
  ];

  @override
  void initState() {
    super.initState();
    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _scaleController.forward();
    });
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    final done = await PrefsHelper.isOnboardingDone();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            done ? const AppSelectorScreen() : const OnboardingScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _wheelController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SizedBox.expand(
            child: Stack(
              children: [
                ..._buildFloatingIcons(size),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: _scaleAnim,
                        child: AnimatedBuilder(
                          animation: _wheelController,
                          builder: (_, __) => Transform.rotate(
                            angle: _wheelController.value * 2 * pi,
                            child: _buildWheelIllustration(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ScaleTransition(
                        scale: _scaleAnim,
                        child: Text(
                          '🎰 Lucky Spinner',
                          style: GoogleFonts.fredoka(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                            shadows: [
                              Shadow(
                                color: AppColors.primary.withAlpha(204),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        'Wheel',
                        style: GoogleFonts.fredoka(
                          fontSize: 28,
                          color: AppColors.white,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 48),
                      _buildLoadingDots(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWheelIllustration() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withAlpha(128),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _SplashWheelPainter(),
        child: const Center(
          child: Text('🎯', style: TextStyle(fontSize: 40)),
        ),
      ),
    );
  }

  List<Widget> _buildFloatingIcons(Size size) {
    return List.generate(_icons.length, (i) {
      final angle = (i / _icons.length) * 2 * pi;
      final radius = size.width * 0.42;
      final x = size.width / 2 + radius * cos(angle) - 20;
      final y = size.height / 2 + radius * sin(angle) - 20;
      return Positioned(
        left: x,
        top: y,
        child: AnimatedBuilder(
          animation: _wheelController,
          builder: (_, __) {
            final bounce = sin(_wheelController.value * 2 * pi + i) * 6;
            return Transform.translate(
              offset: Offset(0, bounce),
              child: Text(_icons[i], style: const TextStyle(fontSize: 28)),
            );
          },
        ),
      );
    });
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _wheelController,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final offset = sin(_wheelController.value * 2 * pi + i * 1.0) * 6;
            return Transform.translate(
              offset: Offset(0, offset),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withAlpha(153),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _SplashWheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final colors = AppColors.wheelColors;
    final segments = colors.length;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < segments; i++) {
      paint.color = colors[i % colors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        (i / segments) * 2 * pi - pi / 2,
        (1 / segments) * 2 * pi,
        true,
        paint,
      );
    }
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
