import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../data/article_models.dart';

/// Capa do conteúdo, com fundo neutro enquanto carrega ou sem imagem.
class ArticleCover extends StatelessWidget {
  const ArticleCover({
    super.key,
    required this.article,
    this.radius = Radii.lg,
    this.aspectRatio = 16 / 10,
  });

  final Article article;
  final double radius;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final url = article.imageUrl;
    final fallback = ColoredBox(
      color: context.colors.primaryContainer.withValues(alpha: 0.5),
      child: Center(
        child: Icon(
          Icons.article_outlined,
          size: 40,
          color: context.colors.primary,
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: url == null
            ? fallback
            : Image.network(
                url,
                fit: BoxFit.cover,
                semanticLabel: article.imageAlt ?? article.title,
                errorBuilder: (_, _, _) => fallback,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : ColoredBox(color: context.pic.surfaceMuted),
              ),
      ),
    );
  }
}

/// Etiqueta da categoria.
class ArticleTag extends StatelessWidget {
  const ArticleTag({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 2),
    decoration: BoxDecoration(
      color: context.colors.primaryContainer,
      borderRadius: BorderRadius.circular(Radii.pill),
    ),
    child: Text(
      label,
      style: context.text.labelSmall?.copyWith(
        color: context.colors.onPrimaryContainer,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// Cartão vertical, para carrosséis.
class ArticleCard extends StatelessWidget {
  const ArticleCard({super.key, required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.xl),
      side: BorderSide(color: context.pic.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => context.push(AppRoutes.article(article.slug)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArticleCover(article: article, radius: 0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ArticleTag(label: article.categoryLabel),
                  const SizedBox(height: Space.xs),
                  Text(
                    article.title,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  if (article.readingMinutes != null)
                    Text(
                      '${article.readingMinutes} min de leitura',
                      style: context.text.bodySmall?.copyWith(
                        color: context.pic.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Linha com miniatura, para listas.
class ArticleTile extends StatelessWidget {
  const ArticleTile({super.key, required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push(AppRoutes.article(article.slug)),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.page,
        vertical: Space.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: ArticleCover(article: article, radius: Radii.md),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  [
                    article.categoryLabel,
                    if (article.readingMinutes != null)
                      '${article.readingMinutes} min',
                  ].join(' · '),
                  style: context.text.bodySmall?.copyWith(
                    color: context.pic.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
