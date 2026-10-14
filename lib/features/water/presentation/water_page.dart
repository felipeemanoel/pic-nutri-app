import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/request_id.dart';
import '../../../shared/state/refresh.dart';
import '../../../shared/state/selected_date.dart';
import '../../../shared/validators.dart';
import '../../../shared/widgets/charts.dart';
import '../../../shared/widgets/day_navigator.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/progress_widgets.dart';
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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const DayNavigator(),
          AsyncValueView<WaterDay>(
            value: water,
            onRetry: () => ref.invalidate(waterDayProvider(day)),
            data: (w) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Stat(
                          value: Fmt.ml(w.totalMl),
                          label: 'de ${Fmt.ml(w.goalMl)} (meta de referência)',
                        ),
                        const SizedBox(height: 12),
                        LabeledProgress(
                          label: 'Progresso do dia',
                          value: w.totalMl.toDouble(),
                          unit: 'ml',
                          goal: w.goalMl,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final ml in const [150, 200, 300, 500])
                              ActionChip(
                                avatar: const Icon(
                                  Icons.water_drop_outlined,
                                  size: 18,
                                ),
                                label: Text('+$ml ml'),
                                onPressed: _busy ? null : () => _add(day, ml),
                              ),
                            ActionChip(
                              avatar: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Outro valor'),
                              onPressed: _busy
                                  ? null
                                  : () async {
                                      final ml = await _askAmount();
                                      if (ml != null) await _add(day, ml);
                                    },
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _busy ? null : () => _editGoal(w.goalMl),
                            child: const Text('Ajustar meta diária'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Registros',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
          const SizedBox(height: 16),
          Text(
            'Últimos 7 dias',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          history.when(
            data: (days) => DailyBarChart(
              days: [for (final d in days) (d.date, d.totalMl.toDouble())],
              goal: (water.value?.goalMl ?? 2000).toDouble(),
            ),
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(message: friendlyMessage(e)),
          ),
        ],
      ),
    );
  }
}
