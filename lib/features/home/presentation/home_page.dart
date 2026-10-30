import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/request_id.dart';
import '../../../shared/state/refresh.dart';
import '../../../shared/state/selected_date.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../../activity/presentation/activity_home_card.dart';
import '../../auth/application/session_controller.dart';
import '../../food/data/food_repository.dart';
import '../../food/data/nutrition_models.dart';
import '../../food/presentation/food_page.dart';
import '../../notifications/presentation/notification_bell.dart';
import '../../profile/data/profile_repository.dart';
import '../../progress/presentation/body_forms.dart';
import '../../water/data/water_repository.dart';
import '../data/dashboard.dart';
import '../data/dashboard_repository.dart';
import 'next_dose_card.dart';

/// Painel de hoje, de relance: equilíbrio de calorias e macronutrientes,
/// água, o próximo passo e as refeições do dia. Histórico e outros dias ficam
/// na Alimentação; sequência e resumo da semana, na Evolução.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // O Início é sempre "hoje"; outros dias ficam na Alimentação.
    final day = SelectedDate.today();
    final dashboard = ref.watch(dashboardProvider(day));
    final name = ref.watch(currentAccountProvider)?.firstName ?? '';

    return Scaffold(
      // Um único ponto de registro: refeição, aplicação, sintoma, peso e água.
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home-register',
        onPressed: () => _registerToday(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Registrar'),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () {
            ref.invalidate(mealsOnDayProvider(day));
            return ref.refresh(dashboardProvider(day).future);
          },
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  Space.lg,
                  Space.lg,
                  Space.fabClearance,
                ),
                children: [
                  _Header(name: name),
                  const SizedBox(height: Space.xl),
                  AsyncValueView<Dashboard>(
                    value: dashboard,
                    onRetry: () => ref.invalidate(dashboardProvider(day)),
                    loading: const _DashboardSkeleton(),
                    data: (data) => _DashboardBody(data: data, day: day),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Registro a partir do Início: sempre no dia de hoje, mesmo que a
/// Alimentação esteja mostrando outro dia. O botão "Registrar" abre também os
/// outros registros (aplicação, sintoma, peso, água).
Future<void> _registerToday(
  BuildContext context,
  WidgetRef ref, {
  bool mealOnly = false,
}) {
  ref.read(selectedDateProvider.notifier).goToday();
  return chooseHowToAddMeal(context, otherLogs: !mealOnly);
}

/// Marca, data, saudação com o ícone do período e sino de notificações.
class _Header extends StatelessWidget {
  const _Header({required this.name});

  final String name;

  static final _date = DateFormat("EEEE, d 'de' MMMM", 'pt_BR');

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final (greeting, icon, iconColor) = hour < 12
        ? ('Bom dia', Icons.wb_twilight_rounded, const Color(0xFFF4A62A))
        : hour < 18
        ? ('Boa tarde', Icons.wb_sunny_rounded, const Color(0xFFF6B92B))
        : ('Boa noite', Icons.nightlight_round, const Color(0xFF7C8CD8));
    final raw = _date.format(now).replaceFirst('-feira', '');
    final date = raw.isEmpty ? raw : raw[0].toUpperCase() + raw.substring(1);

    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: PicNutriHorizontalLogo(width: 132),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(Radii.lg),
                border: Border.all(color: context.pic.border),
              ),
              child: const SizedBox.square(
                dimension: 48,
                child: NotificationBell(),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.lg),
        Divider(height: 1, thickness: 1, color: context.pic.border),
        const SizedBox(height: Space.xl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      name.isEmpty ? greeting : '$greeting, $name',
                      style: context.text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                  Text(
                    date,
                    style: context.text.bodySmall?.copyWith(
                      color: context.pic.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.md),
            ExcludeSemantics(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      SkeletonCard(lines: 5),
      SizedBox(height: Space.md),
      SkeletonCard(lines: 2),
      SizedBox(height: Space.md),
      SkeletonCard(lines: 3),
    ],
  );
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.data, required this.day});

  final Dashboard data;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skipped = _CompleteProfileCard.pending(ref);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Quem acompanha a medicação vê primeiro a próxima aplicação.
        if (data.medicationTrackingEnabled) ...[
          const NextDoseCard(),
          const SizedBox(height: Space.md),
        ],
        // Um número por cartão: calorias; depois água e peso lado a lado.
        _CaloriesCard(data: data),
        const SizedBox(height: Space.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _WaterTile(data: data)),
              const SizedBox(width: Space.md),
              Expanded(child: _WeightTile(data: data)),
            ],
          ),
        ),
        const SizedBox(height: Space.md),
        const ActivityHomeCard(),
        const SizedBox(height: Space.md),
        // Um só lembrete por vez: completar o perfil tem prioridade enquanto
        // faltar algo; depois, o próximo passo do dia.
        if (skipped.isNotEmpty)
          _CompleteProfileCard(skipped: skipped)
        else
          _DailyCareCard(data: data),
        const SizedBox(height: Space.section),
        _MealsSection(
          data: data,
          day: day,
          onAddMeal: () => _registerToday(context, ref, mealOnly: true),
        ),
      ],
    );
  }
}

