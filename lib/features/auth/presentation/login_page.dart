import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../shared/validators.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../application/session_controller.dart';
import 'social_buttons.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

/// Entrada no app com o mesmo visual do restante: tipografia e cores do
/// tema, campos e botões padrão. A foto do bowl aparece só no tema claro,
/// como apresentação (não representa um prato registrado).
class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .login(email: _email.text, password: _password.text);
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider).value;
    final notice = session is SessionSignedOut ? session.message : null;
    final light = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            if (light)
              Positioned(
                top: -MediaQuery.paddingOf(context).top,
                right: 0,
                width: (MediaQuery.sizeOf(context).width * 0.56).clamp(
                  180,
                  300,
                ),
                child: const ExcludeSemantics(
                  child: Image(
                    image: AssetImage('assets/images/login/login_bowl.png'),
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 780;
                final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
                final gap = keyboard
                    ? 0.3
                    : compact
                    ? 0.55
                    : 0.8;
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 24 : 28,
                    vertical: compact ? 12 : 24,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: (constraints.maxWidth - (compact ? 48 : 56))
                            .clamp(0.0, 440.0),
                        child: _form(
                          context,
                          notice,
                          gap: gap,
                          compact: compact,
                          keyboard: keyboard,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _form(
    BuildContext context,
    String? notice, {
    required double gap,
    required bool compact,
    required bool keyboard,
  }) => AutofillGroup(
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!keyboard)
            Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'assets/brand/picnutri_logo_square_trimmed.png',
                width: compact ? 104 : 140,
                semanticLabel: 'PicNutri',
              ),
            ),
          SizedBox(height: Space.sm * gap),
          if (!keyboard)
            Text(
              'Um espaço para cuidar de você.',
              style: context.text.bodyMedium?.copyWith(
                color: context.pic.textSecondary,
              ),
            ),
          SizedBox(height: keyboard ? 0 : 48 * gap),
          Semantics(
            header: true,
            child: Text(
              'Bem-vindo de volta!',
              style: context.text.headlineMedium?.copyWith(
                fontSize: compact ? 25 : 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.15,
              ),
            ),
          ),
          SizedBox(height: Space.sm * gap),
          Text(
            'Entre para acompanhar sua evolução.',
            style: context.text.bodyLarge?.copyWith(
              color: context.pic.textSecondary,
            ),
          ),
          SizedBox(height: Space.section * gap),
          if (notice != null) ...[
            StatusBanner(message: notice),
            SizedBox(height: Space.lg * gap),
          ],
          Text(
            'E-mail',
            style: context.text.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: Space.sm * gap),
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(
              hintText: 'Seu e-mail',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            validator: Validators.email,
          ),
          SizedBox(height: Space.lg * gap),
          Text(
            'Senha',
            style: context.text.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: Space.sm * gap),
          TextFormField(
            controller: _password,
            decoration: InputDecoration(
              hintText: 'Sua senha',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            obscureText: _obscure,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _submit(),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Informe a senha' : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push(AppRoutes.forgotPassword),
              child: const Text('Esqueci minha senha'),
            ),
          ),
          SizedBox(height: Space.md * gap),
          LoadingButton(label: 'Entrar', loading: _loading, onPressed: _submit),
          SizedBox(height: Space.lg * gap),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Ainda não tem conta?', style: context.text.bodyMedium),
              TextButton(
                onPressed: () => context.push(AppRoutes.register),
                child: const Text('Criar conta'),
              ),
            ],
          ),
          const SocialButtons(),
        ],
      ),
    ),
  );
}
