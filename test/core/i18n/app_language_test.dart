import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:picnutri/core/i18n/app_language.dart';
import 'package:picnutri/core/i18n/l10n.dart';
import 'package:picnutri/core/i18n/locale_controller.dart';
import 'package:picnutri/core/utils/formatters.dart';
import 'package:picnutri/features/language/presentation/language_picker.dart';

class _MemoryStore extends LanguagePreferenceStore {
  AppLanguage? saved;

  @override
  Future<AppLanguage?> read() async => saved;

  @override
  Future<void> write(AppLanguage? language) async => saved = language;
}

void main() {
  group('AppLanguage', () {
    test('tags e ida e volta', () {
      expect(AppLanguage.ptBR.tag, 'pt-BR');
      expect(AppLanguage.ja.tag, 'ja');
      for (final language in AppLanguage.values) {
        expect(AppLanguage.fromTag(language.tag), language);
      }
      expect(AppLanguage.fromTag('it'), isNull);
      expect(AppLanguage.fromTag(null), isNull);
    });

    test('qualquer português vira pt-BR', () {
      expect(
        AppLanguage.fromLocale(const Locale('pt', 'PT')),
        AppLanguage.ptBR,
      );
      expect(
        AppLanguage.fromDevice(const [Locale('pt', 'PT')]),
        AppLanguage.ptBR,
      );
    });

    test('automático só usa idioma com tradução concluída', () {
      for (final language in AppLanguage.values.where((l) => !l.complete)) {
        expect(AppLanguage.fromDevice([language.locale]), AppLanguage.fallback);
      }
      expect(
        AppLanguage.fromDevice(const [Locale('it')]),
        AppLanguage.fallback,
      );
      expect(
        AppLanguage.fromDevice(const [Locale('it'), Locale('pt', 'BR')]),
        AppLanguage.ptBR,
      );
    });
  });

  test('todas as traduções têm as mesmas chaves e marcadores do modelo', () {
    Map<String, dynamic> load(String code) =>
        jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
            as Map<String, dynamic>;
    final template = load('pt');
    final keys = template.keys.where((k) => !k.startsWith('@')).toSet();
    final placeholder = RegExp(r'\{(\w+)\}');
    for (final language in AppLanguage.values) {
      final arb = load(language.languageCode);
      expect(arb['@@locale'], language.languageCode);
      final translated = arb.keys.where((k) => !k.startsWith('@')).toSet();
      expect(translated, keys, reason: language.tag);
      for (final key in keys) {
        Set<String> marks(Map<String, dynamic> m) => placeholder
            .allMatches(m[key] as String)
            .map((match) => match.group(1)!)
            .toSet();
        expect(marks(arb), marks(template), reason: '${language.tag}: $key');
      }
    }
  });

  test('números e datas seguem o idioma do app', () async {
    await initializeDateFormatting('en');
    addTearDown(() => Fmt.useLocale(const Locale('pt', 'BR')));
    final now = DateTime(2026, 10, 28, 12);
    expect(Fmt.decimal(1234.5), '1.234,5');
    expect(
      Fmt.relativeDayTime(DateTime(2026, 10, 28, 9, 5), now: now),
      'hoje, 09:05',
    );

    Fmt.useLocale(const Locale('en'));
    expect(Fmt.decimal(1234.5), '1,234.5');
    // O intl usa espaço estreito antes de AM: confere só o começo.
    expect(
      Fmt.relativeDayTime(DateTime(2026, 10, 29, 9), now: now),
      startsWith('tomorrow, 9:00'),
    );
    expect(Fmt.dayMonth(DateTime(2026, 10, 23)), 'Oct 23');
  });

  testWidgets('seletor troca o idioma e guarda a escolha', (tester) async {
    final store = _MemoryStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [languagePreferenceStoreProvider.overrideWithValue(store)],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            locale: (ref.watch(languageControllerProvider) ?? AppLanguage.ptBR)
                .locale,
            supportedLocales: AppLanguage.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: Center(child: LanguageCard())),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Português (Brasil)'), findsOneWidget);
    expect(find.text('Alterar'), findsOneWidget);

    await tester.tap(find.byType(LanguageCard));
    await tester.pumpAndSettle();
    expect(find.text('Escolha o idioma do app'), findsOneWidget);
    // A lista é rolável: os últimos idiomas só são montados ao rolar.
    for (final language in AppLanguage.values) {
      final row = find.byKey(ValueKey('language-${language.tag}'));
      await tester.scrollUntilVisible(
        row,
        64,
        scrollable: find.byType(Scrollable).last,
      );
      expect(row, findsOneWidget);
    }

    final spanish = find.byKey(const ValueKey('language-es'));
    await tester.scrollUntilVisible(
      spanish,
      -64,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(spanish);
    await tester.pumpAndSettle();
    expect(store.saved, AppLanguage.es);
    expect(find.text('Español'), findsOneWidget);
    expect(find.text('Cambiar'), findsOneWidget);
  });
}
