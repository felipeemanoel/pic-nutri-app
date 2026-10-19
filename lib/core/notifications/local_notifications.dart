import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../app/features.dart';
import '../design/tokens.dart';

/// Notificação a agendar: semanal (um dia da semana), diária (sem dia) ou
/// única (com data), sempre num horário.
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

  /// 1 = segunda ... 7 = domingo; null = todos os dias.
  final int? weekday;
  final int hour;
  final int minute;

  /// Quando informado, a notificação é única nesse dia (sem repetir).
  final DateTime? date;

  /// Rota do app aberta ao tocar na notificação.
  final String? payload;
}

/// Notificação tocada: tela a abrir e, se veio do servidor, a mensagem da central.
class NotificationTap {
  const NotificationTap({this.route, this.notificationId});

  /// Lê o payload gravado na notificação (JSON ou, nos lembretes, só a rota).
  static NotificationTap? parse(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    if (payload.startsWith('/')) return NotificationTap(route: payload);
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      return NotificationTap(
        route: data['route'] as String?,
        notificationId: data['notification_id'] as String?,
      );
    } on Object {
      return null;
    }
  }

  static String encode({String? route, String? notificationId}) =>
      jsonEncode({'route': ?route, 'notification_id': ?notificationId});

  final String? route;
  final String? notificationId;
}

/// Situação da permissão de notificações no sistema.
enum NotificationPermission {
  granted,
  denied,

  /// iOS: ainda não perguntado.
  notDetermined,

  /// Plataforma sem suporte (testes, desktop).
  unavailable,
}

/// Notificações locais (lembretes). Nada sai do aparelho: o sistema dispara
/// as notificações agendadas mesmo sem internet.
class LocalNotifications {
  LocalNotifications([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;
  final _taps = StreamController<NotificationTap>.broadcast();

  /// Canal nativo (MainActivity/AppDelegate): situação da permissão e atalho
  /// para as configurações de notificação do app no sistema.
  static const _settingsChannel = MethodChannel(
    'br.com.picnutri/notification_settings',
  );

  /// O iOS mantém no máximo 64 notificações agendadas por app.
  static const maxScheduled = 60;

  /// Notificações tocadas pelo usuário.
  Stream<NotificationTap> get taps => _taps.stream;

  // Conteúdo escondido na tela bloqueada (Android); os textos também evitam dados de saúde.
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Lembretes',
      channelDescription: AppFeatures.medical
          ? 'Lembretes de água, refeições, pesagem e medicamento'
          : 'Lembretes de água, refeições e pesagem',
      importance: Importance.defaultImportance,
      visibility: NotificationVisibility.private,
      color: PicPalette.primary,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void>? _initializing;

  // Uma única inicialização, mesmo com chamadas simultâneas (o toque que abriu o app é entregue uma vez).
  Future<void> _init() =>
      _initializing ??= _initialize().catchError((Object e) {
        _initializing = null;
        throw e;
      });

  Future<void> _initialize() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        // A permissão é pedida só depois de explicar o motivo ao usuário.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final tap = NotificationTap.parse(response.payload);
        if (tap != null) _taps.add(tap);
      },
    );
    _ready = true;
    // App aberto por uma notificação: entrega a rota também.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final tap = NotificationTap.parse(launch?.notificationResponse?.payload);
    if ((launch?.didNotificationLaunchApp ?? false) && tap != null) {
      _taps.add(tap);
    }
  }

  /// Inicializa cedo (no início da sessão) para receber o toque que abriu o app.
  Future<void> ensureInitialized() => _safe(_init, fallback: null);

  /// Situação atual da permissão no sistema.
  Future<NotificationPermission> permissionStatus() async {
    try {
      final status = await _settingsChannel.invokeMethod<String>('status');
      return switch (status) {
        'granted' => NotificationPermission.granted,
        'notDetermined' => NotificationPermission.notDetermined,
        'denied' => NotificationPermission.denied,
        _ => NotificationPermission.unavailable,
      };
    } on MissingPluginException {
      return NotificationPermission.unavailable;
    } on PlatformException {
      return NotificationPermission.unavailable;
    }
  }

  /// Abre as configurações de notificação do app no sistema.
  Future<bool> openSystemSettings() async {
    try {
      return await _settingsChannel.invokeMethod<bool>('open') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
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
    for (final n in notifications.take(maxScheduled)) {
      final once = n.date;
      final when = once == null
          ? _next(location, n.weekday, n.hour, n.minute)
          : tz.TZDateTime(
              location,
              once.year,
              once.month,
              once.day,
              n.hour,
              n.minute,
            );
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
        matchDateTimeComponents: once != null
            ? null
            : n.weekday == null
            ? DateTimeComponents.time
            : DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }, fallback: null);

  static const _serverDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'server',
      'Avisos do PicNutri',
      channelDescription:
          'Análises prontas, respostas do assistente e avisos da conta',
      importance: Importance.high,
      visibility: NotificationVisibility.private,
      color: PicPalette.primary,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Exibe agora uma notificação recebida do servidor com o app aberto.
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) => _safe(() async {
    await _init();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _serverDetails,
      payload: payload,
    );
  }, fallback: null);

  /// Repassa uma notificação do servidor tocada pelo usuário.
  void openTap(NotificationTap tap) => _taps.add(tap);

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

  tz.TZDateTime _next(
    tz.Location location,
    int? weekday,
    int hour,
    int minute,
  ) {
    final now = tz.TZDateTime.now(location);
    var date = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while ((weekday != null && date.weekday != weekday) || !date.isAfter(now)) {
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
