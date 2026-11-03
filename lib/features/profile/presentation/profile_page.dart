import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/env.dart';
import '../../../app/features.dart';
import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/design/theme_preference.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/labels.dart';
import '../../../shared/widgets/feedback.dart';
import '../../auth/application/session_controller.dart';
import '../../language/presentation/language_picker.dart';
import '../../notifications/presentation/notification_bell.dart';
import 'profile_photo.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(
      context,
      title: context.l10n.profileLogoutConfirmTitle,
      message: context.l10n.profileLogoutConfirmMessage,
      confirmLabel: context.l10n.profileLogout,
    );
    if (ok) await ref.read(sessionControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(currentAccountProvider);
    final env = ref.watch(appEnvProvider);
    if (account == null) return const SizedBox.shrink();
    final profile = account.profile;
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: const [NotificationBell()],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.page,
              Space.sm,
              Space.page,
              Space.lg,
            ),
            child: Row(
              children: [
                const ProfilePhoto(),
                const SizedBox(width: Space.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.name, style: theme.textTheme.titleMedium),
                      Text(account.email, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Três grupos: Conta, Preferências e Ajuda. Hábitos, relatórios e
          // bem-estar ficam na Evolução; receitas e artigos, na aba Conteúdo;
          // a central de notificações, no sino do topo.
          _Header(l10n.profileSectionAccount),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(l10n.profileGoals),
            subtitle: Text(
              [
                Labels.of(Labels.goals, profile.goal),
                if (profile.dailyCalorieGoal != null)
                  Fmt.kcal(profile.dailyCalorieGoal!),
                l10n.profileWater(Fmt.ml(profile.waterGoalMl)),
              ].join(' · '),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.editProfile),
          ),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: Text(l10n.profileMyPlan),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.plan),
          ),
          if (AppFeatures.medical) ...[
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: Text(l10n.profileProfessionals),
              subtitle: Text(l10n.profileProfessionalsSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.professionals),
            ),
            if (!profile.medicationTrackingEnabled)
              ListTile(
                leading: const Icon(Icons.medication_outlined),
                title: Text(l10n.profileTrackMedication),
                subtitle: Text(l10n.profileTrackMedicationSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.editProfile),
              ),
          ],
          ListTile(
            leading: const Icon(Icons.key_outlined),
            title: Text(l10n.profileSignInMethods),
            subtitle: Text(l10n.profileSignInMethodsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.signInMethods),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.profilePrivacy),
            subtitle: Text(l10n.profilePrivacySubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.privacy),
          ),
          const Divider(),
          _Header(l10n.profileSectionPreferences),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: Text(l10n.profileNotifications),
            subtitle: Text(
              profile.notificationsEnabled
                  ? l10n.profileNotificationsOn
                  : l10n.profileNotificationsOff,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.notificationSettings),
          ),
          if (AppFeatures.languages)
            Builder(
              builder: (context) {
                final language = displayedLanguage(context);
                return ListTile(
                  key: const ValueKey('profile-language'),
                  leading: const Icon(Icons.translate_rounded),
                  title: Text(l10n.languageTitle),
                  subtitle: Text('${language.flag}  ${language.nativeName}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showLanguagePicker(context),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l10n.profileTheme),
            dense: true,
          ),
          const _ThemeSelector(),
          const Divider(),
          _Header(l10n.profileSectionHelp),
          ListTile(
            leading: const Icon(Icons.auto_awesome_outlined),
            title: Text(l10n.profileAssistant),
            subtitle: Text(l10n.profileAssistantSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.assistant),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(l10n.profileHelpCenter),
            subtitle: Text(l10n.profileHelpCenterSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.help),
          ),
          if (env.isDev)
            ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: Text(l10n.profileServerStatusDev),
              onTap: () => context.push(AppRoutes.systemStatus),
            ),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text(
              l10n.profileLogout,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () => _logout(context, ref),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Space.page,
      Space.xxl,
      Space.page,
      Space.xs,
    ),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
  );
}

/// Tema do app: seguir o sistema, claro ou escuro (preferência do aparelho).
class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.xs,
        Space.lg,
        Space.md,
      ),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<ThemeMode>(
          segments: [
            ButtonSegment(
              value: ThemeMode.system,
              label: Text(l10n.themeSystem),
              icon: const Icon(Icons.brightness_auto_outlined),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              label: Text(l10n.themeLight),
              icon: const Icon(Icons.light_mode_outlined),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text(l10n.themeDark),
              icon: const Icon(Icons.dark_mode_outlined),
            ),
          ],
          selected: {mode},
          showSelectedIcon: false,
          onSelectionChanged: (v) =>
              ref.read(themeModeProvider.notifier).set(v.first),
        ),
      ),
    );
  }
}
