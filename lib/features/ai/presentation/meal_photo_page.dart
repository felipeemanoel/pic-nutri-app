import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/request_id.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../../food/data/nutrition_models.dart';
import '../data/ai_models.dart';
import '../data/ai_repository.dart';

/// Dados passados para a revisão da análise no editor de refeição.
class PhotoReview {
  const PhotoReview({required this.analysisId, required this.items});

  final String analysisId;
  final List<MealItem> items;
}

/// Registro de refeição por foto:
/// 1. escolher/capturar → 2. pré-visualizar → 3. confirmar o envio →
/// 4. processamento (estados reais do servidor) → 5. resultado →
/// 6. revisão no editor → 7. confirmação no diário.
/// Nada é salvo sem a confirmação do usuário.
class MealPhotoPage extends ConsumerStatefulWidget {
  const MealPhotoPage({super.key, this.textMode = false});

  /// Registro por texto ou voz (descrição da refeição) em vez de foto.
  final bool textMode;

  @override
  ConsumerState<MealPhotoPage> createState() => _MealPhotoPageState();
}

enum _Stage { choose, preview, uploading, analyzing, result, slow, uploadFailed }

class _MealPhotoPageState extends ConsumerState<MealPhotoPage> {
  static const _pollEvery = Duration(seconds: 2);
  static const _giveUpAfter = Duration(minutes: 3);

