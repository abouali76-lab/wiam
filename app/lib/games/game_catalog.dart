import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/bubble_pop_game.dart';
import '../widgets/feelings_game.dart';
import '../widgets/handwash_game.dart';
import '../widgets/healthy_food_game.dart';
import '../widgets/market_game.dart';
import '../widgets/memory_match_game.dart';
import '../widgets/star_catch_game.dart';
import '../widgets/traffic_light_game.dart';
import '../widgets/waste_sort_game.dart';

/// One educational mini-game. The same catalog backs both free play (the
/// reward the child spends earned minutes on) and task activities (a
/// digital task the parent bound to a specific game), so a game only has
/// to be described once.
class GameInfo {
  /// Stable id — persisted in level progress and in Task.gameId on the
  /// server, so these strings must not change.
  final String id;
  final String label;

  /// What the game actually teaches, shown to both parent and child.
  final String tag;
  final IconData icon;
  final Color color;

  const GameInfo({
    required this.id,
    required this.label,
    required this.tag,
    required this.icon,
    required this.color,
  });

  Widget build({Key? key, required int level, required VoidCallback onComplete}) {
    switch (id) {
      case 'memory':
        return MemoryMatchGame(key: key, level: level, onLevelComplete: onComplete);
      case 'stars':
        return StarCatchGame(key: key, level: level, onLevelComplete: onComplete);
      case 'bubbles':
        return BubblePopGame(key: key, level: level, onLevelComplete: onComplete);
      case 'food':
        return HealthyFoodGame(key: key, level: level, onLevelComplete: onComplete);
      case 'handwash':
        return HandwashGame(key: key, level: level, onLevelComplete: onComplete);
      case 'traffic':
        return TrafficLightGame(key: key, level: level, onLevelComplete: onComplete);
      case 'waste':
        return WasteSortGame(key: key, level: level, onLevelComplete: onComplete);
      case 'feelings':
        return FeelingsGame(key: key, level: level, onLevelComplete: onComplete);
      case 'market':
        return MarketGame(key: key, level: level, onLevelComplete: onComplete);
      default:
        return const SizedBox.shrink();
    }
  }
}

const kGames = <GameInfo>[
  GameInfo(id: 'memory', label: 'الذاكرة', tag: 'تركيز', icon: Icons.grid_view_rounded, color: Color(0xFF7B6BC4)),
  GameInfo(id: 'stars', label: 'التقاط النجوم', tag: 'تناسق حركي', icon: Icons.star_rounded, color: Color(0xFFE0A93F)),
  GameInfo(id: 'bubbles', label: 'الفقاعات', tag: 'سرعة بديهة', icon: Icons.bubble_chart_rounded, color: Color(0xFF4E9FC4)),
  GameInfo(id: 'food', label: 'الغذاء الصحي', tag: 'تغذية', icon: Icons.restaurant_menu, color: Color(0xFF5FAE72)),
  GameInfo(id: 'handwash', label: 'نظّف يديك', tag: 'نظافة', icon: Icons.clean_hands, color: Color(0xFF4EAFA8)),
  GameInfo(id: 'traffic', label: 'إشارة المرور', tag: 'سلامة', icon: Icons.traffic, color: Color(0xFFD9645A)),
  GameInfo(id: 'waste', label: 'فرز النفايات', tag: 'بيئة', icon: Icons.recycling_rounded, color: Color(0xFF5B8FD1)),
  GameInfo(id: 'feelings', label: 'دائرة المشاعر', tag: 'مشاعر', icon: Icons.favorite_rounded, color: Color(0xFFD97BA0)),
  GameInfo(id: 'market', label: 'سوق المعرفة', tag: 'حساب', icon: Icons.storefront_rounded, color: Color(0xFFDE9142)),
];

GameInfo? gameById(String? id) {
  if (id == null) return null;
  for (final g in kGames) {
    if (g.id == id) return g;
  }
  return null;
}

/// Ids used by Storage.clearAllLevelProgress and by the server's allowlist.
List<String> get kGameIds => [for (final g in kGames) g.id];

/// Shared frame so a game looks the same whether it is free play or a task.
BoxDecoration gameFrame(Color color) => BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: color.withValues(alpha: 0.55), width: 2),
      color: WiamColors.bg1.withValues(alpha: 0.5),
    );
