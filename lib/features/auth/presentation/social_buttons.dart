import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/feedback.dart';
import '../application/session_controller.dart';
import '../data/social_sign_in.dart';
import 'provider_buttons.dart';
import 'social_flow.dart';

/// "Continuar com Google/Facebook/Apple": Android mostra Google e Facebook;
/// iOS mostra também a Apple. Cada botão só aparece quando o provedor está
/// configurado no app e habilitado no servidor.
class SocialButtons extends ConsumerStatefulWidget {
  const SocialButtons({super.key});

  /// Ordem de exibição (Apple primeiro no iOS, como recomenda a Apple).
  static const order = ['apple', 'google', 'facebook'];

  @override
  ConsumerState<SocialButtons> createState() => _SocialButtonsState();
}

class _SocialButtonsState extends ConsumerState<SocialButtons> {
  String? _busy;

  Future<void> _signIn(String provider) async {
    if (_busy != null) return; // evita toques duplicados
    setState(() => _busy = provider);
    try {
      final credential = await ref.read(socialSignInProvider).signIn(provider);
      if (!mounted) return;
      final session = ref.read(sessionControllerProvider.notifier);
      await runSocialStep(context, ref, () => session.socialLogin(credential));
    } on SocialSignInCanceled {
      // Usuário fechou a tela do provedor: continua no login normalmente.
    } on SocialSignInFailed catch (e) {
      if (mounted) showMessage(context, e.message);
    } on Object catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final providers =
        ref.watch(socialProvidersProvider).value ?? const <String>{};
    if (providers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 22),
        const Row(
          children: [
            Expanded(child: Divider(color: Color(0xFFDCE1DF), height: 1)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OU CONTINUE COM',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.4,
                  color: Color(0xFF6B7774),
                ),
              ),
            ),
            Expanded(child: Divider(color: Color(0xFFDCE1DF), height: 1)),
          ],
        ),
        const SizedBox(height: 22),
        for (final provider in SocialButtons.order.where(
          providers.contains,
        )) ...[
          ProviderButton(
            provider: provider,
            label: 'Continuar com ${SocialProviders.buttonName(provider)}',
            loading: _busy == provider,
            onPressed: _busy == null ? () => _signIn(provider) : null,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
