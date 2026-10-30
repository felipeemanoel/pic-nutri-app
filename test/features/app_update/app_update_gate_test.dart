import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/app_update/application/app_update_controller.dart';
import 'package:picnutri/features/app_update/data/app_update_repository.dart';
import 'package:picnutri/features/app_update/presentation/app_update_gate.dart';

class _FakeRepo extends AppUpdateRepository {
  _FakeRepo(this.status) : super(Dio());

  final String status;
  int calls = 0;

  @override
  Future<AppUpdateInfo> check({
    required String platform,
    required int build,
  }) async {
    calls++;
    return AppUpdateInfo.fromJson({
      'status': status,
      'latest_version': '0.3.0',
      'store_url':
          'https://play.google.com/store/apps/details?id=br.com.picnutri',
      'message': 'Atualize para ver as novidades.',
    });
  }
}

Widget _app(_FakeRepo repo) => ProviderScope(
  overrides: [
    installedBuildProvider.overrideWith(
      (ref) async => (platform: 'android', build: 4),
    ),
    appUpdateRepositoryProvider.overrideWithValue(repo),
  ],
  child: MaterialApp(
    builder: (context, child) => AppUpdateGate(child: child!),
    home: const Scaffold(body: Center(child: Text('Início'))),
  ),
);

void main() {
  testWidgets('versão nova: convite com "Atualizar" e "Agora não"', (
    tester,
  ) async {
    final repo = _FakeRepo('optional');
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();
    expect(repo.calls, 1);
    expect(find.text('Versão 0.3.0 disponível'), findsOneWidget);
    expect(find.text('Atualizar'), findsOneWidget);
    await tester.tap(find.text('Agora não'));
    await tester.pumpAndSettle();
    expect(find.text('Versão 0.3.0 disponível'), findsNothing);
    expect(find.text('Início'), findsOneWidget);
  });

  testWidgets('abaixo da versão mínima: cobre o app até atualizar', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_FakeRepo('required')));
    await tester.pumpAndSettle();
    expect(find.text('Atualize o PicNutri'), findsOneWidget);
    expect(find.text('Atualizar agora'), findsOneWidget);
    expect(find.text('Agora não'), findsNothing);
  });

  testWidgets('atualizado: nada aparece', (tester) async {
    await tester.pumpWidget(_app(_FakeRepo('up_to_date')));
    await tester.pumpAndSettle();
    expect(find.text('Atualizar'), findsNothing);
    expect(find.text('Atualize o PicNutri'), findsNothing);
  });
}
