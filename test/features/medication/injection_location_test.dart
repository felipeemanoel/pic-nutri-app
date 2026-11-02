import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/medication/data/injection_location.dart';

void main() {
  test('subáreas sobrevivem ao registro e preservam observações', () {
    for (final point in InjectionLocation.labels.keys) {
      final saved = InjectionLocation.encode('Minha observação', point);
      expect(InjectionLocation.point(saved), point);
      expect(InjectionLocation.cleanNotes(saved), 'Minha observação');
      expect(
        InjectionLocation.region(point),
        matches(RegExp(r'^(abdomen|thigh|arm|upper_arm)_(left|right)$')),
      );
      expect(InjectionLocation.encode(saved, point), saved);
    }
  });
  test('registro antigo não inventa subárea e edição pode removê-la', () {
    expect(InjectionLocation.point('Registro anterior'), isNull);
    final saved = InjectionLocation.encode('Observação', 'abdomen_left_upper');
    expect(InjectionLocation.encode(saved, null), 'Observação');
    expect(InjectionLocation.encode('', null), isNull);
  });
}