  final _picker = ImagePicker();
  _Stage _stage = _Stage.choose;
  double _progress = 0;
  MealAnalysis? _analysis;
  Timer? _timer;
  DateTime? _startedAt;
  String? _requestId;
  String? _path;
  String? _description;
  String? _uploadError;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    XFile? file;
    try {
      // Reduz no aparelho (envio mais rápido); o servidor reduz de novo e
      // remove os metadados da foto.
      file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      final what = source == ImageSource.camera ? 'câmera' : 'galeria';
      showMessage(
        context,
        error.code.contains('denied')
            ? 'Permita o acesso à $what nas configurações do aparelho.'
            : 'Não foi possível abrir a $what.',
      );
      return;
    }
    if (file == null || !mounted) return;
    setState(() {
      _path = file!.path;
      _stage = _Stage.preview;
    });
  }

  /// Envia a foto da pré-visualização. Em nova tentativa após falha de rede,
  /// reaproveita o mesmo identificador (o servidor não duplica a análise).
  Future<void> _upload({bool newAttempt = true}) async {
    final path = _path;
    final description = _description;
    if (path == null && description == null) return;
    if (newAttempt || _requestId == null) _requestId = newRequestId();
    setState(() {
      _stage = _Stage.uploading;
      _progress = 0;
      _uploadError = null;
    });
    try {
      final repo = ref.read(aiRepositoryProvider);
      final analysis = description != null
          ? await repo.describeMeal(description, requestId: _requestId!)
          : await repo.uploadMealPhoto(
              path!,
              requestId: _requestId!,
              onProgress: (p) {
                if (mounted) setState(() => _progress = p);
              },
            );
      ref.invalidate(aiStatusProvider);
      _onAnalysis(analysis);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.uploadFailed;
        _uploadError = friendlyMessage(error);
      });
    }
  }

  void _onAnalysis(MealAnalysis analysis) {
    if (!mounted) return;
    _timer?.cancel();
    if (analysis.inProgress) {
      _startedAt ??= DateTime.now();
      setState(() {
        _analysis = analysis;
        _stage = _Stage.analyzing;
      });
      _timer = Timer(_pollEvery, _poll);
    } else {
      _startedAt = null;
      setState(() {
        _analysis = analysis;
        _stage = _Stage.result;
      });
    }
  }

  Future<void> _poll() async {
    final current = _analysis;
    if (current == null || !mounted) return;
    if (DateTime.now().difference(_startedAt!) > _giveUpAfter) {
      setState(() => _stage = _Stage.slow);
      return;
    }
    try {
      _onAnalysis(await ref.read(aiRepositoryProvider).mealAnalysis(current.id));
    } on Object {
      // Falha momentânea de rede: tenta de novo no próximo ciclo.
      if (mounted) _timer = Timer(_pollEvery, _poll);
    }
  }

  void _checkAgain() {
    _startedAt = DateTime.now();
    setState(() => _stage = _Stage.analyzing);
    _poll();
  }

  Future<void> _review() async {
    final analysis = _analysis!;
    final saved = await context.push<bool>(
      AppRoutes.photoReview,
      extra: PhotoReview(analysisId: analysis.id, items: analysis.items),
    );
    if (saved == true && mounted) context.pop(true);
  }

  Future<void> _discard() async {
    final analysis = _analysis;
    if (analysis != null) {
      try {
        await ref.read(aiRepositoryProvider).discardMealAnalysis(analysis.id);
      } on Object {
        // A foto é apagada automaticamente pelo servidor após o prazo de retenção.
      }
    }
    if (mounted) context.pop();
  }

  void _describe(String text) {
    _description = text;
    _upload();
  }

  void _chooseAnother() {
    _timer?.cancel();
    setState(() {
      _analysis = null;
      _startedAt = null;
      _path = null;
      _stage = _Stage.choose;
    });
  }

  void _manual() => context.pushReplacement(AppRoutes.newMeal);

  @override
  Widget build(BuildContext context) {
    final busy = _stage == _Stage.uploading || _stage == _Stage.analyzing;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.textMode ? 'Refeição por texto ou voz' : 'Refeição por foto'),
        actions: [
          if (!busy)
            const Padding(
              padding: EdgeInsets.only(right: Space.lg),
              child: Center(child: AiBadge(label: 'IA')),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : Motion.medium,
        child: KeyedSubtree(
          key: ValueKey(_stage),
          child: switch (_stage) {
            _Stage.choose => widget.textMode
                ? DescribeMealView(initial: _description, onSubmit: _describe, onManual: _manual)
                : _ChooseView(onPick: _pick, onManual: _manual),
            _Stage.preview => _PreviewView(
              path: _path!,
              onConfirm: _upload,
              onChooseAnother: _chooseAnother,
            ),
            _Stage.uploading => _ProcessingView(
              path: _path,
              title: widget.textMode ? 'Enviando descrição' : 'Enviando foto',
              message: widget.textMode
                  ? 'Aguarde um instante.'
                  : 'Aguarde enquanto a foto é enviada com segurança.',
              progress: _progress,
            ),
            _Stage.analyzing => _ProcessingView(
              path: _path,
              title: _analysis?.status == 'processing' ? 'Identificando alimentos' : 'Foto recebida',
              message: _analysis?.status == 'processing'
                  ? 'Estimando alimentos e porções. Costuma levar alguns segundos.'
                  : 'A análise vai começar em instantes.',
            ),
            _Stage.slow => _Problem(
              icon: Icons.hourglass_bottom,
              title: 'A análise está demorando',
              message: 'Você pode verificar novamente ou registrar a refeição manualmente.',
              primaryLabel: 'Verificar novamente',
              onPrimary: _checkAgain,
              onManual: _manual,
            ),
            _Stage.uploadFailed => _Problem(
              icon: Icons.cloud_off_outlined,
              title: widget.textMode ? 'A descrição não foi enviada' : 'A foto não foi enviada',
              message: _uploadError ?? 'Verifique sua conexão e tente novamente.',
              primaryLabel: 'Tentar novamente',
              // Mesma foto e mesmo identificador: não duplica a análise.
              onPrimary: () => _upload(newAttempt: false),
              onSecondary: _chooseAnother,
              secondaryLabel: widget.textMode ? 'Editar descrição' : 'Escolher outra foto',
              onManual: _manual,
            ),
            _Stage.result => _ResultView(
              analysis: _analysis!,
              path: _path,
              onReview: _review,
              onDiscard: _discard,
              onRetrySame: _upload,
              onChooseAnother: _chooseAnother,
              onManual: _manual,
              textMode: widget.textMode,
            ),
          },
        ),
      ),
    );
  }
}

