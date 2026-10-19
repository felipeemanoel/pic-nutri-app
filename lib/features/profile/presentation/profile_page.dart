import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/env.dart';
import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/design/theme_preference.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/labels.dart';
import '../../../shared/widgets/feedback.dart';
import '../../auth/application/session_controller.dart';

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
      appBar: AppBar(title: const Text('Perfil')),
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
                CircleAvatar(
                  radius: 28,
                  backgroundColor: context.pic.brandContainer,
                  foregroundColor: context.pic.onBrandContainer,
                  child: Text(
                    account.firstName.isEmpty
                        ? '?'
                        : account.firstName[0].toUpperCase(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: context.pic.onBrandContainer,
                    ),
                  ),
                ),
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
          const _Header('Meu perfil'),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Objetivo'),
            subtitle: Text(Labels.of(Labels.goals, profile.goal)),
          ),
          ListTile(
            leading: const Icon(Icons.local_fire_department_outlined),
            title: const Text('Metas diárias'),
            subtitle: Text(
              [
                if (profile.dailyCalorieGoal != null)
                  Fmt.kcal(profile.dailyCalorieGoal!),
                'Água ${Fmt.ml(profile.waterGoalMl)}',
              ].join(' · '),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Editar perfil e metas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.editProfile),
          ),
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
          ListTile(
            leading: const Icon(Icons.inbox_outlined),
            title: const Text('Central de notificações'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.notifications),
          ),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: const Text('Meu plano'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.plan),
          ),
          const Divider(),
          // Telas dentro das abas: `go` troca para a aba (o Perfil fica fora delas).
          const _Header('Saúde e histórico'),
          ListTile(
            leading: const Icon(Icons.healing_outlined),
            title: const Text('Sintomas e bem-estar'),
            subtitle: const Text('Registro, linha do tempo e resumo'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.symptoms),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_rounded),
            title: const Text('Relatórios e histórico'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.reports),
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: const Text('Hábitos e conquistas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.engagement),
          ),
          const Divider(),
          const _Header('Ajuda'),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Central de ajuda'),
            subtitle: const Text('Perguntas frequentes e orientações de uso'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.help),
          ),
          const Divider(),
          const _Header('Aparência'),
          const _ThemeSelector(),
          const Divider(),
          const _Header('Conta e segurança'),
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
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
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
