import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../../utils/app_colors.dart';
import '../../utils/prefs_helper.dart';
import '../../utils/sound_service.dart';
import '../models/td_data.dart';
import '../../widgets/spinner_wheel.dart';
import '../../models/game_data.dart' show Option;
//Ali Raza Demo
git
class TdGameScreen extends StatefulWidget {
  final List<String> items;
  final TdMode mode;
  final Color modeColor;
  final String modeLabel;

  const TdGameScreen({
    super.key,
    required this.items,
    required this.mode,
    required this.modeColor,
    required this.modeLabel,
  });

  @override
  State<TdGameScreen> createState() => _TdGameScreenState();
}

class _TdGameScreenState extends State<TdGameScreen>
    with SingleTickerProviderStateMixin {
  bool _isSpinning = false;
  int _targetIndex = 0;
  String _equippedTheme = 'classic';
  late ConfettiController _confetti;
  late AnimationController _btnCtrl;
  late Animation<double> _btnScale;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _btnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _btnScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut));
    _loadData();
  }

  Future<void> _loadData() async {
    final theme = await PrefsHelper.getTdEquippedTheme();
    if (mounted) setState(() { _equippedTheme = theme; });
  }

  void _spin() {
    if (_isSpinning) return;
    SoundService.instance.playSpin();
    final idx = Random().nextInt(widget.items.length);
    setState(() { _targetIndex = idx; _isSpinning = true; });
  }

  void _onSpinComplete() {
    if (!mounted) return;
    setState(() => _isSpinning = false);
    _confetti.play();
    final item = widget.items[_targetIndex];
    // Play truth or dare sound based on content
    final isTruth = item.startsWith('🤔') || widget.mode == TdMode.truth;
    if (isTruth) {
      SoundService.instance.playTruth();
    } else {
      SoundService.instance.playDare();
    }
    _showResult(item);
  }

  void _showResult(String item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TdResultDialog(
        item: item,
        modeColor: widget.modeColor,
        modeLabel: widget.modeLabel,
        onPlayAgain: () { Navigator.pop(context); Navigator.pop(context); },
        onSpinAgain: () => Navigator.pop(context),
      ),
    );
  }

  List<Color> get _segmentColors {
    final palette = AppColors.themeColors[_equippedTheme] ?? AppColors.themeColors['classic']!;
    return List.generate(widget.items.length, (i) => palette[i % palette.length]);
  }

  // Convert string items to Option objects for SpinnerWheel
  List<Option> get _options => widget.items.map((item) {
    // Strip mode prefix for mixed mode display
    final clean = item.replaceFirst(RegExp(r'^[🤔😈]\s'), '');
    final emoji = item.startsWith('🤔') ? '🤔' : item.startsWith('😈') ? '😈' : _modeEmoji;
    // Truncate long text for wheel display
    final label = clean.length > 10 ? '${clean.substring(0, 9)}…' : clean;
    return Option(name: label, emoji: emoji);
  }).toList();

  String get _modeEmoji {
    if (widget.mode == TdMode.truth) return '🤔';
    if (widget.mode == TdMode.dare)  return '😈';
    return '🎲';
  }

  @override
  void dispose() { _confetti.dispose(); _btnCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0533), Color(0xFF2D0B5E), Color(0xFF0F0F2E)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  // Mode badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.modeColor.withAlpha(40),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: widget.modeColor.withAlpha(150)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_modeEmoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text('${widget.modeLabel} Wheel · ${widget.items.length} items',
                        style: GoogleFonts.fredoka(fontSize: 15, color: Colors.white)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  // Pointer
                  _TdPointer(color: widget.modeColor),
                  const SizedBox(height: 2),
                  SpinnerWheel(
                    options: _options,
                    segmentColors: _segmentColors,
                    targetIndex: _targetIndex,
                    isSpinning: _isSpinning,
                    onSpinComplete: _onSpinComplete,
                  ),
                  const SizedBox(height: 20),
                  _buildSpinButton(),
                ],
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [Colors.purple, Colors.pink, Colors.blue, Colors.yellow, Colors.green],
                  numberOfParticles: 40,
                ),
              ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _isSpinning ? null : () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_rounded,
              color: _isSpinning ? Colors.white30 : Colors.white),
          ),
          Text('🎭 ${widget.modeLabel}',
            style: GoogleFonts.fredoka(fontSize: 20, color: widget.modeColor, fontWeight: FontWeight.bold)),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSpinButton() {
    return GestureDetector(
      onTapDown: _isSpinning ? null : (_) => _btnCtrl.forward(),
      onTapUp: _isSpinning ? null : (_) { _btnCtrl.reverse(); SoundService.instance.playTap(); _spin(); },
      onTapCancel: () => _btnCtrl.reverse(),
      child: ScaleTransition(
        scale: _btnScale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 180, height: 62,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isSpinning
                ? [const Color(0xFF555555), const Color(0xFF444444)]
                : [widget.modeColor, widget.modeColor.withAlpha(200)],
            ),
            borderRadius: BorderRadius.circular(31),
            boxShadow: _isSpinning ? [] : [
              BoxShadow(color: widget.modeColor.withAlpha(150), blurRadius: 22, offset: const Offset(0, 8)),
            ],
          ),
          child: Center(
            child: Text(
              _isSpinning ? '🌀 Spinning...' : '🎡  SPIN!',
              style: GoogleFonts.fredoka(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Pointer ──────────────────────────────────────────────────────────────────

class _TdPointer extends StatelessWidget {
  final Color color;
  const _TdPointer({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(32, 36), painter: _TdPointerPainter(color: color));
  }
}

class _TdPointerPainter extends CustomPainter {
  final Color color;
  _TdPointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()
      ..color = Colors.black.withAlpha(100)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final path = Path()
      ..moveTo(size.width / 2, size.height + 2)
      ..lineTo(2, 2)
      ..lineTo(size.width - 2, 2)
      ..close();
    canvas.drawPath(path, shadow);

    final fill = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final tri = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(tri, fill);

    canvas.drawPath(tri, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant _TdPointerPainter old) => old.color != color;
}

// ─── Result Dialog ────────────────────────────────────────────────────────────

class _TdResultDialog extends StatefulWidget {
  final String item, modeLabel;
  final Color modeColor;
  final VoidCallback onPlayAgain, onSpinAgain;

  const _TdResultDialog({
    required this.item, required this.modeColor,
    required this.modeLabel, required this.onPlayAgain, required this.onSpinAgain,
  });

  @override
  State<_TdResultDialog> createState() => _TdResultDialogState();
}

class _TdResultDialogState extends State<_TdResultDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    // Detect if it's a truth or dare from prefix
    final isTruth = widget.item.startsWith('🤔') || widget.modeLabel == 'Truth';
    final isDare  = widget.item.startsWith('😈') || widget.modeLabel == 'Dare';
    final emoji   = isTruth ? '🤔' : isDare ? '😈' : '🎲';
    final label   = isTruth ? 'TRUTH!' : isDare ? 'DARE!' : 'CHALLENGE!';
    final cleanItem = widget.item.replaceFirst(RegExp(r'^[🤔😈]\s'), '');

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [
                  widget.modeColor.withAlpha(60),
                  const Color(0xFF1A0533),
                  const Color(0xFF0F0F2E),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: widget.modeColor, width: 2),
              boxShadow: [BoxShadow(color: widget.modeColor.withAlpha(100), blurRadius: 28, spreadRadius: 4)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 8),
                Text(label, style: GoogleFonts.fredoka(fontSize: 30, color: widget.modeColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: widget.modeColor.withAlpha(100)),
                  ),
                  child: Text(cleanItem, textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(fontSize: 18, color: Colors.white, height: 1.5, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onPlayAgain,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text('Back', style: GoogleFonts.fredoka(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.onSpinAgain,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.modeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 8,
                          shadowColor: widget.modeColor.withAlpha(128),
                        ),
                        child: Text('Spin Again', style: GoogleFonts.fredoka(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