class _ChooseView extends ConsumerWidget {
  const _ChooseView({required this.onPick, required this.onManual});

  final ValueChanged<ImageSource> onPick;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(aiStatusProvider);
    return AsyncValueView<AiStatus>(
      value: status,
      onRetry: () => ref.invalidate(aiStatusProvider),
      data: (s) {
        final photo = s.photoAnalysis;
        if (!photo.available) {
          return EmptyState(
            icon: Icons.no_photography_outlined,
            title: 'Análise por foto indisponível',
            message: 'Este recurso não está disponível no momento. Você pode registrar a refeição manualmente.',
            actionLabel: 'Registrar manualmente',
            onAction: onManual,
          );
        }
        if (!photo.hasQuota) {
          return EmptyState(
            icon: Icons.event_busy_outlined,
            title: 'Limite diário atingido',
            message: 'Você usou todas as análises por foto do seu plano hoje. O limite renova à meia-noite.',
            actionLabel: 'Registrar manualmente',
            onAction: onManual,
          );
        }
        final p = context.pic;
        return ListView(
          padding: const EdgeInsets.all(Space.page),
          children: [
            Container(
              padding: const EdgeInsets.all(Space.xl),
              decoration: BoxDecoration(color: p.aiContainer, borderRadius: Radii.card),
              child: Column(
                children: [
                  Icon(Icons.photo_camera_outlined, size: 40, color: p.ai),
                  const SizedBox(height: Space.md),
                  Text(
                    'Fotografe o prato de cima',
                    style: context.text.titleMedium?.copyWith(color: p.onAiContainer),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    'Com boa luz e todos os alimentos visíveis. Você revisa tudo antes de salvar.',
                    style: context.text.bodyMedium?.copyWith(color: p.onAiContainer),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.xl),
            FilledButton.icon(
              onPressed: () => onPick(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Tirar foto'),
            ),
            const SizedBox(height: Space.md),
            OutlinedButton.icon(
              onPressed: () => onPick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Escolher da galeria'),
            ),
            if (photo.quotaLabel != null) ...[
              const SizedBox(height: Space.lg),
              Text(photo.quotaLabel!, style: context.text.bodySmall, textAlign: TextAlign.center),
            ],
            const SizedBox(height: Space.xl),
            Text(photo.disclaimer, style: context.text.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: Space.sm),
            Text(
              'A foto é usada apenas para esta análise e apagada após a confirmação ou em até 24 horas.',
              style: context.text.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}

/// Foto escolhida, com bordas arredondadas e decodificada em tamanho reduzido.
class _Photo extends StatelessWidget {
  const _Photo({required this.path, this.height = 280, this.dimmed = false});

  final String path;
  final double height;
  final bool dimmed;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'Foto da refeição',
    child: ClipRRect(
      borderRadius: Radii.card,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          cacheWidth: 900,
          color: dimmed ? Colors.black.withValues(alpha: 0.25) : null,
          colorBlendMode: dimmed ? BlendMode.darken : null,
          errorBuilder: (_, _, _) => ColoredBox(
            color: context.pic.surfaceMuted,
            child: const Center(child: Icon(Icons.broken_image_outlined)),
          ),
        ),
      ),
    ),
  );
}

class _PreviewView extends StatelessWidget {
  const _PreviewView({required this.path, required this.onConfirm, required this.onChooseAnother});

  final String path;
  final VoidCallback onConfirm;
  final VoidCallback onChooseAnother;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(Space.page),
    children: [
      _Photo(path: path, height: 320),
      const SizedBox(height: Space.lg),
      Text('A foto está boa?', style: context.text.titleMedium),
      const SizedBox(height: Space.xs),
      Text(
        'Confira se todos os alimentos aparecem e se a imagem está nítida. '
        'Depois de enviar, a IA estima alimentos, porções, calorias e macronutrientes.',
        style: context.text.bodyMedium?.copyWith(color: context.pic.textSecondary),
      ),
      const SizedBox(height: Space.xl),
      FilledButton.icon(
        onPressed: onConfirm,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Analisar foto'),
      ),
      const SizedBox(height: Space.sm),
      TextButton(onPressed: onChooseAnother, child: const Text('Escolher outra foto')),
    ],
  );
}

class _ProcessingView extends StatelessWidget {
  const _ProcessingView({required this.title, required this.message, this.path, this.progress});

  final String title;
  final String message;
  final String? path;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final p = context.pic;
    return ListView(
      padding: const EdgeInsets.all(Space.page),
      children: [
        if (path != null)
          Stack(
            alignment: Alignment.center,
            children: [
              _Photo(path: path!, height: 240, dimmed: true),
              Container(
                padding: const EdgeInsets.all(Space.md),
                decoration: BoxDecoration(color: p.aiContainer, shape: BoxShape.circle),
                child: SizedBox.square(
                  dimension: 36,
                  child: CircularProgressIndicator(
                    value: progress == null || progress == 0 ? null : progress,
                    strokeWidth: 3,
                    color: p.ai,
                    semanticsLabel: title,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: Space.xl),
        Semantics(
          liveRegion: true,
          child: Text(title, style: context.text.titleMedium, textAlign: TextAlign.center),
        ),
        const SizedBox(height: Space.xs),
        Text(
          message,
          style: context.text.bodyMedium?.copyWith(color: p.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.analysis,
    required this.onReview,
    required this.onDiscard,
    required this.onRetrySame,
    required this.onChooseAnother,
    required this.onManual,
    this.path,
    this.textMode = false,
  });

  final bool textMode;
  final MealAnalysis analysis;
  final String? path;
  final VoidCallback onReview;
  final VoidCallback onDiscard;
  final VoidCallback onRetrySame;
  final VoidCallback onChooseAnother;
  final VoidCallback onManual;

  /// Confiança baixa em todos os itens: sugerir revisão cuidadosa.
  bool get _lowConfidence =>
      analysis.items.isNotEmpty && analysis.items.every((i) => (i.aiConfidence ?? 1) < 0.45);

  @override
  Widget build(BuildContext context) {
    if (analysis.isFailed) {
      return _Problem(
        icon: Icons.error_outline,
        title: textMode ? 'Não foi possível analisar a descrição' : 'Não foi possível analisar a foto',
        message: analysis.errorMessage ?? 'Tente novamente ou registre a refeição manualmente.',
        primaryLabel: 'Tentar novamente',
        onPrimary: onRetrySame,
        secondaryLabel: textMode ? 'Editar descrição' : 'Escolher outra foto',
        onSecondary: onChooseAnother,
        onManual: onManual,
      );
    }
    if (analysis.notFood || analysis.items.isEmpty) {
      return _Problem(
        icon: Icons.image_not_supported_outlined,
        title: 'Nenhum alimento identificado',
        message: analysis.notes.isNotEmpty
            ? analysis.notes.join('\n')
            : textMode
            ? 'Descreva os alimentos e as quantidades, por exemplo: "2 ovos mexidos e 1 pão francês".'
            : 'Tente outra foto, com o prato inteiro visível e boa iluminação, ou informe os alimentos manualmente.',
        primaryLabel: textMode ? 'Editar descrição' : 'Escolher outra foto',
        onPrimary: onChooseAnother,
        onManual: onManual,
      );
    }

    final totals = analysis.totals ?? const Nutrients();
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, Space.xxl),
      children: [
        if (path != null) ...[_Photo(path: path!, height: 180), const SizedBox(height: Space.lg)],
        if (analysis.description != null) ...[
          AppCard(
            color: context.pic.surfaceMuted,
            child: Text('“${analysis.description}”', style: context.text.bodyMedium),
          ),
          const SizedBox(height: Space.lg),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Estimativa da refeição', style: context.text.titleMedium)),
                  const AiBadge(label: 'Estimativa'),
                ],
              ),
              const SizedBox(height: Space.md),
              MetricValue(value: Fmt.integer(totals.energyKcal), unit: 'kcal', large: true),
              const SizedBox(height: Space.lg),
              MacroSummary(proteinG: totals.proteinG, carbsG: totals.carbsG, fatG: totals.fatG),
            ],
          ),
        ),
        const SizedBox(height: Space.md),
        StatusBanner(tone: BannerTone.ai, message: analysis.disclaimer),
        if (analysis.lowQuality || _lowConfidence) ...[
          const SizedBox(height: Space.sm),
          StatusBanner(
            tone: BannerTone.warning,
            title: 'Revise com atenção',
            message: analysis.lowQuality
                ? 'A foto tem pouca nitidez ou iluminação; a estimativa pode ser menos precisa.'
                : 'A IA teve pouca confiança na identificação. Se preferir, informe os alimentos manualmente.',
            actionLabel: 'Registrar manualmente',
            onAction: onManual,
          ),
        ],
        const SectionHeader(title: 'Alimentos identificados'),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: Space.xs),
          child: Column(
            children: [
              for (final (index, item) in analysis.items.indexed) ...[
                if (index > 0) const Divider(indent: Space.lg, endIndent: Space.lg),
                ListTile(
                  title: Text(item.name),
                  subtitle: Text('${item.quantityLabel} · ${Fmt.kcal(item.nutrients.energyKcal)}'),
                  trailing: item.aiConfidence == null
                      ? null
                      : _ConfidenceLabel(confidence: item.aiConfidence!),
                ),
              ],
            ],
          ),
        ),
        if (analysis.notes.isNotEmpty) ...[
          const SectionHeader(title: 'Observações da análise'),
          for (final note in analysis.notes)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Icon(Icons.info_outline, size: 16, color: context.pic.textSecondary),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(child: Text(note, style: context.text.bodyMedium)),
                ],
              ),
            ),
        ],
        const SizedBox(height: Space.xl),
        FilledButton.icon(
          onPressed: onReview,
          icon: const Icon(Icons.edit_note),
          label: const Text('Revisar e salvar'),
        ),
        const SizedBox(height: Space.sm),
        TextButton(onPressed: onDiscard, child: const Text('Descartar análise')),
      ],
    );
  }
}

