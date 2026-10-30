import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../content/data/article_models.dart';
import '../../content/data/article_repository.dart';
import '../../content/presentation/article_widgets.dart';
import '../../help/data/help_repository.dart';
import '../../notifications/presentation/notification_bell.dart';
import '../data/planning_models.dart';
import '../data/planning_repository.dart';
import 'recipe_widgets.dart';

const _allRecipes = (
  search: null,
  mealType: null,
  tag: null,
  maxMinutes: null,
  favorites: false,
);
const _savedRecipes = (
  search: null,
  mealType: null,
  tag: null,
  maxMinutes: null,
  favorites: true,
);
const _allArticles = (search: null, category: null);
const _editorial = (category: null, search: null);

/// Conteúdos: receitas e artigos de saúde, com autoria, fonte e data.
/// Aba principal de Conteúdo; também acessível pelos atalhos de Alimentação.
class ContentsPage extends ConsumerWidget {
  const ContentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes = ref.watch(recipeSearchProvider(_allRecipes));
    final editorial = ref.watch(articlesProvider(_editorial));
    final saved =
        ref.watch(recipeSearchProvider(_savedRecipes)).value?.recipes ??
        const [];
    final articles =
        (ref.watch(helpArticlesProvider(_allArticles)).value ??
                const <HelpArticle>[])
            .where((a) => a.isHealth && a.reviewed)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conteúdo'),
        actions: const [NotificationBell()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(recipeSearchProvider)
            ..invalidate(articlesProvider(_editorial))
            ..invalidate(helpArticlesProvider(_allArticles));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, Space.sm, 0, Space.xxxl),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.page),
              child: Text(
                'Receitas, dicas e guias da equipe PicNutri. São sugestões gerais: não substituem '
                'um plano feito por um profissional para você.',
                style: context.text.bodyMedium?.copyWith(
                  color: context.pic.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: Space.section),
            _SectionTitle(
              title: 'Receitas',
              action: 'Ver todas',
              onAction: () => context.push(AppRoutes.recipes),
            ),
            const SizedBox(height: Space.md),
            switch (recipes) {
              AsyncData(:final value) when value.recipes.isNotEmpty =>
                _RecipeCarousel(recipes: value.recipes.take(8).toList()),
              AsyncData() => const _Empty(
                text: 'As receitas publicadas pela equipe aparecem aqui.',
              ),
              AsyncError() => _Empty(
                text: 'Não foi possível carregar as receitas.',
                onRetry: () =>
                    ref.invalidate(recipeSearchProvider(_allRecipes)),
              ),
              _ => const Padding(
                padding: EdgeInsets.all(Space.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
            },
            const SizedBox(height: Space.section),
            _SectionTitle(
              title: 'Dicas e guias',
              action: 'Ver todos',
              onAction: () => context.push(AppRoutes.articles),
            ),
            const SizedBox(height: Space.md),
            switch (editorial) {
              AsyncData(:final value) when value.isNotEmpty => _ArticleCarousel(
                articles: value.take(8).toList(),
              ),
              AsyncData() => const _Empty(
                text: 'Dicas e guias da equipe aparecem aqui.',
              ),
              AsyncError() => _Empty(
                text: 'Não foi possível carregar as dicas.',
                onRetry: () => ref.invalidate(articlesProvider(_editorial)),
              ),
              _ => const Padding(
                padding: EdgeInsets.all(Space.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
            },
            if (saved.isNotEmpty) ...[
              const SizedBox(height: Space.section),
              const _SectionTitle(title: 'Suas receitas salvas'),
              const SizedBox(height: Space.md),
              _RecipeCarousel(recipes: saved),
            ],
            const SizedBox(height: Space.section),
            _SectionTitle(
              title: 'Informações de saúde',
              action: 'Central de ajuda',
              onAction: () => context.push(AppRoutes.help),
            ),
            const SizedBox(height: Space.sm),
            if (articles.isEmpty)
              const _Empty(
                text: 'Artigos revisados por profissionais aparecem aqui.',
              )
            else
              for (final a in articles.take(6)) _ArticleTile(article: a),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Space.page),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: context.text.titleMedium),
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}

class _RecipeCarousel extends StatelessWidget {
  const _RecipeCarousel({required this.recipes});

  final List<Recipe> recipes;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return SizedBox(
      height: 300 * scale.clamp(1, 1.6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.page),
        itemCount: recipes.length,
        separatorBuilder: (_, _) => const SizedBox(width: Space.md),
        itemBuilder: (context, i) => SizedBox(
          width: 250,
          child: RecipeCard(
            recipe: recipes[i],
            onTap: () => context.push(AppRoutes.recipe(recipes[i].id)),
          ),
        ),
      ),
    );
  }
}

class _ArticleCarousel extends StatelessWidget {
  const _ArticleCarousel({required this.articles});

  final List<Article> articles;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return SizedBox(
      height: 290 * scale.clamp(1, 1.6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.page),
        itemCount: articles.length,
        separatorBuilder: (_, _) => const SizedBox(width: Space.md),
        itemBuilder: (context, i) =>
            SizedBox(width: 250, child: ArticleCard(article: articles[i])),
      ),
    );
  }
}

class _ArticleTile extends StatelessWidget {
  const _ArticleTile({required this.article});

  final HelpArticle article;

  static final _date = DateFormat('dd/MM/y', 'pt_BR');

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(
      horizontal: Space.page,
      vertical: Space.xs,
    ),
    leading: Icon(Icons.article_outlined, color: context.colors.primary),
    title: Text(article.title),
    subtitle: Text(
      [
        if (article.summary != null) article.summary!,
        [
          if (article.reviewedBy != null) 'Revisado por ${article.reviewedBy}',
          if (article.reviewedAt != null)
            'em ${_date.format(article.reviewedAt!)}',
        ].join(' '),
      ].where((t) => t.isNotEmpty).join('\n'),
    ),
    isThreeLine: article.summary != null,
    trailing: const Icon(Icons.chevron_right),
    onTap: () => context.push(AppRoutes.helpArticle(article.slug)),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Space.page),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: context.text.bodyMedium?.copyWith(
              color: context.pic.textSecondary,
            ),
          ),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
      ],
    ),
  );
}
