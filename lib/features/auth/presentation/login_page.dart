import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../shared/validators.dart';
import '../../../shared/widgets/feedback.dart';
import '../application/session_controller.dart';
import 'social_buttons.dart';

/// Cores da tela de login (verde da marca sobre fundo menta claro).
/// A tela tem visual próprio e fica clara mesmo no tema escuro, como a arte.
abstract final class LoginColors {
  static const background = Color(0xFFF6FBF5);
  static const green = Color(0xFF10B26A);
  static const greenDark = Color(0xFF0B9A5A);
  static const link = Color(0xFF0EA864);
  static const title = Color(0xFF0F1E1C);
  static const brandText = Color(0xFF0A241E);
  static const body = Color(0xFF4A5C5A);
  static const label = Color(0xFF5F666B);
  static const hint = Color(0xFF9AA0A6);
  static const icon = Color(0xFF2B3338);
  static const border = Color(0xFFDDE3E0);
  static const muted = Color(0xFF7A8784);
  static const error = Color(0xFFC62828);
}

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

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
    final padding = MediaQuery.paddingOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: LoginColors.background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            // As ilustrações acompanham a largura da tela (arte de 853 px).
            final scale = constraints.maxWidth / 853;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      right: 0,
                      width: 448 * scale,
                      child: const ExcludeSemantics(
                        child: Image(
                          image: AssetImage(
                            'assets/images/login/login_bowl.png',
                          ),
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 254 * scale,
                      child: const ExcludeSemantics(
                        child: Image(
                          image: AssetImage(
                            'assets/images/login/login_footer.png',
                          ),
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: padding.bottom / 2 + 150 * scale,
                      child: const Text(
                        'Sua evolução, no seu ritmo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: LoginColors.muted,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        22,
                        padding.top + 52,
                        22,
                        padding.bottom / 2 + 150 * scale + 48,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: _form(context, notice),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _form(BuildContext context, String? notice) {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: _Brand(),
            ),
            const SizedBox(height: 64),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bem-vindo de volta',
                    style: TextStyle(
                      fontSize: 31,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      color: LoginColors.title,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sua evolução começa com um pequeno passo.',
                    style: TextStyle(
                      fontSize: 16.5,
                      height: 1.3,
                      color: LoginColors.body,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            if (notice != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: LoginColors.border),
                ),
                child: Text(
                  notice,
                  style: const TextStyle(color: LoginColors.title),
                ),
              ),
              const SizedBox(height: 14),
            ],
            _LoginField(
              label: 'E-MAIL',
              icon: Icons.mail_outline_rounded,
              child: TextFormField(
                controller: _email,
                style: _LoginField.inputStyle,
                cursorColor: LoginColors.green,
                decoration: _LoginField.decoration('Seu e-mail'),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                validator: Validators.email,
              ),
            ),
            const SizedBox(height: 12),
            _LoginField(
              label: 'SENHA',
              icon: Icons.lock_outline_rounded,
              trailing: IconButton(
                tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                color: LoginColors.icon,
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              child: TextFormField(
                controller: _password,
                style: _LoginField.inputStyle,
                cursorColor: LoginColors.green,
                decoration: _LoginField.decoration('Sua senha'),
                obscureText: _obscure,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
                validator: (v) => Validators.required(v, 'Senha'),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push(AppRoutes.forgotPassword),
                style: TextButton.styleFrom(
                  foregroundColor: LoginColors.link,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 14,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Esqueci minha senha'),
              ),
            ),
            const SizedBox(height: 4),
            _EnterButton(loading: _loading, onPressed: _submit),
            const SizedBox(height: 18),
            const _RegisterLink(),
            const SocialButtons(),
          ],
        ),
      ),
    );
  }
}

/// Ícone do app + "PicNutri" + frase da marca, alinhados à esquerda.
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GreenAppIcon(size: 50),
          SizedBox(width: 14),
          Text(
            'PicNutri',
            style: TextStyle(
              fontSize: 33,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              color: LoginColors.brandText,
            ),
          ),
        ],
      ),
      SizedBox(height: 14),
      Text(
        'Um espaço para cuidar de você.',
        style: TextStyle(fontSize: 14.5, color: LoginColors.body),
      ),
    ],
  );
}

class _GreenAppIcon extends StatelessWidget {
  const _GreenAppIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: LoginColors.green,
      borderRadius: BorderRadius.circular(size * 0.24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x2210B26A),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: PicNutriSymbol(size: size, color: Colors.white),
  );
}

/// Campo branco com ícone à esquerda e rótulo em caixa alta sobre o texto.
class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.label,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String label;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  static const inputStyle = TextStyle(fontSize: 16.5, color: LoginColors.title);

  static InputDecoration decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 16.5, color: LoginColors.hint),
    isDense: true,
    filled: false,
    contentPadding: const EdgeInsets.only(top: 4, bottom: 2),
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    errorStyle: const TextStyle(fontSize: 12.5, color: LoginColors.error),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: EdgeInsets.only(left: 16, right: trailing == null ? 16 : 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LoginColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: LoginColors.icon),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.8,
                        color: LoginColors.label,
                      ),
                    ),
                  ),
                  Semantics(label: label, child: child),
                ],
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Botão "Entrar" verde com a seta à direita.
class _EnterButton extends StatelessWidget {
  const _EnterButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x3310B26A),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: LoginColors.green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: LoginColors.green.withValues(alpha: 0.7),
          disabledForegroundColor: Colors.white,
          overlayColor: LoginColors.greenDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
        ),
        child: loading
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                  semanticsLabel: 'Enviando',
                ),
              )
            : const Stack(
                alignment: Alignment.center,
                children: [
                  Text('Entrar'),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.arrow_forward_rounded, size: 26),
                  ),
                ],
              ),
      ),
    ),
  );
}

/// "Ainda não tem conta? Criar conta" com o link sublinhado em verde.
class _RegisterLink extends StatelessWidget {
  const _RegisterLink();

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      const Text(
        'Ainda não tem conta?',
        style: TextStyle(fontSize: 15.5, color: LoginColors.body),
      ),
      const SizedBox(width: 4),
      InkWell(
        onTap: () => context.push(AppRoutes.register),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Container(
            padding: const EdgeInsets.only(bottom: 2),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: LoginColors.link, width: 1.5),
              ),
            ),
            child: const Text(
              'Criar conta',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: LoginColors.link,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
