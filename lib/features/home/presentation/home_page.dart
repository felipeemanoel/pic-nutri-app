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
import '../../../shared/widgets/day_navigator.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/profile_button.dart';
import '../../../shared/widgets/state_views.dart';
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

/// Painel do dia com os dados reais do usuário: equilíbrio de calorias e
/// macronutrientes, água, refeições do dia e atalhos.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(selectedDateProvider);
    final dashboard = ref.watch(dashboardProvider(day));
    final name = ref.watch(currentAccountProvider)?.firstName ?? '';

    return Scaffold(
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
                  Space.xxl,
                ),
                children: [
                  _Header(name: name),
                  const SizedBox(height: Space.xl),
                  const DayNavigator(),
                  const SizedBox(height: Space.lg),
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

/// Data em caixa alta, saudação com o ícone do período, sino e avatar.
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
    final date = _date.format(now).replaceFirst('-feira', '').toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(left: Space.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: context.text.labelMedium?.copyWith(
                    color: context.pic.textSecondary,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: Space.xs),
                Row(
                  children: [
                    Flexible(
                      child: Semantics(
                        header: true,
                        child: Text(
                          name.isEmpty ? greeting : '$greeting, $name',
                          style: context.text.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    ExcludeSemantics(
                      child: Icon(icon, size: 26, color: iconColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const NotificationBell(),
          const ProfileButton(),
        ],
      ),
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

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.data, required this.day});

  final Dashboard data;
  final DateTime day;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _CompleteProfileCard(),
      _BalanceCard(data: data),
      const SizedBox(height: Space.lg),
      _WaterCard(data: data),
      if (data.medicationTrackingEnabled) ...[
        const SizedBox(height: Space.md),
        _MedicationCard(data: data),
      ],
      const SizedBox(height: Space.xxl),
      _MealsSection(data: data, day: day),
      const SizedBox(height: Space.lg),
      const _Shortcuts(),
    ],
  );
}

/// Cartão branco das seções da home (cantos de 24, borda e sombra suave).
class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(Space.xl),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: Radii.card,
      border: Border.all(color: context.pic.border),
      boxShadow: Shadows.soft,
    ),
    child: child,
  );
}

