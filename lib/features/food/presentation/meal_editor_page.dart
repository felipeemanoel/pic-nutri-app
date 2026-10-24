import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/request_id.dart';
import '../../../shared/state/refresh.dart';
import '../../../shared/state/selected_date.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../../ai/presentation/meal_photo_page.dart';
import '../../assistant/presentation/chat_page.dart';
import '../data/food_repository.dart';
import '../data/nutrition_models.dart';
import 'favorite_meal_action.dart';
import 'food_picker_sheet.dart';
import 'item_sheets.dart';

/// Criação e edição de refeição. Os totais exibidos são uma prévia; a API
/// recalcula e grava os valores oficiais.
/// Como abrir o editor de uma refeição nova.
enum MealEditorStart { search }

class MealEditorPage extends ConsumerStatefulWidget {
  const MealEditorPage({
    super.key,
    this.meal,
    this.initialItems,
    this.photoAnalysisId,
    this.repeatFrom,
    this.initialTitle,
    this.initialType,
    this.start,
  });

  /// [MealEditorStart.search]: abre direto a busca de alimentos.
  final MealEditorStart? start;

  /// Refeição existente (edição).
  final Meal? meal;

  /// Refeição usada como base para um NOVO registro ("Repetir refeição"):
  /// alimentos, quantidades e tipo vêm preenchidos; a original não muda.
  final Meal? repeatFrom;

  /// Novo registro a partir de outro conteúdo (ex.: "Comi esta receita").
  final String? initialTitle;
  final String? initialType;

  /// Itens pré-preenchidos (ex.: revisão da análise por foto).
  final List<MealItem>? initialItems;
  final String? photoAnalysisId;

  @override
  ConsumerState<MealEditorPage> createState() => _MealEditorPageState();
}

class _MealEditorPageState extends ConsumerState<MealEditorPage> {
  late final _requestId = newRequestId();
  late String _type;
  late DateTime _eatenAt;
  late final _title = TextEditingController(
    text: widget.meal?.title ?? widget.repeatFrom?.title ?? widget.initialTitle,
  );
  late final _notes = TextEditingController(text: widget.meal?.notes);
  late final List<MealItem> _items = [
    ...?widget.meal?.items,
    ...?widget.initialItems,
    ...?widget.repeatFrom?.items,
  ];
  bool _saving = false;

  bool get _isEdit => widget.meal != null;
  bool get _isRepeat => widget.repeatFrom != null;

