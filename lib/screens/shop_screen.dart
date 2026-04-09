import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_data.dart';
import '../utils/app_colors.dart';
import '../utils/prefs_helper.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  int _points = 0;
  List<String> _unlockedThemes = ['classic'];
  List<String> _unlockedCats   = ['fruits', 'animals'];
  String _equippedTheme = 'classic';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final pts      = await PrefsHelper.getPoints();
    final themes   = await PrefsHelper.getUnlockedThemes();
    final cats     = await PrefsHelper.getUnlockedCategories();
    final equipped = await PrefsHelper.getEquippedTheme();
    if (mounted) setState(() {
      _points         = pts;
      _unlockedThemes = themes;
      _unlockedCats   = cats;
      _equippedTheme  = equipped;
    });
  }

  Future<void> _unlockTheme(WheelTheme t) async {
    if (_points < t.requiredPoints) { _showNotEnough(); return; }
    await PrefsHelper.addPoints(-t.requiredPoints);
    await PrefsHelper.unlockTheme(t.id);
    await _loadData();
    if (!mounted) return;
    _showSnack('${t.emoji} ${t.name} unlocked!', AppColors.success);
  }

  Future<void> _equipTheme(WheelTheme t) async {
    await PrefsHelper.setEquippedTheme(t.id);
    await _loadData();
  }

  Future<void> _unlockCategory(Category c) async {
    if (_points < c.unlockCost) { _showNotEnough(); return; }
    await PrefsHelper.addPoints(-c.unlockCost);
    await PrefsHelper.unlockCategory(c.id);
    await _loadData();
    if (!mounted) return;
    _showSnack('${c.emoji} ${c.name} unlocked!', AppColors.success);
  }

  void _showNotEnough() {
    if (!mounted) return;
    _showSnack('Not enough points! Spin to earn more.', AppColors.error);
  }

  void _showSnack(String msg, Color color) {
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
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
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
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              // Tab bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(13),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: GoogleFonts.fredoka(fontSize: 15),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  tabs: const [
                    Tab(text: '🎡  Wheel Themes'),
                    Tab(text: '🗂️  Categories'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ThemesTab(
                      themes: GameData.themes,
                      unlockedThemes: _unlockedThemes,
                      equippedTheme: _equippedTheme,
                      userPoints: _points,
                      onUnlock: _unlockTheme,
                      onEquip: _equipTheme,
                    ),
                    _CategoriesTab(
                      categories: GameData.shopCategories,
                      unlockedCats: _unlockedCats,
                      userPoints: _points,
                      onUnlock: _unlockCategory,
                    ),
                  ],
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
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          ),
          Text('🛍️ Shop',
            style: GoogleFonts.fredoka(fontSize: 22, color: AppColors.secondary, fontWeight: FontWeight.bold)),
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
              Text('$_points',
                style: GoogleFonts.fredoka(color: AppColors.secondary, fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── Themes Tab ───────────────────────────────────────────────────────────────

class _ThemesTab extends StatelessWidget {
  final List<WheelTheme> themes;
  final List<String> unlockedThemes;
  final String equippedTheme;
  final int userPoints;
  final void Function(WheelTheme) onUnlock;
  final void Function(WheelTheme) onEquip;

  const _ThemesTab({
    required this.themes, required this.unlockedThemes,
    required this.equippedTheme, required this.userPoints,
    required this.onUnlock, required this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: themes.length,
      itemBuilder: (_, i) => _ThemeCard(
        theme: themes[i],
        isUnlocked: unlockedThemes.contains(themes[i].id),
        isEquipped: equippedTheme == themes[i].id,
        userPoints: userPoints,
        onUnlock: () => onUnlock(themes[i]),
        onEquip: () => onEquip(themes[i]),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final WheelTheme theme;
  final bool isUnlocked, isEquipped;
  final int userPoints;
  final VoidCallback onUnlock, onEquip;

  const _ThemeCard({
    required this.theme, required this.isUnlocked, required this.isEquipped,
    required this.userPoints, required this.onUnlock, required this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.themeColors[theme.id] ?? AppColors.themeColors['classic']!;
    final canAfford = userPoints >= theme.requiredPoints;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(isEquipped ? 20 : 10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isEquipped ? AppColors.secondary : Colors.white.withAlpha(26),
          width: isEquipped ? 2 : 1,
        ),
        boxShadow: isEquipped ? [BoxShadow(color: AppColors.secondary.withAlpha(60), blurRadius: 12, spreadRadius: 2)] : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _MiniWheelPreview(colors: colors, emoji: theme.emoji),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(child: Text(theme.name,
                      style: GoogleFonts.fredoka(fontSize: 17, color: AppColors.white, fontWeight: FontWeight.bold))),
                    if (isEquipped) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withAlpha(50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Active', style: GoogleFonts.nunito(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Text('⭐', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 3),
                    Text(theme.requiredPoints == 0 ? 'Free' : '${theme.requiredPoints} pts',
                      style: GoogleFonts.nunito(fontSize: 12, color: Colors.white54)),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _actionBtn(canAfford),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(bool canAfford) {
    if (isEquipped) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.secondary.withAlpha(46),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.secondary.withAlpha(128)),
        ),
        child: Text('✓ Active', style: GoogleFonts.fredoka(fontSize: 13, color: AppColors.secondary)),
      );
    }
    if (isUnlocked) {
      return ElevatedButton(
        onPressed: onEquip,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
        child: Text('Equip', style: GoogleFonts.fredoka(fontSize: 13)),
      );
    }
    return ElevatedButton(
      onPressed: canAfford ? onUnlock : null,
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

// ─── Categories Tab ───────────────────────────────────────────────────────────

class _CategoriesTab extends StatelessWidget {
  final List<Category> categories;
  final List<String> unlockedCats;
  final int userPoints;
  final void Function(Category) onUnlock;

  const _CategoriesTab({
    required this.categories, required this.unlockedCats,
    required this.userPoints, required this.onUnlock,
  });

  static const List<List<Color>> _gradients = [
    [Color(0xFF00B4D8), Color(0xFF0096C7)],
    [Color(0xFFD00000), Color(0xFFE85D04)],
    [Color(0xFF2D6A4F), Color(0xFF52B788)],
    [Color(0xFF6A040F), Color(0xFFFFBA08)],
    [Color(0xFF10002B), Color(0xFF9D4EDD)],
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: categories.length,
      itemBuilder: (_, i) {
        final cat = categories[i];
        final unlocked = unlockedCats.contains(cat.id);
        final canAfford = userPoints >= cat.unlockCost;
        final g = _gradients[i % _gradients.length];

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: unlocked ? g : [const Color(0xFF2A2A3E), const Color(0xFF1A1A2E)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: unlocked ? g[0].withAlpha(180) : Colors.white.withAlpha(26),
            ),
            boxShadow: unlocked ? [BoxShadow(color: g[0].withAlpha(80), blurRadius: 12, offset: const Offset(0,4))] : [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(cat.emoji, style: const TextStyle(fontSize: 44)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat.name,
                        style: GoogleFonts.fredoka(fontSize: 18,
                          color: unlocked ? Colors.white : Colors.white54,
                          fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Text('${cat.options.length} options',
                        style: GoogleFonts.nunito(fontSize: 12,
                          color: unlocked ? Colors.white70 : Colors.white38)),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Text('⭐', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 3),
                        Text('${cat.unlockCost} pts',
                          style: GoogleFonts.nunito(fontSize: 12,
                            color: unlocked ? Colors.white70 : Colors.white38)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (unlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('✓ Owned', style: GoogleFonts.fredoka(fontSize: 13, color: Colors.white)),
                  )
                else
                  ElevatedButton(
                    onPressed: canAfford ? () => onUnlock(cat) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAfford ? AppColors.primary : const Color(0xFF333333),
                      disabledBackgroundColor: const Color(0xFF333333),
                      foregroundColor: Colors.white, disabledForegroundColor: Colors.white38,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: canAfford ? 4 : 0,
                    ),
                    child: Text(canAfford ? 'Unlock' : '🔒',
                      style: GoogleFonts.fredoka(fontSize: 13)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Mini Wheel Preview ───────────────────────────────────────────────────────

class _MiniWheelPreview extends StatefulWidget {
  final List<Color> colors;
  final String emoji;
  const _MiniWheelPreview({required this.colors, required this.emoji});
  @override
  State<_MiniWheelPreview> createState() => _MiniWheelPreviewState();
}

class _MiniWheelPreviewState extends State<_MiniWheelPreview>
    with SingleTickerProviderStateMixin {
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
    for (int i = 0; i < colors.length; i++) {
      if (old.colors[i] != colors[i]) return true;
    }
    return false;
  }
}