/// "Seu dia em equilíbrio": calorias em relação à meta, macronutrientes e o
/// botão principal para registrar uma refeição.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.data});

  final Dashboard data;

  @override
  Widget build(BuildContext context) {
    final n = data.nutrition;
    final kcal = n.totals.energyKcal;
    final goal = n.goalKcal;
    final hasGoal = goal != null && goal > 0;
    final remaining = n.remainingKcal ?? (hasGoal ? goal - kcal : null);

    return _HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Seu dia em equilíbrio',
            style: context.text.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: Space.xs),
          Text(
            n.mealsCount == 0
                ? 'Nenhuma refeição registrada neste dia.'
                : 'Cada registro é um passo à frente.',
            style: context.text.bodyMedium?.copyWith(
              color: context.pic.textSecondary,
            ),
          ),
          const SizedBox(height: Space.xl),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ProgressRing(
                      progress: hasGoal ? kcal / goal : null,
                      size: 128,
                      strokeWidth: 11,
                      semanticLabel: hasGoal
                          ? '${Fmt.kcal(kcal)} de ${Fmt.kcal(goal)}'
                          : '${Fmt.kcal(kcal)} registradas',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            Fmt.integer(kcal),
                            style: context.text.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.8,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          Text(
                            hasGoal ? 'de ${Fmt.kcal(goal)}' : 'kcal',
                            style: context.text.bodySmall?.copyWith(
                              color: context.pic.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Space.md),
                    _GoalHint(hasGoal: hasGoal, remaining: remaining),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                  child: VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: context.pic.border,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _MacroBar(
                        label: 'Proteínas',
                        grams: n.totals.proteinG,
                        goal: n.goalProteinG,
                        color: _MacroColors.protein,
                        share: _share(n.totals.proteinG * 4, n.totals),
                      ),
                      _MacroBar(
                        label: 'Carboidratos',
                        grams: n.totals.carbsG,
                        goal: n.goalCarbsG,
                        color: _MacroColors.carbs,
                        share: _share(n.totals.carbsG * 4, n.totals),
                      ),
                      _MacroBar(
                        label: 'Gorduras',
                        grams: n.totals.fatG,
                        goal: n.goalFatG,
                        color: _MacroColors.fat,
                        share: _share(n.totals.fatG * 9, n.totals),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.xl),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: () => chooseHowToAddMeal(context),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: const Icon(Icons.photo_camera_rounded, size: 24),
              label: const Text('Registrar refeição'),
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(
            'Tire uma foto ou registre manualmente.',
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(
              color: context.pic.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Parte das calorias do dia vinda do macronutriente (sem meta definida).
  static double _share(double kcal, Nutrients totals) {
    final total =
        totals.proteinG * 4 + totals.carbsG * 4 + totals.fatG * 9;
    return total <= 0 ? 0 : kcal / total;
  }
}

/// Cores das barras de macronutrientes. São só apoio visual: o nome e o valor
/// de cada um aparecem em texto ao lado.
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
    final style = context.text.bodySmall?.copyWith(
      color: context.pic.textSecondary,
    );
    if (!hasGoal || remaining == null) {
      return InkWell(
        onTap: () => context.push(AppRoutes.editProfile),
        child: Text(
          'Defina sua meta',
          style: style?.copyWith(
            color: context.colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    final over = remaining! < 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.local_fire_department_rounded,
          size: 18,
          color: over ? context.pic.warning : context.colors.primary,
        ),
        const SizedBox(width: Space.xs),
        Text(
          Fmt.kcal(remaining!.abs()),
          style: context.text.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: over ? context.pic.warning : context.colors.primary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(over ? ' acima da meta' : ' para sua meta', style: style),
      ],
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.grams,
    required this.goal,
    required this.color,
    required this.share,
  });

  final String label;
  final double grams;
  final int? goal;
  final Color color;

  /// Usado quando não há meta: fração das calorias do dia.
  final double share;

  @override
  Widget build(BuildContext context) {
    final g = goal;
    final progress = (g != null && g > 0 ? grams / g : share).clamp(0.0, 1.0);
    return Semantics(
      label: g != null && g > 0
          ? '$label: ${Fmt.integer(grams)} de ${Fmt.integer(g)} gramas'
          : '$label: ${Fmt.integer(grams)} gramas',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${Fmt.integer(grams)} g',
                style: context.text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              color: color,
              backgroundColor: context.pic.surfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Água do dia: total, percentual da meta e atalho de +200 ml.
class _WaterCard extends ConsumerStatefulWidget {
  const _WaterCard({required this.data});

  final Dashboard data;

  @override
  ConsumerState<_WaterCard> createState() => _WaterCardState();
}

class _WaterCardState extends ConsumerState<_WaterCard> {
  static const _quickMl = 200;
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

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final light = Theme.of(context).brightness == Brightness.light;
    final blue = context.pic.water;
    final background = light ? const Color(0xFFEEF6FE) : context.pic.infoContainer;
    final circle = light
        ? const Color(0xFFD8EBFD)
        : blue.withValues(alpha: 0.18);
    final track = light ? const Color(0xFFD3E5F7) : context.pic.surfaceMuted;
    final progress = d.waterGoalMl > 0 ? d.waterTotalMl / d.waterGoalMl : 0.0;
    final percent = (progress * 100).round();

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: blue.withValues(alpha: 0.14)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.water),
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: circle, shape: BoxShape.circle),
                child: Icon(Icons.water_drop_outlined, color: blue, size: 26),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Água',
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: Space.xxs),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${Fmt.integer(d.waterTotalMl)} / '
                            '${Fmt.ml(d.waterGoalMl)}',
                            style: context.text.bodyLarge?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          '$percent%',
                          style: context.text.bodyMedium?.copyWith(
                            color: blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.pill),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 9,
                        color: blue,
                        backgroundColor: track,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.lg),
              OutlinedButton.icon(
                onPressed: _saving ? null : () => _add(_quickMl),
                style: OutlinedButton.styleFrom(
                  foregroundColor: blue,
                  backgroundColor: context.colors.surface,
                  side: BorderSide(color: blue),
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: Space.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text('$_quickMl ml'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Suas refeições": registradas no dia e as habituais ainda sem registro.
class _MealsSection extends ConsumerWidget {
  const _MealsSection({required this.data, required this.day});

  final Dashboard data;
  final DateTime day;

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
              onPressed: () => context.go(AppRoutes.food),
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
          ),
          AsyncError() => _MealList(meals: const [], pending: pending),
          _ => const SkeletonCard(lines: 2),
        },
      ],
    );
  }
}

class _MealList extends StatelessWidget {
  const _MealList({required this.meals, required this.pending});

  final List<Meal> meals;
  final List<PendingMeal> pending;

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
            onTap: () => chooseHowToAddMeal(context),
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

  /// Ilustração por tipo de refeição (as fotos dos pratos não ficam guardadas).
  static String image(String mealType) => switch (mealType) {
    'breakfast' || 'supper' => 'assets/images/meals/meal_breakfast.png',
    'lunch' || 'dinner' => 'assets/images/meals/meal_lunch.png',
    _ => 'assets/images/meals/meal_snack.png',
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
              padding: const EdgeInsets.fromLTRB(
                Space.sm,
                Space.sm,
                Space.sm,
                Space.sm,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      image(mealType),
                      width: 60,
                      height: 46,
                      fit: BoxFit.cover,
                    ),
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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.pic.brandContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      done ? Icons.check_rounded : Icons.add_rounded,
                      color: primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.pic.textSecondary,
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

/// Atalhos: peso, hábitos e bem-estar.
class _Shortcuts extends StatelessWidget {
  const _Shortcuts();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _ShortcutTile(
          icon: Icons.monitor_weight_outlined,
          label: 'Peso',
          onTap: () => showWeightForm(context),
        ),
      ),
      const SizedBox(width: Space.sm),
      Expanded(
        child: _ShortcutTile(
          icon: Icons.bar_chart_rounded,
          label: 'Hábitos',
          onTap: () => context.push(AppRoutes.engagement),
        ),
      ),
      const SizedBox(width: Space.sm),
      Expanded(
        child: _ShortcutTile(
          icon: Icons.spa_outlined,
          label: 'Bem-estar',
          onTap: () => context.push(AppRoutes.symptoms),
        ),
      ),
    ],
  );
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: context.pic.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: Space.lg,
          ),
          child: Row(
            children: [
              Icon(icon, color: context.colors.primary, size: 26),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  label,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: context.pic.textSecondary,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.data});

  final Dashboard data;

  @override
  Widget build(BuildContext context) {
    final last = data.lastDose;
    return AppCard(
      color: context.pic.aiContainer,
      borderColor: context.pic.ai.withValues(alpha: 0.18),
      onTap: () => context.go(AppRoutes.progress),
      child: Row(
        children: [
          Icon(Icons.medication_outlined, color: context.colors.primary),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  last == null
                      ? 'Nenhuma aplicação registrada'
                      : 'Última aplicação: ${last.medicationName}',
                  style: context.text.titleSmall,
                ),
                Text(
                  last == null
                      ? 'Registre aplicações e sintomas em Evolução.'
                      : '${Fmt.shortDate(last.takenAt)} às '
                            '${Fmt.time(last.takenAt)}',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

/// Etapas do onboarding puladas: lembra de completar (ou dispensar).
class _CompleteProfileCard extends ConsumerWidget {
  const _CompleteProfileCard();

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
    final skipped =
        (ref.watch(currentAccountProvider)?.onboardingSkipped ??
                const <String>[])
            .where(_labels.containsKey)
            .toList();
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

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
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
