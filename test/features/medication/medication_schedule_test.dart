import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/core/utils/formatters.dart';
import 'package:picnutri/features/medication/data/medication_models.dart';
import 'package:picnutri/features/medication/domain/medication_schedule.dart';

Medication _med({
  String name = 'Mounjaro',
  String form = 'injection',
  String frequency = 'weekly',
  String? notes,
  DateTime? last,
  bool active = true,
}) => Medication(
  id: name,
  name: name,
  form: form,
  doseUnit: 'mg',
  frequency: frequency,
  isActive: active,
  notes: notes,
  lastDoseAt: last,
);

MedicationDose _dose(DateTime at, double mg, {String unit = 'mg'}) =>
    MedicationDose(
      id: '$at',
      medicationId: 'm',
      takenAt: at,
      localDate: '',
      doseUnit: unit,
      doseAmount: mg,
      symptoms: const [],
    );

void main() {
  final t0 = DateTime(2026, 10, 1, 9);

  group('intervalo e próxima aplicação', () {
    test('frequências cadastradas', () {
      expect(MedicationSchedule.interval(_med()), const Duration(days: 7));
      expect(
        MedicationSchedule.interval(_med(frequency: 'daily')),
        const Duration(days: 1),
      );
      expect(
        MedicationSchedule.interval(
          _med(frequency: 'other', notes: 'A cada duas semanas'),
        ),
        const Duration(days: 14),
      );
      expect(
        MedicationSchedule.interval(
          _med(frequency: 'other', notes: 'Uma vez por mês'),
        ),
        const Duration(days: 30),
      );
      expect(MedicationSchedule.interval(_med(frequency: 'other')), isNull);
    });

    test('próxima = última + intervalo; sem última, nada é previsto', () {
      expect(
        MedicationSchedule.nextDoseAt(_med(last: t0)),
        DateTime(2026, 10, 8, 9),
      );
      expect(MedicationSchedule.nextDoseAt(_med()), isNull);
      expect(
        MedicationSchedule.cycleProgress(
          _med(last: t0),
          t0.add(const Duration(days: 7, hours: 12)),
        ),
        greaterThan(1),
      );
    });

    test('destaque: ativo, injetável e com dose mais recente', () {
      final oral = _med(name: 'Rybelsus', form: 'oral', last: t0);
      final inj = _med(last: t0.subtract(const Duration(days: 3)));
      final off = _med(name: 'Antigo', active: false, last: t0);
      expect(MedicationSchedule.primary([oral, inj, off]), inj);
      expect(MedicationSchedule.primary([off]), isNull);
    });

    test('contagem curta', () {
      expect(
        MedicationSchedule.countdown(const Duration(days: 2, hours: 4)),
        '2d 4h',
      );
      expect(
        MedicationSchedule.countdown(const Duration(hours: 5, minutes: 12)),
        '5h 12min',
      );
      expect(
        MedicationSchedule.countdown(const Duration(minutes: 12)),
        '12min',
      );
      expect(MedicationSchedule.countdown(Duration.zero), 'agora');
    });
  });

  group('nível estimado', () {
    test('reconhece só injetáveis semanais conhecidos', () {
      expect(ActiveIngredient.of(_med()), ActiveIngredient.tirzepatide);
      expect(
        ActiveIngredient.of(_med(name: 'Ozempic')),
        ActiveIngredient.semaglutide,
      );
      expect(ActiveIngredient.of(_med(name: 'Saxenda')), isNull);
      expect(ActiveIngredient.of(_med(name: 'Rybelsus', form: 'oral')), isNull);
    });

    test('sobe após a aplicação, cai pela meia-vida e acumula', () {
      final level = MedicationLevel(
        ingredient: ActiveIngredient.tirzepatide,
        doses: [_dose(t0, 2.5), _dose(t0.add(const Duration(days: 7)), 2.5)],
      );
      expect(level.at(t0), 0);
      final day2 = level.at(t0.add(const Duration(days: 2)));
      final day6 = level.at(t0.add(const Duration(days: 6)));
      final day9 = level.at(t0.add(const Duration(days: 9)));
      expect(day2, greaterThan(day6));
      expect(
        day9,
        greaterThan(day2),
        reason: 'segunda dose soma ao que restou',
      );
      expect(day2, lessThan(2.5));
    });

    test('ignora doses sem valor ou em outra unidade', () {
      final level = MedicationLevel(
        ingredient: ActiveIngredient.semaglutide,
        doses: [_dose(t0, 0.5, unit: 'ml')],
      );
      expect(level.isEmpty, isTrue);
    });

    test('arredonda em 0,1 mg', () {
      expect(MedicationLevel.rounded(1.86), 1.9);
      expect(MedicationLevel.rounded(1.84), 1.8);
    });
  });

  test('dia relativo para datas próximas', () {
    final now = DateTime(2026, 10, 28, 15);
    expect(
      Fmt.relativeDayTime(DateTime(2026, 10, 28, 9, 5), now: now),
      'hoje, 09:05',
    );
    expect(
      Fmt.relativeDayTime(DateTime(2026, 10, 29, 9), now: now),
      'amanhã, 09:00',
    );
    expect(
      Fmt.relativeDayTime(DateTime(2026, 10, 27, 9), now: now),
      'ontem, 09:00',
    );
  });
}
