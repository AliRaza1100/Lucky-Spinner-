import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_data.dart';
import '../utils/app_colors.dart';
import '../utils/prefs_helper.dart';
import 'option_screen.dart';
import 'shop_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});
  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen>
    with SingleTickerProviderStateMixin {
  int _points = 0;
  List<String> _unlockedCats = ['fruits', 'animals'];
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    )..forward();
    _loadData();
  }

  Future<void> _loadData() async {
    final pts = await PrefsHelper.getPoints();
    final cats = await PrefsHelper.getUnlockedCategories();
    if (mounted) setState(() { _points = pts; _unlockedCats = cats; });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _goToShop() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()))
          .then((_) => _loadData());

  @override
  Widget build(BuildContext context) {
    final all = GameData.allCategories;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Choose a Category',
                  style: GoogleFonts.fredoka(
                    fontSize: 26, color: AppColors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Unlock more categories in the Shop!',
                  style: GoogleFonts.nunito(fontSize: 13, color: Colors.white54)),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  itemCount: all.length,
                  itemBuilder: (_, i) {
                    final cat = all[i];
                    final unlocked = _unlockedCats.contains(cat.id);
                    final delay = i * 0.07;
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (_, child) {
                        final t = ((_controller.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - t)),
                          child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
                        );
                      },
                      child: _CategoryCard(
                        category: cat,
                        index: i,
                        isUnlocked: unlocked,
                        onTap: unlocked
                          ? () => Navigator.push(context, PageRouteBuilder(
                              pageBuilder: (_, __, ___) => OptionScreen(category: cat),
                              transitionsBuilder: (_, anim, __, child) => SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1, 0), end: Offset.zero)
                                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
                                child: child,
                              ),
                              transitionDuration: const Duration(milliseconds: 400),
                            )).then((_) => _loadData())
                          : _goToShop,
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('🎰 Lucky Spinner',
            style: GoogleFonts.fredoka(
              fontSize: 22, color: AppColors.secondary, fontWeight: FontWeight.bold)),
          GestureDetector(
            onTap: _goToShop,
            child: Container(
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
                  style: GoogleFonts.fredoka(
                    color: AppColors.secondary, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                const Icon(Icons.store_rounded, color: AppColors.secondary, size: 18),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Card ────────────────────────────────────────────────────────────

class _CategoryCard extends StatefulWidget {
  final Category category;
  final int index;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.index,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;
  late Animation<double> _scale;

  static const List<List<Color>> _gradients = [
    [Color(0xFFFF6B35), Color(0xFFFF8E53)],
    [Color(0xFF7C4DFF), Color(0xFF9C6FFF)],
    [Color(0xFF00B4D8), Color(0xFF0096C7)],
    [Color(0xFF2D6A4F), Color(0xFF52B788)],
    [Color(0xFFD00000), Color(0xFFE85D04)],
    [Color(0xFF6A040F), Color(0xFFFFBA08)],
    [Color(0xFF10002B), Color(0xFF9D4EDD)],
  ];

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _press, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _press.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final g = _gradients[widget.index % _gradients.length];
    final locked = !widget.isUnlocked;

    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) { _press.reverse(); widget.onTap(); },
      onTapCancel: () => _press.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: locked
                  ? [const Color(0xFF252540), const Color(0xFF1A1A35)]
                  : g,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: locked
                  ? Colors.white.withAlpha(20)
                  : g[0].withAlpha(200),
              width: 1.5,
            ),
            boxShadow: locked
                ? []
                : [BoxShadow(color: g[0].withAlpha(90), blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                // Emoji badge
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: locked
                        ? Colors.white.withAlpha(10)
                        : Colors.white.withAlpha(35),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(widget.category.emoji,
                        style: TextStyle(
                            fontSize: 30,
                            color: locked ? null : null)),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.category.name,
                        style: GoogleFonts.fredoka(
                          fontSize: 19,
                          color: locked ? Colors.white38 : Colors.white,
                          fontWeight: FontWeight.bold,
                        )),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.tune_rounded,
                          size: 13,
                          color: locked ? Colors.white24 : Colors.white60),
                        const SizedBox(width: 4),
                        Text('${widget.category.options.length} options',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: locked ? Colors.white24 : Colors.white70)),
                        if (locked) ...[
                          const SizedBox(width: 12),
                          const Text('⭐', style: TextStyle(fontSize: 11)),
                          const SizedBox(width: 3),
                          Text('${widget.category.unlockCost} pts',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: Colors.white38,
                              fontWeight: FontWeight.w600)),
                        ],
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Action
                locked ? _LockedBadge() : _PlayBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LockedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(30)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.lock_rounded, color: Colors.white38, size: 14),
        const SizedBox(width: 5),
        Text('Shop', style: GoogleFonts.fredoka(fontSize: 13, color: Colors.white38)),
      ]),
    );
  }
}

class _PlayBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(40),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.white.withAlpha(20), blurRadius: 8)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Text('Play', style: GoogleFonts.fredoka(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
