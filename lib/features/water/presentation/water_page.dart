import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/request_id.dart';
import '../../../shared/state/refresh.dart';
import '../../../shared/state/selected_date.dart';
import '../../../shared/validators.dart';
import '../../../shared/widgets/charts.dart';
import '../../../shared/widgets/day_navigator.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/application/session_controller.dart';
import '../../profile/data/profile_repository.dart';
import '../data/water_repository.dart';

/// Consumo de água do dia, registros, meta e histórico da semana.
class WaterPage extends ConsumerStatefulWidget {
  const WaterPage({super.key});

  @override
  ConsumerState<WaterPage> createState() => _WaterPageState();
}

class _WaterPageState extends ConsumerState<WaterPage> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      Refresh.water(ref);
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add(DateTime day, int ml) => _run(
    () => ref
        .read(waterRepositoryProvider)
        .add(
          ml,
          requestId: newRequestId(),
          at: day == SelectedDate.today()
              ? null
              : day.add(const Duration(hours: 12)),
        ),
  );

  Future<int?> _askAmount({String title = 'Quantidade', int? initial}) {
    final controller = TextEditingController(text: initial?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: NumberField(
            controller: controller,
            label: 'Mililitros',
            unit: 'ml',
            min: 10,
            max: 3000,
            decimal: false,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(
                  context,
                  Validators.parseNumber(controller.text)!.round(),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _editGoal(int current) async {
    final value = await _askAmount(
      title: 'Meta diária de água',
      initial: current,
    );
    if (value == null) return;
    if (value < 500) {
      if (mounted) {
        showMessage(context, 'A meta deve ser de pelo menos 500 ml.');
      }
      return;
    }
    await _run(() async {
      await ref.read(profileRepositoryProvider).updateProfile({
        'water_goal_ml': value,
      });
      await ref.read(sessionControllerProvider.notifier).reloadAccount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final day = ref.watch(selectedDateProvider);
    final water = ref.watch(waterDayProvider(day));
    final history = ref.watch(waterHistoryProvider(day));

    return Scaffold(
      appBar: AppBar(title: const Text('Água')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xxl),
        children: [
          const DayNavigator(),
          AsyncValueView<WaterDay>(
            value: water,
            onRetry: () => ref.invalidate(waterDayProvider(day)),
            data: (w) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Consumido, meta e botões rápidos em destaque.
                AppCard(
                  semanticLabel: 'Água: ${Fmt.ml(w.totalMl)} de ${Fmt.ml(w.goalMl)}.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ExcludeSemantics(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: Fmt.ml(w.totalMl), style: context.text.headlineMedium),
                              TextSpan(text: '  de ${Fmt.ml(w.goalMl)}', style: context.text.bodyLarge),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.md),
                      ExcludeSemantics(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(Radii.pill),
                          child: LinearProgressIndicator(
                            value: w.goalMl > 0 ? (w.totalMl / w.goalMl).clamp(0.0, 1.0) : 0,
                            minHeight: 10,
                            color: context.pic.water,
                            backgroundColor: context.pic.surfaceMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.lg),
                      Wrap(
                        spacing: Space.sm,
                        runSpacing: Space.sm,
                        children: [
                          for (final ml in const [150, 200, 300, 500])
                            FilledButton.tonalIcon(
                              onPressed: _busy ? null : () => _add(day, ml),
                              icon: const Icon(Icons.add_rounded),
                              label: Text('$ml ml'),
                            ),
                          OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () async {
                                    final ml = await _askAmount();
                                    if (ml != null) await _add(day, ml);
                                  },
                            child: const Text('Outro valor'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.section),
                Text('Registros do dia', style: context.text.titleMedium),
                if (w.entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Nenhum registro neste dia.'),
                  ),
                for (final e in w.entries)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.water_drop),
                    title: Text(Fmt.ml(e.amountMl)),
                    subtitle: Text(Fmt.time(e.consumedAt)),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Opções',
                      onSelected: (action) async {
                        if (action == 'edit') {
                          final ml = await _askAmount(
                            title: 'Editar registro',
                            initial: e.amountMl,
                          );
                          if (ml != null) {
                            await _run(
                              () => ref
                                  .read(waterRepositoryProvider)
                                  .update(e.id, ml),
                            );
                          }
                        } else {
                          final ok = await confirmAction(
                            context,
                            title: 'Remover registro?',
                            message:
                                'O registro de ${Fmt.ml(e.amountMl)} será removido.',
                            confirmLabel: 'Remover',
                            destructive: true,
                          );
                          if (ok) {
                            await _run(
                              () => ref
                                  .read(waterRepositoryProvider)
                                  .delete(e.id),
                            );
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'delete', child: Text('Remover')),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.section),
          Text('Últimos 7 dias', style: context.text.titleMedium),
          const SizedBox(height: Space.sm),
          history.when(
            data: (days) => DailyBarChart(
              days: [for (final d in days) (d.date, d.totalMl.toDouble())],
              goal: (water.value?.goalMl ?? 2000).toDouble(),
            ),
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(message: friendlyMessage(e)),
          ),
          // Meta separada do registro de um copo.
          const SizedBox(height: Space.section),
          if (water.value case final w?)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Meta diária de água'),
              subtitle: Text(Fmt.ml(w.goalMl)),
              trailing: TextButton(
                onPressed: _busy ? null : () => _editGoal(w.goalMl),
                child: const Text('Alterar'),
              ),
            ),
        ],
      ),
    );
  }
}
