import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/app/theme/app_theme.dart';
import 'package:picnutri/features/medication/data/medication_models.dart';
import 'package:picnutri/features/medication/data/medication_repository.dart';
import 'package:picnutri/features/medication/presentation/medication_forms.dart';

class _Repository implements MedicationRepository {
  String? savedSite;
  String? savedMedication;
  int saves = 0;
  @override
  Future<MedicationOptions> options() async => const MedicationOptions(
    forms: [Option('injection', 'Injetável')],
    doseUnits: [Option('mg', 'mg')],
    frequencies: [Option('weekly', 'Semanal')],
    injectionSites: [
      Option('abdomen_left', 'Abdome esquerdo'),
      Option('abdomen_right', 'Abdome direito'),
    ],
    symptoms: [],
    intensities: [],
    disclaimer: 'Registro informativo.',
  );
  @override
  Future<List<Medication>> medications() async => const [
    Medication(
      id: 'med',
      name: 'Mounjaro',
      form: 'injection',
      doseUnit: 'mg',
      frequency: 'weekly',
      isActive: true,
    ),
  ];
  @override
  Future<List<MedicationDose>> recentDoses() async => [];
  @override
  Future<SavedDose> saveDose({
    String? id,
    required String medicationId,
    required DateTime takenAt,
    required String doseUnit,
    double? doseAmount,
    String? injectionSite,
    List<SymptomEntry> symptoms = const [],
    String? notes,
    String? requestId,
  }) async {
    savedSite = injectionSite;
    savedMedication = medicationId;
    saves++;
    return SavedDose(
      MedicationDose(
        id: 'dose',
        medicationId: medicationId,
        takenAt: takenAt,
        localDate: '2026-10-19',
        doseUnit: doseUnit,
        symptoms: symptoms,
        injectionSite: injectionSite,
      ),
      null,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('seleção no corpo é gravada pelo contrato existente da API', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 1200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _Repository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [medicationRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => openDoseForm(context),
                child: const Text('Abrir aplicação'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir aplicação'));
    await tester.pumpAndSettle();
    final selector = find.widgetWithText(
      DropdownButtonFormField<String>,
      'Produto e apresentação',
    );
    await tester.ensureVisible(selector);
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mounjaro · Eli Lilly').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Abdome esquerdo'));
    await tester.tap(find.byTooltip('Abdome esquerdo'));
    await tester.pumpAndSettle();
    expect(repo.saves, 0);
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Salvar'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(repo.savedSite, 'abdomen_left');
    expect(repo.savedMedication, 'med');
    expect(repo.saves, 1);
  });
}
