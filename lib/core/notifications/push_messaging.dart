import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/integrations.dart';
import '../error/app_failure.dart';
import '../network/api_client.dart';
import 'local_notifications.dart';

/// Push enviado pelo servidor (Firebase Cloud Messaging).
///
/// Desligado sem a configuração do Firebase no build. Com ela, registra o
/// token do aparelho na API (que só envia se as notificações estiverem
/// ativas no perfil), mostra avisos com o app aberto e abre a rota indicada
/// quando a notificação é tocada.
///
/// Toda mensagem do servidor também fica na central de notificações, que
/// independe desta permissão.
class PushMessaging {
  PushMessaging(this._dio, this._local);

  final Dio _dio;
  final LocalNotifications _local;
  bool _ready = false;
  String? _registered;
  // Notificações ligadas pelo usuário (token renovado só é registrado nesse caso).
  bool _wanted = false;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final _received = StreamController<void>.broadcast();

  /// Mensagem recebida com o app aberto (para atualizar a central e o contador).
  Stream<void> get received => _received.stream;

  Future<bool> _init() async {
    if (_ready) return true;
    if (!Integrations.push) return false;
    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: Platform.isIOS
              ? Integrations.firebaseIosApiKey
              : Integrations.firebaseAndroidApiKey,
          appId: Platform.isIOS
              ? Integrations.firebaseIosAppId
              : Integrations.firebaseAndroidAppId,
          messagingSenderId: Integrations.firebaseSenderId,
          projectId: Integrations.firebaseProjectId,
          iosBundleId: Platform.isIOS ? Integrations.iosBundleId : null,
        ),
      );
      final messaging = FirebaseMessaging.instance;
      // iOS: com o app aberto, o sistema mostra o aviso; no Android, o app mostra.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        sound: true,
      );
      _subscriptions
        ..add(FirebaseMessaging.onMessage.listen(_onForeground))
        ..add(FirebaseMessaging.onMessageOpenedApp.listen(_onOpened))
        // Token renovado pelo provedor: substitui o anterior na API.
        ..add(
          messaging.onTokenRefresh.listen((token) {
            if (_wanted) unawaited(_register(token));
          }),
        );
      final initial = await messaging.getInitialMessage();
      if (initial != null) _onOpened(initial);
      _ready = true;
      return true;
    } on Object catch (e) {
      debugPrint('Push indisponível: $e');
      return false;
    }
  }

  /// Registra o aparelho para receber push (após login, com notificações ativas).
  Future<void> enable() async {
    _wanted = true;
    if (!await _init()) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _register(token);
    } on Object catch (e) {
      debugPrint('Falha ao registrar push: $e');
    }
  }

  /// Remove o aparelho (logout ou notificações desativadas).
  Future<void> disable() async {
    _wanted = false;
    var token = _registered;
    _registered = null;
    // Registrado numa abertura anterior do app: busca o token atual do aparelho.
    if (token == null && await _init()) {
      try {
        token = await FirebaseMessaging.instance.getToken();
      } on Object {
        token = null;
      }
    }
    if (token == null) return;
    try {
      await guard(
        () => _dio.delete<void>('device-tokens', data: {'token': token}),
      );
    } on AppFailure {
      // Sem rede: o servidor remove o token quando o Firebase recusá-lo.
    }
  }

  Future<void> _register(String token) async {
    if (token == _registered) return;
    try {
      await guard(
        () => _dio.post<void>(
          'device-tokens',
          data: {
            'token': token,
            'platform': Platform.isIOS ? 'ios' : 'android',
            'previous_token': ?_registered,
          },
        ),
      );
      _registered = token;
    } on AppFailure catch (e) {
      // Sem rede: tenta de novo na próxima abertura do app.
      debugPrint('Falha ao registrar o aparelho: ${e.message}');
    }
  }

  void _onForeground(RemoteMessage message) {
    _received.add(null);
    if (Platform.isIOS) return; // No iOS o sistema mostra o aviso.
    final notification = message.notification;
    if (notification == null) return;
    final id = message.data['notification_id'] as String?;
    unawaited(
      _local.showNow(
        // Mesmo id para a mesma mensagem: novas tentativas do servidor não duplicam o aviso.
        id:
            (id ?? message.messageId ?? '${message.hashCode}').hashCode &
            0x7FFFFFFF,
        title: notification.title ?? 'PicNutri',
        body: notification.body ?? '',
        payload: NotificationTap.encode(
          route: message.data['route'] as String?,
          notificationId: id,
        ),
      ),
    );
  }

  void _onOpened(RemoteMessage message) {
    _local.openTap(
      NotificationTap(
        route: message.data['route'] as String?,
        notificationId: message.data['notification_id'] as String?,
      ),
    );
  }

  Future<void> dispose() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _received.close();
  }
}

final pushMessagingProvider = Provider<PushMessaging>((ref) {
  final push = PushMessaging(
    ref.watch(dioProvider),
    ref.watch(localNotificationsProvider),
  );
  ref.onDispose(() => unawaited(push.dispose()));
  return push;
});
