import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/app/env.dart';
import 'package:picnutri/core/storage/token_storage.dart';
import 'package:picnutri/features/auth/application/session_controller.dart';
import 'package:picnutri/features/home/data/dashboard_repository.dart';
import 'package:picnutri/features/progress/data/body_repository.dart';

import '../../helpers/fakes.dart';

class _SwitchableSession extends SessionController {
  _SwitchableSession(this._initial);

  final SessionState _initial;

  @override
  Future<SessionState> build() async => _initial;

  void set(SessionState next) => state = AsyncData(next);
}

void main() {
  test(
    'trocar de conta descarta os repositórios (e o cache) da conta anterior',
    () async {
      final container = ProviderContainer(
        overrides: [
          appEnvProvider.overrideWithValue(testEnv),
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          sessionControllerProvider.overrideWith(
            () => _SwitchableSession(SessionSignedIn(testAccount())),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(sessionControllerProvider.future);

      final body = container.read(bodyRepositoryProvider);
      final dashboard = container.read(dashboardRepositoryProvider);
      expect(container.read(sessionScopeProvider), 'maria@example.com');

      // Atualizar o perfil da mesma conta não descarta nada.
      final session =
          container.read(sessionControllerProvider.notifier)
              as _SwitchableSession;
      session.set(SessionSignedIn(testAccount(name: 'Maria S.')));
      expect(container.read(bodyRepositoryProvider), same(body));

      // Sair da conta recria os repositórios.
      session.set(const SessionSignedOut());
      expect(container.read(sessionScopeProvider), isNull);
      expect(container.read(bodyRepositoryProvider), isNot(same(body)));
      expect(
        container.read(dashboardRepositoryProvider),
        isNot(same(dashboard)),
      );
    },
  );
}
