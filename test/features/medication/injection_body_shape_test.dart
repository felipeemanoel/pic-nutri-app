import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/medication/presentation/injection_body_shape.dart';

void main() {
  test('porte considera altura e peso e acompanha os alvos', () {
    final small = InjectionBodyShape.fromProfile(
      sex: 'female',
      weightKg: 55,
      heightCm: 170,
    );
    final large = InjectionBodyShape.fromProfile(
      sex: 'female',
      weightKg: 110,
      heightCm: 170,
    );
    final tall = InjectionBodyShape.fromProfile(weightKg: 110, heightCm: 200);
    expect(large.fullness, greaterThan(small.fullness));
    expect(large.abdomenX, greaterThan(small.abdomenX));
    expect(large.thighX, greaterThan(small.thighX));
    expect(tall.fullness, lessThan(large.fullness));
    expect(small.feminine, isTrue);
    expect(const InjectionBodyShape(sex: 'male').feminine, isFalse);
  });

  test('dados ausentes ou inválidos usam porte padrão sem inventar sexo', () {
    for (final weight in [null, -1.0, double.nan, double.infinity]) {
      final shape = InjectionBodyShape.fromProfile(
        weightKg: weight,
        heightCm: 170,
      );
      expect(shape.fullness, .35);
      expect(shape.sex, isNull);
    }
    expect(InjectionBodyShape.fromProfile(weightKg: 80).fullness, .35);
  });
}
