import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/local_notifications.dart';
import '../../../core/utils/request_id.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/application/session_controller.dart';
import '../../home/data/dashboard_repository.dart';
import '../../medication/data/medication_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../application/reminder_scheduler.dart';
import '../data/reminder_models.dart';
import '../data/reminder_repository.dart';

/// Lembretes: ativação das notificações (com explicação antes da permissão)
/// e cadastro de lembretes de água, refeição, pesagem, medicamento ou livres.
class RemindersPage extends ConsumerStatefulWidget {
  const RemindersPage({super.key});

  @override
  ConsumerState<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends ConsumerState<RemindersPage> {
  bool _busy = false;

  Future<void> _afterChange() async {
    ref
      ..invalidate(remindersProvider)
      ..invalidate(dashboardProvider);
    await ref.read(reminderSchedulerProvider).sync();
  }

  Future<void> _toggleNotifications(bool enable) async {
    if (enable) {
      final proceed = await confirmAction(
        context,
        title: 'Ativar lembretes?',
        message:
            'O PicNutri vai mostrar notificações nos horários que você escolher, '
            'como beber água ou registrar refeições. Você pode desativar a qualquer momento. '
            'Em seguida, o sistema vai pedir sua permissão.',
        confirmLabel: 'Continuar',
      );
      if (!proceed || !mounted) return;
      final granted = await ref
          .read(localNotificationsProvider)
          .requestPermission();
      if (!granted) {
        if (mounted) {
          showMessage(
            context,
            'Permissão de notificações negada. Ative nas configurações do aparelho para receber lembretes.',
          );
        }
        return;
      }
    }

    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile({
        'notifications_enabled': enable,
      });
      await ref.read(sessionControllerProvider.notifier).reloadAccount();
      await ref.read(reminderSchedulerProvider).sync();
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleReminder(Reminder reminder, bool enabled) async {
    try {
      await ref
          .read(reminderRepositoryProvider)
          .setEnabled(reminder.id, enabled);
      await _afterChange();
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    }
  }

  Future<void> _openForm([Reminder? reminder]) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ReminderForm(reminder: reminder),
    );
    if (changed == true) await _afterChange();
  }

  @override
  Widget build(BuildContext context) {
    final enabled =
        ref.watch(currentAccountProvider)?.profile.notificationsEnabled ??
        false;
    final reminders = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lembretes')),
      floatingActionButton: enabled
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_alarm),
              label: const Text('Lembrete'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Receber lembretes neste aparelho'),
            subtitle: const Text(
              'Notificações locais nos horários escolhidos.',
            ),
            value: enabled,
            onChanged: _busy ? null : _toggleNotifications,
          ),
          const Divider(),
          if (!enabled)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Ative os lembretes para criar e receber notificações.',
              ),
            )
          else
            AsyncValueView<List<Reminder>>(
              value: reminders,
              onRetry: () => ref.invalidate(remindersProvider),
              data: (list) => list.isEmpty
                  ? EmptyState(
                      icon: Icons.alarm_add_outlined,
                      title: 'Nenhum lembrete',
                      message:
                          'Crie lembretes para beber água, registrar refeições ou se pesar.',
                      actionLabel: 'Criar lembrete',
                      onAction: () => _openForm(),
                    )
                  : Column(
                      children: [
                        for (final r in list)
                          SwitchListTile(
                            title: Text('${r.time} · ${r.displayTitle}'),
                            subtitle: Text(
                              '${ReminderLabels.types[r.type] ?? r.type} · ${ReminderLabels.days(r.days)}',
                            ),
                            value: r.enabled,
                            onChanged: (v) => _toggleReminder(r, v),
                            secondary: IconButton(
                              tooltip: 'Editar',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _openForm(r),
                            ),
                          ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}

class _ReminderForm extends ConsumerStatefulWidget {
  const _ReminderForm({this.reminder});

  final Reminder? reminder;

  @override
  ConsumerState<_ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends ConsumerState<_ReminderForm> {
  final _requestId = newRequestId();
  late String _type = widget.reminder?.type ?? 'water';
  late final _title = TextEditingController(text: widget.reminder?.title);
  late TimeOfDay _time = widget.reminder == null
      ? const TimeOfDay(hour: 9, minute: 0)
      : TimeOfDay(hour: widget.reminder!.hour, minute: widget.reminder!.minute);
  late final Set<int> _days = {...?widget.reminder?.days};
  late String? _medicationId = widget.reminder?.medicationId;
  bool _saving = false;

  bool get _isEdit => widget.reminder != null;

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

  String get _timeText =>
      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (_days.isEmpty) {
      showMessage(context, 'Escolha pelo menos um dia.');
      return;
    }
    if (_type == 'custom' && _title.text.trim().length < 2) {
      showMessage(context, 'Dê um título ao lembrete personalizado.');
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
            time: _timeText,
            days: _days.toList()..sort(),
            medicationId: _type == 'medication' ? _medicationId : null,
            requestId: _isEdit ? null : _requestId,
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

  @override
  Widget build(BuildContext context) {
    final tracking =
        ref.watch(currentAccountProvider)?.profile.medicationTrackingEnabled ??
        false;
    final types = {
      for (final e in ReminderLabels.types.entries)
        if (e.key != 'medication' || tracking || _type == 'medication')
          e.key: e.value,
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
              title: const Text('Horário'),
              subtitle: Text(_timeText),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _time,
                );
                if (picked != null) setState(() => _time = picked);
              },
            ),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final e in ReminderLabels.weekdays.entries)
                  FilterChip(
                    label: Text(e.value),
                    selected: _days.contains(e.key),
                    onSelected: (on) => setState(() {
                      if (on) {
                        _days.add(e.key);
                      } else {
                        _days.remove(e.key);
                      }
                    }),
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
