import '../../../app/features.dart';

/// Dica, guia ou novidade publicada pela equipe (Conteúdo e site).
class Article {
  const Article({
    required this.slug,
    required this.type,
    required this.typeLabel,
    required this.category,
    required this.categoryLabel,
    required this.title,
    required this.summary,
    this.body,
    this.imageUrl,
    this.imageAlt,
    this.tags = const [],
    this.readingMinutes,
    this.author,
    this.source,
    this.isHealth = false,
    this.reviewedBy,
    this.reviewedAt,
    this.featured = false,
    this.publishedAt,
    this.webUrl,
  });

  factory Article.fromJson(Map<String, dynamic> j) => Article(
    slug: j['slug'] as String,
    type: j['type'] as String? ?? 'tip',
    typeLabel: j['type_label'] as String? ?? '',
    category: j['category'] as String? ?? '',
    categoryLabel: j['category_label'] as String? ?? '',
    title: j['title'] as String,
    summary: j['summary'] as String? ?? '',
    body: j['body'] as String?,
    imageUrl: j['image_url'] as String?,
    imageAlt: j['image_alt'] as String?,
    tags: (j['tags'] as List<dynamic>? ?? const []).cast<String>(),
    readingMinutes: (j['reading_minutes'] as num?)?.toInt(),
    author: j['author'] as String?,
    source: j['source'] as String?,
    isHealth: j['kind'] == 'health',
    reviewedBy: j['reviewed_by'] as String?,
    reviewedAt: DateTime.tryParse(j['reviewed_at'] as String? ?? ''),
    featured: j['featured'] as bool? ?? false,
    publishedAt: DateTime.tryParse(
      j['published_at'] as String? ?? '',
    )?.toLocal(),
    webUrl: j['web_url'] as String?,
  );

  final String slug;
  final String type;
  final String typeLabel;
  final String category;
  final String categoryLabel;
  final String title;
  final String summary;
  final String? body;
  final String? imageUrl;
  final String? imageAlt;
  final List<String> tags;
  final int? readingMinutes;
  final String? author;
  final String? source;
  final bool isHealth;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final bool featured;
  final DateTime? publishedAt;
  final String? webUrl;

  /// Assunto de medicamento: categoria de canetas ou etiquetas do tema.
  bool get isAboutMedication =>
      category == 'tratamento' ||
      tags.any((t) => _medicationTags.contains(t.toLowerCase()));

  /// Visível neste build (sem recursos de medicamento, some o tema).
  bool get isAvailable => AppFeatures.medical || !isAboutMedication;
}

const _medicationTags = {
  'caneta',
  'canetas',
  'medicamento',
  'glp-1',
  'tirzepatida',
  'semaglutida',
};

/// Categorias dos conteúdos (iguais às do painel). Sem os recursos de
/// medicamento (build da Play com `FEATURE_MEDICAL=false`), a categoria de
/// canetas não aparece.
final articleCategories = <String, String>{
  'alimentacao': 'Alimentação',
  if (AppFeatures.medical) 'tratamento': 'Canetas e tratamento',
  'atividade': 'Atividade física',
  'hidratacao': 'Hidratação',
  'bem-estar': 'Bem-estar',
  'app': 'Como usar o PicNutri',
};
