import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/request_id.dart';
import '../../../shared/state/refresh.dart';
import '../../../shared/validators.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/medication_models.dart';
import '../data/medication_repository.dart';

/// Cadastro/edição de medicamento.
Future<void> showMedicationForm(
  BuildContext context, {
  Medication? medication,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _MedicationForm(medication: medication),
);

/// Registro/edição de aplicação com sintomas.
Future<void> openDoseForm(BuildContext context, {MedicationDose? dose}) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _DoseFormPage(dose: dose),
      ),
    );

class _MedicationForm extends ConsumerStatefulWidget {
  const _MedicationForm({this.medication});

  final Medication? medication;

  @override
  ConsumerState<_MedicationForm> createState() => _MedicationFormState();
}

class _MedicationFormState extends ConsumerState<_MedicationForm> {
  final _formKey = GlobalKey<FormState>();
  final _requestId = newRequestId();
  late final _name = TextEditingController(text: widget.medication?.name);
  late final _notes = TextEditingController(text: widget.medication?.notes);
  late String _form = widget.medication?.form ?? 'injection';
  late String _unit = widget.medication?.doseUnit ?? 'mg';
  late String _frequency = widget.medication?.frequency ?? 'weekly';
  late bool _active = widget.medication?.isActive ?? true;
  bool _saving = false;

  bool get _isEdit => widget.medication != null;

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(medicationRepositoryProvider)
          .saveMedication(
            id: widget.medication?.id,
            name: _name.text,
            form: _form,
            doseUnit: _unit,
            frequency: _frequency,
            isActive: _isEdit ? _active : null,
            notes: _notes.text,
            requestId: _isEdit ? null : _requestId,
          );
      Refresh.medication(ref);
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmAction(
      context,
      title: 'Excluir medicamento?',
      message:
          'O medicamento e todas as aplicações registradas para ele serão apagados. '
          'Para manter o histórico, marque-o como inativo.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(medicationRepositoryProvider)
          .deleteMedication(widget.medication!.id);
      Refresh.medication(ref);
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(medicationOptionsProvider).value;
    if (options == null) {
      return const SizedBox(height: 200, child: LoadingView());
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEdit ? 'Editar medicamento' : 'Novo medicamento',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Informe o medicamento conforme a sua prescrição.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Nome do medicamento',
                ),
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v?.trim().length ?? 0) < 2 ? 'Informe o nome.' : null,
              ),
              _Dropdown(
                label: 'Forma',
                value: _form,
                options: options.forms,
                onChanged: (v) => setState(() => _form = v),
              ),
              const SizedBox(height: 12),
              _Dropdown(
                label: 'Unidade da dose',
                value: _unit,
                options: options.doseUnits,
                onChanged: (v) => setState(() => _unit = v),
              ),
              const SizedBox(height: 12),
              _Dropdown(
                label: 'Frequência (para organização)',
                value: _frequency,
                options: options.frequencies,
                onChanged: (v) => setState(() => _frequency = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                ),
                maxLength: 500,
                maxLines: 2,
              ),
              if (_isEdit)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Em uso'),
                  subtitle: const Text(
                    'Desative quando não estiver mais usando.',
                  ),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
              const SizedBox(height: 8),
              LoadingButton(
                label: 'Salvar',
                loading: _saving,
                onPressed: _save,
              ),
              if (_isEdit)
                TextButton(
                  onPressed: _saving ? null : _delete,
                  child: const Text('Excluir medicamento'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<Option> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    // Recria o campo quando o valor muda por fora (ex.: troca de medicamento).
    key: ValueKey('$label:$value'),
    initialValue: options.any((o) => o.value == value) ? value : null,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      for (final o in options)
        DropdownMenuItem(value: o.value, child: Text(o.label)),
    ],
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
  );
}

class _DoseFormPage extends ConsumerStatefulWidget {
  const _DoseFormPage({this.dose});

  final MedicationDose? dose;

  @override
  ConsumerState<_DoseFormPage> createState() => _DoseFormPageState();
}

