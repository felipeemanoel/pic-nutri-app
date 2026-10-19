import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_system.dart';
import '../../../core/error/app_failure.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/legal_summary.dart';
import '../../../shared/widgets/state_views.dart';
import '../application/session_controller.dart';
import '../data/auth_repository.dart';

/// Continua o login social quando a API pede uma etapa extra:
/// - conta nova: aceite dos termos;
/// - provedor sem e-mail (ex.: Facebook): informar e confirmar um e-mail;
/// - e-mail de uma conta existente: comprovar a conta (senha ou código)
///   antes de vincular — nunca há vínculo automático pelo e-mail.
///
/// Fechar qualquer etapa volta à tela de login sem erro.
Future<void> runSocialStep(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() action,
) async {
  try {
    await action();
  } on AppFailure catch (e) {
    final step = SocialFlowStep.fromFailure(e.code, e.details);
    if (step == null || !context.mounted) rethrow;
    await continueSocialStep(context, ref, step);
  }
}

Future<void> continueSocialStep(
  BuildContext context,
  WidgetRef ref,
  SocialFlowStep step,
) async {
  final session = ref.read(sessionControllerProvider.notifier);
  switch (step.code) {
    case 'terms_acceptance_required':
      if (await askSocialTerms(context) && context.mounted) {
        await runSocialStep(
          context,
          ref,
          () => session.completeSocial(
            pendingToken: step.pendingToken,
            acceptTerms: true,
          ),
        );
      }
    case 'social_email_required':
      final next = await _sheet<SocialFlowStep>(
        context,
        _EmailStep(step: step),
      );
      if (next != null && context.mounted) {
        await continueSocialStep(context, ref, next);
      }
    case 'account_link_required':
      await _sheet<void>(context, _LinkStep(step: step));
  }
}

Future<T?> _sheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          Space.page,
          0,
          Space.page,
          MediaQuery.viewInsetsOf(context).bottom + Space.xl,
        ),
        child: SingleChildScrollView(child: child),
      ),
    );

