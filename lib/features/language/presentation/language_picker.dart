import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/features.dart';
import '../../../core/design/design_system.dart';
import '../../../core/i18n/app_language.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/i18n/locale_controller.dart';

/// Idioma que está aparecendo na tela agora (escolhido ou do aparelho).
AppLanguage displayedLanguage(BuildContext context) =>
    AppLanguage.fromLocale(Localizations.localeOf(context)) ??
    AppLanguage.fallback;

/// Folha com a lista de idiomas: bandeira, nome no próprio idioma e o aviso
/// de tradução em andamento. Usada no login, no início do cadastro e no
/// Perfil.
Future<void> showLanguagePicker(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _LanguageSheet(),
    );

class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chosen = ref.watch(languageControllerProvider);
    final l10n = context.l10n;

    Future<void> pick(AppLanguage? language) async {
      await ref.read(languageControllerProvider.notifier).set(language);
      if (context.mounted) Navigator.of(context).pop();
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: Space.lg),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.xxl,
                0,
                Space.xxl,
                Space.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.languageChooseTitle,
                      style: context.text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    l10n.languageChooseSubtitle,
                    style: context.text.bodyMedium?.copyWith(
                      color: context.pic.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _LanguageRow(
              leading: const Icon(Icons.smartphone_outlined),
              title: l10n.languageFollowDevice,
              selected: chosen == null,
              onTap: () => pick(null),
            ),
            const Divider(height: 1),
            for (final language in AppLanguage.values)
              _LanguageRow(
                key: ValueKey('language-${language.tag}'),
                leading: Text(
                  language.flag,
                  style: const TextStyle(fontSize: 26),
                ),
                title: language.nativeName,
                subtitle: language.complete ? null : l10n.languageInProgress,
                selected: chosen == language,
                onTap: () => pick(language),
              ),
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    super.key,
    required this.leading,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: Space.xxl),
    leading: SizedBox(width: 36, child: Center(child: leading)),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    selected: selected,
    trailing: selected
        ? Icon(Icons.check_circle_rounded, color: context.colors.primary)
        : null,
    onTap: onTap,
  );
}

/// Botão compacto (bandeira + sigla) para telas de entrada, como o login.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppFeatures.languages) return const SizedBox.shrink();
    final language = displayedLanguage(context);
    return Tooltip(
      message: context.l10n.languageChange,
      child: Material(
        color: context.colors.surface.withValues(alpha: 0.92),
        shape: StadiumBorder(side: BorderSide(color: context.pic.border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => showLanguagePicker(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.md,
              vertical: Space.xs + 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(language.flag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: Space.xs + 2),
                Text(
                  language.languageCode.toUpperCase(),
                  style: context.text.labelLarge,
                ),
                const Icon(Icons.expand_more_rounded, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cartão com o idioma atual e a ação "Alterar", para o início do cadastro.
class LanguageCard extends StatelessWidget {
  const LanguageCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppFeatures.languages) return const SizedBox.shrink();
    final language = displayedLanguage(context);
    final l10n = context.l10n;
    return Material(
      color: context.pic.surfaceMuted,
      borderRadius: Radii.control,
      child: InkWell(
        borderRadius: Radii.control,
        onTap: () => showLanguagePicker(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.lg,
            vertical: Space.md,
          ),
          child: Row(
            children: [
              Text(language.flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.languageTitle, style: context.text.labelSmall),
                    Text(language.nativeName, style: context.text.titleSmall),
                  ],
                ),
              ),
              Text(
                l10n.languageChangeShort,
                style: context.text.labelLarge?.copyWith(
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