/// Próximo passo do Início: o que falta, sem repetir os números dos cartões.
({String title, String message, String? action, String? route}) homeNextStep(
  Dashboard data,
) {
  final n = data.nutrition;
  final proteinGoal = n.goalProteinG;
  final hasProteinGoal = proteinGoal != null && proteinGoal > 0;
  final waterGoal = data.waterGoalMl;
  // Registrar refeição já é o botão principal do cartão acima: não se repete aqui.
  if (waterGoal > 0 && data.waterTotalMl < waterGoal) {
    return (
      title: 'Faltam ${Fmt.ml(waterGoal - data.waterTotalMl)} de água',
      message: 'Um copo de cada vez já ajuda.',
      action: 'Registrar água',
      route: AppRoutes.water,
    );
  }
  if (hasProteinGoal && n.totals.proteinG < proteinGoal) {
    return (
      title:
          'Faltam ${Fmt.grams(proteinGoal - n.totals.proteinG)} de proteínas',
      message: 'Veja ideias de receitas com boas fontes de proteína.',
      action: 'Ver receitas',
      route: AppRoutes.recipes,
    );
  }
  if (waterGoal <= 0 || !hasProteinGoal) {
    return (
      title: 'Defina suas metas',
      message:
          'Com metas de água e proteínas, o app mostra o que falta a cada dia.',
      action: 'Definir metas',
      route: AppRoutes.editProfile,
    );
  }
  return (
    title: 'Metas de água e proteínas alcançadas',
    message: 'Cada cuidado conta. Continue no seu ritmo.',
    action: null,
    route: null,
  );
}

/// Próximo passo do dia: uma informação e uma ação. Não repete os números
/// dos cartões de alimentação e água; aponta só o que falta (ou reconhece o
/// que foi feito). Calorias nunca viram pontuação a superar.
class _DailyCareCard extends StatelessWidget {
  const _DailyCareCard({required this.data});
  final Dashboard data;

  @override
  Widget build(BuildContext context) {
    final step = homeNextStep(data);
    final done = step.action == null;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.flag_outlined,
            color: done ? context.pic.success : context.colors.primary,
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title, style: context.text.titleSmall),
                const SizedBox(height: Space.xxs),
                Text(step.message, style: context.text.bodySmall),
                if (step.action != null) ...[
                  const SizedBox(height: Space.sm),
                  OutlinedButton(
                    onPressed: () => context.push(step.route!),
                    child: Text(step.action!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cartão branco das seções da home (cantos de 24, borda e sombra suave).
class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.child, this.padding, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: Radii.card,
      side: BorderSide(color: context.pic.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(Space.xl),
        child: child,
      ),
    ),
  );
}

/// Rótulo pequeno + número grande + unidade: o padrão dos cartões do Início.
class _BigNumber extends StatelessWidget {
  const _BigNumber({
    required this.value,
    required this.unit,
    this.size = _BigNumberSize.large,
  });

  final String value;
  final String unit;
  final _BigNumberSize size;

