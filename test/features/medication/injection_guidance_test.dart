import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/app/theme/app_theme.dart';
import 'package:picnutri/features/medication/data/injection_guides.dart';
import 'package:picnutri/features/medication/data/medication_models.dart';
import 'package:picnutri/features/medication/data/medication_repository.dart';
import 'package:picnutri/features/medication/presentation/injection_guidance.dart';
import 'package:picnutri/features/medication/presentation/injection_site_map.dart';

const _sites = [
  Option('abdomen_left', 'Abdome esquerdo'),
  Option('abdomen_right', 'Abdome direito'),
  Option('thigh_left', 'Coxa esquerda'),
  Option('thigh_right', 'Coxa direita'),
  Option('arm_left', 'Braço esquerdo'),
  Option('arm_right', 'Braço direito'),
  Option('other', 'Outro local'),
];

void main() {
  test(
    'referências têm fonte oficial e apresentação específica sem adivinhar locais',
    () {
      expect(InjectionGuide.catalog.map((g) => g.id).toSet().length, 4);
      for (final g in InjectionGuide.catalog) {
        final uri = Uri.parse(g.sourceUrl);
        expect(uri.scheme, 'https');
        expect([
          'www.novonordisk.com.br',
          'delivery-p137454-e1438138.adobeaemcloud.com',
        ], contains(uri.host));
        expect(g.presentation, isNotEmpty);
        expect(g.sourceVersion, isNotEmpty);
      }
      expect(InjectionGuide.catalog.last.armRequiresHelper, isTrue);
      expect(regionForSite('abdomen_left'), BodyRegion.abdomen);
      expect(regionForSite('other'), isNull);
      expect(regionForSite('unknown_left'), isNull);
      expect(guidesForMedication('Mounjaro 5 mg').single.brand, 'Mounjaro');
      expect(guidesForMedication('Semaglutida'), isEmpty);
      expect(guidesForMedication('falsoOzempic'), isEmpty);
    },
  );

  testWidgets(
    'mapa espelha a esquerda na frente e mantém seleção e códigos da API',
    (tester) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 360,
                child: InjectionSiteMap(
                  sites: _sites,
                  selected: null,
                  onSelected: (value) => selected = value,
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byTooltip('Outro local'), findsNothing);
      final left = tester.getCenter(find.byTooltip('Abdome esquerdo'));
      final right = tester.getCenter(find.byTooltip('Abdome direito'));
      expect(left.dx, greaterThan(right.dx));
      await tester.tap(find.byTooltip('Abdome esquerdo'));
      expect(selected, 'abdomen_left');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'mapa aparece só após confirmar apresentação; outra apresentação remove instruções',
    (tester) async {
      tester.view
        ..physicalSize = const Size(390, 1400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [recentDosesProvider.overrideWith((ref) async => [])],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: InjectionGuidance(
                  medicationName: 'Mounjaro',
                  sites: _sites,
                  site: null,
                  onSiteChanged: (_) {},
                  takenAt: DateTime(2026, 10, 19),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(InjectionSiteMap), findsNothing);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mounjaro · Eli Lilly').last);
      await tester.pumpAndSettle();
      expect(find.byType(InjectionSiteMap), findsNothing);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      expect(find.byType(InjectionSiteMap), findsOneWidget);
      expect(
        find.textContaining('deve ser feita por outra pessoa'),
        findsOneWidget,
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Outro / não sei informar').last);
      await tester.pumpAndSettle();
      expect(find.byType(InjectionSiteMap), findsNothing);
      expect(
        find.textContaining('deve ser feita por outra pessoa'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
