import 'package:flutter/material.dart';

import '../../core/design/design_system.dart';

/// Resumo sempre visível; detalhes e ações aparecem ao tocar no cabeçalho.
class ExpandableHomeCard extends StatelessWidget {
  const ExpandableHomeCard({
    super.key,
    required this.title,
    required this.summary,
    required this.icon,
    required this.child,
  });

  final String title;
  final String summary;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    surfaceTintColor: Colors.transparent,
    color: context.colors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: Radii.card,
      side: BorderSide(color: context.pic.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.xs,
      ),
      leading: IconBadge(icon: icon),
      title: Text(title, style: context.text.titleSmall),
      subtitle: Text(summary, style: context.text.bodySmall),
      children: [child],
    ),
  );
}
