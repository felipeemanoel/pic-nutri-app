import 'package:flutter/material.dart';

/// Ícone e cor de cada modalidade (apoio visual: o nome sempre aparece).
abstract final class ActivityVisuals {
  static IconData icon(String type) => switch (type) {
    'strength' => Icons.fitness_center_rounded,
    'running' => Icons.directions_run_rounded,
    'walking' => Icons.directions_walk_rounded,
    'cycling' => Icons.directions_bike_rounded,
    'swimming' => Icons.pool_rounded,
    'functional' => Icons.sports_gymnastics_rounded,
    'yoga_pilates' => Icons.self_improvement_rounded,
    'dance' => Icons.music_note_rounded,
    'team_sport' => Icons.sports_soccer_rounded,
    'racket' => Icons.sports_tennis_rounded,
    'martial_arts' => Icons.sports_martial_arts_rounded,
    _ => Icons.bolt_rounded,
  };

  static Color color(String type) => switch (type) {
    'strength' => const Color(0xFF5B6CE0),
    'running' => const Color(0xFFE0703A),
    'walking' => const Color(0xFF2E9D6A),
    'cycling' => const Color(0xFF2B8FC4),
    'swimming' => const Color(0xFF1E9BB0),
    'functional' => const Color(0xFFD1495B),
    'yoga_pilates' => const Color(0xFF9C6ADE),
    'dance' => const Color(0xFFDB5C9B),
    'team_sport' => const Color(0xFF3C9A3C),
    'racket' => const Color(0xFFB7952B),
    'martial_arts' => const Color(0xFF8C5A3C),
    _ => const Color(0xFF6B7A75),
  };

  /// Rótulos curtos dos dias (1 = segunda ... 7 = domingo).
  static const weekdaysShort = {
    1: 'S',
    2: 'T',
    3: 'Q',
    4: 'Q',
    5: 'S',
    6: 'S',
    7: 'D',
  };

  static const weekdays = {
    1: 'Seg',
    2: 'Ter',
    3: 'Qua',
    4: 'Qui',
    5: 'Sex',
    6: 'Sáb',
    7: 'Dom',
  };

  static const weekdaysLong = {
    1: 'segunda',
    2: 'terça',
    3: 'quarta',
    4: 'quinta',
    5: 'sexta',
    6: 'sábado',
    7: 'domingo',
  };
}
