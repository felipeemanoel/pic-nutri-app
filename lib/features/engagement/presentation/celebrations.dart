import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_system.dart';
import '../data/engagement_models.dart';
import '../data/engagement_repository.dart';
import 'engagement_widgets.dart';

/// Mostra as celebrações pendentes (conquistas novas, metas do dia de água e
/// proteína) num aviso breve que não bloqueia o app. Várias ao mesmo tempo
/// viram uma única apresentação. Depois de mostradas, são marcadas como vistas
/// no servidor e não reaparecem — nem ao reabrir o app.
class CelebrationHost extends ConsumerStatefulWidget {
  const CelebrationHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CelebrationHost> createState() => _CelebrationHostState();
}

class _CelebrationHostState extends ConsumerState<CelebrationHost> {
  /// Já mostradas nesta sessão (evita repetir se a confirmação ao servidor falhar).
  final _shown = <String>{};

  void _show(List<Celebration> pending) {
    final fresh = pending.where((c) => !_shown.contains(c.key)).toList();
    if (fresh.isEmpty || !mounted) return;
    _shown.addAll(fresh.map((c) => c.key));

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          showCloseIcon: true,
          content: CelebrationContent(items: fresh),
        ),
      );
    unawaited(
      ref
          .read(engagementRepositoryProvider)
          .markCelebrationsSeen([for (final c in fresh) c.key])
          .then(
            (_) => ref.invalidate(engagementProvider),
            onError:
                (
                  Object _,
                ) {}, // Sem conexão: tenta de novo na próxima abertura do app.
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<Celebration>>>(celebrationsProvider, (_, next) {
      final items = next.value;
      if (items != null && items.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _show(items));
      }
    });
    return widget.child;
  }
}

/// Conteúdo do aviso: um item com título e mensagem, ou vários agrupados.
class CelebrationContent extends StatelessWidget {
  const CelebrationContent({super.key, required this.items});

  final List<Celebration> items;

  @override
  Widget build(BuildContext context) {
    final single = items.length == 1;
    final color = Theme.of(context).colorScheme.onInverseSurface;
    final label = single
        ? '${items.first.title}. ${items.first.message}'
        : 'Conquistas: ${items.map((c) => c.title).join(', ')}.';

    return Semantics(
      liveRegion: true,
      label: label,
      excludeSemantics: true,
      child: Row(
        children: [
          _Pop(
            child: Icon(
              achievementIcon(single ? items.first.icon : 'emoji_events'),
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  single ? items.first.title : 'Boas notícias!',
                  style: context.text.titleSmall?.copyWith(color: color),
                ),
                const SizedBox(height: Space.xxs),
                if (single)
                  Text(
                    items.first.message,
                    style: context.text.bodyMedium?.copyWith(color: color),
                  )
                else
                  for (final c in items)
                    Text(
                      '• ${c.title}',
                      style: context.text.bodyMedium?.copyWith(color: color),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pequeno "salto" do ícone; sem animação com movimento reduzido.
class _Pop extends StatelessWidget {
  const _Pop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: Motion.slow,
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: child,
    );
  }
}
