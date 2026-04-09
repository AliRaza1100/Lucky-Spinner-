import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../models/game_data.dart';
import '../utils/app_colors.dart';
import '../utils/prefs_helper.dart';
import '../utils/sound_service.dart';
import '../widgets/spinner_wheel.dart';

class GameScreen extends StatefulWidget {
  final Category category;
  final Option selectedOption;

  const GameScreen({
    super.key,
    required this.category,
    required this.selectedOption,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  bool _isSpinning = false;
  int _targetIndex = 0;
  int _points = 0;
  String _equippedTheme = 'classic';
  late ConfettiController _confettiController;
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    final pts = await PrefsHelper.getPoints();
    final theme = await PrefsHelper.getEquippedTheme();
    if (mounted) {
      setState(() {
        _points = pts;
        _equippedTheme = theme;
      });
    }
  }

  void _spin() {
    if (_isSpinning) return;
    SoundService.instance.playSpin();
    final random = Random();
    final win = random.nextDouble() < 0.6;
    final selectedIdx = widget.category.options
        .indexWhere((o) => o.name == widget.selectedOption.name);

    int target;
    if (win) {
      target = selectedIdx;
    } else {
      // Guarantee a different segment
      do {
        target = random.nextInt(widget.category.options.length);
      } while (target == selectedIdx);
    }

    setState(() {
      _targetIndex = target;
      _isSpinning = true;
    });
  }

  // Called by SpinnerWheel when animation finishes
  void _onSpinComplete() {
    if (!mounted) return;
    final landedOption = widget.category.options[_targetIndex];
    final won = landedOption.name == widget.selectedOption.name;

    // Fix: single setState — always reset spinning here, not in _showResultDialog
    setState(() => _isSpinning = false);

    if (won) {
      _confettiController.play();
      SoundService.instance.playWin();
      final reward = GameData.getRewardPoints();
      PrefsHelper.addPoints(reward).then((_) {
        if (mounted) {
          SoundService.instance.playPoints();
          _loadData();
        }
      });
      _showResultDialog(won: true, reward: reward, landed: landedOption);
    } else {
      SoundService.instance.playLose();
      _showResultDialog(won: false, reward: 0, landed: landedOption);
    }
  }

  void _showResultDialog({
    required bool won,
    required int reward,
    required Option landed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        won: won,
        reward: reward,
        landedOption: landed,
        selectedOption: widget.selectedOption,
        onPlayAgain: () {
          Navigator.pop(context); // close dialog
          Navigator.pop(context); // back to option screen
        },
        onSpinAgain: () {
          Navigator.pop(context); // close dialog — wheel is ready to spin again
        },
      ),
    );
  }

