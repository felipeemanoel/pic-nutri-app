/// Personalização visual aproximada; não representa anatomia nem diagnóstico.
class InjectionBodyShape {
  const InjectionBodyShape({this.sex, this.fullness = .35});

  factory InjectionBodyShape.fromProfile({
    String? sex,
    double? weightKg,
    double? heightCm,
  }) {
    var fullness = .35;
    if (weightKg != null &&
        weightKg.isFinite &&
        weightKg > 0 &&
        heightCm != null &&
        heightCm.isFinite &&
        heightCm >= 50) {
      final metres = heightCm / 100;
      // Interpolação contínua, sem saltos de aparência em um peso específico.
      fullness = ((weightKg / (metres * metres) - 18) / 22).clamp(0.0, 1.0);
    }
    return InjectionBodyShape(sex: sex, fullness: fullness);
  }

  final String? sex;
  final double fullness;
  bool get feminine => sex == 'female';
  double get shoulder => (sex == 'male' ? 39 : 34) + fullness * 5;
  double get waist => (feminine ? 23 : 28) + fullness * 17;
  double get hip => (feminine ? 34 : 30) + fullness * 12;

  /// Posições normalizadas compartilhadas pelo desenho e pelos alvos.
  double get armX => (shoulder + 9) / 180;
  double get abdomenX => waist * .48 / 180;
  double get thighX => hip * .50 / 180;
}
