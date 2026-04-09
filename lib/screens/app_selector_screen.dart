import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/prefs_helper.dart';
import 'category_screen.dart';
import '../truth_dare/screens/td_home_screen.dart';

class AppSelectorScreen extends StatefulWidget {
  const AppSelectorScreen({super.key});
  @override
  State<AppSelectorScreen> createState() => _AppSelectorScreenState();
}

class _AppSelectorScreenState extends State<AppSelectorScreen>
    with TickerProviderStateMixin {
  int _points = 0;
  late AnimationController _bgCtrl;
  late AnimationController _cardCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    final pts = await PrefsHelper.getPoints();
    if (mounted) setState(() => _points = pts);
  }

  @override
  void dispose() { _bgCtrl.dispose(); _cardCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (_, child) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(cos(_bgCtrl.value * 2 * pi), sin(_bgCtrl.value * 2 * pi)),
              end: Alignment(-cos(_bgCtrl.value * 2 * pi), -sin(_bgCtrl.value * 2 * pi)),
              colors: const [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460), Color(0xFF1A0533)],
            ),
          ),
          child: child,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _cardCtrl,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, 20 * (1 - _cardCtrl.value)),
                  child: Opacity(opacity: _cardCtrl.value, child: child),
                ),
                child: Column(children: [
                  Text('Choose Your Game',
                    style: GoogleFonts.fredoka(fontSize: 28, color: AppColors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Two amazing games in one app!',
                    style: GoogleFonts.nunito(fontSize: 14, color: Colors.white54)),
                ]),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Expanded(
                        child: _GameCard(
                          delay: 0.0, ctrl: _cardCtrl,
                          emoji: '🎰', title: 'Lucky Spinner', subtitle: 'Spin the wheel & win rewards',
                          features: const ['🍎 Multiple categories', '🎡 15 wheel themes', '⭐ Earn points'],
                          gradientColors: const [Color(0xFFFF6B35), Color(0xFFFF8E53), Color(0xFFFFD700)],
                          glowColor: Color(0xFFFF6B35),
                          onTap: () => Navigator.push(context, PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const CategoryScreen(),
                            transitionsBuilder: (_, a, __, c) => SlideTransition(
                              position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
                                .animate(CurvedAnimation(parent: a, curve: Curves.easeInOut)),
                              child: c,
                            ),
                            transitionDuration: const Duration(milliseconds: 400),
                          )).then((_) => _loadPoints()),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: _GameCard(
                          delay: 0.15, ctrl: _cardCtrl,
                          emoji: '🎭', title: 'Truth or Dare', subtitle: 'The ultimate party game',
                          features: const ['🤔 Custom truths', '😈 Wild dares', '🎲 Mixed mode'],
                          gradientColors: const [Color(0xFF7C4DFF), Color(0xFF9C6FFF), Color(0xFFDA70D6)],
                          glowColor: Color(0xFF7C4DFF),
                          onTap: () => Navigator.push(context, PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const TdHomeScreen(),
                            transitionsBuilder: (_, a, __, c) => SlideTransition(
                              position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                                .animate(CurvedAnimation(parent: a, curve: Curves.easeInOut)),
                              child: c,
                            ),
                            transitionDuration: const Duration(milliseconds: 400),
                          )).then((_) => _loadPoints()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('🎮 Game Hub',
            style: GoogleFonts.fredoka(fontSize: 22, color: AppColors.secondary, fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(38),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.secondary.withAlpha(128)),
            ),
            child: Row(children: [
              const Text('⭐', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text('$_points',
                style: GoogleFonts.fredoka(color: AppColors.secondary, fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatefulWidget {
  final String emoji, title, subtitle;
  final List<String> features;
  final List<Color> gradientColors;
  final Color glowColor;
  final double delay;
  final AnimationController ctrl;
  final VoidCallback onTap;
  const _GameCard({required this.emoji, required this.title, required this.subtitle,
    required this.features, required this.gradientColors, required this.glowColor,
    required this.delay, required this.ctrl, required this.onTap});
  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> with SingleTickerProviderStateMixin {
  late AnimationController _press;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _press, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _press.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.ctrl,
      builder: (_, child) {
        final t = ((widget.ctrl.value - widget.delay) / (1.0 - widget.delay)).clamp(0.0, 1.0);
        return Transform.translate(offset: Offset(0, 50 * (1 - t)), child: Opacity(opacity: t, child: child));
      },
      child: GestureDetector(
        onTapDown: (_) => _press.forward(),
        onTapUp: (_) { _press.reverse(); widget.onTap(); },
        onTapCancel: () => _press.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: widget.gradientColors),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: widget.glowColor.withAlpha(100), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(widget.emoji, style: const TextStyle(fontSize: 48)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: GoogleFonts.fredoka(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(widget.subtitle, style: GoogleFonts.nunito(fontSize: 13, color: Colors.white70)),
                      ],
                    )),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withAlpha(40), shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                    ),
                  ]),
                  const Spacer(),
                  Wrap(
                    spacing: 8, runSpacing: 6,
                    children: widget.features.map((f) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white.withAlpha(35), borderRadius: BorderRadius.circular(20)),
                      child: Text(f, style: GoogleFonts.nunito(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}