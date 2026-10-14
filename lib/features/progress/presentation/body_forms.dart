import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/request_id.dart';
import '../../../shared/state/refresh.dart';
import '../../../shared/validators.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/body_models.dart';
import '../data/body_repository.dart';

/// Formulário de peso (novo ou edição).
Future<void> showWeightForm(BuildContext context, {WeightEntry? entry}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _WeightForm(entry: entry),
    );

class _WeightForm extends ConsumerStatefulWidget {
  const _WeightForm({this.entry});

  final WeightEntry? entry;

  @override
  ConsumerState<_WeightForm> createState() => _WeightFormState();
}

class _WeightFormState extends ConsumerState<_WeightForm> {
  final _formKey = GlobalKey<FormState>();
  final _requestId = newRequestId();
  late final _weight = TextEditingController(
    text: widget.entry == null ? '' : Fmt.decimal(widget.entry!.weightKg),
  );
  late final _notes = TextEditingController(text: widget.entry?.notes);
  late DateTime _date = widget.entry?.measuredAt ?? DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _weight.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(bodyRepositoryProvider)
          .saveWeight(
            id: widget.entry?.id,
            weightKg: Validators.parseNumber(_weight.text)!,
            measuredAt: _date,
            notes: _notes.text,
            requestId: widget.entry == null ? _requestId : null,
          );
      Refresh.body(ref);
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
      title: 'Excluir registro de peso?',
      message:
          'O registro de ${Fmt.kg(widget.entry!.weightKg)} será removido do histórico.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok) return;
    setState(() => _saving = true);
    try {
      await ref.read(bodyRepositoryProvider).deleteWeight(widget.entry!.id);
      Refresh.body(ref);
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.entry == null ? 'Registrar peso' : 'Editar peso',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          NumberField(
            controller: _weight,
            label: 'Peso',
            unit: 'kg',
            min: 30,
            max: 300,
          ),
          const SizedBox(height: 12),
          DateField(
            label: 'Data',
            value: _date,
            firstDate: DateTime(2015),
            lastDate: DateTime.now(),
            onChanged: (d) => setState(
              () => _date = DateTime(
                d.year,
                d.month,
                d.day,
                _date.hour,
                _date.minute,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notes,
            decoration: const InputDecoration(
              labelText: 'Observação (opcional)',
            ),
            maxLength: 500,
          ),
          const SizedBox(height: 8),
          LoadingButton(label: 'Salvar', loading: _saving, onPressed: _save),
          if (widget.entry != null)
            TextButton(
              onPressed: _saving ? null : _delete,
              child: const Text('Excluir registro'),
            ),
        ],
      ),
    ),
  );
}

/// Formulário de medida corporal (novo ou edição).
Future<void> showMeasurementForm(BuildContext context, {Measurement? entry}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MeasurementForm(entry: entry),
    );

class _MeasurementForm extends ConsumerStatefulWidget {
  const _MeasurementForm({this.entry});

  final Measurement? entry;

  @override
  ConsumerState<_MeasurementForm> createState() => _MeasurementFormState();
}

class _MeasurementFormState extends ConsumerState<_MeasurementForm> {
  final _formKey = GlobalKey<FormState>();
  final _requestId = newRequestId();
  late String _type = widget.entry?.type ?? 'waist';
  late final _label = TextEditingController(text: widget.entry?.label);
  late final _value = TextEditingController(
    text: widget.entry == null ? '' : Fmt.decimal(widget.entry!.valueCm),
  );
  late DateTime _date = widget.entry?.measuredAt ?? DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _label.dispose();
    _value.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(bodyRepositoryProvider)
          .saveMeasurement(
            id: widget.entry?.id,
            type: _type,
            label: _type == 'custom' ? _label.text.trim() : null,
            valueCm: Validators.parseNumber(_value.text)!,
            measuredAt: _date,
            requestId: widget.entry == null ? _requestId : null,
          );
      Refresh.body(ref);
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
      title: 'Excluir medida?',
      message: 'Este registro será removido do histórico.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(bodyRepositoryProvider)
          .deleteMeasurement(widget.entry!.id);
      Refresh.body(ref);
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.entry == null ? 'Registrar medida' : 'Editar medida',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Medida'),
            items: [
              for (final e in MeasurementTypes.labels.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: widget.entry != null
                ? null
                : (v) => setState(() => _type = v ?? _type),
          ),
          if (_type == 'custom') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _label,
              decoration: const InputDecoration(
                labelText: 'Nome da medida',
                hintText: 'Ex.: Panturrilha',
              ),
              maxLength: 40,
              validator: (v) => Validators.required(v, 'Nome'),
            ),
          ],
          const SizedBox(height: 12),
          NumberField(
            controller: _value,
            label: 'Valor',
            unit: 'cm',
            min: 10,
            max: 300,
          ),
          const SizedBox(height: 12),
          DateField(
            label: 'Data',
            value: _date,
            firstDate: DateTime(2015),
            lastDate: DateTime.now(),
            onChanged: (d) => setState(
              () => _date = DateTime(
                d.year,
                d.month,
                d.day,
                _date.hour,
                _date.minute,
              ),
            ),
          ),
          const SizedBox(height: 16),
          LoadingButton(label: 'Salvar', loading: _saving, onPressed: _save),
          if (widget.entry != null)
            TextButton(
              onPressed: _saving ? null : _delete,
              child: const Text('Excluir medida'),
            ),
        ],
      ),
    ),
  );
}
