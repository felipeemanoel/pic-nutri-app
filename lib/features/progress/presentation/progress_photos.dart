import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/request_id.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/body_models.dart';
import '../data/body_repository.dart';

/// Fotos de evolução: privadas, guardadas cifradas e nunca compartilhadas
/// com profissionais. Comparação lado a lado com data e peso do dia.
class ProgressPhotosTab extends ConsumerStatefulWidget {
  const ProgressPhotosTab({super.key});

  @override
  ConsumerState<ProgressPhotosTab> createState() => _ProgressPhotosTabState();
}

class _ProgressPhotosTabState extends ConsumerState<ProgressPhotosTab> {
  String? _pose;

  void _open(ProgressPhoto photo) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => PhotoViewerPage(photo: photo)),
  );

  void _compare(List<ProgressPhoto> photos) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => PhotoComparePage(photos: photos)),
  );

  @override
  Widget build(BuildContext context) {
    final photos = ref.watch(progressPhotosProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-photo',
        onPressed: () => addProgressPhoto(context),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Foto'),
      ),
      body: AsyncValueView<List<ProgressPhoto>>(
        value: photos,
        onRetry: () => ref.invalidate(progressPhotosProvider),
        data: (all) {
          if (all.isEmpty) {
            return EmptyState(
              icon: Icons.photo_camera_front_outlined,
              title: 'Nenhuma foto de evolução',
              message:
                  'Fotos mostram mudanças que a balança não mostra. Tire sempre no mesmo lugar, com a mesma luz e roupa. '
                  'Elas são privadas: só você vê.',
              actionLabel: 'Adicionar foto',
              onAction: () => addProgressPhoto(context),
            );
          }
          final list = _pose == null ? all : all.where((p) => p.pose == _pose).toList();
          return RefreshIndicator(
            onRefresh: () => ref.refresh(progressPhotosProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, Space.fabClearance),
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: context.pic.textSecondary),
                    const SizedBox(width: Space.xs),
                    Expanded(
                      child: Text(
                        'Privadas e cifradas. Não entram em compartilhamentos com profissionais.',
                        style: context.text.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Todas'),
                        selected: _pose == null,
                        onSelected: (_) => setState(() => _pose = null),
                      ),
                      for (final e in PhotoPoses.labels.entries) ...[
                        const SizedBox(width: Space.xs),
                        ChoiceChip(
                          label: Text(e.value),
                          selected: _pose == e.key,
                          onSelected: (_) => setState(() => _pose = e.key),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: Space.sm),
                if (list.length >= 2)
                  OutlinedButton.icon(
                    onPressed: () => _compare(list),
                    icon: const Icon(Icons.compare_outlined),
                    label: const Text('Comparar lado a lado'),
                  ),
                const SizedBox(height: Space.sm),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: Space.xl),
                    child: Text('Nenhuma foto com esse ângulo.', textAlign: TextAlign.center),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: Space.sm,
                      crossAxisSpacing: Space.sm,
                      childAspectRatio: 0.62,
                    ),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _Thumb(photo: list[i], onTap: () => _open(list[i])),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.photo, required this.onTap});

  final ProgressPhoto photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Foto de ${photo.poseLabel.toLowerCase()} em ${Fmt.shortDate(photo.localDate)}',
    child: InkWell(
      onTap: onTap,
      borderRadius: Radii.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(borderRadius: Radii.card, child: PhotoImage(id: photo.id)),
          ),
          const SizedBox(height: Space.xs),
          Text(Fmt.shortDate(photo.localDate), style: context.text.labelMedium, textAlign: TextAlign.center),
          Text(photo.poseLabel, style: context.text.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

/// Imagem carregada pela API autenticada (só em memória).
class PhotoImage extends ConsumerWidget {
  const PhotoImage({super.key, required this.id, this.fit = BoxFit.cover});

  final String id;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = ref.watch(progressPhotoBytesProvider(id));
    return ColoredBox(
      color: context.pic.surfaceMuted,
      child: bytes.when(
        data: (b) => Image.memory(b, fit: fit, gaplessPlayback: true),
        loading: () => const Center(child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        error: (_, _) => Center(
          child: IconButton(
            tooltip: 'Tentar de novo',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(progressPhotoBytesProvider(id)),
          ),
        ),
      ),
    );
  }
}

/// Escolhe a origem, a imagem e o ângulo, e envia.
Future<void> addProgressPhoto(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Tirar foto'),
            onTap: () => Navigator.of(sheet).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Escolher da galeria'),
            onTap: () => Navigator.of(sheet).pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return;

  XFile? file;
  try {
    file = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 85);
  } on Object {
    if (context.mounted) showMessage(context, 'Não foi possível abrir a câmera ou a galeria. Verifique as permissões do app.');
    return;
  }
  if (file == null || !context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _PhotoDetailsSheet(file: file!),
  );
}

class _PhotoDetailsSheet extends ConsumerStatefulWidget {
  const _PhotoDetailsSheet({required this.file});

  final XFile file;

  @override
  ConsumerState<_PhotoDetailsSheet> createState() => _PhotoDetailsSheetState();
}

class _PhotoDetailsSheetState extends ConsumerState<_PhotoDetailsSheet> {
  final _requestId = newRequestId();
  final _notes = TextEditingController();
  String _pose = 'front';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(bodyRepositoryProvider).uploadPhoto(
        path: widget.file.path,
        pose: _pose,
        takenAt: DateTime.now(),
        requestId: _requestId,
        notes: _notes.text,
      );
      ref.invalidate(progressPhotosProvider);
      if (!mounted) return;
      showMessage(context, 'Foto salva.');
      Navigator.of(context).pop();
    } on Object catch (e) {
      if (mounted) setState(() => _error = friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xl),
      children: [
        Text('Nova foto de evolução', style: context.text.titleMedium),
        const SizedBox(height: Space.md),
        Center(
          child: ClipRRect(
            borderRadius: Radii.card,
            child: SizedBox(height: 220, child: _LocalImage(path: widget.file.path)),
          ),
        ),
        const SizedBox(height: Space.md),
        Text('Ângulo', style: context.text.labelLarge),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: Space.xs,
          children: [
            for (final e in PhotoPoses.labels.entries)
              ChoiceChip(label: Text(e.value), selected: _pose == e.key, onSelected: (_) => setState(() => _pose = e.key)),
          ],
        ),
        TextField(
          controller: _notes,
          maxLength: 500,
          decoration: const InputDecoration(labelText: 'Observação (opcional)'),
        ),
        Text(
          'A foto é reduzida, os dados de localização são removidos e ela fica guardada de forma cifrada.',
          style: context.text.bodySmall,
        ),
        const SizedBox(height: Space.md),
        if (_error != null) ...[
          StatusBanner(tone: BannerTone.error, message: _error!),
          const SizedBox(height: Space.sm),
        ],
        LoadingButton(label: 'Salvar foto', loading: _saving, onPressed: _save),
      ],
    ),
  );
}

