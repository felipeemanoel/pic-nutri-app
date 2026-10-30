import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import 'article_models.dart';

typedef ArticleQuery = ({String? category, String? search});

class ArticleRepository {
  const ArticleRepository(this._dio);

  final Dio _dio;

  Future<List<Article>> list(ArticleQuery q, {int perPage = 30}) async {
    final r = await guard(
      () => _dio.get<Map<String, dynamic>>(
        'contents/articles',
        queryParameters: {
          'category': ?(articleCategories.containsKey(q.category)
              ? q.category
              : null),
          if (q.search != null && q.search!.trim().isNotEmpty)
            'q': q.search!.trim(),
          'per_page': perPage,
        },
      ),
    );
    return (r.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Article.fromJson)
        .where((a) => a.isAvailable)
        .toList();
  }

  Future<Article> show(String slug) async {
    final r = await guard(
      () => _dio.get<Map<String, dynamic>>('contents/articles/$slug'),
    );
    final article = Article.fromJson(r.data!['data'] as Map<String, dynamic>);
    if (!article.isAvailable) {
      throw const NotFoundFailure();
    }
    return article;
  }
}

final articleRepositoryProvider = Provider<ArticleRepository>(
  (ref) => ArticleRepository(ref.watch(dioProvider)),
);

final articlesProvider = FutureProvider.autoDispose
    .family<List<Article>, ArticleQuery>(
      (ref, q) => ref.watch(articleRepositoryProvider).list(q),
    );

final articleProvider = FutureProvider.autoDispose.family<Article, String>(
  (ref, slug) => ref.watch(articleRepositoryProvider).show(slug),
);
