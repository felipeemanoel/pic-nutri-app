import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/notifications/push_messaging.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/utils/device_timezone.dart';
import '../data/account.dart';
import '../data/auth_repository.dart';
import '../data/social_sign_in.dart';

export '../data/sign_in_methods.dart' show SocialFlowStep;

/// Estado da sessão do app.
sealed class SessionState {
  const SessionState();
}

final class SessionSignedOut extends SessionState {
  const SessionSignedOut({this.message});

  /// Motivo exibido na tela de login (ex.: sessão expirada).
  final String? message;
}

final class SessionSignedIn extends SessionState {
  const SessionSignedIn(this.account);

  final Account account;
}

/// Controla login, cadastro, renovação do token e encerramento da sessão.
///
/// O token fica só no armazenamento seguro; a conta é recarregada da API a
/// cada abertura do app (a API é a fonte da verdade).
class SessionController extends AsyncNotifier<SessionState> {
  static const expiredMessage = 'Sua sessão expirou. Entre novamente.';

  /// Renova o token quando faltar menos que isso para vencer.
  static const refreshWindow = Duration(days: 7);

  TokenStorage get _storage => ref.read(tokenStorageProvider);
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<SessionState> build() async {
    ref.listen(sessionExpiredSignalProvider, (_, _) => _expire());

    final token = await _storage.readAccessToken();
    if (token == null) {
      return const SessionSignedOut();
    }

    final expiresAt = await _storage.readExpiresAt();
    final now = DateTime.now().toUtc();
    if (expiresAt != null && !expiresAt.isAfter(now)) {
      await _storage.clear();
      return const SessionSignedOut(message: expiredMessage);
    }

    try {
      if (expiresAt != null && expiresAt.difference(now) < refreshWindow) {
        final session = await _repository.refresh();
        await _storage.writeSession(session.token, session.expiresAt);
        return SessionSignedIn(session.account);
      }
      return SessionSignedIn(await _repository.me());
    } on UnauthorizedFailure {
      await _storage.clear();
      return const SessionSignedOut(message: expiredMessage);
    }
  }

  Future<void> login({required String email, required String password}) async {
    final session = await _repository.login(
      email: email,
      password: password,
      deviceName: _deviceName(),
    );
    await _start(session);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required bool acceptTerms,
  }) async {
    final session = await _repository.register(
      name: name,
      email: email,
      password: password,
      acceptTerms: acceptTerms,
      deviceName: _deviceName(),
      timezone: await deviceTimezone(),
    );
    await _start(session);
  }

  /// Entra com uma credencial do Google, Facebook ou Apple já obtida no aparelho.
  ///
  /// Conta nova, e-mail ausente ou conta existente com o mesmo e-mail viram
  /// falhas com uma etapa pendente (ver [SocialFlowStep]); a tela continua o
  /// fluxo com [completeSocial] ou [linkSocial]. Conta nova vai para o
  /// onboarding; conta existente, para o início (decidido pelo roteador).
  Future<void> socialLogin(
    SocialCredential credential, {
    bool acceptTerms = false,
  }) async {
    final session = await _repository.social(
      credential.data,
      acceptTerms: acceptTerms,
      deviceName: _deviceName(),
      timezone: await deviceTimezone(),
    );
    await _start(session);
  }

  /// Conclui o cadastro social pendente. `false` = código enviado ao e-mail.
  Future<bool> completeSocial({
    required String pendingToken,
    bool acceptTerms = false,
    String? email,
    String? code,
  }) async {
    final session = await _repository.socialComplete(
      pendingToken: pendingToken,
      acceptTerms: acceptTerms,
      email: email,
      code: code,
      deviceName: _deviceName(),
      timezone: await deviceTimezone(),
    );
    if (session == null) return false;
    await _start(session);
    return true;
  }

  /// Vincula o acesso social à conta existente, comprovada por senha ou código.
  Future<void> linkSocial({
    required String pendingToken,
    String? password,
    String? code,
  }) async {
    final session = await _repository.socialLink(
      pendingToken: pendingToken,
      password: password,
      code: code,
      deviceName: _deviceName(),
    );
    await _start(session);
  }

  /// Atualiza a conta em memória após mudanças (perfil, onboarding).
  void updateAccount(Account account) {
    state = AsyncData(SessionSignedIn(account));
  }

  Future<void> reloadAccount() async {
    final account = await _repository.me();
    updateAccount(account);
  }

  Future<void> logout() async {
    // Antes de revogar o token: o servidor para de enviar push a este aparelho.
    await ref.read(pushMessagingProvider).disable();
    try {
      await _repository.logout();
    } on AppFailure {
      // Mesmo sem rede, a sessão local é encerrada; o token expira no servidor.
    }
    try {
      await ref.read(socialSignInProvider).signOut();
    } on Object {
      // Sem sessão do Google aberta (ou plugin indisponível): nada a fazer.
    }
    await _storage.clear();
    state = const AsyncData(SessionSignedOut());
  }

  /// Conta excluída no servidor: encerra a sessão local sem chamar a API.
  Future<void> accountDeleted() async {
    await _storage.clear();
    state = const AsyncData(
      SessionSignedOut(message: 'Sua conta e seus dados foram excluídos.'),
    );
  }

  Future<void> _start(AuthSession session) async {
    await _storage.writeSession(session.token, session.expiresAt);
    state = AsyncData(SessionSignedIn(session.account));
  }

  Future<void> _expire() async {
    if (state.value is SessionSignedOut) return;
    await _storage.clear();
    state = const AsyncData(SessionSignedOut(message: expiredMessage));
  }

  String _deviceName() {
    try {
      return 'PicNutri ${Platform.operatingSystem}';
    } on Object {
      return 'PicNutri';
    }
  }
}

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, SessionState>(
      SessionController.new,
    );

/// Conta autenticada atual (null fora de sessão).
final currentAccountProvider = Provider<Account?>((ref) {
  final session = ref.watch(sessionControllerProvider).value;
  return session is SessionSignedIn ? session.account : null;
});
