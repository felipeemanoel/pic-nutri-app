import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/routes.dart';
import '../../../core/notifications/local_notifications.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/legal_summary.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/application/session_controller.dart';
import '../../profile/data/profile_repository.dart';
import '../data/privacy_repository.dart';

/// Privacidade: consentimentos, exportação e exclusão dos dados (LGPD).
class PrivacyPage extends ConsumerStatefulWidget {
  const PrivacyPage({super.key});

  @override
  ConsumerState<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends ConsumerState<PrivacyPage> {
  bool _busy = false;
  Timer? _poll;

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleHealthConsent(bool grant) async {
    final ok = await confirmAction(
      context,
      title: grant ? 'Autorizar dados de saúde?' : 'Revogar autorização?',
      message: grant
          ? 'Você autoriza o PicNutri a tratar seus dados de saúde (alimentação, peso, medidas, '
                'medicamentos e sintomas) para o acompanhamento no app e nas análises por IA.'
          : 'Sem esta autorização, não será possível registrar refeições, peso, medidas, '
                'medicamentos nem usar as análises por IA. Os dados já registrados continuam '
                'disponíveis para consulta, exportação ou exclusão.',
      confirmLabel: grant ? 'Autorizar' : 'Revogar',
      destructive: !grant,
    );
    if (!ok) return;
    await _run(() async {
      await ref
          .read(profileRepositoryProvider)
          .setConsent('health_data', granted: grant);
      await ref.read(sessionControllerProvider.notifier).reloadAccount();
    });
  }

  Future<void> _requestExport() => _run(() async {
    await ref.read(privacyRepositoryProvider).requestExport();
    ref.invalidate(dataExportsProvider);
    _schedulePoll();
  });

  void _schedulePoll() {
    _poll?.cancel();
    _poll = Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;
      ref.invalidate(dataExportsProvider);
      final list = await ref
          .read(dataExportsProvider.future)
          .catchError((_) => <DataExport>[]);
      if (mounted && list.any((e) => e.isPending)) _schedulePoll();
    });
  }

  Future<void> _download(DataExport export) => _run(() async {
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/picnutri-dados-${export.createdAt.toIso8601String().substring(0, 10)}.json';
    await ref.read(privacyRepositoryProvider).download(export.id, path);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'application/json')],
        subject: 'Meus dados do PicNutri',
      ),
    );
    // O arquivo temporário não fica no aparelho depois de compartilhado.
    final file = File(path);
    if (file.existsSync()) await file.delete();
  });

  Future<void> _deleteAccount() async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (password == null || !mounted) return;
    await _run(() async {
      await ref
          .read(privacyRepositoryProvider)
          .deleteAccount(password: password);
      await ref.read(localNotificationsProvider).cancelAll();
      await ref.read(sessionControllerProvider.notifier).accountDeleted();
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(currentAccountProvider);
    final exports = ref.watch(dataExportsProvider);
    final theme = Theme.of(context);
    if (account == null) return const Scaffold(body: LoadingView());

    return Scaffold(
      appBar: AppBar(title: const Text('Privacidade e dados')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Como usamos seus dados'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLegalSummary(context),
          ),
          const Divider(),
          const _Header('Autorizações'),
          const ListTile(
            leading: Icon(Icons.gavel_outlined),
            title: Text('Termos de Uso e Política de Privacidade'),
            subtitle: Text(
              'Aceitos no cadastro. Para deixar de aceitá-los, exclua a conta.',
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.health_and_safety_outlined),
            title: const Text('Dados de saúde'),
            subtitle: const Text(
              'Necessária para registros de alimentação, peso, medicamentos e IA.',
            ),
            value: account.consents.healthData,
            onChanged: _busy ? null : _toggleHealthConsent,
          ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('Compartilhamentos com profissionais'),
            subtitle: const Text('Quem pode ver seus dados, até quando, e revogar'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.shareGrants),
          ),
          const Divider(),
          const _Header('Exportar meus dados'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Gera um arquivo com todos os seus dados (conta, perfil, registros, conversas). '
              'O arquivo fica disponível por 7 dias.',
              style: theme.textTheme.bodySmall,
            ),
          ),
          AsyncValueView<List<DataExport>>(
            value: exports,
            onRetry: () => ref.invalidate(dataExportsProvider),
            data: (list) {
              final latest = list.isEmpty ? null : list.first;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (latest != null) ...[
                      Text(switch (latest.status) {
                        'pending' => 'Gerando arquivo…',
                        'ready' =>
                          'Pronto · ${Fmt.shortDate(latest.createdAt)}'
                              '${latest.expiresAt == null ? '' : ' · disponível até ${Fmt.shortDate(latest.expiresAt!)}'}',
                        'failed' =>
                          'A última exportação falhou. Solicite novamente.',
                        _ => 'A última exportação expirou.',
                      }),
                      const SizedBox(height: 8),
                    ],
                    if (latest != null && latest.isReady)
                      FilledButton.icon(
                        onPressed: _busy ? null : () => _download(latest),
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Baixar e compartilhar'),
                      ),
                    if (latest == null || !latest.isPending)
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _requestExport,
                        icon: const Icon(Icons.file_present_outlined),
                        label: Text(
                          latest == null
                              ? 'Solicitar exportação'
                              : 'Gerar novo arquivo',
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          const _Header('Excluir conta'),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: theme.colorScheme.error,
            ),
            title: Text(
              'Excluir conta e todos os dados',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: const Text(
              'Definitivo: apaga registros, fotos, conversas e a conta.',
            ),
            onTap: _busy ? null : _deleteAccount,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _valid =>
      _password.text.isNotEmpty && _confirm.text.trim() == 'EXCLUIR';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Excluir conta?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Todos os seus dados serão apagados definitivamente. Se quiser guardar uma cópia, '
              'exporte seus dados antes.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha atual'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirm,
              decoration: const InputDecoration(
                labelText: 'Digite EXCLUIR para confirmar',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: _valid
              ? () => Navigator.of(context).pop(_password.text)
              : null,
          child: const Text('Excluir'),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}
