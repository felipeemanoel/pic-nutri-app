import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/features.dart';
import '../../../core/utils/request_id.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/application/session_controller.dart';
import '../../medication/data/medication_repository.dart';
import '../data/reminder_models.dart';
import '../data/reminder_repository.dart';

/// Abre o formulário de lembrete; devolve `true` se algo mudou.
Future<bool> showReminderForm(
  BuildContext context, {
  Reminder? reminder,
  required String category,
}) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ReminderForm(reminder: reminder, category: category),
    ) ??
    false;

/// Cadastro de lembrete: tipo (da categoria), horário, frequência no dia e
/// dias da semana.
class ReminderForm extends ConsumerStatefulWidget {
  const ReminderForm({super.key, this.reminder, required this.category});

  final Reminder? reminder;
  final String category;

  @override
  ConsumerState<ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends ConsumerState<ReminderForm> {
  final _requestId = newRequestId();
  late String _type =
      widget.reminder?.type ??
      ReminderLabels.typesByCategory[widget.category]!.first;
  late final _title = TextEditingController(text: widget.reminder?.title);
  late TimeOfDay _time = widget.reminder == null
      ? const TimeOfDay(hour: 9, minute: 0)
      : TimeOfDay(hour: widget.reminder!.hour, minute: widget.reminder!.minute);
  late int? _interval = widget.reminder?.repeats ?? false
      ? widget.reminder!.intervalMinutes
      : null;
  late TimeOfDay _end =
      _parse(widget.reminder?.endTime) ?? const TimeOfDay(hour: 20, minute: 0);
  late final Set<int> _days = {...?widget.reminder?.days};
  late String? _medicationId = widget.reminder?.medicationId;
  bool _saving = false;

  bool get _isEdit => widget.reminder != null;
  bool get _conditional => ReminderLabels.conditionalTypes.contains(_type);

  @override
  void initState() {
    super.initState();
    if (_days.isEmpty) _days.addAll([1, 2, 3, 4, 5, 6, 7]);
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  static TimeOfDay? _parse(String? hhmm) => hhmm == null
      ? null
      : TimeOfDay(
          hour: int.parse(hhmm.substring(0, 2)),
          minute: int.parse(hhmm.substring(3, 5)),
        );

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (_days.isEmpty) {
      showMessage(context, 'Escolha pelo menos um dia.');
      return;
    }
    if (_type == 'custom' && _title.text.trim().length < 2) {
      showMessage(context, 'Dê um título ao lembrete personalizado.');
      return;
    }
    final repeat = !_conditional && _interval != null;
    if (repeat &&
        _end.hour * 60 + _end.minute <= _time.hour * 60 + _time.minute) {
      showMessage(context, 'O horário final precisa ser depois do inicial.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(reminderRepositoryProvider)
          .save(
            id: widget.reminder?.id,
            type: _type,
            title: _title.text,
            time: _fmt(_time),
            days: _days.toList()..sort(),
            medicationId: _type == 'medication' ? _medicationId : null,
            requestId: _isEdit ? null : _requestId,
            intervalMinutes: repeat ? _interval : null,
            endTime: repeat ? _fmt(_end) : null,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmAction(
      context,
      title: 'Excluir lembrete?',
      message: 'As notificações deste lembrete deixarão de aparecer.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok) return;
    setState(() => _saving = true);
    try {
      await ref.read(reminderRepositoryProvider).delete(widget.reminder!.id);
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<TimeOfDay?> _pick(TimeOfDay initial) =>
      showTimePicker(context: context, initialTime: initial);

  @override
  Widget build(BuildContext context) {
    final tracking =
        AppFeatures.medical &&
        (ref.watch(currentAccountProvider)?.profile.medicationTrackingEnabled ??
            false);
    final types = {
      for (final t
          in ReminderLabels.typesByCategory[widget.category] ?? [_type])
        if (t != 'medication' || tracking || _type == 'medication')
          t: ReminderLabels.types[t] ?? t,
    };
    final medications = _type == 'medication'
        ? ref.watch(medicationsProvider).value
        : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? 'Editar lembrete' : 'Novo lembrete',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (types.length > 1)
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: [
                  for (final e in types.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: _isEdit
                    ? null
                    : (v) => setState(() => _type = v ?? _type),
              ),
            if (ReminderLabels.hints[_type] case final hint?) ...[
              const SizedBox(height: 8),
              Text(hint, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              maxLength: 80,
              decoration: InputDecoration(
                labelText: _type == 'custom' ? 'Título' : 'Título (opcional)',
                helperText:
                    'Evite dados de saúde: o texto pode aparecer na tela bloqueada.',
              ),
            ),
            if (_type == 'medication' &&
                medications != null &&
                medications.isNotEmpty)
              DropdownButtonFormField<String?>(
                initialValue: medications.any((m) => m.id == _medicationId)
                    ? _medicationId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Medicamento (opcional)',
                ),
                items: [
                  const DropdownMenuItem<String?>(child: Text('Não vincular')),
                  for (final m in medications)
                    DropdownMenuItem<String?>(value: m.id, child: Text(m.name)),
                ],
                onChanged: (v) => setState(() => _medicationId = v),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: Text(
                _interval != null && !_conditional ? 'Começa às' : 'Horário',
              ),
              subtitle: Text(_fmt(_time)),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () async {
                final picked = await _pick(_time);
                if (picked != null) setState(() => _time = picked);
              },
            ),
            if (!_conditional) ...[
              DropdownButtonFormField<int?>(
                initialValue: _interval,
                decoration: const InputDecoration(
                  labelText: 'Frequência no dia',
                ),
                items: [
                  const DropdownMenuItem<int?>(child: Text('Uma vez')),
                  for (final m in ReminderLabels.intervals)
                    DropdownMenuItem<int?>(
                      value: m,
                      child: Text('A cada ${ReminderLabels.interval(m)}'),
                    ),
                ],
                onChanged: (v) => setState(() => _interval = v),
              ),
              if (_interval != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.update),
                  title: const Text('Até'),
                  subtitle: Text(_fmt(_end)),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () async {
                    final picked = await _pick(_end);
                    if (picked != null) setState(() => _end = picked);
                  },
                ),
            ],
            const SizedBox(height: 8),
            Text(
              'Dias da semana',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final e in ReminderLabels.weekdays.entries)
                  FilterChip(
                    label: Text(e.value),
                    selected: _days.contains(e.key),
                    onSelected: (on) => setState(
                      () => on ? _days.add(e.key) : _days.remove(e.key),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            LoadingButton(label: 'Salvar', loading: _saving, onPressed: _save),
            if (_isEdit)
              TextButton(
                onPressed: _saving ? null : _delete,
                child: const Text('Excluir lembrete'),
              ),
          ],
        ),
      ),
    );
  }
}
