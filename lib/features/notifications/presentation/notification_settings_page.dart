import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/notifications/local_notifications.dart';
import '../../../core/notifications/push_messaging.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/application/session_controller.dart';
import '../../home/data/dashboard_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../reminders/application/reminder_scheduler.dart';
import '../../reminders/data/reminder_models.dart';
import '../../reminders/data/reminder_repository.dart';
import '../../reminders/presentation/reminder_form.dart';
import '../application/device_permission.dart';
import '../data/notification_models.dart';
import '../data/notification_repository.dart';

/// Configurações de notificações:
/// - notificações neste aparelho (permissão do sistema, com explicação);
/// - lembretes locais por categoria, com horários, frequência e dias;
/// - mensagens enviadas pelo PicNutri (incentivo, comunicados);
/// - período de silêncio.
class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  bool _busy = false;

  static const descriptions = {
    'water': 'Lembretes para beber água.',
    'meals': 'Horários das suas refeições.',
    'meal_log': 'Lembretes para registrar o que você comeu.',
    'progress': 'Peso, evolução e outros acompanhamentos.',
    'goals': 'Avisam só quando as metas do dia estão pendentes.',
    'engagement': 'Incentivos e lembretes para voltar ao app.',
    'announcements': 'Novidades e comunicados do PicNutri.',
  };

  Future<void> _resync() async {
    ref
      ..invalidate(remindersProvider)
      ..invalidate(dashboardProvider);
    await ref.read(reminderSchedulerProvider).sync();
  }

  Future<void> _setDeviceNotifications(bool enable) async {
    final local = ref.read(localNotificationsProvider);
    if (enable) {
      final proceed = await confirmAction(
        context,
        title: 'Ativar notificações?',
        message:
            'O PicNutri vai avisar nos horários que você escolher (como beber água ou registrar '
            'refeições) e enviar mensagens como incentivos e novidades. Os avisos não mostram '
            'dados de saúde na tela bloqueada. Você pode mudar tudo aqui a qualquer momento. '
            'Em seguida, o sistema vai pedir sua permissão.',
        confirmLabel: 'Continuar',
      );
      if (!proceed || !mounted) return;
      final granted = await local.requestPermission();
      ref.invalidate(notificationPermissionProvider);
      if (!granted) {
        if (mounted) await _offerSystemSettings();
        return;
      }
    }

    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile({
        'notifications_enabled': enable,
      });
      await ref.read(sessionControllerProvider.notifier).reloadAccount();
      final push = ref.read(pushMessagingProvider);
      unawaited(enable ? push.enable() : push.disable());
      await ref.read(reminderSchedulerProvider).sync();
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _offerSystemSettings() async {
    final open = await confirmAction(
      context,
      title: 'Notificações bloqueadas',
      message:
          'As notificações do PicNutri estão desativadas nas configurações do aparelho. '
          'Para receber lembretes, ative-as por lá. As mensagens continuam disponíveis na central.',
      confirmLabel: 'Abrir configurações',
    );
    if (open) await ref.read(localNotificationsProvider).openSystemSettings();
  }

  Future<void> _updatePreferences(
    Future<NotificationPreferences> Function(NotificationRepository repo)
    change,
  ) async {
    try {
      await change(ref.read(notificationRepositoryProvider));
      ref.invalidate(notificationPreferencesProvider);
      await ref.read(reminderSchedulerProvider).sync();
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    }
  }

  Future<void> _toggleReminder(Reminder reminder, bool enabled) async {
    try {
      await ref
          .read(reminderRepositoryProvider)
          .setEnabled(reminder.id, enabled);
      await _resync();
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    }
  }

  Future<void> _openForm(String category, [Reminder? reminder]) async {
    if (await showReminderForm(
      context,
      reminder: reminder,
      category: category,
    )) {
      await _resync();
    }
  }

  Future<void> _pickQuiet(
    NotificationPreferences prefs, {
    required bool start,
  }) async {
    final current =
        (start ? prefs.quietStart : prefs.quietEnd) ??
        (start ? '22:00' : '07:00');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(current.substring(0, 2)),
        minute: int.parse(current.substring(3, 5)),
      ),
    );
    if (picked == null) return;
    final value =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    await _updatePreferences(
      (repo) => repo.updatePreferences(
        quietHoursEnabled: true,
        quietStart: start ? value : prefs.quietStart ?? '22:00',
        quietEnd: start ? prefs.quietEnd ?? '07:00' : value,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled =
        ref.watch(currentAccountProvider)?.profile.notificationsEnabled ??
        false;
    final permission = ref.watch(notificationPermissionProvider).value;
    final preferences = ref.watch(notificationPreferencesProvider);
    final reminders = ref.watch(remindersProvider).value ?? const <Reminder>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          IconButton(
            tooltip: 'Central de notificações',
            icon: const Icon(Icons.inbox_outlined),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(notificationPermissionProvider)
            ..invalidate(remindersProvider);
          final _ = await ref.refresh(notificationPreferencesProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, Space.sm, 0, Space.xxxl),
          children: [
            _DeviceStatus(
              enabled: enabled,
              permission: permission,
              busy: _busy,
              onChanged: _setDeviceNotifications,
              onOpenSettings: () =>
                  ref.read(localNotificationsProvider).openSystemSettings(),
            ),
            AsyncValueView<NotificationPreferences>(
              value: preferences,
              onRetry: () => ref.invalidate(notificationPreferencesProvider),
              data: (prefs) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionTitle(
                    'Lembretes no aparelho',
                    'Você escolhe os horários. Funcionam mesmo sem internet.',
                  ),
                  for (final category in prefs.categories.where(
                    (c) => c.localReminders,
                  ))
                    _CategoryReminders(
                      category: category,
                      description: descriptions[category.key],
                      reminders: [
                        for (final r in reminders)
                          if (r.category == category.key) r,
                      ],
                      deviceEnabled: enabled,
                      onToggleCategory: (v) => _updatePreferences(
                        (repo) => repo.updatePreferences(
                          categories: {category.key: v},
                        ),
                      ),
                      onAdd: () => _openForm(category.key),
                      onEdit: (r) => _openForm(category.key, r),
                      onToggleReminder: _toggleReminder,
                    ),
                  const _SectionTitle(
                    'Mensagens do PicNutri',
                    'Enviadas pelo servidor. Também ficam guardadas na central de notificações.',
                  ),
                  for (final category in prefs.categories.where(
                    (c) => !c.localReminders,
                  ))
                    SwitchListTile(
                      title: Text(category.label),
                      subtitle: Text(descriptions[category.key] ?? ''),
                      value: category.enabled,
                      onChanged: (v) => _updatePreferences(
                        (repo) => repo.updatePreferences(
                          categories: {category.key: v},
                        ),
                      ),
                    ),
                  const _SectionTitle(
                    'Período de silêncio',
                    'Nenhum aviso toca neste intervalo; mensagens do servidor chegam depois dele.',
                  ),
                  SwitchListTile(
                    title: const Text('Ativar período de silêncio'),
                    value: prefs.quietHoursEnabled,
                    onChanged: (v) => _updatePreferences(
                      (repo) => repo.updatePreferences(
                        quietHoursEnabled: v,
                        quietStart: v ? prefs.quietStart ?? '22:00' : null,
                        quietEnd: v ? prefs.quietEnd ?? '07:00' : null,
                      ),
                    ),
                  ),
                  if (prefs.quietHoursEnabled) ...[
                    ListTile(
                      leading: const Icon(Icons.bedtime_outlined),
                      title: const Text('Começa às'),
                      trailing: Text(
                        prefs.quietStart ?? '22:00',
                        style: context.text.titleMedium,
                      ),
                      onTap: () => _pickQuiet(prefs, start: true),
                    ),
                    ListTile(
                      leading: const Icon(Icons.wb_sunny_outlined),
                      title: const Text('Termina às'),
                      trailing: Text(
                        prefs.quietEnd ?? '07:00',
                        style: context.text.titleMedium,
                      ),
                      onTap: () => _pickQuiet(prefs, start: false),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.subtitle);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Space.page,
      Space.xl,
      Space.page,
      Space.xs,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: context.text.titleMedium),
        ),
        const SizedBox(height: Space.xxs),
        Text(
          subtitle,
          style: context.text.bodySmall?.copyWith(
            color: context.pic.textSecondary,
          ),
        ),
      ],
    ),
  );
}

