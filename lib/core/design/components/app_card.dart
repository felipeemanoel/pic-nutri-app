import 'package:flutter/material.dart';

import '../pic_colors.dart';
import '../tokens.dart';

/// Cartão padrão: superfície plana com borda discreta, cantos de 20 e espaçamento
/// interno consistente. Com [onTap], ganha resposta ao toque.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Space.xl),
    this.color,
    this.borderColor,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: Radii.card,
      side: BorderSide(color: borderColor ?? context.pic.border),
    );
    final content = Padding(padding: padding, child: child);
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: Material(
        surfaceTintColor: Colors.transparent,
        color: color ?? context.colors.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

/// Título de seção com ação opcional à direita ("Ver tudo", "Adicionar").
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.only(top: Space.xl, bottom: Space.sm),
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: context.text.titleMedium),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    ),
  );
}

/// Ícone de cartão num quadrado suave da marca (40 × 40, raio 12): o mesmo
/// padrão em atalhos, listas e cartões de todas as telas.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, this.ai = false});

  final IconData icon;

  /// Recurso de IA: usa a identidade roxa.
  final bool ai;

  @override
  Widget build(BuildContext context) {
    final p = context.pic;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: ai ? p.aiContainer : p.brandContainer,
        borderRadius: Radii.control,
      ),
      child: Icon(
        icon,
        size: 22,
        color: ai ? p.onAiContainer : p.onBrandContainer,
      ),
    );
  }
}
