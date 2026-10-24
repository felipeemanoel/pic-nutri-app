import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/symptom_models.dart';
import '../data/symptom_repository.dart';
import 'symptom_form.dart';

/// Bem-estar (sintomas): linha do tempo, registro e resumo para compartilhar.
class SymptomsPage extends ConsumerWidget {
  const SymptomsPage({super.key});

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final days = ref.read(symptomDaysProvider);
    final to = DateTime.now();
    try {
      final text = await ref.read(symptomRepositoryProvider).summary(from: to.subtract(Duration(days: days - 1)), to: to);
      await SharePlus.instance.share(ShareParams(text: text, subject: 'Resumo de sintomas'));
    } on Object catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeline = ref.watch(symptomTimelineProvider);
    final days = ref.watch(symptomDaysProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bem-estar'),
        actions: [
          IconButton(
            tooltip: 'Compartilhar resumo',
            icon: const Icon(Icons.ios_share),
            onPressed: () => _share(context, ref),
          ),
          IconButton(
            tooltip: 'Quando procurar atendimento',
            icon: const Icon(Icons.health_and_safety_outlined),
            onPressed: () => context.push(AppRoutes.helpArticle('sinais-de-alerta')),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showSymptomForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(symptomTimelineProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, Space.fabClearance),
          children: [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 30, label: Text('30 dias')),
                ButtonSegment(value: 90, label: Text('90 dias')),
                ButtonSegment(value: 365, label: Text('1 ano')),
              ],
              selected: {days},
              onSelectionChanged: (s) => ref.read(symptomDaysProvider.notifier).set(s.first),
            ),
            const SizedBox(height: Space.md),
            AsyncValueView<SymptomTimeline>(
              value: timeline,
              onRetry: () => ref.invalidate(symptomTimelineProvider),
              data: (t) => t.items.isEmpty
                  ? const EmptyState(
                      icon: Icons.sentiment_satisfied_alt_outlined,
                      title: 'Nenhum sintoma no período',
                      message: 'Registre como você está se sentindo. O histórico ajuda nas conversas com seus profissionais de saúde.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(t.nearbyNote, style: context.text.bodySmall),
                        ..._grouped(context, ref, t.items),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _grouped(BuildContext context, WidgetRef ref, List<SymptomItem> items) {
    final widgets = <Widget>[];
    String? lastDay;
    for (final item in items) {
      final day = Fmt.fullDate(item.occurredAt);
      if (day != lastDay) {
        widgets.add(SectionHeader(title: day[0].toUpperCase() + day.substring(1)));
        lastDay = day;
      }
      widgets.add(_SymptomTile(item: item));
    }
    return widgets;
  }
}

class _SymptomTile extends ConsumerWidget {
  const _SymptomTile({required this.item});

  final SymptomItem item;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(
      context,
      title: 'Excluir registro?',
      message: 'O registro de ${item.label.toLowerCase()} será apagado.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(symptomRepositoryProvider).delete(item.id);
      ref.invalidate(symptomTimelineProvider);
    } on Object catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pic = context.pic;
    final color = switch (item.intensity) {
      >= 3 => pic.error,
      2 => pic.warning,
      _ => pic.success,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: Space.sm),
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 12, color: color),
                const SizedBox(width: Space.sm),
                Expanded(child: Text(item.label, style: context.text.titleSmall)),
                Text(Fmt.time(item.occurredAt), style: context.text.bodySmall),
                if (item.editable)
                  IconButton(
                    tooltip: 'Excluir',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _delete(context, ref),
                  ),
              ],
            ),
            Text('Intensidade ${item.intensityLabel}', style: context.text.bodySmall),
            if (item.contextLabel != null) Text(item.contextLabel!, style: context.text.bodySmall),
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: Space.xs),
              Text(item.notes!),
            ],
            for (final fact in item.nearby)
              Padding(
                padding: const EdgeInsets.only(top: Space.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.schedule, size: 14, color: pic.textSecondary),
                    const SizedBox(width: Space.xs),
                    Expanded(child: Text(fact, style: context.text.bodySmall)),
                  ],
                ),
              ),
            if (item.warningSigns.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: Space.sm),
                child: Text('Sinais de alerta marcados', style: context.text.labelMedium?.copyWith(color: pic.error)),
              ),
          ],
        ),
      ),
    );
  }
}
