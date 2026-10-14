import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/app/theme/app_theme.dart';
import 'package:picnutri/core/design/design_system.dart';

double _luminance(Color c) => c.computeLuminance();

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

Widget _host(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('Temas', () {
    for (final (name, theme) in [
      ('claro', AppTheme.light()),
      ('escuro', AppTheme.dark()),
    ]) {
      test('tema $name usa os tokens e tem contraste AA no texto', () {
        final s = theme.colorScheme;
        final pic = theme.extension<PicColors>()!;
        final bg = theme.scaffoldBackgroundColor;

        expect(_contrast(s.onSurface, s.surface), greaterThanOrEqualTo(4.5));
        expect(_contrast(s.onSurface, bg), greaterThanOrEqualTo(4.5));
        expect(
          _contrast(pic.textSecondary, s.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(_contrast(s.onPrimary, s.primary), greaterThanOrEqualTo(4.5));
        expect(_contrast(s.error, s.surface), greaterThanOrEqualTo(4.5));
        expect(
          _contrast(pic.onAiContainer, pic.aiContainer),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(pic.onBrandContainer, pic.brandContainer),
          greaterThanOrEqualTo(4.5),
        );
        // Elementos gráficos (barras, ícones): pelo menos 3:1.
        for (final c in [
          pic.protein,
          pic.carbs,
          pic.fat,
          pic.water,
          pic.chartLine,
          pic.ai,
        ]) {
          expect(_contrast(c, s.surface), greaterThanOrEqualTo(3));
        }
      });
    }

    test('cores oficiais da marca no tema claro', () {
      final s = AppTheme.light().colorScheme;
      expect(s.primary, PicPalette.primary);
      expect(AppTheme.light().scaffoldBackgroundColor, PicPalette.background);
      expect(s.surface, PicPalette.surface);
      expect(
        AppTheme.dark().scaffoldBackgroundColor,
        PicPalette.darkBackground,
      );
      expect(AppTheme.dark().colorScheme.primary, PicPalette.accent);
    });
  });

  testWidgets('anel de progresso expõe o valor ao leitor de tela', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const ProgressRing(
          progress: 0.5,
          semanticLabel: '900 kcal de 1.800 kcal',
          child: Text('900'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('900 kcal de 1.800 kcal'), findsOneWidget);
  });

  testWidgets('macronutrientes mostram rótulo e valor, não só cor', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 360,
          child: MacroSummary(
            proteinG: 40,
            carbsG: 120,
            fatG: 30,
            proteinGoal: 90,
          ),
        ),
        theme: AppTheme.dark(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Proteínas: 40 g de 90g'), findsOneWidget);
    expect(find.bySemanticsLabel('Carboidratos: 120 g'), findsOneWidget);
  });

  testWidgets('símbolo e selo de IA renderizam nos dois temas', (tester) async {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      await tester.pumpWidget(
        _host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PicNutriWordmark(showTagline: true),
              AiBadge(),
              StatusBanner(
                tone: BannerTone.warning,
                message: 'Revise os valores.',
              ),
            ],
          ),
          theme: theme,
        ),
      );
      expect(find.text('PicNutri'), findsOneWidget);
      expect(find.text('Sua evolução, no seu ritmo.'), findsOneWidget);
      expect(find.bySemanticsLabel('Estimativa por IA'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('textos grandes não estouram o cartão de métrica', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: SizedBox(
            width: 160,
            child: MetricTile(
              icon: Icons.water_drop_outlined,
              label: 'Água',
              value: '1.500',
              unit: 'ml',
              progress: 0.6,
              caption: 'de 2.000 ml',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
