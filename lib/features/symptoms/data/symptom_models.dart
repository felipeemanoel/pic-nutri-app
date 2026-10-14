import '../../../core/utils/formatters.dart';

typedef Option = ({String value, String label});

List<Option> _options(Object? raw) => [
  for (final o in (raw as List<dynamic>? ?? const []).cast<Map<String, dynamic>>())
    (value: '${o['value']}', label: o['label'] as String),
];

class SymptomOptions {
  const SymptomOptions({
    required this.symptoms,
    required this.intensities,
    required this.contexts,
    required this.warningSigns,
    required this.disclaimer,
  });

  factory SymptomOptions.fromJson(Map<String, dynamic> json) => SymptomOptions(
    symptoms: _options(json['symptoms']),
    intensities: _options(json['intensities']),
    contexts: _options(json['contexts']),
    warningSigns: _options(json['warning_signs']),
    disclaimer: json['disclaimer'] as String? ?? '',
  );

  final List<Option> symptoms;
  final List<Option> intensities;
  final List<Option> contexts;
  final List<Option> warningSigns;
  final String disclaimer;
}

/// Item da linha do tempo (registro independente ou anotado na aplicação).
class SymptomItem {
  const SymptomItem({
    required this.id,
    required this.source,
    required this.label,
    required this.intensity,
    required this.intensityLabel,
    required this.occurredAt,
    this.contextLabel,
    this.notes,
    this.warningSigns = const [],
    this.nearby = const [],
  });

  factory SymptomItem.fromJson(Map<String, dynamic> json) => SymptomItem(
    id: json['id'] as String,
    source: json['source'] as String? ?? 'entry',
    label: json['label'] as String? ?? '',
    intensity: toInt(json['intensity']) ?? 1,
    intensityLabel: json['intensity_label'] as String? ?? '',
    occurredAt: DateTime.parse(json['occurred_at'] as String).toLocal(),
    contextLabel: json['context_label'] as String?,
    notes: json['notes'] as String?,
    warningSigns: (json['warning_signs'] as List<dynamic>? ?? const []).whereType<String>().toList(),
    nearby: (json['nearby'] as List<dynamic>? ?? const []).whereType<String>().toList(),
  );

  final String id;

  /// entry (registro próprio) ou medication_dose (anotado na aplicação).
  final String source;
  final String label;
  final int intensity;
  final String intensityLabel;
  final DateTime occurredAt;
  final String? contextLabel;
  final String? notes;
  final List<String> warningSigns;

  /// Eventos próximos no tempo (fatos, sem indicar causa).
  final List<String> nearby;

  bool get editable => source == 'entry';
}

class SymptomTimeline {
  const SymptomTimeline({required this.items, required this.nearbyNote});

  final List<SymptomItem> items;
  final String nearbyNote;
}

/// Orientação de segurança devolvida ao registrar (sem diagnóstico).
class SafetyAlert {
  const SafetyAlert({required this.level, required this.title, required this.message, required this.article});

  factory SafetyAlert.fromJson(Map<String, dynamic> json) => SafetyAlert(
    level: json['level'] as String? ?? 'advice',
    title: json['title'] as String? ?? '',
    message: json['message'] as String? ?? '',
    article: json['article'] as String? ?? '',
  );

  /// urgent (sinais de alerta) ou advice (sintoma forte).
  final String level;
  final String title;
  final String message;

  /// Artigo da central de ajuda com mais orientações.
  final String article;

  bool get urgent => level == 'urgent';
}
