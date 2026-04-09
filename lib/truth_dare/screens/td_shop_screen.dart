import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../utils/prefs_helper.dart';
import '../models/td_data.dart';

class TdShopScreen extends StatefulWidget {
  const TdShopScreen({super.key});
  @override
  State<TdShopScreen> createState() => _TdShopScreenState();
}

class _TdShopScreenState extends State<TdShopScreen> {
  int _points = 0;
  List<String> _unlocked = ['classic'];
  String _equipped = 'classic';

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final pts      = await PrefsHelper.getPoints();
    final unlocked = await PrefsHelper.getTdUnlockedThemes();
    final equipped = await PrefsHelper.getTdEquippedTheme();
    if (mounted) setState(() { _points = pts; _unlocked = unlocked; _equipped = equipped; });
  }

  Future<void> _unlock(TdTheme t) async {
    if (_points < t.requiredPoints) {
      _snack('Not enough points! Keep playing to earn more.', AppColors.error);
      return;
    }
    await PrefsHelper.addPoints(-t.requiredPoints);
    await PrefsHelper.unlockTdTheme(t.id);
    await _loadData();
    if (!mounted) return;
    _snack('${t.emoji} ${t.name} unlocked!', AppColors.success);
  }

  Future<void> _equip(TdTheme t) async {
    await PrefsHelper.setTdEquippedTheme(t.id);
    await _loadData();
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.fredoka(fontSize: 15)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

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
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                    ),
                    Text('🛍️ T&D Shop',
                      style: GoogleFonts.fredoka(fontSize: 22, color: const Color(0xFF9C6FFF), fontWeight: FontWeight.bold)),
                    const Spacer(),
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
                        Text('$_points', style: GoogleFonts.fredoka(color: AppColors.secondary, fontSize: 16, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Row(children: [
                  Text('Wheel Themes', style: GoogleFonts.fredoka(fontSize: 24, color: AppColors.white, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${TdData.themes.length} themes', style: GoogleFonts.nunito(fontSize: 13, color: Colors.white38)),
                ]),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: TdData.themes.length,
                  itemBuilder: (_, i) {
                    final t = TdData.themes[i];
                    final isUnlocked = _unlocked.contains(t.id);
                    final isEquipped = _equipped == t.id;
                    final canAfford  = _points >= t.requiredPoints;
                    final colors = AppColors.themeColors[t.id] ?? AppColors.themeColors['classic']!;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(isEquipped ? 20 : 10),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isEquipped ? const Color(0xFF9C6FFF) : Colors.white.withAlpha(26),
                          width: isEquipped ? 2 : 1,
                        ),
                        boxShadow: isEquipped ? [BoxShadow(color: const Color(0xFF9C6FFF).withAlpha(60), blurRadius: 12, spreadRadius: 2)] : [],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            _MiniWheel(colors: colors, emoji: t.emoji),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Flexible(child: Text(t.name,
                                      style: GoogleFonts.fredoka(fontSize: 17, color: AppColors.white, fontWeight: FontWeight.bold))),
                                    if (isEquipped) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF9C6FFF).withAlpha(50),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text('Active', style: GoogleFonts.nunito(fontSize: 10, color: const Color(0xFF9C6FFF), fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ]),
                                  const SizedBox(height: 3),
                                  Row(children: [
                                    const Text('⭐', style: TextStyle(fontSize: 12)),
                                    const SizedBox(width: 3),
                                    Text(t.requiredPoints == 0 ? 'Free' : '${t.requiredPoints} pts',
                                      style: GoogleFonts.nunito(fontSize: 12, color: Colors.white54)),
                                  ]),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            _actionBtn(t, isUnlocked, isEquipped, canAfford),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(TdTheme t, bool isUnlocked, bool isEquipped, bool canAfford) {
    if (isEquipped) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF9C6FFF).withAlpha(46),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF9C6FFF).withAlpha(128)),
        ),
        child: Text('✓ Active', style: GoogleFonts.fredoka(fontSize: 13, color: const Color(0xFF9C6FFF))),
      );
    }
    if (isUnlocked) {
      return ElevatedButton(
        onPressed: () => _equip(t),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C4DFF), foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4,
        ),
        child: Text('Equip', style: GoogleFonts.fredoka(fontSize: 13)),
      );
    }
    return ElevatedButton(
      onPressed: canAfford ? () => _unlock(t) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canAfford ? AppColors.primary : const Color(0xFF333333),
        disabledBackgroundColor: const Color(0xFF333333),
        foregroundColor: Colors.white, disabledForegroundColor: Colors.white38,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: canAfford ? 4 : 0,
      ),
      child: Text(canAfford ? 'Unlock' : '🔒', style: GoogleFonts.fredoka(fontSize: 13)),
    );
  }
}

class _MiniWheel extends StatefulWidget {
  final List<Color> colors;
  final String emoji;
  const _MiniWheel({required this.colors, required this.emoji});
  @override
  State<_MiniWheel> createState() => _MiniWheelState();
}

class _MiniWheelState extends State<_MiniWheel> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.rotate(
        angle: _ctrl.value * 2 * pi,
        child: CustomPaint(
          size: const Size(64, 64),
          painter: _MiniWheelPainter(colors: widget.colors),
          child: Center(child: Text(widget.emoji, style: const TextStyle(fontSize: 18))),
        ),
      ),
    );
  }
}

class _MiniWheelPainter extends CustomPainter {
  final List<Color> colors;
  _MiniWheelPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final seg = (2 * pi) / colors.length;
    final p = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < colors.length; i++) {
      p.color = colors[i];
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), i * seg - pi / 2, seg, true, p);
    }
    canvas.drawCircle(c, r, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _MiniWheelPainter old) {
    if (old.colors.length != colors.length) return true;
    for (int i = 0; i < colors.length; i++) { if (old.colors[i] != colors[i]) return true; }
    return false;
  }
}
