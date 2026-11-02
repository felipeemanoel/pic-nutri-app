/// Subáreas para o diário visual. A API mantém a região; o detalhe acompanha
/// as observações para sobreviver à sincronização sem novos códigos de região.
abstract final class InjectionLocation {
  static final labels = <String, String>{
    'abdomen_left_upper': 'Abdome esquerdo superior',
    'abdomen_left_lower': 'Abdome esquerdo inferior',
    'abdomen_right_upper': 'Abdome direito superior',
    'abdomen_right_lower': 'Abdome direito inferior',
    for (final region in const {
      'abdomen_left': 'Abdome esquerdo',
      'abdomen_right': 'Abdome direito',
      'thigh_left': 'Coxa esquerda',
      'thigh_right': 'Coxa direita',
      'arm_left': 'Braço esquerdo',
      'arm_right': 'Braço direito',
      'upper_arm_left': 'Braço esquerdo',
      'upper_arm_right': 'Braço direito',
    }.entries)
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 3; col++)
          '${region.key}_p$row$col':
              '${region.value} · ${['superior', 'meio', 'inferior'][row]} · posição ${col + 1}',
  };
  static final _line = RegExp(
    r'^Local no mapa: ((?:abdomen|thigh|arm|upper_arm)_(?:left|right)_(?:upper|lower|p[0-2][0-2]))\.$',
    multiLine: true,
  );

  static String region(String point) => labels.containsKey(point)
      ? point.replaceFirst(RegExp(r'_(upper|lower|p[0-2][0-2])$'), '')
      : point;

  static String? point(String? notes) =>
      _line.firstMatch(notes ?? '')?.group(1);

  static String cleanNotes(String? notes) =>
      (notes ?? '').replaceAll(_line, '').trim();

  static String? encode(String? notes, String? point) {
    final text = cleanNotes(notes);
    final parts = [
      if (text.isNotEmpty) text,
      if (labels.containsKey(point)) 'Local no mapa: $point.',
    ];
    return parts.isEmpty ? null : parts.join('\n');
  }
}
