import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/auth/application/session_controller.dart';
import 'package:picnutri/features/auth/presentation/splash_page.dart';

class _LoadingSession extends SessionController {
  @override
  Future<SessionState> build() => Completer<SessionState>().future;
}

void main() {
  for (final reduced in [false, true]) {
    testWidgets(
      'splash mostra logo e carregamento; movimento reduzido: $reduced',
      (tester) async {
        tester.view
          ..physicalSize = const Size(320, 568)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionControllerProvider.overrideWith(_LoadingSession.new),
            ],
            child: MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  disableAnimations: reduced,
                  textScaler: TextScaler.linear(1.5),
                ),
                child: const SplashPage(),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 1200));
        expect(
          find.byWidgetPredicate(
            (w) => w is Image && w.semanticLabel == 'PicNutri',
          ),
          findsOneWidget,
        );
        expect(find.text('Sua evolução, no seu ritmo.'), findsOneWidget);
        final progress = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(progress.value, reduced ? 0.5 : null);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
      },
    );
  }
}