/// Pré-visualização do arquivo escolhido, lido do aparelho.
class _LocalImage extends StatelessWidget {
  const _LocalImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) => Image.file(File(path), fit: BoxFit.contain);
}

/// Foto em tela cheia, com data, peso do dia, edição e exclusão.
class PhotoViewerPage extends ConsumerWidget {
  const PhotoViewerPage({super.key, required this.photo});

  final ProgressPhoto photo;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(
      context,
      title: 'Apagar foto?',
      message: 'A foto será apagada definitivamente.',
      confirmLabel: 'Apagar',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(bodyRepositoryProvider).deletePhoto(photo.id);
      ref.invalidate(progressPhotosProvider);
      if (context.mounted) Navigator.of(context).pop();
    } on Object catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _EditPhotoDialog(photo: photo),
    );
    if (result == null || !context.mounted) return;
    try {
      await ref.read(bodyRepositoryProvider).updatePhoto(photo.id, pose: result.$1, notes: result.$2);
      ref.invalidate(progressPhotosProvider);
      if (context.mounted) Navigator.of(context).pop();
    } on Object catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: Text('${photo.poseLabel} · ${Fmt.shortDate(photo.localDate)}'),
      actions: [
        IconButton(tooltip: 'Editar', icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(context, ref)),
        IconButton(tooltip: 'Apagar', icon: const Icon(Icons.delete_outline), onPressed: () => _delete(context, ref)),
      ],
    ),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: InteractiveViewer(maxScale: 4, child: PhotoImage(id: photo.id, fit: BoxFit.contain)),
        ),
        Padding(
          padding: const EdgeInsets.all(Space.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                photo.nearestWeightKg == null ? 'Sem peso registrado perto dessa data' : 'Peso perto dessa data: ${Fmt.kg(photo.nearestWeightKg!)}',
                style: context.text.bodyMedium,
              ),
              if (photo.notes != null && photo.notes!.isNotEmpty) ...[
                const SizedBox(height: Space.xs),
                Text(photo.notes!),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _EditPhotoDialog extends StatefulWidget {
  const _EditPhotoDialog({required this.photo});

  final ProgressPhoto photo;

  @override
  State<_EditPhotoDialog> createState() => _EditPhotoDialogState();
}

class _EditPhotoDialogState extends State<_EditPhotoDialog> {
  late String _pose = widget.photo.pose;
  late final _notes = TextEditingController(text: widget.photo.notes);

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Editar foto'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Space.xs,
          children: [
            for (final e in PhotoPoses.labels.entries)
              ChoiceChip(label: Text(e.value), selected: _pose == e.key, onSelected: (_) => setState(() => _pose = e.key)),
          ],
        ),
        TextField(controller: _notes, maxLength: 500, decoration: const InputDecoration(labelText: 'Observação')),
      ],
    ),
    actions: [
      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
      FilledButton(onPressed: () => Navigator.of(context).pop((_pose, _notes.text)), child: const Text('Salvar')),
    ],
  );
}

