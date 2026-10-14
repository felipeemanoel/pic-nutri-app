import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/app/router.dart';
import 'package:picnutri/features/auth/application/session_controller.dart';

import '../helpers/fakes.dart';

void main() {
  const signedOut = AsyncData<SessionState>(SessionSignedOut());
  final onboarded = AsyncData<SessionState>(SessionSignedIn(testAccount()));
  final pending = AsyncData<SessionState>(
    SessionSignedIn(testAccount(onboarded: false)),
  );

  test('enquanto a sessão carrega, mostra a abertura', () {
    expect(redirectFor(const AsyncLoading(), AppRoutes.home), AppRoutes.splash);
    expect(redirectFor(const AsyncLoading(), AppRoutes.splash), isNull);
  });

  test('sem sessão, só permite rotas públicas', () {
    expect(redirectFor(signedOut, AppRoutes.home), AppRoutes.login);
    expect(redirectFor(signedOut, AppRoutes.register), isNull);
    expect(redirectFor(signedOut, AppRoutes.resetPassword), isNull);
  });

  test('com sessão e onboarding pendente, força o onboarding', () {
    expect(redirectFor(pending, AppRoutes.home), AppRoutes.onboarding);
    expect(redirectFor(pending, AppRoutes.onboarding), isNull);
  });

  test('com sessão completa, sai das telas de conta e vai para o início', () {
    expect(redirectFor(onboarded, AppRoutes.login), AppRoutes.home);
    expect(redirectFor(onboarded, AppRoutes.splash), AppRoutes.home);
    expect(redirectFor(onboarded, AppRoutes.onboarding), AppRoutes.home);
    expect(redirectFor(onboarded, AppRoutes.profile), isNull);
  });
}
