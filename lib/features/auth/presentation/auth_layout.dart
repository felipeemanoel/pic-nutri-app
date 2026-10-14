import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';

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
      appBar: showBack ? AppBar() : null,
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
                    const Center(child: PicNutriAppIcon(size: 64)),
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
                      'Sua evolução, no seu ritmo.',
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
