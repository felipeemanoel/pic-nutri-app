/// Lembrete configurado pelo usuário (dias 1 = segunda ... 7 = domingo).
class Reminder {
  const Reminder({
    required this.id,
    required this.type,
    required this.displayTitle,
    required this.time,
    required this.days,
    required this.enabled,
    this.title,
    this.medicationId,
  });

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
  );

  final String id;
  final String type;
  final String? title;
  final String displayTitle;

  /// "HH:MM" no fuso do perfil.
  final String time;
  final List<int> days;
  final bool enabled;
  final String? medicationId;

  int get hour => int.parse(time.split(':')[0]);
  int get minute => int.parse(time.split(':')[1]);

  /// Texto da notificação (sem orientação de saúde ou de dose).
  String get body => switch (type) {
    'water' => 'Que tal um copo de água agora?',
    'meal' => 'Registre o que você comeu no PicNutri.',
    'weigh_in' => 'Registre seu peso de hoje.',
    'medication' =>
      'Registre sua aplicação no PicNutri, conforme sua prescrição.',
    'water_goal' => 'Sua meta de água de hoje ainda não foi atingida.',
    'daily_log' => 'Você ainda não registrou refeições hoje.',
    'weekly_summary' => 'Seu resumo da semana está pronto.',
    'progress' => 'Veja como está sua evolução no PicNutri.',
    _ => 'Lembrete do PicNutri.',
  };

  /// Tela aberta ao tocar na notificação.
  String? get route => switch (type) {
    'water' || 'water_goal' => '/home/water',
    'meal' || 'daily_log' => '/food',
    'weigh_in' || 'progress' || 'medication' => '/progress',
    'weekly_summary' => '/progress/reports',
    _ => null,
  };
}

abstract final class ReminderLabels {
  static const types = {
    'water': 'Água',
    'meal': 'Refeição',
    'weigh_in': 'Pesagem',
    'medication': 'Medicamento',
    'water_goal': 'Aviso da meta de água',
    'daily_log': 'Aviso de registro do dia',
    'weekly_summary': 'Resumo semanal',
    'progress': 'Evolução',
    'custom': 'Personalizado',
  };

  /// Explicação exibida no formulário para tipos especiais.
  static const hints = {
    'water_goal':
        'Só avisa se a meta de água do dia ainda não tiver sido atingida.',
    'daily_log': 'Só avisa se nenhuma refeição tiver sido registrada no dia.',
    'weekly_summary': 'Lembra você de conferir o resumo da semana.',
    'progress': 'Lembra você de acompanhar peso e evolução.',
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

  static String days(List<int> days) {
    if (days.length == 7) return 'Todos os dias';
    if (days.length == 5 && days.every((d) => d <= 5)) return 'Dias úteis';
    return days.map((d) => weekdays[d]).join(', ');
  }
}

/// ID estável da notificação de um lembrete em um dia da semana.
int notificationId(String reminderId, int weekday) {
  var hash = 17;
  for (final unit in reminderId.codeUnits) {
    hash = (hash * 31 + unit) & 0x0FFFFFFF;
  }
  return hash * 8 + weekday;
}
