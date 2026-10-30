import 'dart:math' as math;

import '../data/medication_catalog.dart';
import '../data/medication_models.dart';

/// Calendário e nível estimado das aplicações, calculados no aparelho a partir
/// do que a pessoa registrou. É informativo: não sugere doses nem horários
/// além do intervalo que ela mesma informou no cadastro.
abstract final class MedicationSchedule {
  /// Intervalo entre aplicações pela frequência cadastrada. "Outro" só é
  /// reconhecido pelas observações que o onboarding grava
  /// ("A cada duas semanas", "Uma vez por mês").
  static Duration? interval(Medication m) {
    switch (m.frequency) {
      case 'daily':
        return const Duration(days: 1);
      case 'weekly':
        return const Duration(days: 7);
    }
    final notes = (m.notes ?? '').toLowerCase();
    if (notes.contains('duas semanas')) return const Duration(days: 14);
    if (notes.contains('por mês') || notes.contains('mensal')) {
      return const Duration(days: 30);
    }
    return null;
  }

  /// Próxima aplicação prevista: última registrada + intervalo.
  static DateTime? nextDoseAt(Medication m) {
    final last = m.lastDoseAt;
    final every = interval(m);
    if (last == null || every == null) return null;
    return last.add(every);
  }

  /// Fração do ciclo atual já percorrida (0 a 1; acima de 1 = passou da data).
  static double? cycleProgress(Medication m, DateTime now) {
    final last = m.lastDoseAt;
    final every = interval(m);
    if (last == null || every == null) return null;
    return now.difference(last).inMinutes / every.inMinutes;
  }

  /// Medicamento em destaque: o ativo com a aplicação mais recente,
  /// preferindo os injetáveis.
  static Medication? primary(List<Medication> medications) {
    final active = medications.where((m) => m.isActive).toList();
    if (active.isEmpty) return null;
    int score(Medication m) =>
        (m.isInjection ? 1 << 40 : 0) +
        (m.lastDoseAt?.millisecondsSinceEpoch ?? 0) ~/ 1000;
    active.sort((a, b) => score(b).compareTo(score(a)));
    return active.first;
  }

  /// Texto curto do tempo até a próxima aplicação: "2d 4h", "5h 12min", "12min".
  static String countdown(Duration d) {
    final minutes = d.inMinutes;
    if (minutes < 1) return 'agora';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = minutes % 60;
    if (days > 0) return hours > 0 ? '${days}d ${hours}h' : '${days}d';
    if (d.inHours > 0) {
      return mins > 0 ? '${d.inHours}h ${mins}min' : '${d.inHours}h';
    }
    return '${mins}min';
  }
}

/// Princípio ativo reconhecido pelo nome, com a meia-vida de eliminação
/// informada em bula. Só os de uso semanal entram no gráfico: nos diários a
/// curva sobe e desce todo dia e não ajuda a leitura.
class ActiveIngredient {
  const ActiveIngredient(this.name, this.halfLife);

  final String name;
  final Duration halfLife;

  static const tirzepatide = ActiveIngredient(
    'tirzepatida',
    Duration(hours: 120),
  );
  static const semaglutide = ActiveIngredient(
    'semaglutida',
    Duration(hours: 168),
  );
  static const dulaglutide = ActiveIngredient(
    'dulaglutida',
    Duration(hours: 113),
  );

  /// Injetáveis semanais reconhecidos pela marca do catálogo (inclusive as
  /// outras canetas de tirzepatida em uso) ou pelo princípio ativo no nome.
  /// Semaglutida oral e liraglutida (diária) ficam de fora.
  static ActiveIngredient? of(Medication m) {
    if (m.form == 'oral') return null;
    final known = KnownMedication.byName(m.name);
    if (known != null) {
      return switch (known.ingredient) {
        MedicationIngredient.tirzepatide => tirzepatide,
        MedicationIngredient.semaglutide => semaglutide,
        MedicationIngredient.dulaglutide => dulaglutide,
        MedicationIngredient.liraglutide ||
        MedicationIngredient.oralSemaglutide => null,
      };
    }
    final n = KnownMedication.normalize(m.name);
    if (n.contains('tirzepatid') || n.contains('zepbound')) return tirzepatide;
    if (n.contains('semaglutid')) return semaglutide;
    if (n.contains('dulaglutid')) return dulaglutide;
    return null;
  }
}

/// Ponto da curva de nível estimado.
class LevelPoint {
  const LevelPoint(this.at, this.mg);

  final DateTime at;
  final double mg;
}

/// Quantidade estimada do medicamento no organismo, por um modelo simples de
/// um compartimento com absorção de primeira ordem. Usa só as doses
/// registradas (em mg). É uma ilustração do ritmo das aplicações, não uma
/// medida: absorção e eliminação variam de pessoa para pessoa.
class MedicationLevel {
  MedicationLevel({
    required this.ingredient,
    required List<MedicationDose> doses,
  }) : doses =
           doses
               .where(
                 (d) =>
                     d.doseAmount != null &&
                     d.doseAmount! > 0 &&
                     d.doseUnit == 'mg',
               )
               .toList()
             ..sort((a, b) => a.takenAt.compareTo(b.takenAt));

  final ActiveIngredient ingredient;
  final List<MedicationDose> doses;

  /// Meia-vida de absorção usada no modelo (pico entre 1 e 3 dias, como em bula).
  static const absorptionHalfLife = Duration(hours: 12);

  double get _ke => math.ln2 / ingredient.halfLife.inMinutes * 60;
  double get _ka => math.ln2 / absorptionHalfLife.inMinutes * 60;

  bool get isEmpty => doses.isEmpty;

  /// Nível estimado (mg) em um instante.
  double at(DateTime t) {
    final ke = _ke;
    final ka = _ka;
    var total = 0.0;
    for (final d in doses) {
      final h = t.difference(d.takenAt).inMinutes / 60;
      if (h <= 0) continue;
      total +=
          d.doseAmount! *
          ka /
          (ka - ke) *
          (math.exp(-ke * h) - math.exp(-ka * h));
    }
    return total;
  }

  /// Curva entre [from] e [to], um ponto a cada [step].
  List<LevelPoint> series(
    DateTime from,
    DateTime to, {
    Duration step = const Duration(hours: 6),
  }) {
    final points = <LevelPoint>[];
    for (var t = from; !t.isAfter(to); t = t.add(step)) {
      points.add(LevelPoint(t, at(t)));
    }
    if (points.isEmpty || points.last.at != to) {
      points.add(LevelPoint(to, at(to)));
    }
    return points;
  }

  /// Valor arredondado para exibir (passo de 0,1 mg; sem falsa precisão).
  static double rounded(double mg) => (mg * 10).round() / 10;
}
