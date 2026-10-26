import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/design_system.dart';
import '../../data/onboarding_options.dart';

/// Cartão de resposta: área de toque grande, ícone, título e marcador de
/// escolha (círculo para uma opção, quadrado para várias).
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
    this.multiple = false,
  });

  final OnboardingOption option;
  final bool selected;
  final bool multiple;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pic = context.pic;
    final borderColor = selected ? colors.primary : pic.border;
    final background = selected ? pic.brandContainer : colors.surface;
    final foreground = selected ? pic.onBrandContainer : colors.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Semantics(
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: !multiple,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(Radii.xl),
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: AnimatedContainer(
              duration: Motion.fast,
              curve: Motion.curve,
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.symmetric(
                horizontal: Space.lg,
                vertical: Space.lg,
              ),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(Radii.xl),
                border: Border.all(color: borderColor, width: selected ? 2 : 1),
                boxShadow: selected ? null : Shadows.soft,
              ),
              child: Row(
                children: [
                  if (option.icon != null) ...[
                    Icon(option.icon, color: foreground, size: 26),
                    const SizedBox(width: Space.lg),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.title,
                          style: context.text.titleMedium?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (option.subtitle != null) ...[
                          const SizedBox(height: Space.xxs),
                          Text(
                            option.subtitle!,
                            style: context.text.bodyMedium?.copyWith(
                              color: selected
                                  ? pic.onBrandContainer
                                  : pic.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  _Marker(selected: selected, multiple: multiple),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.selected, required this.multiple});

  final bool selected;
  final bool multiple;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shape = multiple ? BoxShape.rectangle : BoxShape.circle;
    return AnimatedContainer(
      duration: Motion.fast,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: multiple ? BorderRadius.circular(Radii.sm) : null,
        color: selected && multiple ? colors.primary : Colors.transparent,
        border: Border.all(
          color: selected ? colors.primary : context.pic.border,
          width: 2,
        ),
      ),
      child: selected
          ? multiple
                ? Icon(Icons.check_rounded, size: 18, color: colors.onPrimary)
                : Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primary,
                      ),
                    ),
                  )
          : null,
    );
  }
}
