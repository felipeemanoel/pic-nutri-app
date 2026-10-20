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
import '../../assistant/presentation/chat_page.dart';
import '../data/food_repository.dart';
import '../data/nutrition_models.dart';
import 'favorite_meal_action.dart';
import 'food_picker_sheet.dart';
import 'item_sheets.dart';

/// Criação e edição de refeição. Os totais exibidos são uma prévia; a API
/// recalcula e grava os valores oficiais.
class MealEditorPage extends ConsumerStatefulWidget {
  const MealEditorPage({
    super.key,
    this.meal,
    this.initialItems,
    this.photoAnalysisId,
    this.repeatFrom,
  });

  /// Refeição existente (edição).
  final Meal? meal;

  /// Refeição usada como base para um NOVO registro ("Repetir refeição"):
  /// alimentos, quantidades e tipo vêm preenchidos; a original não muda.
  final Meal? repeatFrom;

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
  late final _title = TextEditingController(text: widget.meal?.title ?? widget.repeatFrom?.title);
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
    _type = widget.meal?.mealType ?? MealTypes.suggestFor(_eatenAt);
    final base = widget.repeatFrom;
    if (base != null) {
      // Dia selecionado no diário, no mesmo horário da refeição original (nunca no futuro).
      final at = DateTime(selected.year, selected.month, selected.day, base.eatenAt.hour, base.eatenAt.minute);
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

  /// Ações do item: editar, pedir substituições ao assistente ou remover.
  Future<void> _itemActions(int index) async {
    final item = _items[index];
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
              title: const Text('Sugerir substituições'),
              subtitle: const Text(
                'Pergunte ao assistente, considerando suas preferências',
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
          extra: ChatDraft(
            'Quais substituições posso fazer para "${item.name}" (${item.quantityLabel}) '
            'nesta refeição, considerando minhas metas, preferências e restrições?',
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isRepeat) ...[
            StatusBanner(
              tone: BannerTone.info,
              icon: Icons.replay_rounded,
              title: 'Novo registro em ${Fmt.fullDate(_eatenAt)}',
              message:
                  'Revise alimentos, quantidades, tipo, data e horário. '
                  'Nada é salvo até você tocar em "Registrar refeição", e a refeição original não muda.',
            ),
            const SizedBox(height: Space.md),
          ],
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Tipo de refeição'),
            items: [
              for (final e in MealTypes.labels.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Nome personalizado (opcional)',
              hintText: 'Ex.: Pré-treino',
            ),
            maxLength: 80,
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
          const Divider(),
          Row(
            children: [
              Expanded(
                child: Text('Alimentos', style: theme.textTheme.titleMedium),
              ),
              Text(
                Fmt.kcal(preview.energyKcal),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          Text(
            'P ${Fmt.grams(preview.proteinG)} · C ${Fmt.grams(preview.carbsG)} · G ${Fmt.grams(preview.fatG)}',
            style: theme.textTheme.bodySmall,
          ),
          if (hasAi)
            const Padding(
              padding: EdgeInsets.only(top: Space.sm),
              child: StatusBanner(
                tone: BannerTone.ai,
                message:
                    'Itens com o selo de IA são estimativas feitas a partir da foto. '
                    'Toque em um item para corrigir porções e valores antes de salvar.',
              ),
            ),
          const SizedBox(height: 8),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Nenhum alimento adicionado.'),
            ),
          for (var i = 0; i < _items.length; i++)
            Dismissible(
              key: ObjectKey(_items[i]),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
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
                subtitle: Text(
                  '${_items[i].quantityLabel} · ${Fmt.kcal(_items[i].nutrients.energyKcal)}',
                ),
                trailing: IconButton(
                  tooltip: 'Remover',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _items.removeAt(i)),
                ),
                onTap: () => _editItem(i),
                onLongPress: () => _itemActions(i),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addFromDatabase,
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar alimento'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addManual,
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Item manual'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(
              labelText: 'Observações (opcional)',
            ),
            maxLength: 500,
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          LoadingButton(
            label: _isEdit ? 'Salvar refeição' : 'Registrar refeição',
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
