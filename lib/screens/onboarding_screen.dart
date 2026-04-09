import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/prefs_helper.dart';
import 'app_selector_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_PageData> _pages = [
    _PageData(
      emoji: '🎰',
      title: 'Lucky Spinner Wheel',
      description: 'Pick a category, choose your item, spin the wheel and win reward points!',
      bgColors: [Color(0xFF1A1A2E), Color(0xFF0F3460)],
      accentColor: Color(0xFFFFD700),
      icons: ['🍎', '🥭', '🦁', '🐶', '🍌'],
    ),
    _PageData(
      emoji: '🎭',
      title: 'Truth or Dare',
      description: 'Add your own truths and dares, spin the wheel and let the fun begin!',
      bgColors: [Color(0xFF1A0533), Color(0xFF2D0B5E)],
      accentColor: Color(0xFF9C6FFF),
      icons: ['🤔', '😈', '🎲', '😂', '🔥'],
    ),
    _PageData(
      emoji: '🏆',
      title: 'Win & Unlock',
      description: 'Earn points by playing both games. Unlock new wheel themes and categories in the Shop!',
      bgColors: [Color(0xFF0F3460), Color(0xFF1A1A2E)],
      accentColor: Color(0xFF00E676),
      icons: ['⭐', '🎁', '💎', '🛍️', '🎊'],
    ),
  ];

  void _goNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await PrefsHelper.setOnboardingDone();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AppSelectorScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() { _pageController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _OnboardingPage(data: _pages[i]),
          ),
          Positioned(
            bottom: 120, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == i ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == i ? _pages[_currentPage].accentColor : Colors.white38,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
          ),
          Positioned(
            bottom: 40, left: 24, right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _finish(),
                  child: Text('Skip', style: GoogleFonts.fredoka(color: Colors.white54, fontSize: 16)),
                ),
                ElevatedButton(
                  onPressed: _goNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pages[_currentPage].accentColor,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 8,
                    shadowColor: _pages[_currentPage].accentColor.withAlpha(128),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? "Let's Play!" : 'Next →',
                    style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageData {
  final String emoji, title, description;
  final List<Color> bgColors;
  final Color accentColor;
  final List<String> icons;
  const _PageData({required this.emoji, required this.title, required this.description,
    required this.bgColors, required this.accentColor, required this.icons});
}

class _OnboardingPage extends StatefulWidget {
  final _PageData data;
  const _OnboardingPage({required this.data});
  @override
  State<_OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<_OnboardingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _bounce = Tween<double>(begin: -10, end: 10).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: widget.data.bgColors),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 230,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ...List.generate(widget.data.icons.length, (i) => AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(
                        80 * (i % 2 == 0 ? 1 : -1) * (i < 3 ? 0.8 : 1.2),
                        _bounce.value * (i % 2 == 0 ? 1 : -1) + (i < 3 ? -50 : 50),
                      ),
                      child: Text(widget.data.icons[i], style: TextStyle(fontSize: 28 + (i % 2) * 8.0)),
                    ),
                  )),
                  AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, _bounce.value * 0.4),
                      child: Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          color: widget.data.accentColor.withAlpha(30),
                          shape: BoxShape.circle,
                          border: Border.all(color: widget.data.accentColor, width: 3),
                          boxShadow: [BoxShadow(color: widget.data.accentColor.withAlpha(100), blurRadius: 28, spreadRadius: 4)],
                        ),
                        child: Center(child: Text(widget.data.emoji, style: const TextStyle(fontSize: 56))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(widget.data.title, textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(fontSize: 32, fontWeight: FontWeight.bold, color: widget.data.accentColor)),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(widget.data.description, textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 15, color: AppColors.textLight, height: 1.6)),
            ),
          ],
        ),
      ),
    );
  }
}
