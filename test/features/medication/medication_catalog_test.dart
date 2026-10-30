import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/medication/data/medication_catalog.dart';
import 'package:picnutri/features/medication/data/medication_models.dart';
import 'package:picnutri/features/medication/domain/medication_schedule.dart';

Medication _med(String name, {String form = 'injection'}) => Medication(
  id: name,
  name: name,
  form: form,
  doseUnit: 'mg',
  frequency: 'weekly',
  isActive: true,
);

void main() {
  test('ids únicos e doses em ordem crescente', () {
    final ids = KnownMedication.all.map((m) => m.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final m in KnownMedication.all) {
      expect(m.doses.isNotEmpty || m.irregular, isTrue, reason: m.id);
      final sorted = [...m.doses]..sort();
      expect(m.doses, sorted, reason: m.id);
    }
  });

  test('catálogo traz as marcas registradas de cada princípio ativo', () {
    final names = KnownMedication.brands.map((m) => m.name).toSet();
    expect(
      names,
      containsAll([
        'Mounjaro',
        'Ozempic',
        'Wegovy',
        'Poviztra',
        'Extensior',
        'Ozivy',
        'Saxenda',
        'Olire',
        'Victoza',
        'Lirux',
        'Trulicity',
        'Rybelsus',
      ]),
    );
    expect(KnownMedication.genericEntries, hasLength(3));
  });

  test('busca ignora acentos e acha por fabricante ou princípio ativo', () {
    final ylumec = KnownMedication.byId('ylumec')!;
    expect(ylumec.matches('ylumec'), isTrue);
    expect(KnownMedication.byId('ozivy')!.matches('ems'), isTrue);
    expect(KnownMedication.byId('olire')!.matches('liraglutida'), isTrue);
    expect(KnownMedication.byId('mounjaro')!.matches('semaglutida'), isFalse);
  });

  test('reconhece o medicamento pelo nome cadastrado', () {
    expect(KnownMedication.byName('Poviztra')?.id, 'poviztra');
    expect(KnownMedication.byName('Mounjaro 5 mg')?.id, 'mounjaro');
    expect(
      KnownMedication.byName('Genérico EMS (semaglutida)')?.id,
      'generic_semaglutide',
    );
    expect(KnownMedication.byName('Remédio X'), isNull);
  });

  test('nível estimado usa o princípio ativo do catálogo', () {
    expect(ActiveIngredient.of(_med('Poviztra')), ActiveIngredient.semaglutide);
    expect(ActiveIngredient.of(_med('Ozivy')), ActiveIngredient.semaglutide);
    expect(
      ActiveIngredient.of(_med('Trulicity')),
      ActiveIngredient.dulaglutide,
    );
    expect(ActiveIngredient.of(_med('Olire')), isNull, reason: 'diária');
    expect(ActiveIngredient.of(_med('Rybelsus', form: 'oral')), isNull);
    expect(
      ActiveIngredient.of(_med('Tirzepatida', form: 'other')),
      ActiveIngredient.tirzepatide,
    );
  });

  test('outras canetas de tirzepatida aparecem na lista normal', () {
    final tirzepatide = KnownMedication.brands
        .where((m) => m.ingredient == MedicationIngredient.tirzepatide)
        .map((m) => m.name)
        .toSet();
    expect(
      tirzepatide,
      containsAll([
        'Mounjaro',
        'TG',
        'T.G. 5',
        'Lipoless',
        'Synedica',
        'Tirzec',
        'Tirzazep',
        'Lipoland',
        'T36',
      ]),
    );
    expect(KnownMedication.byName('Lipoless 10 mg')?.id, 'irregular_lipoless');
    expect(ActiveIngredient.of(_med('TG')), ActiveIngredient.tirzepatide);
    expect(ActiveIngredient.of(_med('Retatrutida')), isNull);
  });
}
