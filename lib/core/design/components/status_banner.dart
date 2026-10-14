import 'package:flutter/material.dart';

import '../pic_colors.dart';
import '../tokens.dart';

enum BannerTone { info, success, warning, error, ai, brand }

/// Faixa de aviso com ícone, texto e ação opcional. O tipo é indicado por
/// ícone e texto, não só pela cor.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    this.tone = BannerTone.info,
    this.title,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final BannerTone tone;
  final String? title;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.pic;
    final (Color fg, Color bg, IconData defaultIcon) = switch (tone) {
      BannerTone.info => (p.info, p.infoContainer, Icons.info_outline),
      BannerTone.success => (
        p.success,
        p.successContainer,
        Icons.check_circle_outline,
      ),
      BannerTone.warning => (
        p.warning,
        p.warningContainer,
        Icons.warning_amber_rounded,
      ),
      BannerTone.error => (p.error, p.errorContainer, Icons.error_outline),
      BannerTone.ai => (p.ai, p.aiContainer, Icons.auto_awesome_outlined),
      BannerTone.brand => (
        context.colors.primary,
        p.brandContainer,
        Icons.eco_outlined,
      ),
    };
    final textColor = tone == BannerTone.ai
        ? p.onAiContainer
        : context.colors.onSurface;

    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(color: bg, borderRadius: Radii.control),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, color: fg, size: 22),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.xxs),
                    child: Text(
                      title!,
                      style: context.text.titleSmall?.copyWith(
                        color: textColor,
                      ),
                    ),
                  ),
                Text(
                  message,
                  style: context.text.bodyMedium?.copyWith(color: textColor),
                ),
                if (actionLabel != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: tone == BannerTone.ai
                            ? p.onAiContainer
                            : null,
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Selo discreto que identifica conteúdo gerado ou estimado por IA.
class AiBadge extends StatelessWidget {
  const AiBadge({
    super.key,
    this.label = 'Estimativa por IA',
    this.compact = false,
  });

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.pic;
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : Space.sm,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: p.aiContainer,
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 14, color: p.ai),
              if (!compact) ...[
                const SizedBox(width: Space.xs),
                Text(
                  label,
                  style: context.text.labelSmall?.copyWith(
                    color: p.onAiContainer,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
