import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../application/session_controller.dart';
import '../data/auth_repository.dart';
import '../data/social_sign_in.dart';
import 'provider_buttons.dart';

final signInMethodsProvider = FutureProvider.autoDispose<SignInMethods>(
  (ref) => ref.watch(authRepositoryProvider).signInMethods(),
);

/// Formas de acesso da conta: e-mail e senha, Google, Facebook e (no iOS)
/// Apple. Vincular exige entrar no provedor; desvincular só é possível se
/// restar outro meio de acesso. A conta e os dados são sempre os mesmos.
class SignInMethodsPage extends ConsumerStatefulWidget {
  const SignInMethodsPage({super.key});

  @override
  ConsumerState<SignInMethodsPage> createState() => _SignInMethodsPageState();
}

class _SignInMethodsPageState extends ConsumerState<SignInMethodsPage> {
  String? _busy;

  Future<void> _link(String provider) async {
    setState(() => _busy = provider);
    try {
      final credential = await ref.read(socialSignInProvider).signIn(provider);
      await ref.read(authRepositoryProvider).linkProvider(credential.data);
      ref.invalidate(signInMethodsProvider);
      if (mounted) {
        showMessage(
          context,
          '${SocialProviders.name(provider)} vinculado à sua conta.',
        );
      }
    } on SocialSignInCanceled {
      // Usuário desistiu.
    } on SocialSignInFailed catch (e) {
      if (mounted) showMessage(context, e.message);
    } on Object catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _unlink(String provider) async {
    final name = SocialProviders.name(provider);
    final ok = await confirmAction(
      context,
      title: 'Desvincular $name?',
      message:
          'Você não poderá mais entrar com o $name. Sua conta e seus dados continuam iguais.',
      confirmLabel: 'Desvincular',
      destructive: true,
    );
    if (!ok) return;
    setState(() => _busy = provider);
    try {
      await ref.read(authRepositoryProvider).unlinkProvider(provider);
      ref.invalidate(signInMethodsProvider);
    } on Object catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _setPassword(String email) async {
    final proceed = await confirmAction(
      context,
      title: 'Definir uma senha',
      message:
          'Para sua segurança, vamos enviar um código para $email. Com a senha, você também poderá entrar com e-mail e senha.',
      confirmLabel: 'Enviar código',
    );
    if (!proceed || !mounted) return;
    setState(() => _busy = 'password');
    try {
      await ref.read(authRepositoryProvider).sendPasswordCode();
    } on Object catch (e) {
      if (mounted) showFailure(context, e);
      return;
    } finally {
      if (mounted) setState(() => _busy = null);
    }
    if (!mounted) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _SetPasswordSheet(),
    );
    if (saved == true) {
      ref.invalidate(signInMethodsProvider);
      await ref.read(sessionControllerProvider.notifier).reloadAccount();
      if (mounted) {
        showMessage(
          context,
          'Senha definida. Agora você também pode entrar com e-mail e senha.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final methods = ref.watch(signInMethodsProvider);
    final available =
        ref.watch(socialProvidersProvider).value ?? localSocialProviders();

    return Scaffold(
      appBar: AppBar(title: const Text('Formas de acesso')),
      body: AsyncValueView<SignInMethods>(
        value: methods,
        onRetry: () => ref.invalidate(signInMethodsProvider),
        data: (m) => ListView(
          padding: const EdgeInsets.symmetric(vertical: Space.md),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.page,
                0,
                Space.page,
                Space.md,
              ),
              child: Text(
                'Use mais de uma forma de entrar na mesma conta. Seu histórico, metas e plano continuam os mesmos.',
                style: context.text.bodyMedium?.copyWith(
                  color: context.pic.textSecondary,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('E-mail e senha'),
              subtitle: Text(
                m.hasPassword ? m.email : 'Sem senha definida · ${m.email}',
              ),
              trailing: _busy == 'password'
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: _busy != null
                          ? null
                          : m.hasPassword
                          ? () => context.push(AppRoutes.changePassword)
                          : () => _setPassword(m.email),
                      child: Text(
                        m.hasPassword ? 'Alterar senha' : 'Definir senha',
                      ),
                    ),
            ),
            const Divider(),
            for (final provider in const [
              'apple',
              'google',
              'facebook',
            ].where(available.contains))
              _ProviderTile(
                provider: provider,
                linked: m.providers
                    .where((p) => p.provider == provider)
                    .firstOrNull,
                canUnlink: m.canUnlink(provider),
                busy: _busy == provider,
                enabled: _busy == null,
                onLink: () => _link(provider),
                onUnlink: () => _unlink(provider),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({
    required this.provider,
    required this.linked,
    required this.canUnlink,
    required this.busy,
    required this.enabled,
    required this.onLink,
    required this.onUnlink,
  });

  final String provider;
  final LinkedProvider? linked;
  final bool canUnlink;
  final bool busy;
  final bool enabled;
  final VoidCallback onLink;
  final VoidCallback onUnlink;

  @override
  Widget build(BuildContext context) {
    final name = SocialProviders.name(provider);
    final account = linked;
    final subtitle = account == null
        ? 'Não vinculado'
        : account.privateEmail
        ? 'Vinculado · e-mail oculto pela Apple'
        : 'Vinculado${account.email != null ? ' · ${account.email}' : ''}';

    return ListTile(
      leading: Icon(
        switch (provider) {
          'apple' => Icons.apple,
          'facebook' => Icons.facebook,
          _ => Icons.g_mobiledata_rounded,
        },
        color: provider == 'facebook' ? ProviderButton.facebookBlue : null,
        size: 28,
      ),
      title: Text(name),
      subtitle: Text(
        account != null && !canUnlink
            ? '$subtitle\nÚnica forma de acesso: defina uma senha para poder remover.'
            : subtitle,
      ),
      isThreeLine: account != null && !canUnlink,
      trailing: busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : account == null
          ? FilledButton.tonal(
              onPressed: enabled ? onLink : null,
              child: const Text('Vincular'),
            )
          : TextButton(
              onPressed: enabled && canUnlink ? onUnlink : null,
              child: const Text('Desvincular'),
            ),
    );
  }
}

/// Código recebido por e-mail + nova senha.
class _SetPasswordSheet extends ConsumerStatefulWidget {
  const _SetPasswordSheet();

  @override
  ConsumerState<_SetPasswordSheet> createState() => _SetPasswordSheetState();
}

class _SetPasswordSheetState extends ConsumerState<_SetPasswordSheet> {
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_code.text.trim().length != 6) {
      return showMessage(context, 'Digite o código de 6 dígitos.');
    }
    if (_password.text.length < 8) {
      return showMessage(
        context,
        'A senha precisa ter pelo menos 8 caracteres.',
      );
    }
    if (_password.text != _confirm.text) {
      return showMessage(context, 'As senhas não conferem.');
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .setPassword(code: _code.text, password: _password.text);
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      Space.page,
      0,
      Space.page,
      MediaQuery.viewInsetsOf(context).bottom + Space.xl,
    ),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Definir senha', style: context.text.titleLarge),
          const SizedBox(height: Space.lg),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofillHints: const [AutofillHints.oneTimeCode],
            decoration: const InputDecoration(
              labelText: 'Código recebido por e-mail',
            ),
          ),
          TextField(
            controller: _password,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            decoration: const InputDecoration(labelText: 'Nova senha'),
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: _confirm,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirme a nova senha',
            ),
          ),
          const SizedBox(height: Space.lg),
          LoadingButton(
            label: 'Salvar senha',
            loading: _busy,
            onPressed: _save,
          ),
        ],
      ),
    ),
  );
}
