/// Contas do onboarding (IMC, unidades e previsão da meta), sem dependência
/// de Flutter para poderem ser testadas isoladamente.
abstract final class BodyMath {
  static const kgPerLb = 0.45359237;
  static const cmPerInch = 2.54;

  static double kgToLb(double kg) => kg / kgPerLb;
  static double lbToKg(double lb) => lb * kgPerLb;
  static double cmToInches(double cm) => cm / cmPerInch;
  static double inchesToCm(double inches) => inches * cmPerInch;

  /// 175 cm → (5, 9): pés e polegadas, arredondando para a polegada.
  static (int feet, int inches) feetAndInches(double cm) {
    final total = cmToInches(cm).round();
    return (total ~/ 12, total % 12);
  }

  static String feetInchesLabel(double cm) {
    final (feet, inches) = feetAndInches(cm);
    return "$feet'$inches\"";
  }

  /// Índice de massa corporal (kg/m²), ou nulo sem dados plausíveis.
  static double? bmi({required double? weightKg, required double? heightCm}) {
    if (weightKg == null || heightCm == null || heightCm < 50) return null;
    final m = heightCm / 100;
    return weightKg / (m * m);
  }

  /// Peso correspondente a um IMC para a altura informada.
  static double weightForBmi(double bmi, double heightCm) {
    final m = heightCm / 100;
    return bmi * m * m;
  }

  /// Semanas para ir de [currentKg] a [goalKg] no ritmo [paceKgPerWeek].
  static int? weeksToGoal({
    required double? currentKg,
    required double? goalKg,
    required double? paceKgPerWeek,
  }) {
    if (currentKg == null || goalKg == null || paceKgPerWeek == null) {
      return null;
    }
    if (paceKgPerWeek <= 0) return null;
    final diff = (currentKg - goalKg).abs();
    if (diff < 0.1) return 0;
    return (diff / paceKgPerWeek).ceil();
  }

  static DateTime? projectedDate({
    required double? currentKg,
    required double? goalKg,
    required double? paceKgPerWeek,
    DateTime? from,
  }) {
    final weeks = weeksToGoal(
      currentKg: currentKg,
      goalKg: goalKg,
      paceKgPerWeek: paceKgPerWeek,
    );
    if (weeks == null) return null;
    return (from ?? DateTime.now()).add(Duration(days: weeks * 7));
  }
}

/// Faixas de IMC para adultos (OMS). É uma referência populacional: não
/// considera composição corporal, idade ou condições de saúde.
enum BmiBand {
  underweight('Abaixo do peso', 0, 18.5),
  healthy('Peso adequado', 18.5, 25),
  overweight('Sobrepeso', 25, 30),
  obesity1('Obesidade grau I', 30, 35),
  obesity2('Obesidade grau II', 35, 40),
  obesity3('Obesidade grau III', 40, double.infinity);

  const BmiBand(this.label, this.from, this.to);

  final String label;
  final double from;
  final double to;

  static BmiBand of(double bmi) =>
      values.firstWhere((b) => bmi < b.to, orElse: () => obesity3);
}
