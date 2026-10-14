import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/medication/data/medication_models.dart';

void main() {
  test('lê aplicação com sintomas e envia só código e intensidade', () {
    final dose = MedicationDose.fromJson({
      'id': '01JDOSE',
      'medication_id': '01JMED',
      'medication_name': 'Semaglutida',
      'taken_at': '2026-10-13T12:00:00Z',
      'local_date': '2026-10-13',
      'dose_amount': 0.5,
      'dose_unit': 'mg',
      'injection_site': 'abdomen_left',
      'symptoms': [
        {'code': 'nausea', 'label': 'Náusea', 'intensity': 2},
      ],
      'notes': null,
    });

    expect(dose.doseAmount, 0.5);
    expect(dose.symptoms.single.label, 'Náusea');
    expect(dose.symptoms.single.toJson(), {'code': 'nausea', 'intensity': 2});
  });

  test('medicamento com última aplicação e rótulos das opções', () {
    final medication = Medication.fromJson({
      'id': '01JMED',
      'name': 'Semaglutida',
      'form': 'injection',
      'dose_unit': 'mg',
      'frequency': 'weekly',
      'notes': null,
      'is_active': true,
      'last_dose': {
        'id': '01JDOSE',
        'taken_at': '2026-10-13T12:00:00Z',
        'local_date': '2026-10-13',
      },
    });
    final options = MedicationOptions.fromJson({
      'forms': <Object>[],
      'dose_units': <Object>[],
      'frequencies': [
        {'value': 'weekly', 'label': 'Semanal'},
      ],
      'injection_sites': <Object>[],
      'symptoms': <Object>[],
      'intensities': [
        {'value': 1, 'label': 'leve'},
      ],
      'disclaimer': 'Registro informativo.',
    });

    expect(medication.isInjection, isTrue);
    expect(medication.lastDoseAt, isNotNull);
    expect(options.label(options.frequencies, 'weekly'), 'Semanal');
    expect(options.label(options.intensities, '1'), 'leve');
  });
}