/// Aceite dos Termos e da Política (obrigatório para criar a conta).
Future<bool> askSocialTerms(BuildContext context) async {
  var accepted = false;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Criar sua conta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TermsCheckbox(
              value: accepted,
              onChanged: (v) => setState(() => accepted = v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
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

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      CheckboxListTile(
        value: value,
        onChanged: (v) => onChanged(v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        title: const Text(
          'Li e aceito os Termos de Uso e a Política de Privacidade',
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () => showLegalSummary(context),
          child: const Text('Como usamos seus dados'),
        ),
      ),
    ],
  );
}

/// Provedor sem e-mail: informar um e-mail e confirmar com o código enviado.
class _EmailStep extends ConsumerStatefulWidget {
  const _EmailStep({required this.step});

  final SocialFlowStep step;

  @override
  ConsumerState<_EmailStep> createState() => _EmailStepState();
}

class _EmailStepState extends ConsumerState<_EmailStep> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _accepted = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (!_codeSent && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      showMessage(context, 'Informe um e-mail válido.');
      return;
    }
    if (_codeSent && (_code.text.trim().length != 6 || !_accepted)) {
      showMessage(
        context,
        _accepted
            ? 'Digite o código de 6 dígitos.'
            : 'Aceite os termos para criar a conta.',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final session = ref.read(sessionControllerProvider.notifier);
      if (!_codeSent) {
        await session.completeSocial(
          pendingToken: widget.step.pendingToken,
          email: email,
        );
        if (mounted) setState(() => _codeSent = true);
      } else {
        await session.completeSocial(
          pendingToken: widget.step.pendingToken,
          code: _code.text.trim(),
          acceptTerms: true,
        );
        if (mounted) Navigator.of(context).pop();
      }
    } on AppFailure catch (e) {
      // E-mail de uma conta existente: segue para a comprovação.
      final next = SocialFlowStep.fromFailure(e.code, e.details);
      if (next != null && mounted) {
        Navigator.of(context).pop(next);
        return;
      }
      if (mounted) showFailure(context, e);
      if (e.code == 'social_pending_expired' && mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Informe seu e-mail', style: context.text.titleLarge),
      const SizedBox(height: Space.sm),
      Text(
        _codeSent
            ? 'Enviamos um código para ${_email.text.trim()}. Digite-o para confirmar o e-mail.'
            : 'Sua conta não compartilhou um e-mail. Ele é usado para recuperar o acesso e para avisos da conta.',
        style: context.text.bodyMedium,
      ),
      const SizedBox(height: Space.lg),
      TextField(
        controller: _email,
        enabled: !_codeSent && !_busy,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        decoration: const InputDecoration(labelText: 'E-mail'),
      ),
      if (_codeSent) ...[
        const SizedBox(height: Space.md),
        TextField(
          controller: _code,
          enabled: !_busy,
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofillHints: const [AutofillHints.oneTimeCode],
          decoration: const InputDecoration(labelText: 'Código'),
        ),
        _TermsCheckbox(
          value: _accepted,
          onChanged: (v) => setState(() => _accepted = v),
        ),
        TextButton(
          onPressed: _busy ? null : () => setState(() => _codeSent = false),
          child: const Text('Usar outro e-mail'),
        ),
      ],
      const SizedBox(height: Space.md),
      LoadingButton(
        label: _codeSent ? 'Criar conta' : 'Enviar código',
        loading: _busy,
        onPressed: _submit,
      ),
    ],
  );
}

/// Conta existente com o mesmo e-mail: comprovar o acesso para vincular.
class _LinkStep extends ConsumerStatefulWidget {
  const _LinkStep({required this.step});

  final SocialFlowStep step;

  @override
  ConsumerState<_LinkStep> createState() => _LinkStepState();
}

class _LinkStepState extends ConsumerState<_LinkStep> {
  final _password = TextEditingController();
  final _code = TextEditingController();
  late bool _useCode = !widget.step.methods.contains('password');
  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .socialLinkCode(widget.step.pendingToken);
      if (mounted) setState(() => _codeSent = true);
    } on Object catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    final password = _password.text;
    final code = _code.text.trim();
    if (_useCode ? code.length != 6 : password.isEmpty) {
      showMessage(
        context,
        _useCode
            ? 'Digite o código de 6 dígitos.'
            : 'Digite a senha da sua conta.',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .linkSocial(
            pendingToken: widget.step.pendingToken,
            password: _useCode ? null : password,
            code: _useCode ? code : null,
          );
      if (mounted) Navigator.of(context).pop();
    } on AppFailure catch (e) {
      if (mounted) showFailure(context, e);
      if (e.code == 'social_pending_expired' && mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.step.maskedEmail ?? 'este e-mail';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Você já tem uma conta', style: context.text.titleLarge),
        const SizedBox(height: Space.sm),
        Text(
          'Existe uma conta PicNutri com $email. Confirme que ela é sua para usar este acesso '
          'também. Seus registros, metas e plano continuam os mesmos.',
          style: context.text.bodyMedium,
        ),
        const SizedBox(height: Space.lg),
        if (!_useCode) ...[
          TextField(
            controller: _password,
            enabled: !_busy,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(
              labelText: 'Senha da sua conta PicNutri',
            ),
          ),
          TextButton(
            onPressed: _busy ? null : () => setState(() => _useCode = true),
            child: const Text('Prefiro receber um código por e-mail'),
          ),
        ] else if (!_codeSent) ...[
          Text(
            'Vamos enviar um código de 6 dígitos para $email.',
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: Space.md),
          LoadingButton(
            label: 'Enviar código',
            loading: _busy,
            onPressed: _sendCode,
          ),
        ] else
          TextField(
            controller: _code,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofillHints: const [AutofillHints.oneTimeCode],
            decoration: const InputDecoration(
              labelText: 'Código recebido por e-mail',
            ),
          ),
        if (!_useCode || _codeSent) ...[
          const SizedBox(height: Space.md),
          LoadingButton(
            label: 'Confirmar e vincular',
            loading: _busy,
            onPressed: _confirm,
          ),
        ],
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Agora não'),
        ),
      ],
    );
  }
}
