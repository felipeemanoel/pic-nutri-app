import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/ai/data/ai_models.dart';

void main() {
  test('lê a análise concluída com itens estimados', () {
    final analysis = MealAnalysis.fromJson({
      'id': '01JANALYSIS',
      'status': 'completed',
      'image_quality': 'ok',
      'items': [
        {
          'name': 'Arroz branco',
          'quantity': 150,
          'unit': 'g',
          'energy_kcal': 190,
          'protein_g': 3.8,
          'carbs_g': 42,
          'fat_g': 0.4,
          'confidence': 0.8,
          'source': 'ai_estimate',
        },
      ],
      'totals': {
        'energy_kcal': 190,
        'protein_g': 3.8,
        'carbs_g': 42,
        'fat_g': 0.4,
      },
      'notes': ['Óleo não visível.'],
      'error': null,
      'meal_id': null,
      'disclaimer': 'Valores estimados.',
      'created_at': '2026-10-13T12:00:00Z',
    });

    expect(analysis.isCompleted, isTrue);
    expect(analysis.inProgress, isFalse);
    expect(analysis.items.single.source, 'ai_estimate');
    expect(analysis.items.single.nutrients.energyKcal, 190);
    expect(analysis.totals!.carbsG, 42);
    expect(analysis.notes, ['Óleo não visível.']);
  });

  test('lê a análise com falha e a mensagem segura', () {
    final analysis = MealAnalysis.fromJson({
      'id': '01J',
      'status': 'failed',
      'items': <Object>[],
      'notes': <Object>[],
      'error': {
        'code': 'ai_provider_error',
        'message': 'Não foi possível analisar.',
      },
      'disclaimer': '',
    });

    expect(analysis.isFailed, isTrue);
    expect(analysis.errorMessage, 'Não foi possível analisar.');
    expect(analysis.totals, isNull);
  });

  test('conversa com resposta pendente aguarda o servidor', () {
    final conversation = Conversation.fromJson({
      'id': '01JCONV',
      'title': 'Hidratação',
      'last_message_at': '2026-10-13T12:00:00Z',
      'ended_at': null,
      'created_at': '2026-10-13T12:00:00Z',
      'messages': [
        {
          'id': 1,
          'role': 'user',
          'status': 'completed',
          'content': 'Oi',
          'safety_reply': false,
          'error': null,
          'created_at': '2026-10-13T12:00:00Z',
        },
        {
          'id': 2,
          'role': 'assistant',
          'status': 'pending',
          'content': null,
          'safety_reply': false,
          'error': null,
          'created_at': '2026-10-13T12:00:01Z',
        },
      ],
    });

    expect(conversation.awaitingReply, isTrue);
    expect(conversation.isEnded, isFalse);
    expect(conversation.messages.first.isUser, isTrue);
  });

  test('status de IA com cota ilimitada e esgotada', () {
    final status = AiStatus.fromJson({
      'photo_analysis': {
        'available': true,
        'limit': 3,
        'remaining': 0,
        'disclaimer': 'x',
      },
      'assistant': {
        'available': true,
        'limit': null,
        'remaining': null,
        'disclaimer': 'y',
      },
    });

    expect(status.photoAnalysis.hasQuota, isFalse);
    expect(status.photoAnalysis.quotaLabel, '0 de 3 restantes hoje');
    expect(status.assistant.hasQuota, isTrue);
    expect(status.assistant.quotaLabel, isNull);
  });
}