  List<Color> get _segmentColors {
    final palette =
        AppColors.themeColors[_equippedTheme] ?? AppColors.themeColors['classic']!;
    return List.generate(
      widget.category.options.length,
      (i) => palette[i % palette.length],
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  _buildSelectedBadge(),
                  const SizedBox(height: 12),
                  const _PointerArrow(),
                  const SizedBox(height: 2),
                  SpinnerWheel(
                    options: widget.category.options,
                    segmentColors: _segmentColors,
                    targetIndex: _targetIndex,
                    isSpinning: _isSpinning,
                    onSpinComplete: _onSpinComplete,
                  ),
                  const SizedBox(height: 20),
                  _buildSpinButton(),
                ],
              ),
              // Confetti overlay
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [
                    Colors.red,
                    Colors.yellow,
                    Colors.green,
                    Colors.blue,
                    Colors.purple,
                    Colors.orange,
                  ],
                  numberOfParticles: 40,
                  maxBlastForce: 30,
                  minBlastForce: 10,
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
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: _isSpinning ? Colors.white30 : Colors.white,
            ),
          ),
          Text(
            '${widget.category.emoji} ${widget.category.name}',
            style: GoogleFonts.fredoka(
              fontSize: 20,
              color: AppColors.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(38),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.secondary.withAlpha(102)),
            ),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '$_points',
                  style: GoogleFonts.fredoka(
                    color: AppColors.secondary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(46),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.primary.withAlpha(128)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.selectedOption.emoji,
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 8),
          Text(
            'Your pick: ${widget.selectedOption.name}',
            style: GoogleFonts.fredoka(
              fontSize: 16,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpinButton() {
    return GestureDetector(
      onTapDown: _isSpinning ? null : (_) => _buttonController.forward(),
      onTapUp: _isSpinning
          ? null
          : (_) {
              _buttonController.reverse();
              SoundService.instance.playTap();
              _spin();
            },
      onTapCancel: () => _buttonController.reverse(),
      child: ScaleTransition(
        scale: _buttonScale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 170,
          height: 62,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isSpinning
                  ? [const Color(0xFF555555), const Color(0xFF444444)]
                  : [AppColors.primary, const Color(0xFFFF8E53)],
            ),
            borderRadius: BorderRadius.circular(31),
            boxShadow: _isSpinning
                ? []
                : [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(153),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              _isSpinning ? '🌀 Spinning...' : '🎡  SPIN!',
              style: GoogleFonts.fredoka(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Pointer Arrow ────────────────────────────────────────────────────────────

class _PointerArrow extends StatelessWidget {
  const _PointerArrow();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(32, 36),
      painter: _PointerPainter(),
    );
  }
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Drop shadow
    final shadow = Paint()
      ..color = Colors.black.withAlpha(100)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final path = Path()
      ..moveTo(size.width / 2, size.height + 2)
      ..lineTo(2, 2)
      ..lineTo(size.width - 2, 2)
      ..close();
    canvas.drawPath(path, shadow);

    // White fill
    final fill = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final tri = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(tri, fill);

    // Orange border
    final border = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(tri, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── Result Dialog ────────────────────────────────────────────────────────────

class _ResultDialog extends StatefulWidget {
  final bool won;
  final int reward;
  final Option landedOption;
  final Option selectedOption;
  final VoidCallback onPlayAgain;
  final VoidCallback onSpinAgain;

  const _ResultDialog({
    required this.won,
    required this.reward,
    required this.landedOption,
    required this.selectedOption,
    required this.onPlayAgain,
    required this.onSpinAgain,
  });

  @override
  State<_ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<_ResultDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _scaleAnim =
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.won ? AppColors.success : AppColors.error;
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.won
                    ? [const Color(0xFF0D2B1A), const Color(0xFF1A3A28)]
                    : [const Color(0xFF2B0D0D), const Color(0xFF3A1A1A)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: accent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: accent.withAlpha(102),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.won ? '🎉' : '😢',
                  style: const TextStyle(fontSize: 72),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.won ? 'Congratulations!' : 'Try Again!',
                  style: GoogleFonts.fredoka(
                    fontSize: 28,
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.won
                      ? 'Wheel landed on ${widget.landedOption.name} ${widget.landedOption.emoji}'
                      : 'Landed on ${widget.landedOption.name} ${widget.landedOption.emoji}\nYou picked ${widget.selectedOption.name} ${widget.selectedOption.emoji}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                if (widget.won) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(31),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.success.withAlpha(102),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 26)),
                        const SizedBox(width: 10),
                        Text(
                          '+${widget.reward} Points',
                          style: GoogleFonts.fredoka(
                            fontSize: 26,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _rewardLabel(widget.reward),
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.secondary.withAlpha(191),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onPlayAgain,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Play Again',
                          style: GoogleFonts.fredoka(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.onSpinAgain,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.won
                              ? AppColors.success
                              : AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 8,
                          shadowColor: widget.won
                              ? AppColors.success.withAlpha(128)
                              : AppColors.primary.withAlpha(128),
                        ),
                        child: Text(
                          'Spin Again',
                          style: GoogleFonts.fredoka(fontSize: 16),
                        ),
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

  String _rewardLabel(int pts) {
    if (pts >= 100) return '🎰 JACKPOT!';
    if (pts >= 50) return '🥈 Medium Win';
    return '🥉 Small Win';
  }
}
