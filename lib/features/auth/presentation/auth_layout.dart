import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';
import '../../../core/i18n/l10n.dart';
import '../../language/presentation/language_picker.dart';

/// Moldura comum das telas de conta (login, cadastro, senha).
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: showBack
          ? AppBar(
              actions: const [
                LanguageButton(),
                SizedBox(width: Space.md),
              ],
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Space.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!showBack) ...[
                    const Align(
                      alignment: Alignment.centerRight,
                      child: LanguageButton(),
                    ),
                    const SizedBox(height: Space.md),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            context.pic.brandContainer,
                            context.colors.surface,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: context.pic.border),
                      ),
                      child: Column(
                        children: [
                          const PicNutriWordmark(iconSize: 56),
                          const SizedBox(height: Space.md),
                          Text(
                            context.l10n.authTagline,
                            style: context.text.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Space.xl),
                  ],
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall,
                    textAlign: showBack ? TextAlign.start : TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: showBack ? TextAlign.start : TextAlign.center,
                  ),
                  const SizedBox(height: Space.xxl),
                  child,
                  if (!showBack) ...[
                    const SizedBox(height: Space.xxl),
                    Text(
                      context.l10n.authFooter,
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
