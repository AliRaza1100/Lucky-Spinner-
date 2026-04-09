import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../utils/prefs_helper.dart';
import '../models/td_data.dart';
import 'td_game_screen.dart';

class TdSetupScreen extends StatefulWidget {
  final TdMode mode;
  const TdSetupScreen({super.key, required this.mode});
  @override
  State<TdSetupScreen> createState() => _TdSetupScreenState();
}

class _TdSetupScreenState extends State<TdSetupScreen> with SingleTickerProviderStateMixin {
  List<String> _truths = [];
  List<String> _dares  = [];
  late TabController _tabs;
  final _truthCtrl = TextEditingController();
  final _dareCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    final tabCount = widget.mode == TdMode.mixed ? 2 : 1;
    _tabs = TabController(length: tabCount, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final t = await PrefsHelper.getTruths();
    final d = await PrefsHelper.getDares();
    if (mounted) setState(() {
      _truths = t.isEmpty ? List.from(TdData.defaultTruths) : t;
      _dares  = d.isEmpty ? List.from(TdData.defaultDares)  : d;
    });
  }

  Future<void> _save() async {
    await PrefsHelper.saveTruths(_truths);
    await PrefsHelper.saveDares(_dares);
  }

  void _addItem(bool isTruth, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final list = isTruth ? _truths : _dares;
    if (list.length >= 8) {
      _showSnack('Maximum 8 ${isTruth ? "truths" : "dares"} allowed');
      return;
    }
    setState(() { list.add(trimmed); });
    (isTruth ? _truthCtrl : _dareCtrl).clear();
    _save();
  }

  void _removeItem(bool isTruth, int index) {
    final list = isTruth ? _truths : _dares;
    if (list.length <= 2) { _showSnack('Minimum 2 items required'); return; }
    setState(() { list.removeAt(index); });
    _save();
  }

  void _resetToDefaults(bool isTruth) {
    setState(() {
      if (isTruth) _truths = List.from(TdData.defaultTruths);
      else _dares = List.from(TdData.defaultDares);
    });
    _save();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.fredoka(fontSize: 14)),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  bool get _canPlay {
    if (widget.mode == TdMode.truth) return _truths.length >= 2;
    if (widget.mode == TdMode.dare)  return _dares.length >= 2;
    return _truths.length >= 2 && _dares.length >= 2;
  }

