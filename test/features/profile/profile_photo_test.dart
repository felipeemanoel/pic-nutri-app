import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/app/theme/app_theme.dart';
import 'package:picnutri/core/error/app_failure.dart';
import 'package:picnutri/features/auth/application/session_controller.dart';
import 'package:picnutri/features/auth/data/account.dart';
import 'package:picnutri/features/profile/data/profile_repository.dart';
import 'package:picnutri/features/profile/presentation/profile_photo.dart';
import 'package:picnutri/shared/widgets/account_avatar.dart';

import '../../helpers/fakes.dart';

Account _account({String? version}) {
  final account = testAccount();
  return Account(
    name: account.name,
    email: account.email,
    onboardingCompleted: true,
    consents: account.consents,
    profile: account.profile,
    avatarVersion: version,
  );
}

class _PhotoRepository extends ProfileRepository {
  _PhotoRepository({this.fail = false}) : super(Dio());
  final bool fail;
  int removed = 0;
  @override
  Future<Account> removeAvatar() async {
    if (fail) throw const BusinessFailure('Não foi possível remover a foto.');
    removed++;
    return _account();
  }
}

Future<void> _mount(
  WidgetTester tester,
  _PhotoRepository repository, {
  String? version,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...sessionOverrides(SessionSignedIn(_account(version: version))),
        profileRepositoryProvider.overrideWithValue(repository),
        accountAvatarProvider.overrideWith((ref) async => null),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: Center(child: ProfilePhoto())),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'foto opcional oferece câmera e galeria, com iniciais como alternativa',
    (tester) async {
      await _mount(tester, _PhotoRepository());
      expect(find.text('M'), findsOneWidget);
      await tester.tap(find.text('Adicionar foto'));
      await tester.pumpAndSettle();
      expect(find.text('Tirar foto'), findsOneWidget);
      expect(find.text('Escolher da galeria'), findsOneWidget);
      expect(find.text('Remover foto'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('remoção confirmada atualiza a conta e retorna às iniciais', (
    tester,
  ) async {
    final repository = _PhotoRepository();
    await _mount(tester, repository, version: 'foto-v1');
    await tester.tap(find.text('Alterar foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover foto'));
    await tester.pumpAndSettle();
    expect(repository.removed, 0);
    await tester.tap(find.widgetWithText(FilledButton, 'Remover'));
    await tester.pumpAndSettle();
    expect(repository.removed, 1);
    expect(find.text('Adicionar foto'), findsOneWidget);
    expect(find.text('M'), findsOneWidget);
  });

  testWidgets('falha ao remover mantém a foto e permite nova tentativa', (
    tester,
  ) async {
    final repository = _PhotoRepository(fail: true);
    await _mount(tester, repository, version: 'foto-v1');
    await tester.tap(find.text('Alterar foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remover'));
    await tester.pumpAndSettle();
    expect(find.text('Alterar foto'), findsOneWidget);
    expect(find.text('Não foi possível remover a foto.'), findsOneWidget);
    expect(repository.removed, 0);
  });
}
