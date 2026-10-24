import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/env.dart';
import '../../../app/features.dart';
import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/design/theme_preference.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/labels.dart';
import '../../../shared/widgets/feedback.dart';
import '../../auth/application/session_controller.dart';
import '../../notifications/presentation/notification_bell.dart';
import 'profile_photo.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(
      context,
      title: 'Sair da conta?',
      message: 'Você precisará entrar novamente neste aparelho.',
      confirmLabel: 'Sair',
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
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
          const _Header('Conta'),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Perfil, objetivo e metas'),
            subtitle: Text(
              [
                Labels.of(Labels.goals, profile.goal),
                if (profile.dailyCalorieGoal != null)
                  Fmt.kcal(profile.dailyCalorieGoal!),
                'Água ${Fmt.ml(profile.waterGoalMl)}',
              ].join(' · '),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.editProfile),
          ),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: const Text('Meu plano'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.plan),
          ),
          if (AppFeatures.medical) ...[
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Profissionais'),
              subtitle: const Text(
                'Encontre nutricionistas e educadores físicos',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.professionals),
            ),
            if (!profile.medicationTrackingEnabled)
              ListTile(
                leading: const Icon(Icons.medication_outlined),
                title: const Text('Acompanhar medicamento'),
                subtitle: const Text(
                  'Registre aplicações prescritas e sintomas na Evolução',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.editProfile),
              ),
          ],
          ListTile(
            leading: const Icon(Icons.key_outlined),
            title: const Text('Formas de acesso'),
            subtitle: const Text('Senha, Google, Facebook e Apple'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.signInMethods),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacidade e dados'),
            subtitle: const Text(
              'Autorizações, exportação e exclusão da conta',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.privacy),
          ),
          const Divider(),
          const _Header('Preferências'),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notificações e lembretes'),
            subtitle: Text(
              profile.notificationsEnabled
                  ? 'Ativadas neste aparelho'
                  : 'Desativadas neste aparelho',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.notificationSettings),
          ),
          const ListTile(
            leading: Icon(Icons.palette_outlined),
            title: Text('Tema'),
            dense: true,
          ),
          const _ThemeSelector(),
          const Divider(),
          const _Header('Ajuda'),
          ListTile(
            leading: const Icon(Icons.auto_awesome_outlined),
            title: const Text('Assistente'),
            subtitle: const Text(
              'Consulte seus registros e tire dúvidas sobre o app',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.assistant),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Central de ajuda'),
            subtitle: const Text('Perguntas frequentes e orientações de uso'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.help),
          ),
          if (env.isDev)
            ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: const Text('Status do servidor (desenvolvimento)'),
              onTap: () => context.push(AppRoutes.systemStatus),
            ),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text(
              'Sair',
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
          segments: const [
            ButtonSegment(
              value: ThemeMode.system,
              label: Text('Sistema'),
              icon: Icon(Icons.brightness_auto_outlined),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              label: Text('Claro'),
              icon: Icon(Icons.light_mode_outlined),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text('Escuro'),
              icon: Icon(Icons.dark_mode_outlined),
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
