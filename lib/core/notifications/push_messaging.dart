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
class PushMessaging {
  PushMessaging(this._dio, this._local);

  final Dio _dio;
  final LocalNotifications _local;
  bool _ready = false;
  String? _registered;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  Future<bool> _init() async {
    if (_ready) return true;
    if (!Integrations.push) return false;
    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: Platform.isIOS ? Integrations.firebaseIosApiKey : Integrations.firebaseAndroidApiKey,
          appId: Platform.isIOS ? Integrations.firebaseIosAppId : Integrations.firebaseAndroidAppId,
          messagingSenderId: Integrations.firebaseSenderId,
          projectId: Integrations.firebaseProjectId,
          iosBundleId: Platform.isIOS ? Integrations.iosBundleId : null,
        ),
      );
      final messaging = FirebaseMessaging.instance;
      // iOS: com o app aberto, o sistema mostra o aviso; no Android, o app mostra.
      await messaging.setForegroundNotificationPresentationOptions(alert: true, sound: true);
      _subscriptions
        ..add(FirebaseMessaging.onMessage.listen(_onForeground))
        ..add(FirebaseMessaging.onMessageOpenedApp.listen(_onOpened))
        ..add(messaging.onTokenRefresh.listen(_register));
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
    final token = _registered;
    _registered = null;
    if (token == null) return;
    try {
      await guard(() => _dio.delete<void>('device-tokens', data: {'token': token}));
    } on AppFailure {
      // Sem rede: o servidor remove o token quando o Firebase recusá-lo.
    }
  }

  Future<void> _register(String token) async {
    if (token == _registered) return;
    await guard(
      () => _dio.post<void>(
        'device-tokens',
        data: {'token': token, 'platform': Platform.isIOS ? 'ios' : 'android'},
      ),
    );
    _registered = token;
  }

  void _onForeground(RemoteMessage message) {
    if (Platform.isIOS) return;
    final notification = message.notification;
    if (notification == null) return;
    unawaited(
      _local.showNow(
        id: message.hashCode & 0x7FFFFFFF,
        title: notification.title ?? 'PicNutri',
        body: notification.body ?? '',
        payload: message.data['route'] as String?,
      ),
    );
  }

  void _onOpened(RemoteMessage message) {
    final route = message.data['route'];
    if (route is String) _local.openRoute(route);
  }

  Future<void> dispose() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
  }
}

final pushMessagingProvider = Provider<PushMessaging>((ref) {
  final push = PushMessaging(ref.watch(dioProvider), ref.watch(localNotificationsProvider));
  ref.onDispose(() => unawaited(push.dispose()));
  return push;
});
