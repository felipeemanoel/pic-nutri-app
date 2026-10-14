import 'package:flutter/material.dart';

import '../pic_colors.dart';
import '../tokens.dart';

/// Bloco de carregamento (placeholder). Pulsa suavemente, exceto quando o
/// sistema pede menos movimento.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.height = 16,
    this.width,
    this.radius = Radii.sm,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: 0.55, end: 1).animate(_controller),
    child: Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: context.pic.surfaceMuted,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    ),
  );
}

/// Placeholder de cartão para listas e painéis em carregamento.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.lines = 3});

  final int lines;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Carregando',
    child: Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: Radii.card,
        border: Border.all(color: context.pic.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Skeleton(height: 18, width: 140),
          for (var i = 0; i < lines; i++) ...[
            const SizedBox(height: Space.md),
            Skeleton(height: 12, width: i.isEven ? double.infinity : 200),
          ],
        ],
      ),
    ),
  );
}
