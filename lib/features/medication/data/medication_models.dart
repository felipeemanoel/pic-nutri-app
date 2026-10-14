import '../../../core/utils/formatters.dart';

/// Opção com rótulo vinda da API (formas, unidades, sintomas...).
class Option {
  const Option(this.value, this.label);

  factory Option.fromJson(Map<String, dynamic> json) =>
      Option('${json['value']}', json['label'] as String);

  final String value;
  final String label;
}

class MedicationOptions {
  const MedicationOptions({
    required this.forms,
    required this.doseUnits,
    required this.frequencies,
    required this.injectionSites,
    required this.symptoms,
    required this.intensities,
    required this.disclaimer,
  });

  factory MedicationOptions.fromJson(Map<String, dynamic> json) {
    List<Option> list(String key) => (json[key] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(Option.fromJson)
        .toList();
    return MedicationOptions(
      forms: list('forms'),
      doseUnits: list('dose_units'),
      frequencies: list('frequencies'),
      injectionSites: list('injection_sites'),
      symptoms: list('symptoms'),
      intensities: list('intensities'),
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }

  final List<Option> forms;
  final List<Option> doseUnits;
  final List<Option> frequencies;
  final List<Option> injectionSites;
  final List<Option> symptoms;
  final List<Option> intensities;
  final String disclaimer;

  String label(List<Option> options, String? value) => value == null
      ? ''
      : options.where((o) => o.value == value).firstOrNull?.label ?? value;
}

class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.form,
    required this.doseUnit,
    required this.frequency,
    required this.isActive,
    this.notes,
    this.lastDoseAt,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    final last = json['last_dose'] as Map<String, dynamic>?;
    return Medication(
      id: json['id'] as String,
      name: json['name'] as String,
      form: json['form'] as String,
      doseUnit: json['dose_unit'] as String,
      frequency: json['frequency'] as String,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      lastDoseAt: last == null
          ? null
          : DateTime.parse(last['taken_at'] as String).toLocal(),
    );
  }

  final String id;
  final String name;
  final String form;
  final String doseUnit;
  final String frequency;
  final String? notes;
  final bool isActive;
  final DateTime? lastDoseAt;

  bool get isInjection => form == 'injection';
}

class SymptomEntry {
  const SymptomEntry({required this.code, required this.intensity, this.label});

  factory SymptomEntry.fromJson(Map<String, dynamic> json) => SymptomEntry(
    code: json['code'] as String,
    label: json['label'] as String?,
    intensity: toInt(json['intensity']) ?? 1,
  );

  final String code;
  final String? label;

  /// 1 = leve, 2 = moderada, 3 = forte.
  final int intensity;

  Map<String, Object> toJson() => {'code': code, 'intensity': intensity};
}

class MedicationDose {
  const MedicationDose({
    required this.id,
    required this.medicationId,
    required this.takenAt,
    required this.localDate,
    required this.doseUnit,
    required this.symptoms,
    this.medicationName,
    this.doseAmount,
    this.injectionSite,
    this.notes,
  });

  factory MedicationDose.fromJson(Map<String, dynamic> json) => MedicationDose(
    id: json['id'] as String,
    medicationId: json['medication_id'] as String,
    medicationName: json['medication_name'] as String?,
    takenAt: DateTime.parse(json['taken_at'] as String).toLocal(),
    localDate: json['local_date'] as String,
    doseAmount: toDouble(json['dose_amount']),
    doseUnit: json['dose_unit'] as String,
    injectionSite: json['injection_site'] as String?,
    symptoms: (json['symptoms'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(SymptomEntry.fromJson)
        .toList(),
    notes: json['notes'] as String?,
  );

  final String id;
  final String medicationId;
  final String? medicationName;
  final DateTime takenAt;
  final String localDate;
  final double? doseAmount;
  final String doseUnit;
  final String? injectionSite;
  final List<SymptomEntry> symptoms;
  final String? notes;
}

/// Resposta de gravação de aplicação com o alerta opcional de sintoma forte.
class SavedDose {
  const SavedDose(this.dose, this.alert);

  final MedicationDose dose;
  final String? alert;
}
