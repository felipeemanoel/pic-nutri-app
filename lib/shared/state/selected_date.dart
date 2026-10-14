import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dia selecionado no Início e na Alimentação (data local, sem horário).
class SelectedDate extends Notifier<DateTime> {
  @override
  DateTime build() => today();

  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void previous() => state = state.subtract(const Duration(days: 1));

  void next() {
    if (!isToday) state = state.add(const Duration(days: 1));
  }

  void goToday() => state = today();

  void set(DateTime day) => state = DateTime(day.year, day.month, day.day);

  bool get isToday => state == today();
}

final selectedDateProvider = NotifierProvider<SelectedDate, DateTime>(
  SelectedDate.new,
);
