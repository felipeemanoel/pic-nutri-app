import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/request_id.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../../ai/data/ai_models.dart';
import '../../ai/data/ai_repository.dart';
import '../domain/assistant_scope.dart';
import 'assistant_usage.dart';

/// Conversa com o assistente. Sem [conversationId], cria uma nova ao enviar a
/// primeira mensagem. As respostas são geradas no servidor; a tela consulta a
/// conversa enquanto houver resposta pendente.
/// Pergunta pré-preenchida para abrir uma conversa nova (o usuário revisa e envia).
class ChatDraft {
  const ChatDraft(this.text);

  final String text;
}

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, this.conversationId, this.draft});

  final String? conversationId;

  /// Texto inicial do campo de mensagem (ex.: pedido de substituições).
  final String? draft;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  static const _pollEvery = Duration(milliseconds: 1500);
  static const _maxPolls = 80; // ~2 minutos

  late final _input = TextEditingController(text: widget.draft);
  final _scroll = ScrollController();
  Conversation? _conversation;
  Object? _loadError;
  bool _loading = false;
  bool _sending = false;
  String? _pendingRequestId;
  Timer? _timer;
  int _polls = 0;
  String? _notice;

  @override
  void initState() {
    super.initState();
    if (widget.conversationId != null) _load(widget.conversationId!);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load(String id) async {
    setState(() {
      _loading = _conversation == null;
      _loadError = null;
    });
    try {
      final conversation = await ref
          .read(aiRepositoryProvider)
          .conversation(id);
      if (!mounted) return;
      setState(() => _conversation = conversation);
      _scheduleIfPending();
      _scrollToEnd();
    } on Object catch (error) {
      if (mounted) setState(() => _loadError = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scheduleIfPending() {
    _timer?.cancel();
    final conversation = _conversation;
    if (conversation == null || !conversation.awaitingReply) {
      _polls = 0;
      return;
    }
    if (_polls++ >= _maxPolls) return;
    _timer = Timer(_pollEvery, () => _load(conversation.id));
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Envia o texto digitado, ou [override] (sugestão ou nova tentativa).
  Future<void> _send([String? override]) async {
    final text = (override ?? _input.text).trim();
    if (text.isEmpty ||
        _sending ||
        _loading ||
        (_conversation?.awaitingReply ?? false) ||
        (_conversation?.isEnded ?? false)) {
      return;
    }
    if (AssistantScope.resolve(text) == null) {
      setState(() => _notice = AssistantScope.refusal);
      return;
    }
    final status = ref.read(aiStatusProvider).value?.assistant;
    if (_pendingRequestId == null &&
        !(status?.canSendAssistantMessage ?? false)) {
      return;
    }
    setState(() => _notice = null);
    if (override != null) _pendingRequestId = null;
    // Mesmo ID em novas tentativas da mesma mensagem (evita duplicar).
    _pendingRequestId ??= newRequestId();
    setState(() => _sending = true);
    final repo = ref.read(aiRepositoryProvider);
    try {
      final conversation = _conversation ?? await repo.createConversation();
      _conversation ??= conversation;
      await repo.sendMessage(
        conversation.id,
        text,
        requestId: _pendingRequestId!,
      );
      if (!mounted) return;
      if (override == null) _input.clear();
      _pendingRequestId = null;
      ref
        ..invalidate(conversationsProvider)
        ..invalidate(aiStatusProvider);
      _polls = 0;
      await _load(conversation.id);
    } on Object catch (error) {
      ref.invalidate(aiStatusProvider);
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _end() async {
    final c = _conversation;
    if (c == null) return;
    try {
      await ref.read(aiRepositoryProvider).endConversation(c.id);
      ref.invalidate(conversationsProvider);
      await _load(c.id);
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    }
  }

  Future<void> _delete() async {
    final c = _conversation;
    if (c == null) return;
    final ok = await confirmAction(
      context,
      title: 'Excluir conversa?',
      message: 'Todas as mensagens desta conversa serão apagadas.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(aiRepositoryProvider).deleteConversation(c.id);
      ref.invalidate(conversationsProvider);
      if (mounted) context.pop();
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversation = _conversation;
    final ended = conversation?.isEnded ?? false;
    final awaiting = conversation?.awaitingReply ?? false;
    final status = ref.watch(aiStatusProvider);
    final canSend =
        !_loading &&
        !(_loadError != null && conversation == null) &&
        (status.value?.assistant.canSendAssistantMessage ?? false);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const AssistantAvatar(size: 36),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation?.displayTitle ?? 'Nova conversa',
                    style: context.text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text('Assistente PicNutri', style: context.text.labelSmall),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (conversation != null)
            PopupMenuButton<String>(
              onSelected: (v) => v == 'end' ? _end() : _delete(),
              itemBuilder: (_) => [
                if (!ended)
                  const PopupMenuItem(
                    value: 'end',
                    child: Text('Encerrar conversa'),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Excluir conversa'),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.lg,
              vertical: Space.sm,
            ),
            child: status.when(
              data: (s) => AssistantUsage(
                status: s.assistant,
                onRefresh: () => ref.invalidate(aiStatusProvider),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => StatusBanner(
                message: 'Não foi possível consultar seu limite.',
                actionLabel: 'Atualizar',
                onAction: () => ref.invalidate(aiStatusProvider),
              ),
            ),
          ),
          Expanded(child: _messages(conversation)),
          if (_notice != null)
            Padding(
              padding: const EdgeInsets.all(Space.md),
              child: StatusBanner(message: _notice!),
            ),
          if (awaiting || (_loadError != null && conversation != null))
            TextButton.icon(
              onPressed: () {
                _polls = 0;
                _load(conversation!.id);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar conversa'),
            ),
          if (ended)
            Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: StatusBanner(
                message: 'Conversa encerrada. Inicie uma nova para continuar.',
                icon: Icons.lock_outline,
                actionLabel: 'Nova conversa',
                onAction: () => context.pushReplacement(AppRoutes.chat),
              ),
            )
          else
            _Composer(
              controller: _input,
              awaiting: awaiting,
              enabled: canSend || (_pendingRequestId != null && !_loading),
              sending: _sending,
              onSend: () => _send(),
              onChanged: () => setState(() {
                _pendingRequestId = null;
                _notice = null;
              }),
            ),
        ],
      ),
    );
  }

  /// Reenvia a pergunta que antecede uma resposta que falhou.
  void _retry(ChatMessage failed) {
    final messages = _conversation?.messages ?? const <ChatMessage>[];
    final index = messages.indexOf(failed);
    for (var i = index - 1; i >= 0; i--) {
      if (messages[i].isUser && messages[i].content != null) {
        _send(messages[i].content);
        return;
      }
    }
  }

  Widget _messages(Conversation? conversation) {
    if (_loading) return const LoadingView();
    if (_loadError != null && conversation == null) {
      return ErrorView(
        message: friendlyMessage(_loadError!),
        onRetry: () => _load(_conversation?.id ?? widget.conversationId!),
      );
    }
    final messages = conversation?.messages ?? const <ChatMessage>[];
    if (messages.isEmpty) {
      return _Welcome(
        onSuggestion:
            _sending ||
                !(ref
                        .watch(aiStatusProvider)
                        .value
                        ?.assistant
                        .canSendAssistantMessage ??
                    false)
            ? null
            : _send,
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.md,
        Space.lg,
        Space.lg,
      ),
      itemCount: messages.length,
      itemBuilder: (context, i) => _Bubble(
        message: messages[i],
        onRetry: messages[i].isFailed && !(conversation?.isEnded ?? false)
            ? () => _retry(messages[i])
            : null,
      ),
    );
  }
}

/// Avatar do assistente (identidade roxa da IA).
class AssistantAvatar extends StatelessWidget {
  const AssistantAvatar({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: context.pic.aiContainer,
      shape: BoxShape.circle,
    ),
    child: Icon(Icons.auto_awesome, size: size * 0.55, color: context.pic.ai),
  );
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onSuggestion});

  final ValueChanged<String>? onSuggestion;

  static const _suggestions = AssistantScope.suggestions;

  @override
  Widget build(BuildContext context) {
    final p = context.pic;
    return ListView(
      padding: const EdgeInsets.all(Space.page),
      children: [
        const SizedBox(height: Space.lg),
        const Center(child: AssistantAvatar(size: 64)),
        const SizedBox(height: Space.lg),
        Text(
          'Como posso ajudar?',
          style: context.text.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Space.xs),
        Text(
          '${AssistantScope.description} Escolha uma pergunta abaixo para começar.',
          style: context.text.bodyMedium?.copyWith(color: p.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Space.xl),
        ExpansionTile(
          title: const Text('Todos os assuntos disponíveis'),
          children: [
            for (final question in AssistantScope.questions.keys.where(
              (q) => q != 'Olá!',
            ))
              ListTile(
                title: Text(question),
                onTap: onSuggestion == null
                    ? null
                    : () => onSuggestion!(question),
              ),
          ],
        ),
        for (final s in _suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: AppCard(
              onTap: onSuggestion == null ? null : () => onSuggestion!(s),
              padding: const EdgeInsets.symmetric(
                horizontal: Space.lg,
                vertical: Space.md,
              ),
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 18, color: p.ai),
                  const SizedBox(width: Space.md),
                  Expanded(child: Text(s, style: context.text.bodyMedium)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.awaiting,
    required this.enabled,
    required this.sending,
    required this.onSend,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool awaiting;
  final bool enabled;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.pic;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.md,
            Space.sm,
            Space.sm,
            Space.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 1000,
                      enabled: enabled && !awaiting && !sending,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: awaiting
                            ? 'Aguardando resposta…'
                            : 'Escreva sua pergunta',
                        counterText: '',
                        fillColor: p.surfaceMuted,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Radii.xl),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Radii.xl),
                          borderSide: BorderSide(color: p.ai, width: 1.5),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Radii.xl),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: Space.lg,
                          vertical: Space.md,
                        ),
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                  const SizedBox(width: Space.xs),
                  IconButton.filled(
                    tooltip: 'Enviar',
                    style: IconButton.styleFrom(
                      backgroundColor: p.ai,
                      foregroundColor: context.colors.onTertiary,
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed:
                        !enabled ||
                            sending ||
                            awaiting ||
                            controller.text.trim().isEmpty
                        ? null
                        : onSend,
                    icon: sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
              const SizedBox(height: Space.xs),
              Text(
                'Consultas aos registros desta conta. Não substitui orientação profissional.',
                style: context.text.labelSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, this.onRetry});

  final ChatMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.pic;
    final scheme = context.colors;
    final mine = message.isUser;

    final Widget content;
    if (message.isPending) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: p.ai),
          ),
          const SizedBox(width: Space.sm),
          Semantics(liveRegion: true, child: const Text('Gerando resposta…')),
        ],
      );
    } else if (message.isFailed) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 18, color: p.error),
              const SizedBox(width: Space.xs),
              Flexible(
                child: Text(
                  message.errorMessage ?? 'Não foi possível gerar a resposta.',
                ),
              ),
            ],
          ),
          if (onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tentar novamente'),
            ),
        ],
      );
    } else if (mine) {
      content = SelectableText(
        message.content ?? '',
        style: context.text.bodyMedium,
      );
    } else {
      content = _FormattedText(message.content ?? '');
    }

    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: Space.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md + 2,
        vertical: Space.md,
      ),
      decoration: BoxDecoration(
        color: mine
            ? p.brandContainer
            : message.safetyReply
            ? p.warningContainer
            : scheme.surface,
        border: mine
            ? null
            : Border.all(
                color: message.safetyReply ? p.warningContainer : p.border,
              ),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(Radii.lg),
          topRight: const Radius.circular(Radii.lg),
          bottomLeft: Radius.circular(mine ? Radii.lg : Radii.xs),
          bottomRight: Radius.circular(mine ? Radii.xs : Radii.lg),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.safetyReply)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.health_and_safety_outlined,
                    size: 16,
                    color: p.warning,
                  ),
                  const SizedBox(width: Space.xs),
                  Text(
                    'Orientação de segurança',
                    style: context.text.labelMedium,
                  ),
                ],
              ),
            ),
          content,
          const SizedBox(height: Space.xs),
          Text(Fmt.time(message.createdAt), style: context.text.labelSmall),
        ],
      ),
    );

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
        ),
        child: mine
            ? bubble
            : Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: Space.sm, right: Space.sm),
                    child: AssistantAvatar(size: 28),
                  ),
                  Flexible(child: bubble),
                ],
              ),
      ),
    );
  }
}

