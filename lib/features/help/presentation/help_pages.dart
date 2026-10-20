import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/help_repository.dart';

/// Central de ajuda: busca e categorias, com conteúdo administrado no painel.
class HelpCenterPage extends ConsumerStatefulWidget {
  const HelpCenterPage({super.key});

  @override
  ConsumerState<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends ConsumerState<HelpCenterPage> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _term = '';
  String? _category;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(helpCategoriesProvider).value ?? const <HelpCategory>[];
    final HelpQuery query = (search: _term, category: _category);
    final articles = ref.watch(helpArticlesProvider(query));

    return Scaffold(
      appBar: AppBar(title: const Text('Central de ajuda')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, Space.xxl),
        children: [
          TextField(
            controller: _search,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar na ajuda'),
            onChanged: (v) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), () => setState(() => _term = v.trim()));
            },
          ),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              ChoiceChip(label: const Text('Todas'), selected: _category == null, onSelected: (_) => setState(() => _category = null)),
              for (final c in categories)
                ChoiceChip(label: Text(c.label), selected: _category == c.key, onSelected: (_) => setState(() => _category = c.key)),
            ],
          ),
          const SizedBox(height: Space.md),
          AppCard(
            onTap: () => context.push('${AppRoutes.introTour}?review=1'),
            semanticLabel: 'Primeiros passos. Rever o guia: refeição, água, metas e evolução.',
            child: Row(
              children: [
                Icon(Icons.tour_outlined, color: context.colors.primary),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Primeiros passos', style: context.text.titleSmall),
                      Text('Rever o guia: refeição, água, metas e evolução', style: context.text.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          AsyncValueView<List<HelpArticle>>(
            value: articles,
            onRetry: () => ref.invalidate(helpArticlesProvider(query)),
            data: (list) => list.isEmpty
                ? const EmptyState(
                    compact: true,
                    icon: Icons.search_off,
                    title: 'Nada encontrado',
                    message: 'Tente outras palavras ou outra categoria.',
                  )
                : Column(
                    children: [
                      for (final a in list)
                        Card(
                          margin: const EdgeInsets.only(bottom: Space.sm),
                          child: ListTile(
                            leading: Icon(a.isHealth ? Icons.health_and_safety_outlined : Icons.help_outline),
                            title: Text(a.title),
                            subtitle: Text(a.summary ?? a.categoryLabel),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push(AppRoutes.helpArticle(a.slug)),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class HelpArticlePage extends ConsumerWidget {
  const HelpArticlePage({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final article = ref.watch(helpArticleProvider(slug));
    return Scaffold(
      appBar: AppBar(title: const Text('Ajuda')),
      body: AsyncValueView<HelpArticle>(
        value: article,
        onRetry: () => ref.invalidate(helpArticleProvider(slug)),
        data: (a) => ListView(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, Space.xxl),
          children: [
            Text(a.categoryLabel, style: context.text.labelMedium),
            Semantics(header: true, child: Text(a.title, style: context.text.headlineSmall)),
            const SizedBox(height: Space.md),
            if (a.isHealth)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.md),
                child: a.reviewed
                    ? StatusBanner(
                        tone: BannerTone.success,
                        message: 'Conteúdo revisado por ${a.reviewedBy}${a.reviewedAt != null ? ' em ${Fmt.shortDate(a.reviewedAt!)}' : ''}. Não substitui uma consulta.',
                      )
                    : const StatusBanner(
                        tone: BannerTone.warning,
                        message: 'Informação geral, ainda sem revisão de um profissional de saúde. Não é orientação profissional: em caso de dúvida, procure atendimento.',
                      ),
              ),
            SelectableText(a.body ?? '', style: context.text.bodyLarge),
          ],
        ),
      ),
    );
  }
}
