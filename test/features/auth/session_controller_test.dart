import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picnutri/app/env.dart';
import 'package:picnutri/core/error/app_failure.dart';
import 'package:picnutri/core/network/api_client.dart';
import 'package:picnutri/core/storage/token_storage.dart';
import 'package:picnutri/features/auth/application/session_controller.dart';
import 'package:picnutri/features/auth/data/account.dart';
import 'package:picnutri/features/auth/data/auth_repository.dart';

import '../../helpers/fakes.dart';

void main() {
  late MemoryTokenStorage storage;
  late MockAuthRepository repository;

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      retry: noAutomaticRetry,
      overrides: [
        appEnvProvider.overrideWithValue(testEnv),
        tokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    storage = MemoryTokenStorage();
    repository = MockAuthRepository();
  });

  test('sem token salvo, começa deslogado', () async {
    final container = makeContainer();
    expect(
      await container.read(sessionControllerProvider.future),
      isA<SessionSignedOut>(),
    );
  });

  test('token vencido é descartado e avisa sessão expirada', () async {
    storage
      ..token = 'pn_old'
      ..expiresAt = DateTime.now().toUtc().subtract(const Duration(minutes: 1));
    final container = makeContainer();

    final state = await container.read(sessionControllerProvider.future);

    expect(state, isA<SessionSignedOut>());
    expect(
      (state as SessionSignedOut).message,
      SessionController.expiredMessage,
    );
    expect(storage.token, isNull);
  });

  test('token válido carrega a conta pela API', () async {
    storage
      ..token = 'pn_ok'
      ..expiresAt = DateTime.now().toUtc().add(const Duration(days: 20));
    when(() => repository.me()).thenAnswer((_) async => testAccount());
    final container = makeContainer();

    final state = await container.read(sessionControllerProvider.future);

    expect(state, isA<SessionSignedIn>());
    verifyNever(() => repository.refresh());
  });

  test('token perto de vencer é renovado e salvo', () async {
    storage
      ..token = 'pn_old'
      ..expiresAt = DateTime.now().toUtc().add(const Duration(days: 2));
    final newExpiry = DateTime.now().toUtc().add(const Duration(days: 30));
    when(() => repository.refresh()).thenAnswer(
      (_) async => AuthSession(
        token: 'pn_new',
        expiresAt: newExpiry,
        account: testAccount(),
      ),
    );
    final container = makeContainer();

    await container.read(sessionControllerProvider.future);

    expect(storage.token, 'pn_new');
    expect(storage.expiresAt, newExpiry);
  });

  test('API recusando o token encerra a sessão', () async {
    storage.token = 'pn_revoked';
    when(() => repository.me()).thenThrow(const UnauthorizedFailure());
    final container = makeContainer();

    final state = await container.read(sessionControllerProvider.future);

    expect(state, isA<SessionSignedOut>());
    expect(storage.token, isNull);
  });

  test('sinal de 401 durante o uso encerra a sessão com aviso', () async {
    storage.token = 'pn_ok';
    when(() => repository.me()).thenAnswer((_) async => testAccount());
    final container = makeContainer();
    await container.read(sessionControllerProvider.future);

    container.read(sessionExpiredSignalProvider.notifier).fire();
    await Future<void>.delayed(Duration.zero);

    final state = container.read(sessionControllerProvider).value;
    expect(state, isA<SessionSignedOut>());
    expect(
      (state as SessionSignedOut).message,
      SessionController.expiredMessage,
    );
    expect(storage.token, isNull);
  });

  test('login salva o token e entra', () async {
    when(
      () => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
        deviceName: any(named: 'deviceName'),
      ),
    ).thenAnswer(
      (_) async =>
          AuthSession(token: 'pn_new', expiresAt: null, account: testAccount()),
    );
    final container = makeContainer();
    await container.read(sessionControllerProvider.future);

    await container
        .read(sessionControllerProvider.notifier)
        .login(email: 'maria@example.com', password: 'senha-forte-123');

    expect(storage.token, 'pn_new');
    expect(
      container.read(sessionControllerProvider).value,
      isA<SessionSignedIn>(),
    );
  });

  test('logout limpa a sessão mesmo sem rede', () async {
    storage.token = 'pn_ok';
    when(() => repository.me()).thenAnswer((_) async => testAccount());
    when(() => repository.logout()).thenThrow(const NetworkFailure());
    final container = makeContainer();
    await container.read(sessionControllerProvider.future);

    await container.read(sessionControllerProvider.notifier).logout();

    expect(storage.token, isNull);
    expect(
      container.read(sessionControllerProvider).value,
      isA<SessionSignedOut>(),
    );
  });
}
