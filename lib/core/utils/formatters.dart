import 'dart:ui' show Locale;

import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

/// Formatação de números e datas, centralizada para manter as telas
/// consistentes. Segue o idioma do app ([useLocale], chamado pelo
/// `MaterialApp`); o padrão é pt-BR (testes e antes da primeira tela).
abstract final class Fmt {
  static String _locale = 'pt_BR';
  static final Map<String, _Formats> _cache = {};

  /// Troca o idioma dos formatos (ex.: `en`, `pt_BR`).
  static void useLocale(Locale locale) {
    final tag = locale.languageCode == 'pt' ? 'pt_BR' : locale.languageCode;
    if (tag == _locale) return;
    _locale = tag;
    Intl.defaultLocale = tag;
  }

  /// Idioma em uso pelos formatos (`pt_BR`, `en`...).
  static String get localeTag => _locale;

  static _Formats get _f =>
      _cache.putIfAbsent(_locale, () => _Formats(_locale));

  static String decimal(num value) => _f.decimal1.format(value);
  static String integer(num value) => _f.integer.format(value.round());
  static String kg(num value) => '${_f.decimal1.format(value)} kg';
  static String kcal(num value) => '${_f.integer.format(value.round())} kcal';
  static String grams(num value) => '${_f.decimal1.format(value)} g';
  static String ml(num value) => '${_f.integer.format(value.round())} ml';
  static String dayMonth(DateTime d) => _f.dayMonth.format(d);
  static String fullDate(DateTime d) => _f.fullDate.format(d);
  static String shortDate(DateTime d) => _f.shortDate.format(d);
  static String time(DateTime d) => _f.time.format(d.toLocal());
  static String monthYear(DateTime d) => _f.monthYear.format(d);

  /// Dia relativo e hora: "hoje, 18:27", "amanhã, 09:00", "ontem, 09:00" ou
  /// "qui, 23 de out, 09:00" (no idioma do app).
  static String relativeDayTime(DateTime d, {DateTime? now}) {
    final local = d.toLocal();
    final ref = now ?? DateTime.now();
    final day = DateTime(local.year, local.month, local.day);
    final today = DateTime(ref.year, ref.month, ref.day);
    final diff = (day.difference(today).inHours / 24).round();
    final hour = time(local);
    final l10n = _f.l10n;
    return switch (diff) {
      0 => l10n.relToday(hour),
      1 => l10n.relTomorrow(hour),
      -1 => l10n.relYesterday(hour),
      _ =>
        '${_f.weekday.format(local).replaceAll('.', '')}, '
            '${dayMonth(local).replaceAll('.', '')}, $hour',
    };
  }

  /// Data no formato da API (YYYY-MM-DD), sem fuso.
  static String apiDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Formatos de um idioma. O português mantém os padrões já usados no app
/// ("23 de out"); os demais usam os padrões do próprio idioma.
class _Formats {
  _Formats(String tag)
    : decimal1 = NumberFormat('#,##0.#', tag),
      integer = NumberFormat('#,##0', tag),
      dayMonth = tag == 'pt_BR'
          ? DateFormat("d 'de' MMM", tag)
          : DateFormat.MMMd(tag),
      fullDate = tag == 'pt_BR'
          ? DateFormat("EEEE, d 'de' MMMM", tag)
          : DateFormat.MMMMEEEEd(tag),
      shortDate = tag == 'pt_BR'
          ? DateFormat('dd/MM/yyyy', tag)
          : DateFormat.yMd(tag),
      time = tag == 'en' ? DateFormat.jm(tag) : DateFormat('HH:mm', tag),
      monthYear = tag == 'pt_BR'
          ? DateFormat("MMMM 'de' y", tag)
          : DateFormat.yMMMM(tag),
      weekday = DateFormat('EEE', tag),
      l10n = lookupAppLocalizations(Locale(tag.split('_').first));

  final NumberFormat decimal1;
  final NumberFormat integer;
  final DateFormat dayMonth;
  final DateFormat fullDate;
  final DateFormat shortDate;
  final DateFormat time;
  final DateFormat monthYear;
  final DateFormat weekday;
  final AppLocalizations l10n;
}

/// Converte números vindos do JSON (int, double ou string) com segurança.
double? toDouble(Object? value) => switch (value) {
  final num v => v.toDouble(),
  final String v => double.tryParse(v),
  _ => null,
};

int? toInt(Object? value) => switch (value) {
  final int v => v,
  final num v => v.round(),
  final String v => int.tryParse(v),
  _ => null,
};
