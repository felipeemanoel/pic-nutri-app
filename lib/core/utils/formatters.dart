import 'package:intl/intl.dart';

/// Formatação em pt-BR, centralizada para manter as telas consistentes.
abstract final class Fmt {
  static final _decimal1 = NumberFormat('#,##0.#', 'pt_BR');
  static final _integer = NumberFormat('#,##0', 'pt_BR');
  static final _dayMonth = DateFormat("d 'de' MMM", 'pt_BR');
  static final _fullDate = DateFormat("EEEE, d 'de' MMMM", 'pt_BR');
  static final _shortDate = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _time = DateFormat('HH:mm', 'pt_BR');
  static final _monthYear = DateFormat("MMMM 'de' y", 'pt_BR');

  static String decimal(num value) => _decimal1.format(value);
  static String integer(num value) => _integer.format(value.round());
  static String kg(num value) => '${_decimal1.format(value)} kg';
  static String kcal(num value) => '${_integer.format(value.round())} kcal';
  static String grams(num value) => '${_decimal1.format(value)} g';
  static String ml(num value) => '${_integer.format(value.round())} ml';
  static String dayMonth(DateTime d) => _dayMonth.format(d);
  static String fullDate(DateTime d) => _fullDate.format(d);
  static String shortDate(DateTime d) => _shortDate.format(d);
  static String time(DateTime d) => _time.format(d.toLocal());
  static String monthYear(DateTime d) => _monthYear.format(d);
  static final _weekday = DateFormat('EEE', 'pt_BR');

  /// Dia relativo e hora: "hoje, 18:27", "amanhã, 09:00", "ontem, 09:00" ou
  /// "qui, 23 de out, 09:00".
  static String relativeDayTime(DateTime d, {DateTime? now}) {
    final local = d.toLocal();
    final ref = now ?? DateTime.now();
    final day = DateTime(local.year, local.month, local.day);
    final today = DateTime(ref.year, ref.month, ref.day);
    final diff = (day.difference(today).inHours / 24).round();
    final hour = time(local);
    return switch (diff) {
      0 => 'hoje, $hour',
      1 => 'amanhã, $hour',
      -1 => 'ontem, $hour',
      _ => '${_weekday.format(local).replaceAll('.', '')}, '
          '${dayMonth(local).replaceAll('.', '')}, $hour',
    };
  }

  /// Data no formato da API (YYYY-MM-DD), sem fuso.
  static String apiDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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
