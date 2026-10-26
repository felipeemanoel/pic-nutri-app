import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/onboarding/domain/body_math.dart';

void main() {
  test('IMC e faixas da OMS', () {
    final bmi = BodyMath.bmi(weightKg: 75, heightCm: 175)!;
    expect(bmi, closeTo(24.5, 0.05));
    expect(BmiBand.of(bmi), BmiBand.healthy);
    expect(BmiBand.of(18.4), BmiBand.underweight);
    expect(BmiBand.of(25), BmiBand.overweight);
    expect(BmiBand.of(41), BmiBand.obesity3);
    expect(BodyMath.bmi(weightKg: 75, heightCm: null), isNull);
  });

  test('conversões de unidade', () {
    expect(BodyMath.kgToLb(75), closeTo(165.3, 0.05));
    expect(BodyMath.lbToKg(BodyMath.kgToLb(80)), closeTo(80, 1e-9));
    expect(BodyMath.feetInchesLabel(175), "5'9\"");
    expect(BodyMath.feetAndInches(152.4), (5, 0));
  });

  test('previsão da meta no ritmo escolhido', () {
    expect(
      BodyMath.weeksToGoal(currentKg: 75, goalKg: 67, paceKgPerWeek: 0.5),
      16,
    );
    final from = DateTime.utc(2026, 10, 26);
    expect(
      BodyMath.projectedDate(
        currentKg: 75,
        goalKg: 67,
        paceKgPerWeek: 0.5,
        from: from,
      ),
      DateTime.utc(2027, 2, 15),
    );
    expect(
      BodyMath.weeksToGoal(currentKg: 60, goalKg: 63, paceKgPerWeek: 0.25),
      12,
    );
    expect(
      BodyMath.weeksToGoal(currentKg: 70, goalKg: 70, paceKgPerWeek: 0.5),
      0,
    );
    expect(
      BodyMath.weeksToGoal(currentKg: 70, goalKg: null, paceKgPerWeek: 0.5),
      isNull,
    );
  });
}
