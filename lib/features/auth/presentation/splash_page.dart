import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_system.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../application/session_controller.dart';

/// Exibida enquanto a sessão é verificada ou quando a API está inacessível.
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: session.hasError && !session.isLoading
            ? ErrorView(
                message: friendlyMessage(session.error!),
                onRetry: () => ref.invalidate(sessionControllerProvider),
              )
            : const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PicNutriWordmark(iconSize: 72, showTagline: true),
                    SizedBox(height: Space.xxxl),
                    SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        semanticsLabel: 'Abrindo o PicNutri',
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
