/// Lembrete configurado pelo usuário (dias 1 = segunda ... 7 = domingo).
///
/// Lembretes são notificações locais: o aparelho dispara nos horários
/// escolhidos, mesmo sem internet. O servidor guarda a configuração.
class Reminder {
  Reminder({
    required this.id,
    required this.type,
    required this.displayTitle,
    required this.time,
    required this.days,
    required this.enabled,
    this.title,
    this.medicationId,
    this.intervalMinutes,
    this.endTime,
    String? category,
  }) : category = category ?? ReminderLabels.categoryOf(type);

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    id: json['id'] as String,
    type: json['type'] as String,
    title: json['title'] as String?,
    displayTitle: json['display_title'] as String? ?? '',
    time: json['time'] as String,
    days: (json['days'] as List<dynamic>)
        .map((d) => (d as num).toInt())
        .toList(),
    enabled: json['enabled'] as bool? ?? true,
    medicationId: json['medication_id'] as String?,
    intervalMinutes: (json['interval_minutes'] as num?)?.toInt(),
    endTime: json['end_time'] as String?,
    category: json['category'] as String?,
  );

  final String id;
  final String type;
  final String? title;
  final String displayTitle;

  /// "HH:MM" no fuso do perfil (primeiro horário, se repetir no dia).
  final String time;
  final List<int> days;
  final bool enabled;
  final String? medicationId;

  /// Repetição no dia: a cada [intervalMinutes] até [endTime].
  final int? intervalMinutes;
  final String? endTime;

  /// Categoria de preferência (a API informa; o app deduz se faltar).
  final String category;

  int get hour => int.parse(time.split(':')[0]);
  int get minute => int.parse(time.split(':')[1]);

  bool get repeats =>
      intervalMinutes != null && intervalMinutes! > 0 && endTime != null;

  /// Horários do dia como (hora, minuto).
  List<(int, int)> get times {
    if (!repeats) return [(hour, minute)];
    final end =
        int.parse(endTime!.substring(0, 2)) * 60 +
        int.parse(endTime!.substring(3, 5));
    return [
      for (var m = hour * 60 + minute; m <= end; m += intervalMinutes!)
        (m ~/ 60, m % 60),
    ].take(24).toList();
  }

  /// Texto curto dos horários para listas.
  String get timesLabel {
    if (!repeats) return time;
    return '$time às $endTime, a cada ${ReminderLabels.interval(intervalMinutes!)}';
  }

  /// Título exibido na notificação. Medicamento usa texto neutro: a
  /// notificação pode aparecer na tela bloqueada.
  String get notificationTitle =>
      type == 'medication' ? 'Lembrete do PicNutri' : displayTitle;

  /// Texto da notificação (sem orientação de saúde ou de dose).
  String get body => switch (type) {
    'water' => 'Que tal um copo de água agora?',
    'meal_time' => 'Hora de se alimentar.',
    'meal' => 'Registre o que você comeu no PicNutri.',
    'weigh_in' => 'Registre seu peso de hoje.',
    'medication' => 'Toque para abrir seus registros no PicNutri.',
    'water_goal' => 'Sua meta de água de hoje ainda não foi atingida.',
    'daily_log' => 'Você ainda não registrou refeições hoje.',
    'daily_goals' => 'Confira como estão suas metas de hoje.',
    'weekly_summary' => 'Seu resumo da semana está pronto.',
    'progress' => 'Veja como está sua evolução no PicNutri.',
    _ => 'Lembrete do PicNutri.',
  };

  /// Tela aberta ao tocar na notificação.
  String? get route => switch (type) {
    'water' || 'water_goal' => '/home/water',
    'meal' || 'daily_log' || 'meal_time' => '/food',
    'daily_goals' => '/home',
    'weigh_in' || 'progress' || 'medication' => '/progress',
    'weekly_summary' => '/progress/reports',
    _ => null,
  };
}

abstract final class ReminderLabels {
  static const types = {
    'water': 'Água',
    'meal_time': 'Hora de comer',
    'meal': 'Registrar refeição',
    'daily_log': 'Aviso de registro do dia',
    'weigh_in': 'Pesagem',
    'progress': 'Evolução',
    'weekly_summary': 'Resumo semanal',
    'medication': 'Medicamento',
    'custom': 'Personalizado',
    'water_goal': 'Aviso da meta de água',
    'daily_goals': 'Metas do dia',
  };

  /// Tipos de lembrete de cada categoria de preferência.
  static const typesByCategory = {
    'water': ['water'],
    'meals': ['meal_time'],
    'meal_log': ['meal', 'daily_log'],
    'progress': [
      'weigh_in',
      'progress',
      'weekly_summary',
      'medication',
      'custom',
    ],
    'goals': ['water_goal', 'daily_goals'],
  };

  static String categoryOf(String type) =>
      typesByCategory.entries
          .where((e) => e.value.contains(type))
          .firstOrNull
          ?.key ??
      'progress';

  /// Avisos que só disparam se a meta do dia ainda não foi cumprida.
  static const conditionalTypes = {'water_goal', 'daily_log', 'daily_goals'};

  /// Explicação exibida no formulário para tipos especiais.
  static const hints = {
    'water_goal':
        'Só avisa se a meta de água do dia ainda não tiver sido atingida.',
    'daily_log': 'Só avisa se nenhuma refeição tiver sido registrada no dia.',
    'daily_goals':
        'Só avisa se a meta de água ou o registro de refeições do dia estiverem pendentes.',
    'weekly_summary': 'Lembra você de conferir o resumo da semana.',
    'progress': 'Lembra você de acompanhar peso e evolução.',
    'meal_time': 'Lembra você do horário das refeições.',
  };

  static const weekdays = {
    1: 'Seg',
    2: 'Ter',
    3: 'Qua',
    4: 'Qui',
    5: 'Sex',
    6: 'Sáb',
    7: 'Dom',
  };

  /// Intervalos de repetição oferecidos (minutos).
  static const intervals = [30, 60, 90, 120, 180, 240];

  static String interval(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h h' : '${h}h$m';
  }

  static String days(List<int> days) {
    if (days.length == 7) return 'Todos os dias';
    if (days.length == 5 && days.every((d) => d <= 5)) return 'Dias úteis';
    return days.map((d) => weekdays[d]).join(', ');
  }
}

/// ID estável da notificação de um lembrete num dia da semana (0 = todos
/// os dias) e num dos horários do dia ([slot]).
int notificationId(String reminderId, int weekday, [int slot = 0]) {
  var hash = 17;
  for (final unit in reminderId.codeUnits) {
    hash = (hash * 31 + unit) & 0x003FFFFF;
  }
  return hash * 256 + (slot % 24) * 8 + weekday;
}
