import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design_system.dart';
import '../../features/auth/application/session_controller.dart';
import '../../features/profile/data/profile_repository.dart';

/// Cache somente em memória; muda com a conta e a versão da foto.
final accountAvatarProvider = FutureProvider.autoDispose<Uint8List?>((
  ref,
) async {
  final account = ref.watch(
    currentAccountProvider.select((a) => (a?.email, a?.avatarVersion)),
  );
  if (account.$1 == null || account.$2 == null) return null;
  return ref.watch(profileRepositoryProvider).avatarBytes();
});

class AccountAvatar extends ConsumerWidget {
  const AccountAvatar({super.key, this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(currentAccountProvider)?.firstName ?? '';
    final photo = ref.watch(accountAvatarProvider);
    final image = photo.isLoading ? null : photo.value;
    final fallback = ColoredBox(
      color: context.pic.brandContainer,
      child: Center(
        child: Text(
          name.isEmpty ? '?' : name[0].toUpperCase(),
          style: context.text.titleMedium?.copyWith(
            color: context.pic.onBrandContainer,
          ),
        ),
      ),
    );
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: image == null
            ? fallback
            : Image.memory(
                image,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}
