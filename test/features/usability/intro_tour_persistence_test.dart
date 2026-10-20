import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picnutri/core/error/app_failure.dart';
import 'package:picnutri/features/auth/data/account.dart';
import 'package:picnutri/features/intro_tour/data/intro_tour_store.dart';

import '../../helpers/fakes.dart';

Account _pending(String email) => Account.fromJson({
  'name': 'Pessoa',
  'email': email,
  'onboarding_completed': true,
  'onboarding': {'intro_tour_pending': true},
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'conclusão persiste ao recriar o armazenamento e não afeta outra conta',
    () async {
      final store = IntroTourStore();
      expect(await store.shouldShow(_pending('ana@example.com')), isTrue);
      await store.writeStatus('ana@example.com', 'completed');
      final reopened = IntroTourStore();
      expect(await reopened.shouldShow(_pending('ana@example.com')), isFalse);
      expect(await reopened.shouldShow(_pending('outra@example.com')), isTrue);
    },
  );

  test(
    'Pular também persiste e pode sincronizar depois de uma falha de rede',
    () async {
      final repo = MockAuthRepository();
      when(() => repo.introTour('skipped')).thenThrow(const NetworkFailure());
      final store = IntroTourStore();
      await store.writeStatus('ana@example.com', 'skipped');
      await store.sync('ana@example.com', repo);
      final reopened = IntroTourStore();
      expect(await reopened.shouldShow(_pending('ana@example.com')), isFalse);
      when(
        () => repo.introTour('skipped'),
      ).thenAnswer((_) async => testAccount());
      await reopened.sync('ana@example.com', repo);
      verify(() => repo.introTour('skipped')).called(2);
    },
  );
}
