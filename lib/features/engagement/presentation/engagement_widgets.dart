import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../data/engagement_repository.dart';

/// Ícone Material correspondente ao nome enviado pela API.
IconData achievementIcon(String name) => switch (name) {
  'restaurant' => Icons.restaurant_rounded,
  'photo_camera' => Icons.photo_camera_rounded,
  'monitor_weight' => Icons.monitor_weight_rounded,
  'local_fire_department' => Icons.local_fire_department_rounded,
  'emoji_events' => Icons.emoji_events_rounded,
  'water_drop' => Icons.water_drop_rounded,
  'egg' => Icons.egg_rounded,
  'menu_book' => Icons.menu_book_rounded,
  'flag' => Icons.flag_rounded,
  _ => Icons.star_rounded,
};

String dayCount(int n) => n == 1 ? '1 dia' : '$n dias';

/// Cartão do Início: sequência, consistência e mensagem motivacional.
/// Some silenciosamente se o resumo não carregar (não bloqueia o painel).
class StreakCard extends ConsumerStatefulWidget {
  const StreakCard({super.key});

  @override
  ConsumerState<StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends ConsumerState<StreakCard> {
  // Conquistas novas são celebradas pelo CelebrationHost (uma vez, para todo o app).
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(engagementProvider).value;
    if (data == null) return const SizedBox.shrink();

    final pic = context.pic;
    final streak = data.currentStreak;
    return AppCard(
      onTap: () => context.go(AppRoutes.engagement),
      semanticLabel:
          'Sequência de ${dayCount(streak)}. ${data.last7Days} de 7 dias com registro. ${data.message}',
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: streak > 0 ? pic.warningContainer : pic.surfaceMuted,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Icon(
              Icons.local_fire_department_rounded,
              color: streak > 0 ? pic.warning : pic.textSecondary,
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streak > 0 ? '${dayCount(streak)} seguidos' : 'Sua sequência',
                  style: context.text.titleSmall,
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  data.message,
                  style: context.text.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Space.sm),
                _WeekDots(count: data.last7Days),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _WeekDots extends StatelessWidget {
  const _WeekDots({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      children: [
        for (var i = 0; i < 7; i++)
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: Space.xs),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < count ? context.colors.primary : context.pic.border,
            ),
          ),
        const SizedBox(width: Space.xs),
        Text('$count/7 dias', style: context.text.labelSmall),
      ],
    ),
  );
}