class _ConfidenceLabel extends StatelessWidget {
  const _ConfidenceLabel({required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final (label, dots) = switch (confidence) {
      >= 0.75 => ('Confiança alta', 3),
      >= 0.45 => ('Confiança média', 2),
      _ => ('Confiança baixa', 1),
    };
    final p = context.pic;
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    margin: const EdgeInsets.only(left: 3),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i < dots ? p.ai : p.border,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label.replaceFirst('Confiança ', ''), style: context.text.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onManual,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(Space.page),
    children: [
      const SizedBox(height: Space.xl),
      EmptyState(icon: icon, title: title, message: message),
      const SizedBox(height: Space.md),
      FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
      if (secondaryLabel != null) ...[
        const SizedBox(height: Space.sm),
        OutlinedButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
      ],
      const SizedBox(height: Space.sm),
      TextButton(onPressed: onManual, child: const Text('Registrar manualmente')),
    ],
  );
}

/// Descrição da refeição por texto, com ditado por voz no aparelho
/// (o áudio não sai do celular; só o texto reconhecido é enviado).
class DescribeMealView extends ConsumerStatefulWidget {
  const DescribeMealView({
    super.key,
    required this.onSubmit,
    required this.onManual,
    this.initial,
  });

  final ValueChanged<String> onSubmit;
  final VoidCallback onManual;
  final String? initial;

