import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../utils/prefs_helper.dart';
import '../../screens/app_selector_screen.dart';
import '../models/td_data.dart';
import 'td_setup_screen.dart';
import 'td_shop_screen.dart';

class TdHomeScreen extends StatefulWidget {
  const TdHomeScreen({super.key});
  @override
  State<TdHomeScreen> createState() => _TdHomeScreenState();
}

class _TdHomeScreenState extends State<TdHomeScreen> with SingleTickerProviderStateMixin {
  int _points = 0;
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    final pts = await PrefsHelper.getPoints();
    if (mounted) setState(() => _points = pts);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1A0533), Color(0xFF2D0B5E), Color(0xFF0F0F2E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              // Big title
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, 30 * (1 - _ctrl.value)),
                  child: Opacity(opacity: _ctrl.value, child: child),
                ),
                child: Column(
                  children: [
                    const Text('🎭', style: TextStyle(fontSize: 72)),
                    const SizedBox(height: 12),
                    Text('Truth or Dare',
                      style: GoogleFonts.fredoka(fontSize: 36, color: AppColors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('The ultimate party game!',
                      style: GoogleFonts.nunito(fontSize: 15, color: Colors.white54)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Mode buttons
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _ModeButton(
                        emoji: '🤔',
                        label: 'Truth',
                        subtitle: 'Answer honest questions',
                        color: const Color(0xFF00B4D8),
                        delay: 0.1,
                        ctrl: _ctrl,
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const TdSetupScreen(mode: TdMode.truth),
                        )).then((_) => _loadPoints()),
                      ),
                      const SizedBox(height: 16),
                      _ModeButton(
                        emoji: '😈',
                        label: 'Dare',
                        subtitle: 'Perform wild challenges',
                        color: const Color(0xFFFF4D6D),
                        delay: 0.2,
                        ctrl: _ctrl,
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const TdSetupScreen(mode: TdMode.dare),
                        )).then((_) => _loadPoints()),
                      ),
                      const SizedBox(height: 16),
                      _ModeButton(
                        emoji: '🎲',
                        label: 'Mixed',
                        subtitle: 'Truths AND dares together',
                        color: const Color(0xFFFFD700),
                        delay: 0.3,
                        ctrl: _ctrl,
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const TdSetupScreen(mode: TdMode.mixed),
                        )).then((_) => _loadPoints()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pushReplacement(context, PageRouteBuilder(
              pageBuilder: (_, __, ___) => const AppSelectorScreen(),
              transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
              transitionDuration: const Duration(milliseconds: 400),
            )),
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          ),
          Text('🎭 Truth or Dare',
            style: GoogleFonts.fredoka(fontSize: 20, color: const Color(0xFF9C6FFF), fontWeight: FontWeight.bold)),
          const Spacer(),
          // Shop button
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TdShopScreen()))
              .then((_) => _loadPoints()),
            icon: const Icon(Icons.store_rounded, color: Color(0xFF9C6FFF)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(38),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.secondary.withAlpha(102)),
            ),
            child: Row(children: [
              const Text('⭐', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text('$_points', style: GoogleFonts.fredoka(color: AppColors.secondary, fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatefulWidget {
  final String emoji, label, subtitle;
  final Color color;
  final double delay;
  final AnimationController ctrl;
  final VoidCallback onTap;
  const _ModeButton({required this.emoji, required this.label, required this.subtitle,
    required this.color, required this.delay, required this.ctrl, required this.onTap});
  @override
  State<_ModeButton> createState() => _ModeButtonState();
}

class _ModeButtonState extends State<_ModeButton> with SingleTickerProviderStateMixin {
  late AnimationController _press;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _press, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _press.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.ctrl,
      builder: (_, child) {
        final t = ((widget.ctrl.value - widget.delay) / (1.0 - widget.delay)).clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, 40 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _press.forward(),
        onTapUp: (_) { _press.reverse(); widget.onTap(); },
        onTapCancel: () => _press.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: widget.color.withAlpha(30),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: widget.color.withAlpha(180), width: 2),
              boxShadow: [BoxShadow(color: widget.color.withAlpha(60), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                Text(widget.emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.label, style: GoogleFonts.fredoka(fontSize: 24, color: widget.color, fontWeight: FontWeight.bold)),
                      Text(widget.subtitle, style: GoogleFonts.nunito(fontSize: 13, color: Colors.white60)),
                    ],
                  ),
                ),
                Icon(Icons.play_circle_filled_rounded, color: widget.color, size: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