/// Chave geral do aparelho e situação da permissão do sistema.
class _DeviceStatus extends StatelessWidget {
  const _DeviceStatus({
    required this.enabled,
    required this.permission,
    required this.busy,
    required this.onChanged,
    required this.onOpenSettings,
  });

  final bool enabled;
  final NotificationPermission? permission;
  final bool busy;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final blocked = permission == NotificationPermission.denied;
    final status = switch ((enabled, permission)) {
      (false, _) => 'Desativadas. As mensagens continuam na central.',
      (true, NotificationPermission.denied) =>
        'Bloqueadas nas configurações do aparelho.',
      (true, NotificationPermission.notDetermined) =>
        'Aguardando sua permissão no sistema.',
      _ => 'Ativadas neste aparelho.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          secondary: Icon(
            enabled && !blocked
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
          ),
          title: const Text('Notificações neste aparelho'),
          subtitle: Text(status),
          value: enabled,
          onChanged: busy ? null : onChanged,
        ),
        if (blocked)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: StatusBanner(
              tone: BannerTone.warning,
              message: enabled
                  ? 'Os lembretes não vão aparecer enquanto as notificações estiverem bloqueadas no sistema.'
                  : 'As notificações do PicNutri estão bloqueadas nas configurações do aparelho.',
              actionLabel: 'Abrir configurações',
              onAction: onOpenSettings,
            ),
          ),
      ],
    );
  }
}

/// Uma categoria de lembretes locais: chave da categoria e seus horários.
class _CategoryReminders extends StatelessWidget {
  const _CategoryReminders({
    required this.category,
    required this.description,
    required this.reminders,
    required this.deviceEnabled,
    required this.onToggleCategory,
    required this.onAdd,
    required this.onEdit,
    required this.onToggleReminder,
  });

  final NotificationCategoryPref category;
  final String? description;
  final List<Reminder> reminders;
  final bool deviceEnabled;
  final ValueChanged<bool> onToggleCategory;
  final VoidCallback onAdd;
  final ValueChanged<Reminder> onEdit;
  final void Function(Reminder, bool) onToggleReminder;

  @override
  Widget build(BuildContext context) {
    final active = category.enabled && deviceEnabled;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.page,
        vertical: Space.xs,
      ),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(category.label, style: context.text.titleSmall),
              subtitle: Text(
                reminders.isEmpty
                    ? description ?? 'Nenhum horário definido.'
                    : '${reminders.length} lembrete${reminders.length == 1 ? '' : 's'} · ${description ?? ''}',
              ),
              value: category.enabled,
              onChanged: onToggleCategory,
            ),
            if (category.enabled) ...[
              for (final r in reminders)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  enabled: active,
                  title: Text(r.displayTitle),
                  subtitle: Text(
                    '${r.timesLabel} · ${ReminderLabels.days(r.days)}',
                  ),
                  onTap: () => onEdit(r),
                  trailing: Switch(
                    value: r.enabled,
                    onChanged: (v) => onToggleReminder(r, v),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_alarm_outlined),
                  label: const Text('Adicionar horário'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
