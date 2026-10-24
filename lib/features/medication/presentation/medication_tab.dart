import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/medication_models.dart';
import '../data/medication_repository.dart';
import 'medication_forms.dart';
import 'medication_instructions_page.dart';

/// Aba "Medicamento" da Evolução: medicamentos informados, aplicações e
/// sintomas. Registro informativo, sem orientação de dose.
class MedicationTab extends ConsumerWidget {
  const MedicationTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(medicationOptionsProvider);
    final medications = ref.watch(medicationsProvider);
    final doses = ref.watch(recentDosesProvider);

    return Scaffold(
      floatingActionButton: (medications.value?.any((m) => m.isActive) ?? false)
          ? FloatingActionButton.extended(
              heroTag: 'add-dose',
              onPressed: () => openDoseForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Aplicação'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(medicationsProvider)
            ..invalidate(recentDosesProvider);
          await ref.read(medicationsProvider.future);
        },
        child: AsyncValueView<MedicationOptions>(
          value: options,
          onRetry: () => ref.invalidate(medicationOptionsProvider),
          data: (opts) => ListView(
            padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, Space.fabClearance),
            children: [
              _Disclaimer(text: opts.disclaimer),
              const SizedBox(height: Space.section),
              // 1. Cadastro
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text('Seus medicamentos', style: context.text.titleMedium),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => showMedicationForm(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Cadastrar'),
                  ),
                ],
              ),
              AsyncValueView<List<Medication>>(
                value: medications,
                onRetry: () => ref.invalidate(medicationsProvider),
                data: (list) => list.isEmpty
                    ? EmptyState(
                        icon: Icons.medication_outlined,
                        title: 'Nenhum medicamento cadastrado',
                        message:
                            'Cadastre o medicamento prescrito para registrar aplicações e sintomas.',
                        actionLabel: 'Cadastrar medicamento',
                        onAction: () => showMedicationForm(context),
                      )
                    : Column(
                        children: [
                          for (final m in list)
                            Card(
                              child: ListTile(
                                leading: Icon(
                                  m.isInjection
                                      ? Icons.vaccines_outlined
                                      : Icons.medication_outlined,
                                ),
                                title: Text(m.name),
                                subtitle: Text(
                                  [
                                    opts.label(opts.frequencies, m.frequency),
                                    if (!m.isActive) 'inativo',
                                    if (m.lastDoseAt != null)
                                      'última: ${Fmt.shortDate(m.lastDoseAt!)} às ${Fmt.time(m.lastDoseAt!)}',
                                  ].join(' · '),
                                ),
                                trailing: const Icon(Icons.edit_outlined),
                                onTap: () =>
                                    showMedicationForm(context, medication: m),
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: Space.section),
              // 2. Registro das aplicações
              Row(
                children: [
                  Expanded(
                    child: Semantics(header: true, child: Text('Aplicações', style: context.text.titleMedium)),
                  ),
                  if (medications.value?.any((m) => m.isActive) ?? false)
                    TextButton.icon(
                      onPressed: () => openDoseForm(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Registrar'),
                    ),
                ],
              ),
              AsyncValueView<List<MedicationDose>>(
                value: doses,
                onRetry: () => ref.invalidate(recentDosesProvider),
                data: (list) => list.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Nenhuma aplicação registrada nos últimos 90 dias.',
                        ),
                      )
                    : Column(
                        children: [
                          for (final d in list)
                            _DoseTile(dose: d, options: opts),
                        ],
                      ),
              ),
              // 3. Consulta às instruções (separada do registro)
              if (medications.value?.any((m) => m.isInjection && m.isActive) ?? false) ...[
                const SizedBox(height: Space.section),
                Semantics(header: true, child: Text('Instruções do fabricante', style: context.text.titleMedium)),
                const SizedBox(height: Space.xs),
                for (final m in medications.value!.where((m) => m.isInjection && m.isActive))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.menu_book_outlined),
                    title: Text(m.name),
                    subtitle: const Text('Bula, dispositivo e rodízio de regiões'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => MedicationInstructionsPage.open(context, m.name),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) =>
      StatusBanner(message: text, icon: Icons.health_and_safety_outlined);
}

class _DoseTile extends StatelessWidget {
  const _DoseTile({required this.dose, required this.options});

  final MedicationDose dose;
  final MedicationOptions options;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = dose.doseAmount == null
        ? null
        : '${Fmt.decimal(dose.doseAmount!)} ${options.label(options.doseUnits, dose.doseUnit)}';
    final details = [
      ?amount,
      if (dose.injectionSite != null)
        options.label(options.injectionSites, dose.injectionSite),
    ].join(' · ');

    return Card(
      child: ListTile(
        title: Text(
          '${dose.medicationName ?? 'Medicamento'} — ${Fmt.shortDate(dose.takenAt)} às ${Fmt.time(dose.takenAt)}',
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (details.isNotEmpty) Text(details),
            if (dose.symptoms.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final s in dose.symptoms)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          '${s.label ?? s.code} (${options.label(options.intensities, '${s.intensity}')})',
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
        isThreeLine: dose.symptoms.isNotEmpty,
        onTap: () => openDoseForm(context, dose: dose),
      ),
    );
  }
}