  @override
  void initState() {
    super.initState();
    final selected = ref.read(selectedDateProvider);
    final now = DateTime.now();
    _eatenAt =
        widget.meal?.eatenAt ??
        (selected == SelectedDate.today()
            ? now
            : DateTime(
                selected.year,
                selected.month,
                selected.day,
                now.hour,
                now.minute,
              ));
    _type =
        widget.meal?.mealType ??
        widget.initialType ??
        MealTypes.suggestFor(_eatenAt);
    if (widget.start == MealEditorStart.search) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _addFromDatabase();
      });
    }
    final base = widget.repeatFrom;
    if (base != null) {
      // Dia selecionado no diário, no mesmo horário da refeição original (nunca no futuro).
      final at = DateTime(
        selected.year,
        selected.month,
        selected.day,
        base.eatenAt.hour,
        base.eatenAt.minute,
      );
      _eatenAt = at.isAfter(now) ? now : at;
      _type = base.mealType;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Nutrients get _preview =>
      _items.fold(const Nutrients(), (sum, i) => sum + i.nutrients);

  Future<void> _addFromDatabase() async {
    final item = await showFoodPicker(context);
    if (item != null) setState(() => _items.add(item));
  }

  Future<void> _addManual() async {
    final item = await showManualItemSheet(context);
    if (item != null) setState(() => _items.add(item));
  }

  Future<void> _editItem(int index) async {
    final current = _items[index];
    final edited = current.food != null
        ? await showQuantitySheet(context, current.food!, initial: current)
        : await showManualItemSheet(context, initial: current);
    if (edited != null) setState(() => _items[index] = edited);
  }

  Future<void> _pickTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eatenAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_eatenAt),
    );
    if (time == null) return;
    setState(
      () => _eatenAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _save() async {
    if (_items.isEmpty) {
      showMessage(context, 'Adicione pelo menos um alimento.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(foodRepositoryProvider)
          .saveMeal(
            id: widget.meal?.id,
            mealType: _type,
            eatenAt: _eatenAt,
            items: _items,
            title: _title.text,
            notes: _notes.text,
            requestId: _isEdit ? null : _requestId,
            photoAnalysisId: widget.photoAnalysisId,
          );
      Refresh.nutrition(ref);
      if (!mounted) return;
      showMessage(
        context,
        _isEdit ? 'Refeição atualizada.' : 'Refeição registrada.',
      );
      context.pop(true);
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveAsFavorite() =>
      saveFavoriteMeal(context, ref, widget.meal!);

  /// Ações do item: editar, consultar metas ou remover.
  Future<void> _itemActions(int index) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar quantidade e valores'),
              onTap: () => Navigator.of(sheet).pop('edit'),
            ),
            ListTile(
              leading: Icon(Icons.auto_awesome_outlined, color: sheet.pic.ai),
              title: const Text('Consultar minhas metas'),
              subtitle: const Text(
                'Veja as metas que você cadastrou no aplicativo',
              ),
              onTap: () => Navigator.of(sheet).pop('swap'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remover da refeição'),
              onTap: () => Navigator.of(sheet).pop('remove'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'edit':
        await _editItem(index);
      case 'swap':
        await context.push(
          AppRoutes.chat,
          extra: const ChatDraft(
            'Quais são minhas metas registradas no PicNutri?',
          ),
        );
      case 'remove':
        setState(() => _items.removeAt(index));
    }
  }

  Future<void> _delete() async {
    final ok = await confirmAction(
      context,
      title: 'Excluir refeição?',
      message:
          'Os alimentos e valores desta refeição serão removidos do diário.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok) return;
    setState(() => _saving = true);
    try {
      await ref.read(foodRepositoryProvider).deleteMeal(widget.meal!.id);
      Refresh.nutrition(ref);
      if (!mounted) return;
      showMessage(context, 'Refeição excluída.');
      context.pop(true);
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _preview;
    final hasAi = _items.any((i) => i.source == 'ai_estimate');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit
              ? 'Editar refeição'
              : _isRepeat
              ? 'Repetir refeição'
              : widget.photoAnalysisId != null
              ? 'Revisar refeição'
              : 'Nova refeição',
        ),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Consultar minha alimentação de hoje',
              icon: Icon(Icons.auto_awesome_outlined, color: context.pic.ai),
              onPressed: () => context.push(
                AppRoutes.chat,
                extra: const ChatDraft('Como foi minha alimentação hoje?'),
              ),
            ),
          if (_isEdit)
            IconButton(
              tooltip: 'Salvar como favorita',
              icon: const Icon(Icons.star_outline_rounded),
              onPressed: _saving ? null : _saveAsFavorite,
            ),
          if (_isEdit)
            IconButton(
              tooltip: 'Excluir refeição',
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      // Registrar sempre visível, mesmo com a lista de alimentos longa.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.page,
            Space.sm,
            Space.page,
            Space.md,
          ),
          child: LoadingButton(
            label: _isEdit ? 'Salvar refeição' : 'Registrar refeição',
            loading: _saving,
            onPressed: _save,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.page,
          Space.md,
          Space.page,
          Space.xxl,
        ),
        children: [
          if (widget.photoAnalysisId != null) ...[
            const AiSteps(current: 2),
            const SizedBox(height: Space.sm),
          ],
          if (_isRepeat) ...[
            StatusBanner(
              tone: BannerTone.info,
              icon: Icons.replay_rounded,
              title: 'Novo registro em ${Fmt.fullDate(_eatenAt)}',
              message:
                  'Revise alimentos, quantidades, tipo, data e horário. '
                  'Nada é salvo até você tocar em "Registrar refeição", e a refeição original não muda.',
            ),
            const SizedBox(height: Space.lg),
          ],
          // Alimentos e quantidades: o centro da tela.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('Alimentos', style: theme.textTheme.titleMedium),
                ),
              ),
              Text(
                Fmt.kcal(preview.energyKcal),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          Text(
            'Proteínas ${Fmt.grams(preview.proteinG)} · Carboidratos ${Fmt.grams(preview.carbsG)} · Gorduras ${Fmt.grams(preview.fatG)}',
            style: theme.textTheme.bodySmall,
          ),
          if (hasAi)
            const Padding(
              padding: EdgeInsets.only(top: Space.sm),
              child: StatusBanner(
                tone: BannerTone.ai,
                message:
                    'Itens com o selo de IA são estimativas. '
                    'Toque em um item para corrigir porções e valores antes de salvar.',
              ),
            ),
          const SizedBox(height: Space.sm),
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.lg),
              child: Text(
                'Nenhum alimento adicionado ainda.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          for (var i = 0; i < _items.length; i++)
            Dismissible(
              key: ObjectKey(_items[i]),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: Space.lg),
                color: theme.colorScheme.errorContainer,
                child: const Icon(Icons.delete_outline),
              ),
              onDismissed: (_) => setState(() => _items.removeAt(i)),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    Flexible(child: Text(_items[i].name)),
                    if (_items[i].source == 'ai_estimate') ...[
                      const SizedBox(width: Space.sm),
                      const AiBadge(label: 'Estimativa', compact: true),
                    ],
                  ],
                ),
                // Quantidade em destaque: é o que mais se ajusta.
                subtitle: Text(
                  '${_items[i].quantityLabel} · ${Fmt.kcal(_items[i].nutrients.energyKcal)}',
                  style: theme.textTheme.bodyMedium,
                ),
                trailing: IconButton(
                  tooltip: 'Remover ${_items[i].name}',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _items.removeAt(i)),
                ),
                onTap: () => _editItem(i),
                onLongPress: () => _itemActions(i),
              ),
            ),
          const SizedBox(height: Space.sm),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _addFromDatabase,
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar alimento'),
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addManual,
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Item manual'),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.section),
          // Quando e qual refeição.
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Tipo de refeição'),
            items: [
              for (final e in MealTypes.labels.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: const Text('Data e horário'),
            subtitle: Text(
              '${Fmt.shortDate(_eatenAt)} às ${Fmt.time(_eatenAt)}',
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: _pickTime,
          ),
          // Opcionais recolhidos: nome personalizado e observações.
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              initiallyExpanded:
                  _title.text.isNotEmpty || _notes.text.isNotEmpty,
              title: Text(
                'Nome e observações (opcional)',
                style: theme.textTheme.bodyLarge,
              ),
              children: [
                TextField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Nome personalizado',
                    hintText: 'Ex.: Pré-treino',
                  ),
                  maxLength: 80,
                ),
                TextField(
                  controller: _notes,
                  decoration: const InputDecoration(labelText: 'Observações'),
                  maxLength: 500,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