/// Duas fotos lado a lado: por padrão a mais antiga e a mais recente.
class PhotoComparePage extends StatefulWidget {
  const PhotoComparePage({super.key, required this.photos});

  /// Fotos disponíveis, da mais recente para a mais antiga.
  final List<ProgressPhoto> photos;

  @override
  State<PhotoComparePage> createState() => _PhotoComparePageState();
}

class _PhotoComparePageState extends State<PhotoComparePage> {
  late ProgressPhoto _before = widget.photos.last;
  late ProgressPhoto _after = widget.photos.first;

  Future<void> _choose(bool before) async {
    final picked = await showModalBottomSheet<ProgressPhoto>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => SizedBox(
        height: MediaQuery.sizeOf(sheet).height * 0.6,
        child: GridView.builder(
          padding: const EdgeInsets.all(Space.page),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: Space.sm,
            crossAxisSpacing: Space.sm,
            childAspectRatio: 0.62,
          ),
          itemCount: widget.photos.length,
          itemBuilder: (_, i) => _Thumb(photo: widget.photos[i], onTap: () => Navigator.of(sheet).pop(widget.photos[i])),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (before) {
        _before = picked;
      } else {
        _after = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _after.localDate.difference(_before.localDate).inDays.abs();
    final w1 = _before.nearestWeightKg;
    final w2 = _after.nearestWeightKg;
    final diff = w1 != null && w2 != null ? w2 - w1 : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Comparar fotos')),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _Side(photo: _before, label: 'Antes', onChange: () => _choose(true))),
                const SizedBox(width: 2),
                Expanded(child: _Side(photo: _after, label: 'Depois', onChange: () => _choose(false))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.page),
            child: Text(
              [
                '$days ${days == 1 ? 'dia' : 'dias'} entre as fotos',
                if (diff != null) 'peso ${diff > 0 ? '+' : ''}${Fmt.decimal(diff)} kg',
              ].join(' · '),
              style: context.text.titleSmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({required this.photo, required this.label, required this.onChange});

  final ProgressPhoto photo;
  final String label;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: PhotoImage(id: photo.id, fit: BoxFit.contain)),
      const SizedBox(height: Space.xs),
      Text(label, style: context.text.labelLarge, textAlign: TextAlign.center),
      Text(
        [
          Fmt.shortDate(photo.localDate),
          if (photo.nearestWeightKg != null) Fmt.kg(photo.nearestWeightKg!),
        ].join(' · '),
        style: context.text.bodySmall,
        textAlign: TextAlign.center,
      ),
      TextButton(onPressed: onChange, child: const Text('Trocar')),
    ],
  );
}
