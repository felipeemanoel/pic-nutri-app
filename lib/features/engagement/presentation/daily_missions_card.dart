import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_system.dart';
import '../../../core/i18n/l10n.dart';
import '../data/daily_missions.dart';

class DailyMissionsCard extends ConsumerStatefulWidget {
  const DailyMissionsCard({super.key});

  @override
  ConsumerState<DailyMissionsCard> createState() => _DailyMissionsCardState();
}

class _DailyMissionsCardState extends ConsumerState<DailyMissionsCard>
    with WidgetsBindingObserver {
  Timer? _midnightCheck;
  DateTime _day = DateUtils.dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _midnightCheck = Timer.periodic(const Duration(minutes: 1), (_) {
      final today = DateUtils.dateOnly(DateTime.now());
      if (today != _day) {
        _day = today;
        ref.invalidate(dailyMissionsProvider);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(dailyMissionsProvider);
    }
  }

  @override
  void dispose() {
    _midnightCheck?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyMissionsProvider);
    return AppCard(
      child: switch (state) {
        AsyncData(:final value) => _Progress(data: value),
        AsyncError() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.missionsTitle, style: context.text.titleMedium),
            Text(context.l10n.missionsError),
            TextButton.icon(
              onPressed: () => ref.invalidate(dailyMissionsProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.actionRetry),
            ),
          ],
        ),
        _ => const SkeletonCard(lines: 2),
      },
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.data});
  final DailyMissions data;

  @override
  Widget build(BuildContext context) {
    final colors = [
      context.colors.primary,
      const Color(0xFFAD6836),
      const Color(0xFF637C99),
      const Color(0xFFB17A00),
      const Color(0xFF7B51C9),
    ];
    final color = colors[data.level.index];
    final next = data.nextLevel;
    final l10n = context.l10n;
    final level = missionLevelName(l10n, data.level);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              data.streakBroken
                  ? Icons.sentiment_dissatisfied_rounded
                  : Icons.auto_awesome_rounded,
              color: color,
              size: 30,
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(l10n.missionsTitle, style: context.text.titleMedium),
            ),
            Text(
              '${data.stars}/${data.missions.length}',
              style: context.text.titleMedium?.copyWith(color: color),
            ),
          ],
        ),
        const SizedBox(height: Space.md),
        Container(
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: .18),
                color.withValues(alpha: .04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events_rounded, size: 36, color: color),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      l10n.missionsMyAchievement,
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.sm),
              Text(
                l10n.missionsLevelStreak(level, data.streak),
                style: context.text.titleSmall?.copyWith(color: color),
              ),
              const SizedBox(height: Space.xs),
              Text(
                data.streakBroken
                    ? l10n.missionsBroken
                    : data.streak == data.level.days && data.streak > 0
                    ? l10n.missionsLevelUp(level)
                    : data.streak > 0
                    ? l10n.missionsKeepGoing
                    : l10n.missionsFirstDay,
              ),
              const SizedBox(height: Space.sm),
              LinearProgressIndicator(
                value: next == null
                    ? 1
                    : ((data.streak - data.level.days) /
                              (next.days - data.level.days))
                          .clamp(0.0, 1.0),
                color: color,
                backgroundColor: color.withValues(alpha: .12),
                minHeight: 6,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: Space.xs),
              Text(
                next == null
                    ? l10n.missionsDiamond
                    : l10n.missionsDaysTo(
                        next.days - data.streak,
                        missionLevelName(l10n, next),
                      ),
                style: context.text.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.sm),
        for (final mission in data.missions)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.xs),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Icon(
                    key: ValueKey(mission.completed),
                    mission.completed
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: mission.completed
                        ? const Color(0xFFB17A00)
                        : context.pic.textSecondary,
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(child: Text(mission.title)),
                if (mission.completed)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: context.pic.success,
                  ),
              ],
            ),
          ),
        const SizedBox(height: Space.xs),
        Text(
          l10n.missionsRecord(data.bestStreak),
          style: context.text.bodySmall,
        ),
      ],
    );
  }
}

/// Nome do nível no idioma do app.
String missionLevelName(AppLocalizations l10n, MissionLevel level) =>
    switch (level) {
      MissionLevel.beginner => l10n.levelBeginner,
      MissionLevel.bronze => l10n.levelBronze,
      MissionLevel.silver => l10n.levelSilver,
      MissionLevel.gold => l10n.levelGold,
      MissionLevel.diamond => l10n.levelDiamond,
    };
