import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picnutri/app/env.dart';
import 'package:picnutri/core/error/app_failure.dart';
import 'package:picnutri/core/storage/token_storage.dart';
import 'package:picnutri/features/auth/data/account.dart';
import 'package:picnutri/features/auth/data/auth_repository.dart';
import 'package:picnutri/features/auth/data/social_sign_in.dart';
import 'package:picnutri/features/auth/presentation/social_buttons.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../helpers/fakes.dart';

/// Provedor falso: devolve a credencial ou simula cancelamento/falha.
class FakeSocialSignIn extends SocialSignIn {
  Object? error;
  int calls = 0;

  @override
  Future<SocialCredential> signIn(String provider) async {
    calls++;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (error != null) throw error!;
    return SocialCredential(provider: provider, accessToken: 'tok-$provider');
  }
}

AuthSession _session({bool onboarded = false}) => AuthSession(
  token: 't',
  expiresAt: null,
  account: testAccount(onboarded: onboarded),
);

BusinessFailure _step(String code, Map<String, dynamic> details) =>
    BusinessFailure('etapa', code: code, details: details);

/// Avança alguns quadros: o botão segue carregando enquanto uma etapa do
/// fluxo está aberta, então pumpAndSettle não estabiliza.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late MockAuthRepository repository;
  late FakeSocialSignIn social;
  late MemoryTokenStorage storage;

  setUpAll(() {
    registerFallbackValue(const SocialCredentialData('x', {}));
    TestWidgetsFlutterBinding.ensureInitialized();
    // Fuso do aparelho (plugin nativo), enviado no cadastro.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_timezone'),
          (call) async => 'America/Recife',
        );
  });

  setUp(() {
    repository = MockAuthRepository();
    social = FakeSocialSignIn();
    storage = MemoryTokenStorage();
  });

  Widget app(Set<String> providers) => ProviderScope(
    overrides: [
      appEnvProvider.overrideWithValue(testEnv),
      tokenStorageProvider.overrideWithValue(storage),
      authRepositoryProvider.overrideWithValue(repository),
      socialSignInProvider.overrideWithValue(social),
      socialProvidersProvider.overrideWith((ref) async => providers),
    ],
    child: const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: SocialButtons())),
    ),
  );

  void socialReturns(Future<AuthSession> Function() answer) => when(
    () => repository.social(
      any(),
      deviceName: any(named: 'deviceName'),
      acceptTerms: any(named: 'acceptTerms'),
      timezone: any(named: 'timezone'),
    ),
  ).thenAnswer((_) => answer());

  group('provedores por plataforma', () {
    test('Android: Google e Facebook; iOS: também a Apple', () {
      expect(
        platformSocialProviders(
          TargetPlatform.android,
          google: true,
          facebook: true,
        ),
        {'google', 'facebook'},
      );
      expect(
        platformSocialProviders(
          TargetPlatform.iOS,
          google: true,
          facebook: true,
        ),
        {'google', 'facebook', 'apple'},
      );
      expect(
        platformSocialProviders(
          TargetPlatform.iOS,
          google: false,
          facebook: false,
        ),
        {'apple'},
      );
      expect(
        platformSocialProviders(
          TargetPlatform.macOS,
          google: true,
          facebook: true,
        ),
        isEmpty,
      );
    });

    testWidgets('Android: Google e Facebook, sem Apple', (tester) async {
      await tester.pumpWidget(app({'google', 'facebook'}));
      await tester.pumpAndSettle();

      expect(find.text('Continuar com Google'), findsOneWidget);
      expect(find.text('Continuar com Facebook'), findsOneWidget);
      expect(find.byType(SignInWithAppleButton), findsNothing);
    });

    testWidgets('iOS: inclui o botão oficial da Apple', (tester) async {
      await tester.pumpWidget(app({'google', 'facebook', 'apple'}));
      await tester.pumpAndSettle();

      expect(find.byType(SignInWithAppleButton), findsOneWidget);
      expect(find.text('Continuar com Google'), findsOneWidget);
      expect(find.text('Continuar com Facebook'), findsOneWidget);
    });
  });

  testWidgets('cancelar no provedor volta ao login sem erro', (tester) async {
    social.error = const SocialSignInCanceled();
    await tester.pumpWidget(app({'google', 'facebook'}));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continuar com Facebook'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    verifyNever(
      () => repository.social(any(), deviceName: any(named: 'deviceName')),
    );
    final button = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Continuar com Facebook'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('falha no provedor mostra mensagem clara', (tester) async {
    social.error = const SocialSignInFailed('google');
    await tester.pumpWidget(app({'google'}));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continuar com Google'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Não foi possível continuar com o Google'),
      findsOneWidget,
    );
  });

  testWidgets('sem conexão com a API, informa e permite tentar de novo', (
    tester,
  ) async {
    socialReturns(() async => throw const NetworkFailure());
    await tester.pumpWidget(app({'google'}));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continuar com Google'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('mostra carregamento e ignora toques duplicados', (tester) async {
    socialReturns(() async => _session(onboarded: true));
    await tester.pumpWidget(app({'google', 'facebook'}));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continuar com Google'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(
      find.text('Continuar com Facebook'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(social.calls, 1);
    expect(storage.token, 't');
  });

  testWidgets('conta nova: pede o aceite dos termos e conclui o cadastro', (
    tester,
  ) async {
    socialReturns(
      () async =>
          throw _step('terms_acceptance_required', {'pending_token': 'p1'}),
    );
    when(
      () => repository.socialComplete(
        pendingToken: 'p1',
        acceptTerms: true,
        deviceName: any(named: 'deviceName'),
        timezone: any(named: 'timezone'),
      ),
    ).thenAnswer((_) async => _session());
    await tester.pumpWidget(app({'google'}));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continuar com Google'));
    await settle(tester);
    expect(find.text('Criar sua conta'), findsOneWidget);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.text('Criar conta'));
    await settle(tester);

    expect(storage.token, 't');
  });

  testWidgets(
    'e-mail de conta existente: comprova com a senha antes de vincular',
    (tester) async {
      socialReturns(
        () async => throw _step('account_link_required', {
          'pending_token': 'p2',
          'email': 'm***a@gmail.com',
          'methods': ['password', 'email_code'],
        }),
      );
      when(
        () => repository.socialLink(
          pendingToken: 'p2',
          password: 'minha-senha',
          deviceName: any(named: 'deviceName'),
        ),
      ).thenAnswer((_) async => _session(onboarded: true));
      await tester.pumpWidget(app({'google'}));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuar com Google'));
      await settle(tester);
      expect(find.text('Você já tem uma conta'), findsOneWidget);
      expect(find.textContaining('m***a@gmail.com'), findsOneWidget);
      expect(storage.token, isNull);

      await tester.enterText(find.byType(TextField), 'minha-senha');
      await tester.tap(find.text('Confirmar e vincular'));
      await settle(tester);

      verify(
        () => repository.socialLink(
          pendingToken: 'p2',
          password: 'minha-senha',
          deviceName: any(named: 'deviceName'),
        ),
      ).called(1);
      expect(storage.token, 't');
    },
  );

  testWidgets('Facebook sem e-mail: informa e confirma o e-mail com código', (
    tester,
  ) async {
    socialReturns(
      () async => throw _step('social_email_required', {'pending_token': 'p3'}),
    );
    when(
      () => repository.socialComplete(
        pendingToken: 'p3',
        email: 'ana@exemplo.com',
        deviceName: any(named: 'deviceName'),
        timezone: any(named: 'timezone'),
      ),
    ).thenAnswer((_) async => null);
    when(
      () => repository.socialComplete(
        pendingToken: 'p3',
        code: '123456',
        acceptTerms: true,
        deviceName: any(named: 'deviceName'),
        timezone: any(named: 'timezone'),
      ),
    ).thenAnswer((_) async => _session());
    await tester.pumpWidget(app({'facebook'}));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continuar com Facebook'));
    await settle(tester);
    expect(find.text('Informe seu e-mail'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ana@exemplo.com');
    await tester.tap(find.text('Enviar código'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Código'), '123456');
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.text('Criar conta'));
    await settle(tester);

    expect(storage.token, 't');
  });

  test('lê a etapa pendente dos detalhes do erro da API', () {
    final options = RequestOptions(path: '/auth/social/google');
    final failure = AppFailure.fromDioException(
      DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: 409,
          data: {
            'error': {
              'code': 'account_link_required',
              'message': 'Já existe uma conta.',
              'details': {
                'pending_token': 'abc',
                'email': 'm***a@gmail.com',
                'methods': ['email_code'],
              },
            },
          },
        ),
      ),
    );

    final step = SocialFlowStep.fromFailure(failure.code, failure.details);
    expect(step?.pendingToken, 'abc');
    expect(step?.maskedEmail, 'm***a@gmail.com');
    expect(step?.methods, ['email_code']);
    expect(
      SocialFlowStep.fromFailure('social_token_invalid', const {
        'pending_token': 'x',
      }),
      isNull,
    );
  });

  test('desvincular só é possível se restar outro acesso', () {
    Map<String, dynamic> methods({required bool password}) => {
      'has_password': password,
      'email': 'a@b.com',
      'providers': [
        {'provider': 'google', 'linked_at': '2026-10-19T10:00:00Z'},
      ],
    };

    expect(
      SignInMethods.fromJson(methods(password: false)).canUnlink('google'),
      isFalse,
    );
    expect(
      SignInMethods.fromJson(methods(password: true)).canUnlink('google'),
      isTrue,
    );
  });
}