/// Texto das respostas com parágrafos e listas legíveis. Marcações simples
/// (`**negrito**`, itens com "-", "*" ou "•", listas numeradas) são
/// convertidas; o restante aparece como texto puro.
class _FormattedText extends StatelessWidget {
  const _FormattedText(this.text);

  final String text;

  static final _bullet = RegExp(r'^\s*([-*•]|\d+[.)])\s+');

  List<TextSpan> _inline(String line, TextStyle? base) {
    final spans = <TextSpan>[];
    final parts = line.split('**');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(
        TextSpan(
          text: parts[i],
          style: i.isOdd ? base?.copyWith(fontWeight: FontWeight.w600) : base,
        ),
      );
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final base = context.text.bodyMedium;
    final blocks = text.trim().split(RegExp(r'\n\s*\n'));
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (bi, block) in blocks.indexed) ...[
            if (bi > 0) const SizedBox(height: Space.sm),
            for (final line in block.split('\n'))
              if (_bullet.hasMatch(line))
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 22,
                        child: Text(
                          RegExp(r'^\s*(\d+[.)])').firstMatch(line)?.group(1) ??
                              '•',
                          style: base,
                        ),
                      ),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: _inline(
                              line.replaceFirst(_bullet, ''),
                              base,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (line.trim().isNotEmpty)
                Text.rich(
                  TextSpan(
                    children: _inline(
                      line.trim().replaceAll(RegExp(r'^#+\s*'), ''),
                      base,
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