  @override
  ConsumerState<DescribeMealView> createState() => _DescribeMealViewState();
}

class _DescribeMealViewState extends ConsumerState<DescribeMealView> {
  late final _text = TextEditingController(text: widget.initial);
  final _speech = SpeechToText();
  bool _speechReady = false;
  bool _listening = false;

  @override
  void dispose() {
    _speech.cancel();
    _text.dispose();
    super.dispose();
  }

  Future<void> _toggleVoice() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    try {
      _speechReady = _speechReady ||
          await _speech.initialize(
            onStatus: (status) {
              if (mounted && (status == 'done' || status == 'notListening')) {
                setState(() => _listening = false);
              }
            },
            onError: (_) {
              if (mounted) setState(() => _listening = false);
            },
          );
    } on Object {
      _speechReady = false;
    }
    if (!mounted) return;
    if (!_speechReady) {
      showMessage(
        context,
        'Reconhecimento de voz indisponível. Verifique a permissão do microfone ou digite a refeição.',
      );
      return;
    }
    final before = _text.text.trim();
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        final words = result.recognizedWords;
        _text.text = before.isEmpty ? words : '$before $words';
        _text.selection = TextSelection.collapsed(offset: _text.text.length);
      },
      listenOptions: SpeechListenOptions(
        localeId: 'pt_BR',
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 4),
        partialResults: true,
      ),
    );
  }

  void _submit() {
    final text = _text.text.trim();
    if (text.length < 3) {
      showMessage(context, 'Descreva os alimentos da refeição.');
      return;
    }
    _speech.stop();
    widget.onSubmit(text);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(aiStatusProvider);
    final p = context.pic;
    return AsyncValueView<AiStatus>(
      value: status,
      onRetry: () => ref.invalidate(aiStatusProvider),
      data: (s) {
        final feature = s.textAnalysis;
        if (!feature.available) {
          return EmptyState(
            icon: Icons.edit_off_outlined,
            title: 'Registro por texto indisponível',
            message: 'Este recurso não está disponível no momento. Você pode registrar a refeição manualmente.',
            actionLabel: 'Registrar manualmente',
            onAction: widget.onManual,
          );
        }
        if (!feature.hasQuota) {
          return EmptyState(
            icon: Icons.event_busy_outlined,
            title: 'Limite diário atingido',
            message: 'Você usou todos os registros por texto do seu plano hoje. O limite renova à meia-noite.',
            actionLabel: 'Registrar manualmente',
            onAction: widget.onManual,
          );
        }
        return ListView(
          padding: const EdgeInsets.all(Space.page),
          children: [
            Text('O que você comeu?', style: context.text.titleLarge),
            const SizedBox(height: Space.xs),
            Text(
              'Escreva ou dite os alimentos e, se souber, as quantidades. '
              'Ex.: "2 ovos mexidos, 1 pão francês e café com leite".',
              style: context.text.bodyMedium?.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: Space.lg),
            TextField(
              controller: _text,
              minLines: 4,
              maxLines: 8,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Descreva a refeição'),
            ),
            const SizedBox(height: Space.sm),
            OutlinedButton.icon(
              onPressed: _toggleVoice,
              style: OutlinedButton.styleFrom(
                foregroundColor: _listening ? p.ai : null,
                side: BorderSide(color: _listening ? p.ai : p.border, width: 1.2),
              ),
              icon: Icon(_listening ? Icons.stop_circle_outlined : Icons.mic_none_rounded),
              label: Text(_listening ? 'Parar de ouvir' : 'Ditar por voz'),
            ),
            if (_listening)
              Padding(
                padding: const EdgeInsets.only(top: Space.sm),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    'Ouvindo… fale os alimentos da refeição.',
                    style: context.text.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            const SizedBox(height: Space.xl),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Estimar refeição'),
            ),
            if (feature.quotaLabel != null) ...[
              const SizedBox(height: Space.md),
              Text(feature.quotaLabel!, style: context.text.bodySmall, textAlign: TextAlign.center),
            ],
            const SizedBox(height: Space.lg),
            Text(feature.disclaimer, style: context.text.bodySmall, textAlign: TextAlign.center),
          ],
        );
      },
    );
  }
}
