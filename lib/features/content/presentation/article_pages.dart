import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design/design_system.dart';
import '../data/article_models.dart';
import '../data/article_repository.dart';
import 'article_widgets.dart';
import 'markdown_view.dart';

/// Todas as dicas e guias, com filtro por categoria e busca.
class ArticlesPage extends ConsumerStatefulWidget {
  const ArticlesPage({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  ConsumerState<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends ConsumerState<ArticlesPage> {
  late String? _category = widget.initialCategory;
  String? _search;

  @override
  Widget build(BuildContext context) {
    final query = (category: _category, search: _search);
    final articles = ref.watch(articlesProvider(query));
    return Scaffold(
      appBar: AppBar(title: const Text('Dicas e guias')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(articlesProvider(query)),
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.page,
                Space.sm,
                Space.page,
                Space.md,
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar dicas e guias',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (v) => setState(() => _search = v.trim()),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Space.page),
                children: [
                  _chip('Tudo', null),
                  for (final e in articleCategories.entries)
                    _chip(e.value, e.key),
                ],
              ),
            ),
            const SizedBox(height: Space.sm),
            switch (articles) {
              AsyncData(:final value) when value.isEmpty => Padding(
                padding: const EdgeInsets.all(Space.xl),
                child: Text(
                  'Nenhum conteúdo encontrado.',
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium?.copyWith(
                    color: context.pic.textSecondary,
                  ),
                ),
              ),
              AsyncData(:final value) => Column(
                children: [for (final a in value) ArticleTile(article: a)],
              ),
              AsyncError() => Padding(
                padding: const EdgeInsets.all(Space.xl),
                child: Column(
                  children: [
                    const Text('Não foi possível carregar os conteúdos.'),
                    TextButton(
                      onPressed: () => ref.invalidate(articlesProvider(query)),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
              _ => const Padding(
                padding: EdgeInsets.all(Space.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
            },
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String? value) => Padding(
    padding: const EdgeInsets.only(right: Space.sm),
    child: ChoiceChip(
      label: Text(label),
      selected: _category == value,
      onSelected: (_) => setState(() => _category = value),
    ),
  );
}

/// Leitura de um conteúdo.
class ArticlePage extends ConsumerWidget {
  const ArticlePage({super.key, required this.slug});

  final String slug;

  static final _date = DateFormat("d 'de' MMMM 'de' y", 'pt_BR');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final article = ref.watch(articleProvider(slug));
    final web = article.value?.webUrl;
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (web != null)
            IconButton(
              tooltip: 'Abrir no site',
              icon: const Icon(Icons.open_in_new_rounded),
              onPressed: () => launchUrl(
                Uri.parse(web),
                mode: LaunchMode.externalApplication,
              ),
            ),
        ],
      ),
      body: switch (article) {
        AsyncData(:final value) => _Body(article: value),
        AsyncError() => Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Não foi possível abrir este conteúdo.'),
                TextButton(
                  onPressed: () => ref.invalidate(articleProvider(slug)),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final a = article;
    final meta = [
      a.author ?? 'Equipe PicNutri',
      if (a.publishedAt != null) ArticlePage._date.format(a.publishedAt!),
      if (a.readingMinutes != null) '${a.readingMinutes} min de leitura',
    ].join(' · ');
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.page,
        Space.xs,
        Space.page,
        Space.xxxl,
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: ArticleTag(label: a.categoryLabel),
        ),
        const SizedBox(height: Space.sm),
        Semantics(
          header: true,
          child: Text(
            a.title,
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: Space.sm),
        Text(
          a.summary,
          style: context.text.titleMedium?.copyWith(
            color: context.pic.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: Space.sm),
        Text(
          meta,
          style: context.text.bodySmall?.copyWith(
            color: context.pic.textSecondary,
          ),
        ),
        const SizedBox(height: Space.lg),
        ArticleCover(article: a, radius: Radii.xl),
        const SizedBox(height: Space.md),
        MarkdownView(data: a.body ?? ''),
        if (a.isHealth) ...[
          const SizedBox(height: Space.md),
          Container(
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              color: context.pic.surfaceMuted,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Text(
              'Conteúdo informativo. Não substitui a orientação do seu médico ou nutricionista.',
              style: context.text.bodySmall,
            ),
          ),
        ],
        if (a.source != null) ...[
          const SizedBox(height: Space.md),
          Text(
            'Fonte: ${a.source}',
            style: context.text.bodySmall?.copyWith(
              color: context.pic.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
