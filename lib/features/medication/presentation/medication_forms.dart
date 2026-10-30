import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/request_id.dart';
import '../../../shared/state/refresh.dart';
import '../../../shared/validators.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/medication_catalog.dart';
import '../data/medication_models.dart';
import '../data/medication_repository.dart';
import 'injection_guidance.dart';
import 'medication_catalog_picker.dart';

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
              OutlinedButton.icon(
                onPressed: () async {
                  final m = await showMedicationCatalogPicker(context);
                  if (m == null || !mounted) return;
                  setState(() {
                    _name.text = m.genericEntry ? '${m.name} ' : m.name;
                    _form = m.form;
                    _unit = 'mg';
                    _frequency = m.frequency;
                  });
                },
                icon: const Icon(Icons.list_alt_rounded),
                label: const Text('Escolher na lista de canetas'),
              ),
              const SizedBox(height: 4),
              Text(
                'Preenche nome, forma e frequência. Você pode ajustar depois.',
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
                onChanged: (_) => setState(() {}),
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
    super.key,
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
    key: ValueKey('$label:$value:$key'),
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
  bool _adding = false;
  int _catalogNonce = 0;
  String? _presentation;

  static const _fromCatalog = '#catalog';

  bool get _isEdit => widget.dose != null;

  /// Escolhe no catálogo completo. Se a pessoa ainda não tem esse
  /// medicamento cadastrado, ele é cadastrado na hora (frequência da bula).
  Future<void> _chooseFromCatalog(List<Medication> registered) async {
    // Volta o campo para o medicamento atual enquanto a lista está aberta.
    setState(() => _catalogNonce++);
    final known = await showMedicationCatalogPicker(context);
    if (known == null || !mounted) return;
    final key = KnownMedication.normalize(known.name);
    final existing = registered
        .where((m) => m.isActive && KnownMedication.normalize(m.name) == key)
        .firstOrNull;
    if (existing != null) {
      _select(existing);
      return;
    }
    setState(() => _adding = true);
    try {
      final created = await ref
          .read(medicationRepositoryProvider)
          .saveMedication(
            name: known.name,
            form: known.form,
            doseUnit: 'mg',
            frequency: known.frequency,
            requestId: newRequestId(),
          );
      Refresh.medication(ref);
      await ref.read(medicationsProvider.future);
      if (mounted) _select(created);
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  void _select(Medication m) => setState(() {
    _medicationId = m.id;
    _site = null;
    _presentation = null;
    _amount.clear();
    _unit = m.doseUnit;
  });

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
      body: options == null || medications == null || _adding
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
                  return EmptyState(
                    icon: Icons.medication_outlined,
                    title: 'Qual medicamento você aplicou?',
                    message:
                        'Escolha na lista de canetas para registrar a aplicação.',
                    actionLabel: 'Escolher medicamento',
                    onAction: () => _chooseFromCatalog(medications),
                  );
                }
                _unit ??= medication.doseUnit;

                final siteLabel = _site == null
                    ? null
                    : options.label(options.injectionSites, _site);
                return Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Identificação sempre visível: medicamento, apresentação, data e região.
                      _DoseSummary(
                        medication: medication.name,
                        presentation: medication.isInjection
                            ? (_presentation ?? 'não confirmada')
                            : null,
                        takenAt: _takenAt,
                        region: medication.isInjection
                            ? (siteLabel ?? 'não informada')
                            : null,
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(
                            Space.page,
                            Space.lg,
                            Space.page,
                            Space.xxl,
                          ),
                          children: [
                            Text(
                              options.disclaimer,
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: Space.lg),
                            Text(
                              'Aplicação',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: Space.sm),
                            _Dropdown(
                              key: ValueKey(_catalogNonce),
                              label: 'Medicamento',
                              value: _medicationId,
                              options: [
                                for (final m in available) Option(m.id, m.name),
                                if (!_isEdit)
                                  const Option(
                                    _fromCatalog,
                                    'Outro medicamento (ver todas as canetas)',
                                  ),
                              ],
                              onChanged: (v) => v == _fromCatalog
                                  ? _chooseFromCatalog(medications)
                                  : _select(
                                      available.firstWhere((m) => m.id == v),
                                    ),
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
                                    helper:
                                        'Conforme a sua prescrição (opcional)',
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
                            if (KnownMedication.byName(medication.name)
                                    ?.doses
                                    case final doses?
                                when doses.isNotEmpty && !_isEdit) ...[
                              const SizedBox(height: Space.sm),
                              Wrap(
                                spacing: Space.sm,
                                runSpacing: Space.sm,
                                children: [
                                  for (final d in doses)
                                    ChoiceChip(
                                      label: Text('${Fmt.decimal(d)} mg'),
                                      selected:
                                          _unit == 'mg' &&
                                          Validators.parseNumber(
                                                _amount.text,
                                              ) ==
                                              d,
                                      onSelected: (_) => setState(() {
                                        _amount.text = Fmt.decimal(d);
                                        _unit = 'mg';
                                      }),
                                    ),
                                ],
                              ),
                            ],
                            if (medication.isInjection) ...[
                              const SizedBox(height: Space.section),
                              Text(
                                'Região da aplicação',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: Space.sm),
                              InjectionGuidance(
                                onPresentationChanged: (p) =>
                                    setState(() => _presentation = p),
                                key: ValueKey(medication.id),
                                medicationName: medication.name,
                                sites: options.injectionSites,
                                site: _site,
                                onSiteChanged: (value) =>
                                    setState(() => _site = value),
                                takenAt: _takenAt,
                                editingDoseId: widget.dose?.id,
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String?>(
                                key: ValueKey('site:${medication.id}:$_site'),
                                initialValue:
                                    options.injectionSites.any(
                                      (s) => s.value == _site,
                                    )
                                    ? _site
                                    : null,
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
                            const SizedBox(height: Space.section),
                            ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              title: Text(
                                'Sintomas e observações (opcional)',
                                style: theme.textTheme.titleMedium,
                              ),
                              subtitle: _symptoms.isEmpty
                                  ? null
                                  : Text(
                                      '${_symptoms.length} sintoma(s) informado(s)',
                                    ),
                              initiallyExpanded:
                                  _symptoms.isNotEmpty ||
                                  _notes.text.isNotEmpty,
                              expandedCrossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    for (final s in options.symptoms)
                                      FilterChip(
                                        label: Text(s.label),
                                        selected: _symptoms.containsKey(
                                          s.value,
                                        ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          onSelectionChanged: (v) => setState(
                                            () => _symptoms[code] = v.first,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: Space.lg),
                                TextFormField(
                                  controller: _notes,
                                  decoration: const InputDecoration(
                                    labelText: 'Observações',
                                  ),
                                  maxLength: 500,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                            const SizedBox(height: Space.lg),
                            LoadingButton(
                              label: _isEdit ? 'Salvar' : 'Registrar aplicação',
                              loading: _saving,
                              onPressed: () => _save(medication),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

/// Resumo fixo do registro: o que, qual apresentação, quando e onde.
class _DoseSummary extends StatelessWidget {
  const _DoseSummary({
    required this.medication,
    required this.takenAt,
    this.presentation,
    this.region,
  });

  final String medication;
  final String? presentation;
  final DateTime takenAt;
  final String? region;

  @override
  Widget build(BuildContext context) {
    final lines = [
      ('Medicamento', medication),
      if (presentation != null) ('Apresentação', presentation!),
      ('Data', '${Fmt.shortDate(takenAt)} às ${Fmt.time(takenAt)}'),
      if (region != null) ('Região', region!),
    ];
    return Semantics(
      container: true,
      label: lines.map((l) => '${l.$1}: ${l.$2}').join('. '),
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: Space.page,
          vertical: Space.md,
        ),
        color: context.pic.surfaceMuted,
        child: Wrap(
          spacing: Space.lg,
          runSpacing: Space.xs,
          children: [
            for (final (label, value) in lines)
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '$label: ', style: context.text.bodySmall),
                    TextSpan(
                      text: value,
                      style: context.text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
