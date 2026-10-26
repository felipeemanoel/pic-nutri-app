import 'package:flutter/material.dart';

/// Ação explícita para teclados numéricos que não oferecem tecla de concluir.
class KeyboardDismiss extends StatelessWidget {
  const KeyboardDismiss({super.key, required this.child});

  final Widget child;
  static const toolbarHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    return Actions(
      actions: {
        EditableTextTapOutsideIntent:
            CallbackAction<EditableTextTapOutsideIntent>(
              onInvoke: (_) {
                FocusManager.instance.primaryFocus?.unfocus();
                return null;
              },
            ),
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: MediaQuery(
              data: keyboard > 0
                  ? media.copyWith(
                      viewInsets: media.viewInsets.copyWith(
                        bottom: keyboard + toolbarHeight,
                      ),
                    )
                  : media,
              child: child,
            ),
          ),
          if (keyboard > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: keyboard,
              height: toolbarHeight,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      icon: const Icon(Icons.keyboard_hide_rounded, size: 20),
                      label: const Text('Fechar teclado'),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
