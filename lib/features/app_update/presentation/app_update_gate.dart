import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design/design_system.dart';
import '../application/app_update_controller.dart';
import '../data/app_update_repository.dart';

/// Fica acima de todas as telas: verifica a versão ao abrir o app e ao voltar
/// para ele. Com versão nova, mostra o convite para atualizar na loja; abaixo
/// da versão mínima, cobre o app até a pessoa atualizar.
class AppUpdateGate extends ConsumerStatefulWidget {
  const AppUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends ConsumerState<AppUpdateGate> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(appUpdateProvider.notifier).check(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(appUpdateProvider.notifier).check(force: true);
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final update = ref.watch(appUpdateProvider);
    final info = update.info;
    return Stack(
      children: [
        widget.child,
        if (info != null && update.required)
          Positioned.fill(child: _RequiredUpdate(info: info))
        else if (info != null && update.optional)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _OptionalUpdate(
              info: info,
              onLater: () => ref.read(appUpdateProvider.notifier).dismiss(),
            ),
          ),
      ],
    );
  }
}

/// Abre a página do app na loja (Play Store ou App Store).
Future<void> openStore(BuildContext context, AppUpdateInfo info) async {
  final fallback = defaultTargetPlatform == TargetPlatform.iOS
      ? 'https://apps.apple.com/br/search?term=PicNutri'
      : 'https://play.google.com/store/apps/details?id=br.com.picnutri';
  final url = Uri.parse(info.storeUrl ?? fallback);
  final messenger = ScaffoldMessenger.maybeOf(context);
  var opened = false;
  try {
    opened = await launchUrl(url, mode: LaunchMode.externalApplication);
  } on Object {
    opened = false;
  }
  if (!opened) {
    messenger?.showSnackBar(
      const SnackBar(
        content: Text(
          'Não foi possível abrir a loja. Procure por PicNutri na loja do seu celular.',
        ),
      ),
    );
  }
}

class _OptionalUpdate extends StatelessWidget {
  const _OptionalUpdate({required this.info, required this.onLater});

  final AppUpdateInfo info;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final version = info.latestVersion;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, 88),
        child: Semantics(
          container: true,
          liveRegion: true,
          child: Material(
            color: context.colors.surface,
            elevation: 8,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: Radii.card,
              side: BorderSide(color: context.pic.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: context.pic.brandContainer,
                        child: Icon(
                          Icons.system_update_rounded,
                          color: context.pic.onBrandContainer,
                        ),
                      ),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: Text(
                          version == null
                              ? 'Nova versão disponível'
                              : 'Versão $version disponível',
                          style: context.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.sm),
                  Text(
                    info.message,
                    style: context.text.bodyMedium?.copyWith(
                      color: context.pic.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Space.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: onLater,
                          child: const Text('Agora não'),
                        ),
                      ),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () => openStore(context, info),
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Atualizar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequiredUpdate extends StatelessWidget {
  const _RequiredUpdate({required this.info});

  final AppUpdateInfo info;

  @override
  Widget build(BuildContext context) {
    final version = info.latestVersion;
    return Material(
      color: context.colors.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Center(child: PicNutriAppIcon(size: 88)),
              const SizedBox(height: Space.xxl),
              Semantics(
                header: true,
                child: Text(
                  'Atualize o PicNutri',
                  textAlign: TextAlign.center,
                  style: context.text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: Space.md),
              Text(
                info.message,
                textAlign: TextAlign.center,
                style: context.text.bodyLarge?.copyWith(
                  color: context.pic.textSecondary,
                ),
              ),
              if (version != null) ...[
                const SizedBox(height: Space.sm),
                Text(
                  'Nova versão: $version',
                  textAlign: TextAlign.center,
                  style: context.text.bodySmall,
                ),
              ],
              const Spacer(),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: () => openStore(context, info),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Atualizar agora'),
                ),
              ),
              const SizedBox(height: Space.sm),
              Text(
                'Leva menos de um minuto. Seus dados continuam salvos.',
                textAlign: TextAlign.center,
                style: context.text.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
