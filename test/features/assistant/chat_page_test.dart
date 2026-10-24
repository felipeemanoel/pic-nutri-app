import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/app/theme/app_theme.dart';
import 'package:picnutri/features/ai/data/ai_models.dart';
import 'package:picnutri/features/ai/data/ai_repository.dart';
import 'package:picnutri/features/assistant/domain/assistant_scope.dart';
import 'package:picnutri/features/assistant/presentation/chat_page.dart';

class FakeChatRepository extends AiRepository {
  FakeChatRepository() : super(Dio());
  int sent = 0;
  int created = 0;
  @override
  Future<AiStatus> status() async => AiStatus.fromJson({
    'photo_analysis': {'available': false},
    'assistant': {'available': true, 'limit': 3, 'remaining': 3 - sent},
  });
  @override
  Future<Conversation> createConversation() async {
    created++;
    return conversation('account-conversation');
  }

  @override
  Future<void> sendMessage(
    String conversationId,
    String content, {
    required String requestId,
  }) async {
    sent++;
  }

  @override
  Future<Conversation> conversation(String id) async => Conversation.fromJson({
    'id': id,
    'created_at': '2026-10-20T12:00:00Z',
    'messages': sent == 0
        ? <Map<String, dynamic>>[]
        : [
            {
              'id': 1,
              'role': 'user',
              'status': 'completed',
              'content': 'Quanto de água registrei hoje?',
              'created_at': '2026-10-20T12:00:00Z',
            },
            {
              'id': 2,
              'role': 'assistant',
              'status': 'completed',
              'content': 'Você registrou 500 ml de água nesta conta.',
              'created_at': '2026-10-20T12:00:00Z',
            },
          ],
  });
}

void main() {
  testWidgets('inicia conversa, envia e atualiza o contador', (tester) async {
    final repo = FakeChatRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [aiRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(theme: AppTheme.light(), home: const ChatPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('3 mensagens restantes hoje'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'Quanto de água registrei hoje?',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Enviar'));
    await tester.pumpAndSettle();
    expect(repo.created, 1);
    expect(repo.sent, 1);
    expect(find.text('2 mensagens restantes hoje'), findsOneWidget);
    expect(find.textContaining('500 ml'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'recusa pergunta externa antes de criar conversa ou consumir consulta',
    (tester) async {
      final repo = FakeChatRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [aiRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(theme: AppTheme.light(), home: const ChatPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Escreva um programa em Python',
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Enviar'));
      await tester.pumpAndSettle();
      expect(repo.created, 0);
      expect(repo.sent, 0);
      expect(find.text(AssistantScope.refusal), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
