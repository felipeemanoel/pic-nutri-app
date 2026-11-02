import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../data/body_repository.dart';
import 'progress_photos.dart';

/// Entrada visual para fotos privadas, com estados sem foto e de falha explícitos.
class ProgressPhotoHighlight extends ConsumerWidget {
  const ProgressPhotoHighlight({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progressPhotosProvider);
    final photos = [...?state.value]
      ..sort((a, b) => b.localDate.compareTo(a.localDate));
    final latest = photos.firstOrNull;
    void open() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Fotos de evolução')),
          body: const ProgressPhotosTab(),
        ),
      ),
    );
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_outlined,
                            size: 17,
                            color: context.colors.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Sua evolução',
                              style: context.text.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.sm),
                      Text(
                        latest != null
                            ? 'Cada foto conta uma parte da sua história.'
                            : 'As mudanças vão além da balança.',
                        style: context.text.bodySmall,
                      ),
                      const SizedBox(height: Space.md),
                      if (state.isLoading && latest == null)
                        const LinearProgressIndicator()
                      else if (state.hasError && latest == null)
                        TextButton.icon(
                          onPressed: () =>
                              ref.invalidate(progressPhotosProvider),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Carregar fotos'),
                        )
                      else if (latest != null)
                        Text(
                          '${photos.length} ${photos.length == 1 ? 'foto' : 'fotos'} · ${Fmt.shortDate(latest.localDate)}',
                          style: context.text.labelSmall,
                        )
                      else
                        Text(
                          'Comece com sua primeira foto.',
                          style: context.text.labelSmall,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.lg),
                Semantics(
                  button: true,
                  label: 'Abrir minhas fotos de evolução',
                  child: InkWell(
                    onTap: open,
                    borderRadius: BorderRadius.circular(18),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        width: 92,
                        height: 116,
                        child: latest != null
                            ? PhotoImage(id: latest.id, fit: BoxFit.cover)
                            : ColoredBox(
                                color: context.pic.brandContainer,
                                child: Icon(
                                  Icons.photo_camera_front_outlined,
                                  size: 34,
                                  color: context.pic.onBrandContainer,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
            child: FilledButton.tonalIcon(
              onPressed: latest != null
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PhotoTimelinePage(photos: photos),
                      ),
                    )
                  : state.hasError || state.isLoading
                  ? open
                  : () => addProgressPhoto(context),
              icon: Icon(
                latest != null ? Icons.timeline : Icons.add_a_photo_outlined,
                size: 18,
              ),
              label: Text(
                latest != null
                    ? 'Ver evolução em fotos'
                    : 'Minhas fotos de evolução',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
