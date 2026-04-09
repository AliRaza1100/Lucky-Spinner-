import 'package:shared_preferences/shared_preferences.dart';

class PrefsHelper {
  // ── Keys ──────────────────────────────────────────────────────────────────
  static const _keyPoints         = 'points';
  static const _keyUnlockedThemes = 'unlocked_themes';
  static const _keyEquippedTheme  = 'equipped_theme';
  static const _keyOnboardingDone = 'onboarding_done';
  static const _keyUnlockedCats   = 'unlocked_categories';
  // Truth & Dare
  static const _keyTdTheme        = 'td_equipped_theme';
  static const _keyTdUnlocked     = 'td_unlocked_themes';
  static const _keyTdTruths       = 'td_truths';
  static const _keyTdDares        = 'td_dares';

  // ── Shared Points (both games share one wallet) ───────────────────────────
  static Future<int> getPoints() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_keyPoints) ?? 0;
  }

  static Future<void> addPoints(int pts) async {
    final p = await SharedPreferences.getInstance();
    final cur = p.getInt(_keyPoints) ?? 0;
    await p.setInt(_keyPoints, (cur + pts).clamp(0, 999999));
  }

  // ── Spinner Themes ────────────────────────────────────────────────────────
  static Future<List<String>> getUnlockedThemes() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_keyUnlockedThemes) ?? ['classic'];
  }

  static Future<void> unlockTheme(String id) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_keyUnlockedThemes) ?? ['classic'];
    if (!list.contains(id)) { list.add(id); await p.setStringList(_keyUnlockedThemes, list); }
  }

  static Future<String> getEquippedTheme() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyEquippedTheme) ?? 'classic';
  }

  static Future<void> setEquippedTheme(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyEquippedTheme, id);
  }

  // ── Spinner Categories ────────────────────────────────────────────────────
  static Future<List<String>> getUnlockedCategories() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_keyUnlockedCats) ?? ['fruits', 'animals'];
  }

  static Future<void> unlockCategory(String id) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_keyUnlockedCats) ?? ['fruits', 'animals'];
    if (!list.contains(id)) { list.add(id); await p.setStringList(_keyUnlockedCats, list); }
  }

  // ── Truth & Dare Themes ───────────────────────────────────────────────────
  static Future<String> getTdEquippedTheme() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyTdTheme) ?? 'classic';
  }

  static Future<void> setTdEquippedTheme(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyTdTheme, id);
  }

  static Future<List<String>> getTdUnlockedThemes() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_keyTdUnlocked) ?? ['classic'];
  }

  static Future<void> unlockTdTheme(String id) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_keyTdUnlocked) ?? ['classic'];
    if (!list.contains(id)) { list.add(id); await p.setStringList(_keyTdUnlocked, list); }
  }

  // ── Truth & Dare Custom Questions ─────────────────────────────────────────
  static Future<List<String>> getTruths() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_keyTdTruths) ?? [];
  }

  static Future<void> saveTruths(List<String> truths) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_keyTdTruths, truths);
  }

  static Future<List<String>> getDares() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_keyTdDares) ?? [];
  }

  static Future<void> saveDares(List<String> dares) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_keyTdDares, dares);
  }

  // ── Onboarding ────────────────────────────────────────────────────────────
  static Future<bool> isOnboardingDone() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keyOnboardingDone) ?? false;
  }

  static Future<void> setOnboardingDone() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyOnboardingDone, true);
  }
}
