import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design_system.dart';
import 'feedback.dart';

/// Carregamento simples (indicador + mensagem curta opcional).
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label = 'Carregando', this.message});

  final String label;
  final String? message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Space.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              semanticsLabel: label,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: Space.lg),
            Text(
              message!,
              style: context.text.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    ),
  );
}

/// Ilustração circular usada nos estados vazio e de erro.
class _StateIcon extends StatelessWidget {
  const _StateIcon(this.icon, {this.error = false});

  final IconData icon;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final p = context.pic;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: error ? p.errorContainer : p.brandContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 32,
        color: error ? p.error : context.colors.primary,
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Space.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _StateIcon(Icons.cloud_off_outlined, error: true),
          const SizedBox(height: Space.lg),
          Text(
            'Não foi possível carregar',
            style: context.text.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.xs),
          Text(
            message,
            style: context.text.bodyMedium?.copyWith(
              color: context.pic.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: Space.lg),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Estado vazio com orientação para começar (nunca dados de exemplo).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Versão sem o círculo, para uso dentro de cartões.
  final bool compact;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(compact ? Space.sm : Space.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (compact)
            Icon(icon, size: 28, color: context.colors.primary)
          else
            _StateIcon(icon),
          SizedBox(height: compact ? Space.sm : Space.lg),
          Text(
            title,
            style: context.text.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.xs),
          Text(
            message,
            style: context.text.bodyMedium?.copyWith(
              color: context.pic.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: Space.lg),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

/// Mostra carregando / erro com nova tentativa / conteúdo de um AsyncValue.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  /// Placeholder de carregamento (padrão: indicador circular).
  final Widget? loading;

  @override
  Widget build(BuildContext context) => value.when(
    data: data,
    loading: () => loading ?? const LoadingView(),
    error: (error, _) =>
        ErrorView(message: friendlyMessage(error), onRetry: onRetry),
  );
}

/// Botão principal com indicador de progresso durante a ação.
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      child: AnimatedSwitcher(
        duration: Motion.fast,
        child: loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  semanticsLabel: 'Enviando',
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: Space.sm),
                  ],
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                ],
              ),
      ),
    ),
  );
}

/// Cartão com título usado nas telas de resumo.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.onTap,
    this.icon,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: context.colors.primary),
              const SizedBox(width: Space.sm),
            ],
            Expanded(child: Text(title, style: context.text.titleMedium)),
            ?trailing,
          ],
        ),
        const SizedBox(height: Space.md),
        child,
      ],
    ),
  );
}
