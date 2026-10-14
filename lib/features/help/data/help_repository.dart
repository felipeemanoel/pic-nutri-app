import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';

class HelpCategory {
  const HelpCategory({required this.key, required this.label, required this.articles});

  factory HelpCategory.fromJson(Map<String, dynamic> json) => HelpCategory(
    key: json['key'] as String,
    label: json['label'] as String,
    articles: (json['articles'] as num?)?.toInt() ?? 0,
  );

  final String key;
  final String label;
  final int articles;
}

class HelpArticle {
  const HelpArticle({
    required this.slug,
    required this.category,
    required this.categoryLabel,
    required this.title,
    required this.kind,
    this.summary,
    this.body,
    this.reviewed = false,
    this.reviewedBy,
    this.reviewedAt,
  });

  factory HelpArticle.fromJson(Map<String, dynamic> json) {
    final review = json['review'] as Map<String, dynamic>?;
    return HelpArticle(
      slug: json['slug'] as String,
      category: json['category'] as String,
      categoryLabel: json['category_label'] as String? ?? '',
      title: json['title'] as String,
      kind: json['kind'] as String? ?? 'app',
      summary: json['summary'] as String?,
      body: json['body'] as String?,
      reviewed: review?['reviewed'] as bool? ?? false,
      reviewedBy: review?['reviewed_by'] as String?,
      reviewedAt: DateTime.tryParse(review?['reviewed_at'] as String? ?? ''),
    );
  }

  final String slug;
  final String category;
  final String categoryLabel;
  final String title;

  /// app (funcionamento do aplicativo) ou health (informação de saúde).
  final String kind;
  final String? summary;
  final String? body;
  final bool reviewed;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  bool get isHealth => kind == 'health';
}

typedef HelpQuery = ({String? search, String? category});

class HelpRepository {
  const HelpRepository(this._dio);

  final Dio _dio;

  Future<List<HelpCategory>> categories() async {
    final r = await guard(() => _dio.get<Map<String, dynamic>>('help/categories'));
    return (r.data!['data'] as List<dynamic>).cast<Map<String, dynamic>>().map(HelpCategory.fromJson).toList();
  }

  Future<List<HelpArticle>> articles(HelpQuery q) async {
    final r = await guard(
      () => _dio.get<Map<String, dynamic>>(
        'help/articles',
        queryParameters: {
          if (q.search != null && q.search!.isNotEmpty) 'q': q.search,
          'category': ?q.category,
        },
      ),
    );
    return (r.data!['data'] as List<dynamic>).cast<Map<String, dynamic>>().map(HelpArticle.fromJson).toList();
  }

  Future<HelpArticle> article(String slug) async {
    final r = await guard(() => _dio.get<Map<String, dynamic>>('help/articles/$slug'));
    return HelpArticle.fromJson(r.data!['data'] as Map<String, dynamic>);
  }
}

final helpRepositoryProvider = Provider<HelpRepository>((ref) => HelpRepository(ref.watch(dioProvider)));

final helpCategoriesProvider = FutureProvider<List<HelpCategory>>((ref) => ref.watch(helpRepositoryProvider).categories());

final helpArticlesProvider = FutureProvider.family<List<HelpArticle>, HelpQuery>(
  (ref, q) => ref.watch(helpRepositoryProvider).articles(q),
);

final helpArticleProvider = FutureProvider.family<HelpArticle, String>(
  (ref, slug) => ref.watch(helpRepositoryProvider).article(slug),
);