class _DoseFormPageState extends ConsumerState<_DoseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _requestId = newRequestId();
  late String? _medicationId = widget.dose?.medicationId;
  late DateTime _takenAt = widget.dose?.takenAt ?? DateTime.now();
  late final _amount = TextEditingController(
    text: widget.dose?.doseAmount == null
        ? ''
        : Fmt.decimal(widget.dose!.doseAmount!),
  );
  late String? _unit = widget.dose?.doseUnit;
  late String? _site = widget.dose?.injectionSite;
  late final Map<String, int> _symptoms = {
    for (final s in widget.dose?.symptoms ?? const <SymptomEntry>[])
      s.code: s.intensity,
  };
  late final _notes = TextEditingController(text: widget.dose?.notes);
  bool _saving = false;

  bool get _isEdit => widget.dose != null;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _takenAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_takenAt),
    );
    if (time == null) return;
    setState(
      () => _takenAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _save(Medication medication) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(medicationRepositoryProvider)
          .saveDose(
            id: widget.dose?.id,
            medicationId: medication.id,
            takenAt: _takenAt,
            doseAmount: Validators.parseNumber(_amount.text),
            doseUnit: _unit ?? medication.doseUnit,
            injectionSite: medication.isInjection ? _site : null,
            symptoms: [
              for (final e in _symptoms.entries)
                SymptomEntry(code: e.key, intensity: e.value),
            ],
            notes: _notes.text,
            requestId: _isEdit ? null : _requestId,
          );
      Refresh.medication(ref);
      if (!mounted) return;
      if (saved.alert != null) {
        await showDialog<void>(
          context: context,
          builder: (dialog) => AlertDialog(
            icon: const Icon(Icons.health_and_safety_outlined),
            title: const Text('Atenção aos sintomas'),
            content: Text(saved.alert!),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialog).pop(),
                child: const Text('Entendi'),
              ),
            ],
          ),
        );
      }
      if (!mounted) return;
      showMessage(
        context,
        _isEdit ? 'Aplicação atualizada.' : 'Aplicação registrada.',
      );
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmAction(
      context,
      title: 'Excluir aplicação?',
      message: 'O registro e os sintomas informados serão apagados.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok) return;
    setState(() => _saving = true);
    try {
      await ref.read(medicationRepositoryProvider).deleteDose(widget.dose!.id);
      Refresh.medication(ref);
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(medicationOptionsProvider).value;
    final medications = ref.watch(medicationsProvider).value;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar aplicação' : 'Registrar aplicação'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Excluir aplicação',
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: options == null || medications == null
          ? const LoadingView()
          : Builder(
              builder: (context) {
                final available = medications
                    .where((m) => m.isActive || m.id == _medicationId)
                    .toList();
                _medicationId ??= available.firstOrNull?.id;
                final medication = available
                    .where((m) => m.id == _medicationId)
                    .firstOrNull;
                if (medication == null) {
                  return const EmptyState(
                    icon: Icons.medication_outlined,
                    title: 'Nenhum medicamento em uso',
                    message:
                        'Cadastre um medicamento antes de registrar aplicações.',
                  );
                }
                _unit ??= medication.doseUnit;

                return Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        options.disclaimer,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      _Dropdown(
                        label: 'Medicamento',
                        value: _medicationId,
                        options: [
                          for (final m in available) Option(m.id, m.name),
                        ],
                        onChanged: (v) => setState(() {
                          _medicationId = v;
                          _unit = available
                              .firstWhere((m) => m.id == v)
                              .doseUnit;
                        }),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.schedule),
                        title: const Text('Data e horário'),
                        subtitle: Text(
                          '${Fmt.shortDate(_takenAt)} às ${Fmt.time(_takenAt)}',
                        ),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: _pickTime,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: NumberField(
                              controller: _amount,
                              label: 'Dose informada',
                              helper: 'Conforme a sua prescrição (opcional)',
                              min: 0.001,
                              max: 99999,
                              optional: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _Dropdown(
                              label: 'Unidade',
                              value: _unit,
                              options: options.doseUnits,
                              onChanged: (v) => setState(() => _unit = v),
                            ),
                          ),
                        ],
                      ),
                      if (medication.isInjection) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          initialValue: _site,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Local da aplicação (opcional)',
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              child: Text('Não informar'),
                            ),
                            for (final o in options.injectionSites)
                              DropdownMenuItem<String?>(
                                value: o.value,
                                child: Text(o.label),
                              ),
                          ],
                          onChanged: (v) => setState(() => _site = v),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Sintomas (opcional)',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final s in options.symptoms)
                            FilterChip(
                              label: Text(s.label),
                              selected: _symptoms.containsKey(s.value),
                              onSelected: (on) => setState(() {
                                if (on) {
                                  _symptoms[s.value] = 1;
                                } else {
                                  _symptoms.remove(s.value);
                                }
                              }),
                            ),
                        ],
                      ),
                      for (final code in _symptoms.keys.toList())
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Intensidade: ${options.label(options.symptoms, code)}',
                              ),
                              const SizedBox(height: 4),
                              SegmentedButton<int>(
                                segments: [
                                  for (final i in options.intensities)
                                    ButtonSegment(
                                      value: int.parse(i.value),
                                      label: Text(i.label),
                                    ),
                                ],
                                selected: {_symptoms[code]!},
                                onSelectionChanged: (v) =>
                                    setState(() => _symptoms[code] = v.first),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notes,
                        decoration: const InputDecoration(
                          labelText: 'Observações (opcional)',
                        ),
                        maxLength: 500,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      LoadingButton(
                        label: 'Salvar',
                        loading: _saving,
                        onPressed: () => _save(medication),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
