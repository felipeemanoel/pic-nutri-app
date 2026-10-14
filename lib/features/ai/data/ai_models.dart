import '../../../core/utils/formatters.dart';
import '../../food/data/nutrition_models.dart';

/// Disponibilidade de um recurso de IA e cota de hoje.
class AiFeatureStatus {
  const AiFeatureStatus({
    required this.available,
    required this.limit,
    required this.remaining,
    required this.disclaimer,
  });

  factory AiFeatureStatus.fromJson(Map<String, dynamic> json) =>
      AiFeatureStatus(
        available: json['available'] as bool? ?? false,
        limit: toInt(json['limit']),
        remaining: toInt(json['remaining']),
        disclaimer: json['disclaimer'] as String? ?? '',
      );

  final bool available;

  /// `null` = ilimitado.
  final int? limit;
  final int? remaining;
  final String disclaimer;

  bool get hasQuota => remaining == null || remaining! > 0;

  String? get quotaLabel {
    if (limit == null) return null;
    return '${remaining ?? 0} de $limit restantes hoje';
  }
}

class AiStatus {
  const AiStatus({
    required this.photoAnalysis,
    required this.assistant,
    this.textAnalysis = const AiFeatureStatus(
      available: false,
      limit: 0,
      remaining: 0,
      disclaimer: '',
    ),
  });

  factory AiStatus.fromJson(Map<String, dynamic> json) => AiStatus(
    photoAnalysis: AiFeatureStatus.fromJson(
      json['photo_analysis'] as Map<String, dynamic>,
    ),
    assistant: AiFeatureStatus.fromJson(
      json['assistant'] as Map<String, dynamic>,
    ),
    textAnalysis: json['text_analysis'] is Map<String, dynamic>
        ? AiFeatureStatus.fromJson(json['text_analysis'] as Map<String, dynamic>)
        : const AiFeatureStatus(available: false, limit: 0, remaining: 0, disclaimer: ''),
  );

  final AiFeatureStatus photoAnalysis;
  final AiFeatureStatus assistant;

  /// Registro de refeição por texto ou voz.
  final AiFeatureStatus textAnalysis;
}

/// Análise de refeição por foto (sempre uma estimativa revisável).
class MealAnalysis {
  const MealAnalysis({
    required this.id,
    required this.status,
    required this.items,
    required this.notes,
    required this.disclaimer,
    this.imageQuality,
    this.totals,
    this.errorMessage,
    this.mealId,
    this.description,
  });

  factory MealAnalysis.fromJson(Map<String, dynamic> json) {
    final error = json['error'] as Map<String, dynamic>?;
    final totals = json['totals'] as Map<String, dynamic>?;
    return MealAnalysis(
      id: json['id'] as String,
      status: json['status'] as String,
      imageQuality: json['image_quality'] as String?,
      items: (json['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(MealItem.fromJson)
          .toList(),
      totals: totals == null ? null : Nutrients.fromJson(totals),
      notes: (json['notes'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      errorMessage: error?['message'] as String?,
      mealId: json['meal_id'] as String?,
      description: json['description'] as String?,
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }

  final String id;

  /// pending, processing, completed, failed, confirmed, discarded.
  final String status;
  final String? imageQuality;
  final List<MealItem> items;
  final Nutrients? totals;
  final List<String> notes;
  final String? errorMessage;
  final String? mealId;
  final String disclaimer;

  /// Texto descrito pelo usuário (registro por texto ou voz).
  final String? description;

  bool get inProgress => status == 'pending' || status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get notFood => imageQuality == 'not_food';
  bool get lowQuality => imageQuality == 'low';
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.status,
    required this.createdAt,
    this.content,
    this.safetyReply = false,
    this.errorMessage,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final error = json['error'] as Map<String, dynamic>?;
    return ChatMessage(
      id: toInt(json['id'])!,
      role: json['role'] as String,
      status: json['status'] as String,
      content: json['content'] as String?,
      safetyReply: json['safety_reply'] as bool? ?? false,
      errorMessage: error?['message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  final int id;
  final String role;
  final String status;
  final String? content;
  final bool safetyReply;
  final String? errorMessage;
  final DateTime createdAt;

  bool get isUser => role == 'user';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
}

class Conversation {
  const Conversation({
    required this.id,
    required this.createdAt,
    this.title,
    this.lastMessageAt,
    this.endedAt,
    this.messages = const [],
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'] as String,
    title: json['title'] as String?,
    lastMessageAt: _date(json['last_message_at']),
    endedAt: _date(json['ended_at']),
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    messages: (json['messages'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .toList(),
  );

  final String id;
  final String? title;
  final DateTime? lastMessageAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final List<ChatMessage> messages;

  bool get isEnded => endedAt != null;
  bool get awaitingReply => messages.any((m) => m.isPending);
  String get displayTitle => title ?? 'Nova conversa';

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.parse(value).toLocal() : null;
}
