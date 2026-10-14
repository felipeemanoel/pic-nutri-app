import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Notificação semanal a agendar (um dia da semana, um horário).
class WeeklyNotification {
  const WeeklyNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.weekday,
    required this.hour,
    required this.minute,
    this.date,
    this.payload,
  });

  final int id;
  final String title;
  final String body;

  /// 1 = segunda ... 7 = domingo.
  final int weekday;
  final int hour;
  final int minute;

  /// Quando informado, a notificação é única nesse dia (sem repetir).
  final DateTime? date;

  /// Rota do app aberta ao tocar na notificação.
  final String? payload;
}

/// Notificações locais (lembretes). Nada sai do aparelho: o sistema dispara
/// as notificações agendadas mesmo sem internet.
class LocalNotifications {
  LocalNotifications([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;
  final _taps = StreamController<String>.broadcast();

  /// Rotas das notificações tocadas pelo usuário.
  Stream<String> get taps => _taps.stream;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Lembretes',
      channelDescription: 'Lembretes de água, refeições, pesagem e medicamento',
      importance: Importance.defaultImportance,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // A permissão é pedida só depois de explicar o motivo ao usuário.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.startsWith('/')) _taps.add(payload);
      },
    );
    _ready = true;
    // App aberto por uma notificação: entrega a rota também.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final payload = launch?.notificationResponse?.payload;
    if ((launch?.didNotificationLaunchApp ?? false) && payload != null && payload.startsWith('/')) {
      _taps.add(payload);
    }
  }

  /// Pede a permissão do sistema. Retorna `true` se concedida.
  Future<bool> requestPermission() => _safe(() async {
    await _init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }, fallback: false);

  /// Substitui todos os agendamentos pelos informados.
  Future<void> replaceAll(
    List<WeeklyNotification> notifications, {
    required String timezone,
  }) => _safe(() async {
    await _init();
    await _plugin.cancelAll();
    final location = _location(timezone);
    final now = tz.TZDateTime.now(location);
    for (final n in notifications) {
      final once = n.date;
      final when = once == null
          ? _next(location, n.weekday, n.hour, n.minute)
          : tz.TZDateTime(location, once.year, once.month, once.day, n.hour, n.minute);
      if (once != null && !when.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        id: n.id,
        title: n.title,
        body: n.body,
        payload: n.payload,
        scheduledDate: when,
        notificationDetails: _details,
        // Sem alarme exato: dispensa permissão especial; pode atrasar alguns minutos.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: once == null ? DateTimeComponents.dayOfWeekAndTime : null,
      );
    }
  }, fallback: null);

  static const _serverDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'server',
      'Avisos do PicNutri',
      channelDescription: 'Análises prontas, respostas do assistente e avisos da conta',
      importance: Importance.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Exibe agora uma notificação recebida do servidor com o app aberto.
  Future<void> showNow({required int id, required String title, required String body, String? payload}) =>
      _safe(() async {
        await _init();
        await _plugin.show(id: id, title: title, body: body, notificationDetails: _serverDetails, payload: payload);
      }, fallback: null);

  /// Repassa a rota de uma notificação do servidor tocada pelo usuário.
  void openRoute(String route) {
    if (route.startsWith('/')) _taps.add(route);
  }

  Future<void> cancelAll() => _safe(() async {
    await _init();
    await _plugin.cancelAll();
  }, fallback: null);

  tz.Location _location(String name) {
    try {
      return tz.getLocation(name);
    } on Object {
      return tz.getLocation('America/Sao_Paulo');
    }
  }

  tz.TZDateTime _next(tz.Location location, int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(location);
    var date = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (date.weekday != weekday || !date.isAfter(now)) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  /// Em testes e plataformas sem o plugin, as chamadas não fazem nada.
  Future<T> _safe<T>(Future<T> Function() call, {required T fallback}) async {
    try {
      return await call();
    } on MissingPluginException {
      return fallback;
    } on PlatformException catch (error) {
      debugPrint('Notificações locais: ${error.code}');
      return fallback;
    }
  }
}

final localNotificationsProvider = Provider<LocalNotifications>(
  (ref) => LocalNotifications(),
);
