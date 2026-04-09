import 'dart:math';

// Shared enum — imported by all T&D screens
enum TdMode { truth, dare, mixed }

class TdTheme {
  final String id, name, emoji;
  final int requiredPoints;
  const TdTheme({required this.id, required this.name, required this.emoji, required this.requiredPoints});
}

class TdData {
  static const List<TdTheme> themes = [
    TdTheme(id: 'classic',  name: 'Classic',      emoji: '🎭', requiredPoints: 0),
    TdTheme(id: 'fire',     name: 'Fire',          emoji: '🔥', requiredPoints: 200),
    TdTheme(id: 'neon',     name: 'Neon',          emoji: '⚡', requiredPoints: 350),
    TdTheme(id: 'galaxy',   name: 'Galaxy',        emoji: '🌌', requiredPoints: 500),
    TdTheme(id: 'candy',    name: 'Candy',         emoji: '🍭', requiredPoints: 400),
    TdTheme(id: 'ocean',    name: 'Ocean',         emoji: '🌊', requiredPoints: 300),
    TdTheme(id: 'royal',    name: 'Royal Gold',    emoji: '👑', requiredPoints: 600),
    TdTheme(id: 'pastel',   name: 'Pastel Dream',  emoji: '🌸', requiredPoints: 450),
    TdTheme(id: 'aurora',   name: 'Aurora',        emoji: '🌠', requiredPoints: 800),
    TdTheme(id: 'retro',    name: 'Retro',         emoji: '🕹️', requiredPoints: 700),
  ];

  // Default truths shown when user hasn't added any
  static const List<String> defaultTruths = [
    'What is your biggest fear?',
    'What is the most embarrassing thing you have done?',
    'Who was your first crush?',
    'What is your biggest secret?',
    'Have you ever lied to your best friend?',
    'What is the weirdest dream you have had?',
    'What is something you have never told anyone?',
    'What is your most embarrassing moment?',
  ];

  // Default dares shown when user hasn't added any
  static const List<String> defaultDares = [
    'Do 20 push-ups right now!',
    'Sing a song out loud for 30 seconds',
    'Do your best dance move',
    'Speak in an accent for the next 2 minutes',
    'Do a handstand or try to',
    'Say the alphabet backwards',
    'Do your best celebrity impression',
    'Tell a joke and make everyone laugh',
  ];

  static int getRewardPoints() {
    final roll = Random().nextInt(10);
    if (roll < 5) return 15;
    if (roll < 8) return 30;
    return 75;
  }
}
