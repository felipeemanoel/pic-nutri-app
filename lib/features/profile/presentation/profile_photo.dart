import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/design/design_system.dart';
import '../../../shared/widgets/account_avatar.dart';
import '../../../shared/widgets/feedback.dart';
import '../../auth/application/session_controller.dart';
import '../data/profile_repository.dart';

class ProfilePhoto extends ConsumerStatefulWidget {
  const ProfilePhoto({super.key});

  @override
  ConsumerState<ProfilePhoto> createState() => _ProfilePhotoState();
}

class _ProfilePhotoState extends ConsumerState<ProfilePhoto> {
  bool _saving = false;

  Future<void> _choose() async {
    final hasPhoto = ref.read(currentAccountProvider)?.avatarVersion != null;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.of(sheet).pop('camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.of(sheet).pop('gallery'),
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remover foto'),
                onTap: () => Navigator.of(sheet).pop('remove'),
              ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    final accountEmail = ref.read(currentAccountProvider)?.email;
    final repository = ref.read(profileRepositoryProvider);
    final session = ref.read(sessionControllerProvider.notifier);
    if (action == 'remove') {
      final confirmed = await confirmAction(
        context,
        title: 'Remover foto de perfil?',
        message: 'Suas iniciais voltarão a aparecer no perfil.',
        confirmLabel: 'Remover',
        destructive: true,
      );
      if (!confirmed ||
          !mounted ||
          ref.read(currentAccountProvider)?.email != accountEmail) {
        return;
      }
      setState(() => _saving = true);
      try {
        final account = await repository.removeAvatar();
        if (!mounted ||
            ref.read(currentAccountProvider)?.email != accountEmail) {
          return;
        }
        session.updateAccount(account);
        showMessage(context, 'Foto removida.');
      } on Object catch (error) {
        if (mounted) showFailure(context, error);
      } finally {
        if (mounted) setState(() => _saving = false);
      }
      return;
    }
    try {
      final file = await ImagePicker().pickImage(
        source: action == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      if (await file.length() > 5 * 1024 * 1024) {
        if (mounted) showMessage(context, 'Escolha uma foto de até 5 MB.');
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Usar esta foto?'),
          content: SizedBox.square(
            dimension: 240,
            child: ClipOval(
              child: Image.memory(
                bytes,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Center(child: Text('Não foi possível ler a imagem.')),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialog).pop(true),
              child: const Text('Salvar foto'),
            ),
          ],
        ),
      );
      if (confirmed != true ||
          !mounted ||
          ref.read(currentAccountProvider)?.email != accountEmail) {
        return;
      }
      setState(() => _saving = true);
      final account = await repository.uploadAvatar(bytes);
      if (!mounted || ref.read(currentAccountProvider)?.email != accountEmail) {
        return;
      }
      session.updateAccount(account);
      showMessage(context, 'Foto de perfil atualizada.');
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = ref.watch(currentAccountProvider)?.avatarVersion != null;
    final photo = ref.watch(accountAvatarProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'Foto de perfil',
          child: const AccountAvatar(size: 80),
        ),
        const SizedBox(height: Space.xs),
        if (_saving)
          const Padding(
            padding: EdgeInsets.all(Space.md),
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          TextButton.icon(
            onPressed: _choose,
            icon: const Icon(Icons.add_a_photo_outlined, size: 18),
            label: Text(hasPhoto ? 'Alterar foto' : 'Adicionar foto'),
          ),
        if (photo.hasError)
          TextButton(
            onPressed: () => ref.invalidate(accountAvatarProvider),
            child: const Text('Recarregar foto'),
          ),
      ],
    );
  }
}
