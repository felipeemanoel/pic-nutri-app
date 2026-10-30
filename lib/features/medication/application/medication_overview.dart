import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/medication_models.dart';
import '../data/medication_repository.dart';
import '../domain/medication_schedule.dart';

/// Resumo do tratamento em destaque: próxima aplicação, última dose e o
/// nível estimado (quando o princípio ativo é reconhecido).
class MedicationOverview {
  const MedicationOverview({
    required this.medication,
    required this.doses,
    this.lastDose,
    this.level,
  });

  final Medication medication;

  /// Aplicações deste medicamento nos últimos 90 dias (mais antigas primeiro).
  final List<MedicationDose> doses;
  final MedicationDose? lastDose;

  /// Nulo quando o princípio ativo não é reconhecido ou não há dose em mg.
  final MedicationLevel? level;

  Duration? get interval => MedicationSchedule.interval(medication);
  DateTime? get nextDoseAt => MedicationSchedule.nextDoseAt(medication);
  DateTime? get lastDoseAt => lastDose?.takenAt ?? medication.lastDoseAt;
}

final medicationOverviewProvider = FutureProvider<MedicationOverview?>((
  ref,
) async {
  final medications = await ref.watch(medicationsProvider.future);
  final primary = MedicationSchedule.primary(medications);
  if (primary == null) return null;
  var doses = const <MedicationDose>[];
  try {
    doses =
        (await ref.watch(
            recentDosesProvider.future,
          )).where((d) => d.medicationId == primary.id).toList()
          ..sort((a, b) => a.takenAt.compareTo(b.takenAt));
  } on Object {
    // Sem o histórico, o cartão mostra só a próxima aplicação.
  }
  final ingredient = ActiveIngredient.of(primary);
  final level = ingredient == null
      ? null
      : MedicationLevel(ingredient: ingredient, doses: doses);
  return MedicationOverview(
    medication: primary,
    doses: doses,
    lastDose: doses.isEmpty ? null : doses.last,
    level: level == null || level.isEmpty ? null : level,
  );
});
