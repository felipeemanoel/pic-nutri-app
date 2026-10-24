import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/request_id.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/symptom_models.dart';
import '../data/symptom_repository.dart';

/// Abre o formulário de sintoma. Depois de salvar, mostra a orientação de
/// segurança quando houver sinal de alerta ou intensidade forte.
Future<void> showSymptomForm(BuildContext context) async {
  final alert = await showModalBottomSheet<SafetyAlert?>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const FractionallySizedBox(heightFactor: 0.92, child: _SymptomForm()),
  );
  if (alert != null && context.mounted) await showSafetyAlert(context, alert);
}

Future<void> showSafetyAlert(BuildContext context, SafetyAlert alert) => showDialog<void>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    icon: Icon(
      alert.urgent ? Icons.emergency_outlined : Icons.health_and_safety_outlined,
      color: alert.urgent ? dialogContext.pic.error : dialogContext.pic.warning,
      size: 36,
    ),
    title: Text(alert.title),
    content: Text(alert.message),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.of(dialogContext).pop();
          context.push(AppRoutes.helpArticle(alert.article));
        },
        child: const Text('Ver orientações'),
      ),
      FilledButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Entendi')),
    ],
  ),
);

class _SymptomForm extends ConsumerStatefulWidget {
  const _SymptomForm();

  @override
  ConsumerState<_SymptomForm> createState() => _SymptomFormState();
}

class _SymptomFormState extends ConsumerState<_SymptomForm> {
  final _requestId = newRequestId();
  final _other = TextEditingController();
  final _notes = TextEditingController();
  String? _symptom;
  int _intensity = 1;
  String? _context;
  DateTime _at = DateTime.now();
  final Set<String> _warnings = {};
  bool _saving = false;

  @override
  void dispose() {
    _other.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _at,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_at));
    if (time == null) return;
    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => _at = picked.isAfter(DateTime.now()) ? DateTime.now() : picked);
  }

  Future<void> _save() async {
    if (_symptom == null) {
      showMessage(context, 'Escolha o sintoma.');
      return;
    }
    if (_symptom == 'other' && _other.text.trim().isEmpty) {
      showMessage(context, 'Descreva o sintoma.');
      return;
    }
    setState(() => _saving = true);
    try {
      final alert = await ref.read(symptomRepositoryProvider).create(
        symptom: _symptom!,
        otherLabel: _symptom == 'other' ? _other.text.trim() : null,
        intensity: _intensity,
        occurredAt: _at,
        context: _context,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        warningSigns: _warnings.toList(),
        requestId: _requestId,
      );
      ref.invalidate(symptomTimelineProvider);
      if (mounted) Navigator.of(context).pop(alert);
    } on Object catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(symptomOptionsProvider);
    return AsyncValueView<SymptomOptions>(
      value: options,
      onRetry: () => ref.invalidate(symptomOptionsProvider),
      data: (o) => ListView(
        padding: EdgeInsets.fromLTRB(Space.page, 0, Space.page, MediaQuery.viewInsetsOf(context).bottom + Space.xl),
        children: [
          Semantics(header: true, child: Text('Como você está se sentindo?', style: context.text.titleLarge)),
          const SizedBox(height: Space.xs),
          Text(o.disclaimer, style: context.text.bodySmall),
          const SizedBox(height: Space.lg),
          // Opções frequentes à vista, com um toque.
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              for (final opt in o.symptoms)
                ChoiceChip(
                  label: Text(opt.label),
                  selected: _symptom == opt.value,
                  onSelected: (v) => setState(() => _symptom = v ? opt.value : null),
                ),
            ],
          ),
          if (_symptom == 'other') ...[
            const SizedBox(height: Space.md),
            TextField(controller: _other, maxLength: 80, decoration: const InputDecoration(labelText: 'Qual?')),
          ],
          const SizedBox(height: Space.section),
          Text('Quanto está incomodando?', style: context.text.titleSmall),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              for (final i in o.intensities)
                ChoiceChip(
                  label: Text(i.label),
                  selected: _intensity == int.parse(i.value),
                  onSelected: (_) => setState(() => _intensity = int.parse(i.value)),
                ),
            ],
          ),
          const SizedBox(height: Space.lg),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: const Text('Quando'),
            subtitle: Text('${Fmt.shortDate(_at)} às ${Fmt.time(_at)}'),
            trailing: TextButton(onPressed: _pickTime, child: const Text('Alterar')),
          ),
          // Sinais de alerta continuam à vista: são importantes para a segurança.
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            leading: Icon(Icons.warning_amber_rounded, color: context.pic.error),
            title: const Text('Algum destes sinais de alerta?'),
            subtitle: _warnings.isEmpty ? null : Text('${_warnings.length} marcado(s)'),
            children: [
              for (final w in o.warningSigns)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _warnings.contains(w.value),
                  title: Text(w.label),
                  onChanged: (v) => setState(() => (v ?? false) ? _warnings.add(w.value) : _warnings.remove(w.value)),
                ),
            ],
          ),
          // Complementos: contexto e observações.
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            leading: const Icon(Icons.notes_rounded),
            title: const Text('Contexto e observações (opcional)'),
            initiallyExpanded: _context != null || _notes.text.isNotEmpty,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: [
                    for (final c in o.contexts)
                      ChoiceChip(
                        label: Text(c.label),
                        selected: _context == c.value,
                        onSelected: (v) => setState(() => _context = v ? c.value : null),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Space.md),
              TextField(
                controller: _notes,
                maxLength: 1000,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Observações'),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          LoadingButton(label: 'Registrar', loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