  @override
  Widget build(BuildContext context) {
    final style = size == _BigNumberSize.large
        ? context.text.displaySmall
        : context.text.headlineMedium;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: value,
            style: style?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.05,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          TextSpan(
            text: ' $unit',
            style: context.text.titleSmall?.copyWith(
              color: context.pic.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

enum _BigNumberSize { large, medium }

/// Calorias do dia em número grande, o quanto falta para a meta e os
/// macronutrientes em barras finas com "valor/meta".
class _CaloriesCard extends StatelessWidget {
  const _CaloriesCard({required this.data});

  final Dashboard data;

  @override
  Widget build(BuildContext context) {
    final n = data.nutrition;
    final kcal = n.totals.energyKcal;
    final goal = n.goalKcal;
    final hasGoal = goal != null && goal > 0;
    final remaining = n.remainingKcal ?? (hasGoal ? goal - kcal : null);

    return _HomeCard(
      onTap: () => context.go(AppRoutes.food),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: 20,
                color: context.colors.primary,
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'Calorias de hoje',
                    style: context.text.labelLarge?.copyWith(
                      color: context.pic.textSecondary,
                    ),
                  ),
                ),
              ),
              Text(
                n.mealsCount == 1 ? '1 refeição' : '${n.mealsCount} refeições',
                style: context.text.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          Semantics(
            label: hasGoal
                ? '${Fmt.kcal(kcal)} de ${Fmt.kcal(goal)}'
                : '${Fmt.kcal(kcal)} registradas',
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: _BigNumber(
                    value: Fmt.integer(kcal),
                    unit: hasGoal ? '/ ${Fmt.kcal(goal)}' : 'kcal',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.xs),
          if (n.mealsCount == 0)
            Text(
              'Nenhuma refeição registrada neste dia.',
              style: context.text.bodyMedium?.copyWith(
                color: context.pic.textSecondary,
              ),
            )
          else
            _GoalHint(hasGoal: hasGoal, remaining: remaining),
          if (hasGoal) ...[
            const SizedBox(height: Space.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.pill),
              child: LinearProgressIndicator(
                value: (kcal / goal).clamp(0.0, 1.0),
                minHeight: 8,
                color: kcal > goal
                    ? context.pic.warning
                    : context.colors.primary,
                backgroundColor: context.pic.surfaceMuted,
              ),
            ),
          ],
          const SizedBox(height: Space.lg),
          Row(
            children: [
              Expanded(
                child: _MacroBar(
                  label: 'Carbo',
                  semanticsName: 'Carboidratos',
                  grams: n.totals.carbsG,
                  goal: n.goalCarbsG,
                  color: _MacroColors.carbs,
                  share: _share(n.totals.carbsG * 4, n.totals),
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: _MacroBar(
                  label: 'Prot',
                  semanticsName: 'Proteínas',
                  grams: n.totals.proteinG,
                  goal: n.goalProteinG,
                  color: _MacroColors.protein,
                  share: _share(n.totals.proteinG * 4, n.totals),
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: _MacroBar(
                  label: 'Gord',
                  semanticsName: 'Gorduras',
                  grams: n.totals.fatG,
                  goal: n.goalFatG,
                  color: _MacroColors.fat,
                  share: _share(n.totals.fatG * 9, n.totals),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Parte das calorias do dia vinda do macronutriente (sem meta definida).
  static double _share(double kcal, Nutrients totals) {
    final total = totals.proteinG * 4 + totals.carbsG * 4 + totals.fatG * 9;
    return total <= 0 ? 0 : kcal / total;
  }
}

/// Cores das barras de macronutrientes. São só apoio visual: o nome e o valor
/// de cada um aparecem em texto.
abstract final class _MacroColors {
  static const protein = Color(0xFF1EB375);
  static const carbs = Color(0xFFFBC33F);
  static const fat = Color(0xFFFB8763);
}

class _GoalHint extends StatelessWidget {
  const _GoalHint({required this.hasGoal, required this.remaining});

  final bool hasGoal;
  final double? remaining;

  @override
  Widget build(BuildContext context) {
    final style = context.text.bodyMedium?.copyWith(
      color: context.pic.textSecondary,
    );
    if (!hasGoal || remaining == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: () => context.push(AppRoutes.editProfile),
          child: Text(
            'Defina sua meta',
            style: style?.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    final over = remaining! < 0;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: Fmt.kcal(remaining!.abs()),
            style: style?.copyWith(
              fontWeight: FontWeight.w700,
              color: over ? context.pic.warning : context.colors.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          TextSpan(text: over ? ' acima da meta' : ' para sua meta'),
        ],
      ),
      style: style,
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.semanticsName,
    required this.grams,
    required this.goal,
    required this.color,
    required this.share,
  });

  final String label;
  final String semanticsName;
  final double grams;
  final int? goal;
  final Color color;

  /// Usado quando não há meta: fração das calorias do dia.
  final double share;

  @override
  Widget build(BuildContext context) {
    final g = goal;
    final hasGoal = g != null && g > 0;
    final progress = (hasGoal ? grams / g : share).clamp(0.0, 1.0);
    return Semantics(
      label: hasGoal
          ? '$semanticsName: ${Fmt.integer(grams)} de ${Fmt.integer(g)} gramas'
          : '$semanticsName: ${Fmt.integer(grams)} gramas',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: context.text.bodySmall?.copyWith(
              color: context.pic.textSecondary,
            ),
          ),
          const SizedBox(height: Space.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: color,
              backgroundColor: context.pic.surfaceMuted,
            ),
          ),
          const SizedBox(height: Space.xs),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: Fmt.integer(grams),
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                TextSpan(
                  text: hasGoal ? '/${Fmt.integer(g)} g' : ' g',
                  style: context.text.bodySmall?.copyWith(
                    color: context.pic.textSecondary,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Água do dia em número grande, com "−" (desfaz o último registro), +200 ml
/// e um menu com outros volumes.
class _WaterTile extends ConsumerStatefulWidget {
  const _WaterTile({required this.data});

  final Dashboard data;

  @override
  ConsumerState<_WaterTile> createState() => _WaterTileState();
}

class _WaterTileState extends ConsumerState<_WaterTile> {
  static const _quickMl = 200;
  static const _otherMl = [300, 500];
  bool _saving = false;

  Future<void> _add(int ml) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(waterRepositoryProvider)
          .add(
            ml,
            requestId: newRequestId(),
            at: widget.data.isToday
                ? null
                : widget.data.date.add(const Duration(hours: 12)),
          );
      Refresh.water(ref);
      if (mounted) showMessage(context, '+$ml ml registrados.');
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Remove o registro de água mais recente do dia (corrige um toque a mais).
  Future<void> _undoLast() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(waterRepositoryProvider);
      final day = await repo.day(widget.data.date);
      if (day.entries.isEmpty) {
        if (mounted) showMessage(context, 'Nenhum registro de água hoje.');
        return;
      }
      final last = day.entries.reduce(
        (a, b) => a.consumedAt.isAfter(b.consumedAt) ? a : b,
      );
      await repo.delete(last.id);
      Refresh.water(ref);
      if (mounted) {
        showMessage(context, 'Registro de ${Fmt.ml(last.amountMl)} removido.');
      }
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final blue = context.pic.water;
    final progress = d.waterGoalMl > 0 ? d.waterTotalMl / d.waterGoalMl : 0.0;
    final percent = (progress * 100).round();
    final liters = d.waterTotalMl / 1000;

    return Semantics(
      container: true,
      label:
          'Água: ${Fmt.ml(d.waterTotalMl)} de ${Fmt.ml(d.waterGoalMl)}, $percent% da meta.',
      child: _HomeCard(
        padding: const EdgeInsets.all(Space.lg),
        onTap: () => context.push(AppRoutes.water),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop_rounded, size: 18, color: blue),
                const SizedBox(width: Space.xs),
                Expanded(
                  child: Text(
                    'Água',
                    style: context.text.labelLarge?.copyWith(
                      color: context.pic.textSecondary,
                    ),
                  ),
                ),
                // Outros volumes sem sair do Início.
                PopupMenuButton<int>(
                  tooltip: 'Outras quantidades de água',
                  enabled: !_saving,
                  padding: EdgeInsets.zero,
                  iconSize: 22,
                  icon: Icon(Icons.expand_more_rounded, color: blue),
                  onSelected: (ml) =>
                      ml > 0 ? _add(ml) : context.push(AppRoutes.water),
                  itemBuilder: (_) => [
                    for (final ml in _otherMl)
                      PopupMenuItem(value: ml, child: Text('+$ml ml')),
                    const PopupMenuItem(
                      value: 0,
                      child: Text('Outra quantidade'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            ExcludeSemantics(
              child: _BigNumber(
                value: Fmt.decimal(liters),
                unit: d.waterGoalMl > 0
                    ? '/ ${Fmt.decimal(d.waterGoalMl / 1000)} L'
                    : 'L',
                size: _BigNumberSize.medium,
              ),
            ),
            const SizedBox(height: Space.sm),
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.pill),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 6,
                  color: blue,
                  backgroundColor: context.pic.surfaceMuted,
                ),
              ),
            ),
            const Spacer(),
            const SizedBox(height: Space.md),
            Row(
              children: [
                _RoundButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Desfazer o último registro de água',
                  color: blue,
                  onPressed: _saving || d.waterTotalMl <= 0 ? null : _undoLast,
                ),
                const SizedBox(width: Space.xs),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _saving ? null : () => _add(_quickMl),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: EdgeInsets.zero,
                      foregroundColor: blue,
                      backgroundColor: blue.withValues(alpha: 0.12),
                    ),
                    child: const Text('+$_quickMl'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton.outlined(
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      minimumSize: const Size(44, 44),
    ),
    icon: Icon(icon, size: 20),
  );
}

/// Peso mais recente e a variação de 30 dias; um toque registra o peso.
class _WeightTile extends StatelessWidget {
  const _WeightTile({required this.data});

  final Dashboard data;

  @override
  Widget build(BuildContext context) {
    final w = data.weight;
    final change = w?.change30dKg;
    final goal = data.goal;
    return Semantics(
      container: true,
      label: w == null
          ? 'Peso: nenhum registro'
          : 'Peso: ${Fmt.kg(w.latestKg)}',
      child: _HomeCard(
        padding: const EdgeInsets.all(Space.lg),
        onTap: () => context.go(AppRoutes.progress),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.monitor_weight_outlined,
                  size: 18,
                  color: context.colors.primary,
                ),
                const SizedBox(width: Space.xs),
                Expanded(
                  child: Text(
                    'Peso',
                    style: context.text.labelLarge?.copyWith(
                      color: context.pic.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            ExcludeSemantics(
              child: w == null
                  ? Text(
                      'Sem registro',
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : _BigNumber(
                      value: Fmt.decimal(w.latestKg),
                      unit: 'kg',
                      size: _BigNumberSize.medium,
                    ),
            ),
            const SizedBox(height: Space.xs),
            Text(
              switch ((w, change, goal)) {
                (null, _, _) => 'Registre para acompanhar.',
                (_, final c?, _) when c.abs() >= 0.1 =>
                  '${c < 0 ? '−' : '+'}${Fmt.kg(c.abs())} em 30 dias',
                (_, _, final g?) when g.goalWeightKg > 0 =>
                  'Meta: ${Fmt.kg(g.goalWeightKg)}',
                _ => 'Atualizado em ${Fmt.dayMonth(w!.latestDate)}',
              },
              style: context.text.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            const SizedBox(height: Space.md),
            OutlinedButton(
              onPressed: () => showWeightForm(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: EdgeInsets.zero,
              ),
              child: const Text('Registrar peso'),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Suas refeições": registradas no dia e as habituais ainda sem registro.
class _MealsSection extends ConsumerWidget {
  const _MealsSection({
    required this.data,
    required this.day,
    required this.onAddMeal,
  });

  final Dashboard data;
  final DateTime day;
  final VoidCallback onAddMeal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(mealsOnDayProvider(day));
    final pending = data.isToday ? data.pendingMeals : const <PendingMeal>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Suas refeições',
                  style: context.text.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                ref.read(selectedDateProvider.notifier).goToday();
                context.go(AppRoutes.food);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.only(left: Space.sm),
                textStyle: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ver todas'),
                  Icon(Icons.chevron_right_rounded, size: 22),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.sm),
        switch (meals) {
          AsyncData(:final value) => _MealList(
            meals: [...value]..sort((a, b) => a.eatenAt.compareTo(b.eatenAt)),
            pending: pending,
            onAddMeal: onAddMeal,
          ),
          AsyncError() => ErrorView(
            message: 'Não foi possível carregar suas refeições.',
            onRetry: () => ref.invalidate(mealsOnDayProvider(day)),
          ),
          _ => const SkeletonCard(lines: 2),
        },
      ],
    );
  }
}

class _MealList extends StatelessWidget {
  const _MealList({
    required this.meals,
    required this.pending,
    required this.onAddMeal,
  });

  final List<Meal> meals;
  final List<PendingMeal> pending;
  final VoidCallback onAddMeal;

  @override
  Widget build(BuildContext context) {
    if (meals.isEmpty && pending.isEmpty) {
      return _HomeCard(
        padding: const EdgeInsets.all(Space.lg),
        child: Row(
          children: [
            Icon(Icons.restaurant_menu_rounded, color: context.colors.primary),
            const SizedBox(width: Space.md),
            Expanded(
              child: Text(
                'Suas refeições do dia aparecem aqui.',
                style: context.text.bodyMedium?.copyWith(
                  color: context.pic.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final meal in meals)
          _MealTile(
            mealType: meal.mealType,
            title: meal.displayName,
            subtitle: 'Registrado · ${Fmt.kcal(meal.totals.energyKcal)}',
            done: true,
            onTap: () => context.push(AppRoutes.editMeal, extra: meal),
          ),
        for (final p in pending)
          _MealTile(
            mealType: p.mealType,
            title: p.label,
            subtitle: 'Que tal registrar?',
            done: false,
            onTap: onAddMeal,
          ),
      ],
    );
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({
    required this.mealType,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.onTap,
  });

  final String mealType;
  final String title;
  final String subtitle;
  final bool done;
  final VoidCallback onTap;

  /// Ícone por tipo de refeição: ilustrativo, sem sugerir ser o prato registrado.
  static IconData icon(String mealType) => switch (mealType) {
    'breakfast' || 'supper' => Icons.free_breakfast_outlined,
    'lunch' || 'dinner' => Icons.dinner_dining_outlined,
    _ => Icons.bakery_dining_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Material(
        color: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: context.pic.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Semantics(
            button: true,
            label: '$title. $subtitle',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.pic.surfaceMuted,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon(mealType), color: context.colors.primary),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: Space.xxs),
                        Text(
                          subtitle,
                          style: context.text.bodyMedium?.copyWith(
                            color: context.pic.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    done
                        ? Icons.chevron_right_rounded
                        : Icons.add_circle_outline_rounded,
                    color: done ? context.pic.textSecondary : primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Etapas do onboarding puladas: lembra de completar (ou dispensar).
class _CompleteProfileCard extends ConsumerWidget {
  const _CompleteProfileCard({required this.skipped});

  final List<String> skipped;

  /// Etapas puladas (ou deixadas para depois) que ainda podem ser completadas.
  static List<String> pending(WidgetRef ref) =>
      (ref.watch(currentAccountProvider)?.onboardingSkipped ?? const <String>[])
          .where(_labels.containsKey)
          .toList();

  static const _labels = {
    'essentials': 'dados básicos',
    'routine': 'alimentação e rotina',
    'guidance': 'orientação profissional',
    'medication': 'medicamento',
    'care': 'preferências de atendimento',
    'targets': 'metas diárias',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (skipped.isEmpty) return const SizedBox.shrink();

    Future<void> dismiss() async {
      try {
        final account = await ref
            .read(profileRepositoryProvider)
            .saveOnboardingProgress(step: 'summary', skipped: const []);
        ref.read(sessionControllerProvider.notifier).updateAccount(account);
      } on Object catch (e) {
        if (context.mounted) showFailure(context, e);
      }
    }

    return Semantics(
      container: true,
      child: StatusBanner(
        title: 'Complete seu perfil',
        message:
            'Ficou para depois: ${skipped.map((s) => _labels[s]).join(', ')}. '
            'Com esses dados, metas e sugestões ficam mais precisas.',
        actionLabel: 'Completar agora',
        onAction: () async {
          await context.push(AppRoutes.editProfile);
          if (context.mounted) await dismiss();
        },
      ),
    );
  }
}
