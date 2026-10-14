import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_system.dart';
import '../../../core/error/app_failure.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/legal_summary.dart';
import '../application/session_controller.dart';
import '../data/social_sign_in.dart';

/// Botões "Continuar com Google/Apple", exibidos só quando a integração está
/// configurada no app e habilitada no servidor.
class SocialButtons extends ConsumerStatefulWidget {
  const SocialButtons({super.key});

  @override
  ConsumerState<SocialButtons> createState() => _SocialButtonsState();
}

class _SocialButtonsState extends ConsumerState<SocialButtons> {
  String? _busy;

  Future<void> _signIn(String provider) async {
    setState(() => _busy = provider);
    try {
      final service = ref.read(socialSignInProvider);
      final credential = provider == 'google' ? await service.google() : await service.apple();
      final session = ref.read(sessionControllerProvider.notifier);
      try {
        await session.socialLogin(credential);
      } on AppFailure catch (e) {
        if (e.code != 'terms_acceptance_required' || !mounted) rethrow;
        // Conta nova: o aceite dos termos é obrigatório, como no cadastro.
        if (await _askTerms()) await session.socialLogin(credential, acceptTerms: true);
      }
    } on SocialSignInCanceled {
      // Usuário fechou a tela do provedor.
    } on Object catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<bool> _askTerms() async {
    var accepted = false;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Criar sua conta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                value: accepted,
                onChanged: (v) => setState(() => accepted = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text('Li e aceito os Termos de Uso e a Política de Privacidade'),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => showLegalSummary(context),
                  child: const Text('Como usamos seus dados'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: accepted ? () => Navigator.of(context).pop(true) : null,
              child: const Text('Criar conta'),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final providers = ref.watch(socialProvidersProvider).value ?? const <String>{};
    if (providers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Space.lg),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.md),
              child: Text('ou', style: context.text.bodySmall),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: Space.lg),
        if (providers.contains('apple')) ...[
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            onPressed: _busy == null ? () => _signIn('apple') : null,
            icon: _busy == 'apple'
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.apple),
            label: const Text('Continuar com a Apple'),
          ),
          const SizedBox(height: Space.sm),
        ],
        if (providers.contains('google'))
          OutlinedButton.icon(
            onPressed: _busy == null ? () => _signIn('google') : null,
            icon: _busy == 'google'
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('G', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            label: const Text('Continuar com o Google'),
          ),
      ],
    );
  }
}
