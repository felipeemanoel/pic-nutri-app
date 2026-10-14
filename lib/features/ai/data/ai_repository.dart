import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import 'ai_models.dart';

/// Recursos de IA: análise de refeição por foto e assistente. Toda chamada ao
/// provedor acontece no servidor; o app só envia a foto ou a mensagem.
class AiRepository {
  const AiRepository(this._dio);

  final Dio _dio;

  Future<AiStatus> status() async {
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>('ai/status'),
    );
    return AiStatus.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<MealAnalysis> uploadMealPhoto(
    String path, {
    required String requestId,
    void Function(double progress)? onProgress,
  }) async {
    final form = FormData.fromMap({
      'photo': await MultipartFile.fromFile(path, filename: 'refeicao.jpg'),
      'client_request_id': requestId,
    });
    final response = await guard(
      () => _dio.post<Map<String, dynamic>>(
        'ai/meal-analyses',
        data: form,
        options: Options(sendTimeout: const Duration(minutes: 2)),
        onSendProgress: onProgress == null
            ? null
            : (sent, total) {
                if (total > 0) onProgress(sent / total);
              },
      ),
    );
    return MealAnalysis.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  /// Registro por texto (digitado ou ditado no aparelho).
  Future<MealAnalysis> describeMeal(
    String description, {
    required String requestId,
  }) async {
    final response = await guard(
      () => _dio.post<Map<String, dynamic>>(
        'ai/meal-analyses',
        data: {'description': description.trim(), 'client_request_id': requestId},
      ),
    );
    return MealAnalysis.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<MealAnalysis> mealAnalysis(String id) async {
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>('ai/meal-analyses/$id'),
    );
    return MealAnalysis.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<void> discardMealAnalysis(String id) =>
      guard(() => _dio.delete<void>('ai/meal-analyses/$id'));

  Future<List<Conversation>> conversations() async {
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>('ai/conversations'),
    );
    return (response.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Conversation.fromJson)
        .toList();
  }

  Future<Conversation> createConversation() async {
    final response = await guard(
      () => _dio.post<Map<String, dynamic>>('ai/conversations'),
    );
    return Conversation.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<Conversation> conversation(String id) async {
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>('ai/conversations/$id'),
    );
    return Conversation.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<void> sendMessage(
    String conversationId,
    String content, {
    required String requestId,
  }) => guard(
    () => _dio.post<Map<String, dynamic>>(
      'ai/conversations/$conversationId/messages',
      data: {'content': content.trim(), 'client_request_id': requestId},
    ),
  );

  Future<void> endConversation(String id) =>
      guard(() => _dio.post<void>('ai/conversations/$id/end'));

  Future<void> deleteConversation(String id) =>
      guard(() => _dio.delete<void>('ai/conversations/$id'));
}

final aiRepositoryProvider = Provider<AiRepository>(
  (ref) => AiRepository(ref.watch(dioProvider)),
);

final aiStatusProvider = FutureProvider<AiStatus>(
  (ref) => ref.watch(aiRepositoryProvider).status(),
);

final conversationsProvider = FutureProvider<List<Conversation>>(
  (ref) => ref.watch(aiRepositoryProvider).conversations(),
);
