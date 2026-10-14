import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/design/design_system.dart';
import '../../features/auth/application/session_controller.dart';

/// Avatar que abre Perfil e configurações (fora da barra de abas).
class ProfileButton extends ConsumerWidget {
  const ProfileButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(currentAccountProvider)?.firstName ?? '';
    return Padding(
      padding: const EdgeInsets.only(right: Space.xs),
      child: IconButton(
        tooltip: 'Perfil e configurações',
        onPressed: () => context.push(AppRoutes.profile),
        icon: CircleAvatar(
          radius: 16,
          backgroundColor: context.pic.brandContainer,
          foregroundColor: context.pic.onBrandContainer,
          child: Text(
            name.isEmpty ? '?' : name[0].toUpperCase(),
            style: context.text.labelLarge?.copyWith(color: context.pic.onBrandContainer),
          ),
        ),
      ),
    );
  }
}