  void _startGame() {
    List<String> items;
    Color color;
    String label;
    if (widget.mode == TdMode.truth) {
      items = _truths; color = const Color(0xFF00B4D8); label = 'Truth';
    } else if (widget.mode == TdMode.dare) {
      items = _dares; color = const Color(0xFFFF4D6D); label = 'Dare';
    } else {
      // Mixed: interleave truths and dares, prefix each
      items = [];
      for (int i = 0; i < _truths.length; i++) items.add('🤔 ${_truths[i]}');
      for (int i = 0; i < _dares.length; i++)  items.add('😈 ${_dares[i]}');
      items.shuffle();
      color = const Color(0xFFFFD700); label = 'Mixed';
    }
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => TdGameScreen(items: items, mode: widget.mode, modeColor: color, modeLabel: label),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  Color get _modeColor {
    if (widget.mode == TdMode.truth) return const Color(0xFF00B4D8);
    if (widget.mode == TdMode.dare)  return const Color(0xFFFF4D6D);
    return const Color(0xFFFFD700);
  }

  String get _modeEmoji {
    if (widget.mode == TdMode.truth) return '🤔';
    if (widget.mode == TdMode.dare)  return '😈';
    return '🎲';
  }

  String get _modeLabel {
    if (widget.mode == TdMode.truth) return 'Truth';
    if (widget.mode == TdMode.dare)  return 'Dare';
    return 'Mixed';
  }

  @override
  void dispose() { _tabs.dispose(); _truthCtrl.dispose(); _dareCtrl.dispose(); super.dispose(); }

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
              const SizedBox(height: 8),
              // Tab bar for mixed mode
              if (widget.mode == TdMode.mixed)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(13), borderRadius: BorderRadius.circular(14)),
                  child: TabBar(
                    controller: _tabs,
                    indicator: BoxDecoration(color: _modeColor, borderRadius: BorderRadius.circular(12)),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.bold),
                    unselectedLabelStyle: GoogleFonts.fredoka(fontSize: 15),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    tabs: const [Tab(text: '🤔  Truths'), Tab(text: '😈  Dares')],
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: widget.mode == TdMode.mixed
                  ? TabBarView(controller: _tabs, children: [
                      _ItemList(items: _truths, isTruth: true, color: const Color(0xFF00B4D8),
                        controller: _truthCtrl, onAdd: (t) => _addItem(true, t),
                        onRemove: (i) => _removeItem(true, i), onReset: () => _resetToDefaults(true)),
                      _ItemList(items: _dares, isTruth: false, color: const Color(0xFFFF4D6D),
                        controller: _dareCtrl, onAdd: (t) => _addItem(false, t),
                        onRemove: (i) => _removeItem(false, i), onReset: () => _resetToDefaults(false)),
                    ])
                  : widget.mode == TdMode.truth
                    ? _ItemList(items: _truths, isTruth: true, color: _modeColor,
                        controller: _truthCtrl, onAdd: (t) => _addItem(true, t),
                        onRemove: (i) => _removeItem(true, i), onReset: () => _resetToDefaults(true))
                    : _ItemList(items: _dares, isTruth: false, color: _modeColor,
                        controller: _dareCtrl, onAdd: (t) => _addItem(false, t),
                        onRemove: (i) => _removeItem(false, i), onReset: () => _resetToDefaults(false)),
              ),
              // Start button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: AnimatedOpacity(
                  opacity: _canPlay ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 300),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canPlay ? _startGame : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _modeColor,
                        disabledBackgroundColor: _modeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 12,
                        shadowColor: _modeColor.withAlpha(150),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_modeEmoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Text('Spin the $_modeLabel Wheel!',
                            style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
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
          Text('$_modeEmoji $_modeLabel Setup',
            style: GoogleFonts.fredoka(fontSize: 20, color: _modeColor, fontWeight: FontWeight.bold)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _modeColor.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _modeColor.withAlpha(120)),
            ),
            child: Text('Min 2 · Max 8', style: GoogleFonts.nunito(fontSize: 11, color: _modeColor)),
          ),
        ],
      ),
    );
  }
}

// ─── Item List Widget ─────────────────────────────────────────────────────────

class _ItemList extends StatelessWidget {
  final List<String> items;
  final bool isTruth;
  final Color color;
  final TextEditingController controller;
  final void Function(String) onAdd;
  final void Function(int) onRemove;
  final VoidCallback onReset;

  const _ItemList({
    required this.items, required this.isTruth, required this.color,
    required this.controller, required this.onAdd, required this.onRemove, required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Add field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(13),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withAlpha(120)),
                  ),
                  child: TextField(
                    controller: controller,
                    style: GoogleFonts.nunito(color: Colors.white, fontSize: 14),
                    maxLength: 80,
                    decoration: InputDecoration(
                      hintText: isTruth ? 'Add a truth question...' : 'Add a dare challenge...',
                      hintStyle: GoogleFonts.nunito(color: Colors.white38, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      counterText: '',
                    ),
                    onSubmitted: onAdd,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => onAdd(controller.text),
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: color.withAlpha(100), blurRadius: 10, offset: const Offset(0,4))]),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                ),
              ),
            ],
          ),
        ),
        // Count + reset
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Text('${items.length}/8 items',
                style: GoogleFonts.nunito(fontSize: 12, color: Colors.white54)),
              const Spacer(),
              GestureDetector(
                onTap: onReset,
                child: Text('Reset to defaults',
                  style: GoogleFonts.nunito(fontSize: 12, color: color, decoration: TextDecoration.underline, decorationColor: color)),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            itemBuilder: (_, i) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withAlpha(80)),
              ),
              child: Row(
                children: [
                  Text(isTruth ? '🤔' : '😈', style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(items[i],
                    style: GoogleFonts.nunito(fontSize: 14, color: Colors.white, height: 1.4))),
                  GestureDetector(
                    onTap: () => onRemove(i),
                    child: Icon(Icons.close_rounded, color: Colors.white38, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
