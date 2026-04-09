import 'dart:math';

class Category {
  final String id;
  final String name;
  final String emoji;
  final int unlockCost; // 0 = free
  final List<Option> options;

  const Category({
    required this.id,
    required this.name,
    required this.emoji,
    required this.unlockCost,
    required this.options,
  });
}

class Option {
  final String name;
  final String emoji;
  const Option({required this.name, required this.emoji});
}

class WheelTheme {
  final String id;
  final String name;
  final int requiredPoints;
  final String emoji;
  const WheelTheme({
    required this.id,
    required this.name,
    required this.requiredPoints,
    required this.emoji,
  });
}

class GameData {
  // ── Free categories ──────────────────────────────────────────────────────
  static const List<Category> freeCategories = [
    Category(
      id: 'fruits',
      name: 'Fruits',
      emoji: '🍎',
      unlockCost: 0,
      options: [
        Option(name: 'Apple',      emoji: '�'),
        Option(name: 'Mango',      emoji: '�'),
        Option(name: 'Banana',     emoji: '🍌'),
        Option(name: 'Orange',     emoji: '🍊'),
        Option(name: 'Grapes',     emoji: '🍇'),
        Option(name: 'Watermelon', emoji: '🍉'),
        Option(name: 'Strawberry', emoji: '🍓'),
        Option(name: 'Pineapple',  emoji: '🍍'),
      ],
    ),
    Category(
      id: 'animals',
      name: 'Animals',
      emoji: '🦁',
      unlockCost: 0,
      options: [
        Option(name: 'Lion',     emoji: '🦁'),
        Option(name: 'Dog',      emoji: '🐶'),
        Option(name: 'Cat',      emoji: '🐱'),
        Option(name: 'Elephant', emoji: '🐘'),
        Option(name: 'Monkey',   emoji: '🐵'),
        Option(name: 'Tiger',    emoji: '🐯'),
        Option(name: 'Rabbit',   emoji: '🐰'),
        Option(name: 'Panda',    emoji: '🐼'),
      ],
    ),
  ];

  // ── Unlockable categories (shop) ─────────────────────────────────────────
  static const List<Category> shopCategories = [
    Category(
      id: 'sports',
      name: 'Sports',
      emoji: '⚽',
      unlockCost: 150,
      options: [
        Option(name: 'Soccer',    emoji: '⚽'),
        Option(name: 'Basketball',emoji: '🏀'),
        Option(name: 'Tennis',    emoji: '🎾'),
        Option(name: 'Baseball',  emoji: '⚾'),
        Option(name: 'Football',  emoji: '🏈'),
        Option(name: 'Volleyball',emoji: '🏐'),
        Option(name: 'Golf',      emoji: '⛳'),
        Option(name: 'Swimming',  emoji: '🏊'),
      ],
    ),
    Category(
      id: 'food',
      name: 'Fast Food',
      emoji: '🍕',
      unlockCost: 300,
      options: [
        Option(name: 'Pizza',   emoji: '🍕'),
        Option(name: 'Burger',  emoji: '🍔'),
        Option(name: 'Tacos',   emoji: '🌮'),
        Option(name: 'Sushi',   emoji: '🍣'),
        Option(name: 'Ramen',   emoji: '🍜'),
        Option(name: 'Hotdog',  emoji: '🌭'),
        Option(name: 'Fries',   emoji: '🍟'),
        Option(name: 'Donut',   emoji: '🍩'),
      ],
    ),
    Category(
      id: 'space',
      name: 'Space',
      emoji: '🚀',
      unlockCost: 500,
      options: [
        Option(name: 'Rocket',  emoji: '🚀'),
        Option(name: 'Planet',  emoji: '🪐'),
        Option(name: 'Star',    emoji: '⭐'),
        Option(name: 'Moon',    emoji: '🌙'),
        Option(name: 'Comet',   emoji: '☄️'),
        Option(name: 'Galaxy',  emoji: '🌌'),
        Option(name: 'UFO',     emoji: '🛸'),
        Option(name: 'Alien',   emoji: '👽'),
      ],
    ),
    Category(
      id: 'weather',
      name: 'Weather',
      emoji: '⛅',
      unlockCost: 400,
      options: [
        Option(name: 'Sunny',    emoji: '☀️'),
        Option(name: 'Rainy',    emoji: '🌧️'),
        Option(name: 'Snowy',    emoji: '❄️'),
        Option(name: 'Stormy',   emoji: '⛈️'),
        Option(name: 'Windy',    emoji: '💨'),
        Option(name: 'Rainbow',  emoji: '🌈'),
        Option(name: 'Cloudy',   emoji: '☁️'),
        Option(name: 'Foggy',    emoji: '🌫️'),
      ],
    ),
    Category(
      id: 'gems',
      name: 'Gems',
      emoji: '💎',
      unlockCost: 750,
      options: [
        Option(name: 'Diamond',  emoji: '💎'),
        Option(name: 'Ruby',     emoji: '❤️'),
        Option(name: 'Emerald',  emoji: '💚'),
        Option(name: 'Sapphire', emoji: '💙'),
        Option(name: 'Gold',     emoji: '🥇'),
        Option(name: 'Crystal',  emoji: '🔮'),
        Option(name: 'Pearl',    emoji: '🫧'),
        Option(name: 'Topaz',    emoji: '🟡'),
      ],
    ),
  ];

  static List<Category> get allCategories => [...freeCategories, ...shopCategories];

  // ── Wheel themes (15 total) ───────────────────────────────────────────────
  static const List<WheelTheme> themes = [
    WheelTheme(id: 'classic',   name: 'Classic',      requiredPoints: 0,    emoji: '🎡'),
    WheelTheme(id: 'jungle',    name: 'Jungle',        requiredPoints: 200,  emoji: '🌿'),
    WheelTheme(id: 'neon',      name: 'Neon',          requiredPoints: 350,  emoji: '⚡'),
    WheelTheme(id: 'galaxy',    name: 'Galaxy',        requiredPoints: 500,  emoji: '🌌'),
    WheelTheme(id: 'candy',     name: 'Candy',         requiredPoints: 400,  emoji: '🍭'),
    WheelTheme(id: 'ocean',     name: 'Ocean',         requiredPoints: 300,  emoji: '🌊'),
    WheelTheme(id: 'fire',      name: 'Fire',          requiredPoints: 450,  emoji: '🔥'),
    WheelTheme(id: 'ice',       name: 'Ice',           requiredPoints: 550,  emoji: '❄️'),
    WheelTheme(id: 'sunset',    name: 'Sunset',        requiredPoints: 600,  emoji: '🌅'),
    WheelTheme(id: 'forest',    name: 'Forest',        requiredPoints: 650,  emoji: '🌲'),
    WheelTheme(id: 'royal',     name: 'Royal Gold',    requiredPoints: 800,  emoji: '👑'),
    WheelTheme(id: 'retro',     name: 'Retro',         requiredPoints: 700,  emoji: '🕹️'),
    WheelTheme(id: 'pastel',    name: 'Pastel Dream',  requiredPoints: 750,  emoji: '🌸'),
    WheelTheme(id: 'lava',      name: 'Lava',          requiredPoints: 900,  emoji: '🌋'),
    WheelTheme(id: 'aurora',    name: 'Aurora',        requiredPoints: 1000, emoji: '🌠'),
  ];

  static int getRewardPoints() {
    final roll = Random().nextInt(10);
    if (roll < 5) return 20;   // Small  (50%)
    if (roll < 8) return 50;   // Medium (30%)
    return 100;                 // Jackpot(20%)
  }
}
