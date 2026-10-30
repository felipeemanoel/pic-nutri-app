import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/request_id.dart';
import '../../../shared/state/refresh.dart';
import '../../../shared/validators.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/application/session_controller.dart';
import '../data/activity_models.dart';
import '../data/activity_repository.dart';
import '../domain/activity_math.dart';
import '../domain/activity_visuals.dart';

/// Nova meta (ou edição): modalidade, academia/local, vezes por semana,
/// dias, horário, duração e lembrete.
Future<void> showActivityPlanForm(BuildContext context, {ActivityPlan? plan}) =>
    _sheet(context, _PlanForm(plan: plan));

/// Registrar treino (ou editar). Pode vir de uma meta ou de um evento.
Future<void> showActivitySessionForm(
  BuildContext context, {
  ActivitySession? session,
  ActivityPlan? plan,
  ActivityEvent? event,
}) => _sheet(context, _SessionForm(session: session, plan: plan, event: event));

/// Novo evento (corrida de rua, passeio, aulão...) ou edição.
Future<void> showActivityEventForm(
  BuildContext context, {
  ActivityEvent? event,
}) => _sheet(context, _EventForm(event: event));

Future<void> _sheet(BuildContext context, Widget child) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => FractionallySizedBox(heightFactor: 0.94, child: child),
    );

// ---------------------------------------------------------------- comuns

/// Estrutura dos formulários: título, conteúdo rolável e botão fixo.
class _FormScaffold extends StatelessWidget {
  const _FormScaffold({
    required this.title,
    required this.children,
    required this.saveLabel,
    required this.saving,
    required this.onSave,
    this.formKey,
    this.extraActions = const [],
  });

  final String title;
  final List<Widget> children;
  final String saveLabel;
  final bool saving;
  final VoidCallback onSave;
  final GlobalKey<FormState>? formKey;
  final List<Widget> extraActions;

  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.page,
            0,
            Space.page,
            Space.sm,
          ),
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Space.page,
              Space.sm,
              Space.page,
              Space.xl,
            ),
            children: children,
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              Space.page,
              Space.sm,
              Space.page,
              Space.md + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LoadingButton(
                  label: saveLabel,
                  loading: saving,
                  onPressed: onSave,
                ),
                ...extraActions,
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.hint});

  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Space.lg, bottom: Space.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (hint != null)
          Text(
            hint!,
            style: context.text.bodySmall?.copyWith(
              color: context.pic.textSecondary,
            ),
          ),
      ],
    ),
  );
}

/// Grade de modalidades com ícone.
class _TypePicker extends StatelessWidget {
  const _TypePicker({
    required this.types,
    required this.value,
    required this.onChanged,
  });

  final List<ActivityTypeOption> types;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Space.sm,
    runSpacing: Space.sm,
    children: [
      for (final t in types)
        ChoiceChip(
          avatar: Icon(
            ActivityVisuals.icon(t.value),
            size: 18,
            color: value == t.value
                ? context.pic.onBrandContainer
                : ActivityVisuals.color(t.value),
          ),
          label: Text(t.label),
          showCheckmark: false,
          selected: value == t.value,
          onSelected: (_) => onChanged(t.value),
        ),
    ],
  );
}

/// Linha de opções numéricas rápidas ("30", "45", "60"...).
class _QuickNumbers extends StatelessWidget {
  const _QuickNumbers({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<int> values;
  final int? selected;
  final String Function(int) label;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Space.sm,
    runSpacing: Space.sm,
    children: [
      for (final v in values)
        ChoiceChip(
          label: Text(label(v)),
          selected: selected == v,
          onSelected: (_) => onSelected(v),
        ),
    ],
  );
}

String? _clean(String text) => text.trim().isEmpty ? null : text.trim();

String _hhmm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

// ---------------------------------------------------------------- meta

class _PlanForm extends ConsumerStatefulWidget {
  const _PlanForm({this.plan});

  final ActivityPlan? plan;

  @override
  ConsumerState<_PlanForm> createState() => _PlanFormState();
}

class _PlanFormState extends ConsumerState<_PlanForm> {
  final _requestId = newRequestId();
  late String? _type = widget.plan?.type;
  late final _title = TextEditingController(text: widget.plan?.title);
  late final _location = TextEditingController(text: widget.plan?.location);
  late int _times = widget.plan?.timesPerWeek ?? 3;
  late final Set<int> _days = {...?widget.plan?.days};
  late String? _time = widget.plan?.time;
  late int? _duration = widget.plan?.durationMin ?? 60;
  late bool _reminder = widget.plan?.reminderEnabled ?? true;
  bool _saving = false;

  bool get _isEdit => widget.plan != null;

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final parts = (_time ?? '07:00').split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
    );
    if (picked != null) setState(() => _time = _hhmm(picked));
  }

  Future<void> _save() async {
    if (_type == null) {
      showMessage(context, 'Escolha a atividade.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(activityRepositoryProvider)
          .savePlan(
            id: widget.plan?.id,
            type: _type!,
            timesPerWeek: _times,
            title: _clean(_title.text),
            location: _clean(_location.text),
            days: (_days.toList()..sort()),
            time: _time,
            durationMin: _duration,
            reminderEnabled: _time != null && _reminder,
            requestId: _isEdit ? null : _requestId,
          );
      Refresh.activity(ref);
      if (!mounted) return;
      showMessage(
        context,
        _isEdit ? 'Meta atualizada.' : 'Meta criada. Bons treinos!',
      );
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _togglePause() async {
    final plan = widget.plan!;
    setState(() => _saving = true);
    try {
      await ref
          .read(activityRepositoryProvider)
          .setPlanActive(plan.id, active: !plan.isActive);
      Refresh.activity(ref);
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmAction(
      context,
      title: 'Excluir meta?',
      message: 'Os treinos já registrados continuam no seu histórico.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref.read(activityRepositoryProvider).deletePlan(widget.plan!.id);
      Refresh.activity(ref);
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(activityOptionsProvider);
    return AsyncValueView<ActivityOptions>(
      value: options,
      onRetry: () => ref.invalidate(activityOptionsProvider),
      data: (o) {
        final hasDays = _days.isNotEmpty;
        return _FormScaffold(
          title: _isEdit ? 'Editar meta' : 'Nova meta de atividade',
          saveLabel: _isEdit ? 'Salvar meta' : 'Criar meta',
          saving: _saving,
          onSave: _save,
          extraActions: [
            if (_isEdit) ...[
              const SizedBox(height: Space.xs),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _saving ? null : _togglePause,
                      icon: Icon(
                        widget.plan!.isActive
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                      ),
                      label: Text(
                        widget.plan!.isActive ? 'Pausar meta' : 'Retomar meta',
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _saving ? null : _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Excluir'),
                    ),
                  ),
                ],
              ),
            ],
          ],
          children: [
            const _Label('Qual atividade?'),
            _TypePicker(
              types: o.types,
              value: _type,
              onChanged: (v) => setState(() => _type = v),
            ),
            const _Label(
              'Onde?',
              hint: 'Opcional. Aparece no cartão da meta e no lembrete.',
            ),
            TextFormField(
              controller: _title,
              maxLength: 80,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome (ex.: Academia Smart Fit, Treino de corrida)',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
            ),
            TextFormField(
              controller: _location,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Local (opcional)',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const _Label('Quantas vezes por semana?'),
            _QuickNumbers(
              values: const [1, 2, 3, 4, 5, 6, 7],
              selected: _times,
              label: (v) => '${v}x',
              onSelected: (v) => setState(() => _times = v),
            ),
            _Label(
              'Em quais dias?',
              hint: hasDays
                  ? null
                  : 'Opcional. Sem dias marcados, vale qualquer dia da semana.',
            ),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                for (final d in ActivityVisuals.weekdays.entries)
                  FilterChip(
                    label: Text(d.value),
                    selected: _days.contains(d.key),
                    onSelected: (v) => setState(() {
                      v ? _days.add(d.key) : _days.remove(d.key);
                      if (_days.length > _times) _times = _days.length;
                    }),
                  ),
              ],
            ),
            const _Label('Horário'),
            Material(
              color: context.pic.surfaceMuted,
              borderRadius: BorderRadius.circular(Radii.lg),
              child: ListTile(
                leading: const Icon(Icons.schedule_rounded),
                title: Text(_time ?? 'Sem horário definido'),
                subtitle: const Text('Toque para escolher'),
                trailing: _time == null
                    ? const Icon(Icons.chevron_right)
                    : IconButton(
                        tooltip: 'Remover horário',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _time = null),
                      ),
                onTap: _pickTime,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Lembrar no horário'),
              subtitle: Text(
                _time == null
                    ? 'Escolha um horário para receber o lembrete.'
                    : hasDays
                    ? 'Nos dias marcados, às $_time.'
                    : 'Todos os dias, às $_time.',
              ),
              value: _time != null && _reminder,
              onChanged: _time == null
                  ? null
                  : (v) => setState(() => _reminder = v),
            ),
            const _Label('Duração de cada treino'),
            _QuickNumbers(
              values: const [30, 45, 60, 90, 120],
              selected: _duration,
              label: ActivityMath.duration,
              onSelected: (v) => setState(() => _duration = v),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------- treino

class _SessionForm extends ConsumerStatefulWidget {
  const _SessionForm({this.session, this.plan, this.event});

  final ActivitySession? session;
  final ActivityPlan? plan;
  final ActivityEvent? event;

  @override
  ConsumerState<_SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends ConsumerState<_SessionForm> {
  final _requestId = newRequestId();
  late String? _type =
      widget.session?.type ?? widget.plan?.type ?? widget.event?.type;
  late String? _planId = widget.session?.planId ?? widget.plan?.id;
  late final String? _eventId = widget.session?.eventId ?? widget.event?.id;
  late DateTime _at =
      widget.session?.performedAt ??
      (widget.event != null && widget.event!.startsAt.isBefore(DateTime.now())
          ? widget.event!.startsAt
          : DateTime.now());
  late int _duration =
      widget.session?.durationMin ?? widget.plan?.durationMin ?? 45;
  late String? _intensity = widget.session?.intensity ?? 'moderate';
  late final _distance = TextEditingController(
    text: (widget.session?.distanceKm ?? widget.event?.distanceKm) == null
        ? ''
        : Fmt.decimal(
            (widget.session?.distanceKm ?? widget.event?.distanceKm)!,
          ),
  );
  late final _customDuration = TextEditingController();
  late final _title = TextEditingController(
    text: widget.session?.title ?? widget.event?.name,
  );
  late final _notes = TextEditingController(text: widget.session?.notes);
  bool _saving = false;

  bool get _isEdit => widget.session != null;

  @override
  void dispose() {
    _distance.dispose();
    _customDuration.dispose();
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickWhen() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _at,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_at),
    );
    if (time == null) return;
    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(
      () => _at = picked.isAfter(DateTime.now()) ? DateTime.now() : picked,
    );
  }

  Future<void> _save(ActivityOptions options) async {
    if (_type == null) {
      showMessage(context, 'Escolha a atividade.');
      return;
    }
    final custom = int.tryParse(_customDuration.text.trim());
    final duration = custom ?? _duration;
    if (duration < 1 || duration > 600) {
      showMessage(context, 'Informe a duração em minutos (1 a 600).');
      return;
    }
    final supportsDistance = options.type(_type!)?.supportsDistance ?? false;
    setState(() => _saving = true);
    try {
      await ref
          .read(activityRepositoryProvider)
          .saveSession(
            id: widget.session?.id,
            type: _type!,
            durationMin: duration,
            performedAt: _at,
            planId: _planId,
            eventId: _eventId,
            title: _clean(_title.text),
            intensity: _intensity,
            distanceKm: supportsDistance
                ? Validators.parseNumber(_distance.text)
                : null,
            notes: _clean(_notes.text),
            requestId: _isEdit ? null : _requestId,
          );
      Refresh.activity(ref);
      if (!mounted) return;
      showMessage(
        context,
        _isEdit ? 'Treino atualizado.' : 'Treino registrado. Mandou bem!',
      );
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmAction(
      context,
      title: 'Excluir treino?',
      message: 'O registro sai do histórico e da contagem da semana.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(activityRepositoryProvider)
          .deleteSession(widget.session!.id);
      Refresh.activity(ref);
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(activityOptionsProvider);
    final plans =
        ref.watch(activityPlansProvider).value ?? const <ActivityPlan>[];
    final weight = ref.watch(currentAccountProvider)?.profile.currentWeightKg;
    return AsyncValueView<ActivityOptions>(
      value: options,
      onRetry: () => ref.invalidate(activityOptionsProvider),
      data: (o) {
        final type = _type == null ? null : o.type(_type!);
        final custom = int.tryParse(_customDuration.text.trim());
        final duration = custom ?? _duration;
        final kcal = ActivityMath.estimatedKcal(
          type: type,
          durationMin: duration,
          weightKg: weight,
          intensity: o.intensity(_intensity),
        );
        final pace = type?.supportsDistance ?? false
            ? ActivityMath.pace(
                duration,
                Validators.parseNumber(_distance.text),
              )
            : null;
        final samePlans = [
          for (final p in plans)
            if (p.isActive && p.type == _type) p,
        ];
        return _FormScaffold(
          title: widget.event != null
              ? 'Participação no evento'
              : _isEdit
              ? 'Editar treino'
              : 'Registrar treino',
          saveLabel: _isEdit ? 'Salvar' : 'Registrar',
          saving: _saving,
          onSave: () => _save(o),
          extraActions: [
            if (_isEdit)
              TextButton.icon(
                onPressed: _saving ? null : _delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Excluir treino'),
              ),
          ],
          children: [
            if (widget.event != null)
              _InfoBanner(
                icon: Icons.emoji_events_outlined,
                text: widget.event!.name,
              ),
            const _Label('Atividade'),
            _TypePicker(
              types: o.types,
              value: _type,
              onChanged: (v) => setState(() {
                _type = v;
                if (_planId != null &&
                    !plans.any((p) => p.id == _planId && p.type == v)) {
                  _planId = null;
                }
              }),
            ),
            if (samePlans.isNotEmpty && widget.event == null) ...[
              const _Label(
                'Conta para a meta',
                hint: 'Treinos da mesma atividade contam automaticamente.',
              ),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  for (final p in samePlans)
                    ChoiceChip(
                      label: Text(p.displayName),
                      selected: _planId == p.id,
                      onSelected: (v) =>
                          setState(() => _planId = v ? p.id : null),
                    ),
                ],
              ),
            ],
            const _Label('Quando'),
            Material(
              color: context.pic.surfaceMuted,
              borderRadius: BorderRadius.circular(Radii.lg),
              child: ListTile(
                leading: const Icon(Icons.event_outlined),
                title: Text(Fmt.relativeDayTime(_at)),
                trailing: const Icon(Icons.edit_outlined),
                onTap: _pickWhen,
              ),
            ),
            const _Label('Duração'),
            _QuickNumbers(
              values: const [15, 30, 45, 60, 90, 120],
              selected: custom == null ? _duration : null,
              label: ActivityMath.duration,
              onSelected: (v) => setState(() {
                _duration = v;
                _customDuration.clear();
              }),
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _customDuration,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Outra duração',
                suffixText: 'min',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const _Label('Intensidade'),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                for (final i in o.intensities)
                  ButtonSegment(value: i.value, label: Text(i.label)),
              ],
              selected: {?_intensity},
              emptySelectionAllowed: true,
              onSelectionChanged: (v) =>
                  setState(() => _intensity = v.firstOrNull),
            ),
            if (type?.supportsDistance ?? false) ...[
              const _Label('Distância', hint: 'Opcional.'),
              TextField(
                controller: _distance,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Distância',
                  suffixText: 'km',
                  helperText: pace == null ? null : 'Ritmo médio: $pace',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
            if (kcal != null) ...[
              const SizedBox(height: Space.lg),
              _InfoBanner(
                icon: Icons.local_fire_department_outlined,
                text: 'Gasto estimado: cerca de ${Fmt.integer(kcal)} kcal',
                detail:
                    'Referência pelo tipo de atividade, duração, intensidade e seu peso.',
              ),
            ],
            const _Label('Detalhes', hint: 'Opcional.'),
            TextField(
              controller: _title,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nome do treino (ex.: Treino A, Pernas)',
              ),
            ),
            TextField(
              controller: _notes,
              maxLength: 500,
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Observações'),
            ),
          ],
        );
      },
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text, this.detail});

  final IconData icon;
  final String text;
  final String? detail;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Space.md),
    decoration: BoxDecoration(
      color: context.pic.brandContainer,
      borderRadius: BorderRadius.circular(Radii.lg),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: context.pic.onBrandContainer),
        const SizedBox(width: Space.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: context.text.titleSmall?.copyWith(
                  color: context.pic.onBrandContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (detail != null)
                Text(
                  detail!,
                  style: context.text.bodySmall?.copyWith(
                    color: context.pic.onBrandContainer,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------- evento

class _EventForm extends ConsumerStatefulWidget {
  const _EventForm({this.event});

  final ActivityEvent? event;

  @override
  ConsumerState<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends ConsumerState<_EventForm> {
  final _formKey = GlobalKey<FormState>();
  final _requestId = newRequestId();
  late final _name = TextEditingController(text: widget.event?.name);
  late final _location = TextEditingController(text: widget.event?.location);
  late final _url = TextEditingController(text: widget.event?.url);
  late final _notes = TextEditingController(text: widget.event?.notes);
  late final _distance = TextEditingController(
    text: widget.event?.distanceKm == null
        ? ''
        : Fmt.decimal(widget.event!.distanceKm!),
  );
  late String? _type = widget.event?.type ?? 'running';
  late DateTime? _startsAt = widget.event?.startsAt;
  late bool _reminder = widget.event?.reminderEnabled ?? true;
  bool _saving = false;

  bool get _isEdit => widget.event != null;

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _url.dispose();
    _notes.dispose();
    _distance.dispose();
    super.dispose();
  }

  Future<void> _pickWhen() async {
    final now = DateTime.now();
    final initial = _startsAt ?? DateTime(now.year, now.month, now.day + 7, 7);
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    setState(
      () => _startsAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _save(ActivityOptions options) async {
    if (!_formKey.currentState!.validate()) return;
    if (_type == null) {
      showMessage(context, 'Escolha a atividade do evento.');
      return;
    }
    if (_startsAt == null) {
      showMessage(context, 'Escolha a data e o horário do evento.');
      return;
    }
    final url = _clean(_url.text);
    final supportsDistance = options.type(_type!)?.supportsDistance ?? false;
    setState(() => _saving = true);
    try {
      await ref
          .read(activityRepositoryProvider)
          .saveEvent(
            id: widget.event?.id,
            name: _name.text.trim(),
            type: _type!,
            startsAt: _startsAt!,
            location: _clean(_location.text),
            distanceKm: supportsDistance
                ? Validators.parseNumber(_distance.text)
                : null,
            url: url == null || url.startsWith('http') ? url : 'https://$url',
            notes: _clean(_notes.text),
            reminderEnabled: _reminder,
            requestId: _isEdit ? null : _requestId,
          );
      Refresh.activity(ref);
      if (!mounted) return;
      showMessage(
        context,
        _isEdit ? 'Evento atualizado.' : 'Evento adicionado à sua agenda.',
      );
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmAction(
      context,
      title: 'Excluir evento?',
      message: 'Se você registrou a participação, ela continua no histórico.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref.read(activityRepositoryProvider).deleteEvent(widget.event!.id);
      Refresh.activity(ref);
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(activityOptionsProvider);
    return AsyncValueView<ActivityOptions>(
      value: options,
      onRetry: () => ref.invalidate(activityOptionsProvider),
      data: (o) {
        final supportsDistance =
            _type != null && (o.type(_type!)?.supportsDistance ?? false);
        return _FormScaffold(
          formKey: _formKey,
          title: _isEdit ? 'Editar evento' : 'Novo evento',
          saveLabel: _isEdit ? 'Salvar evento' : 'Adicionar evento',
          saving: _saving,
          onSave: () => _save(o),
          extraActions: [
            if (_isEdit)
              TextButton.icon(
                onPressed: _saving ? null : _delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Excluir evento'),
              ),
          ],
          children: [
            TextFormField(
              controller: _name,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nome do evento',
                hintText: 'Ex.: Corrida de Rua Recife 10K',
                prefixIcon: Icon(Icons.emoji_events_outlined),
              ),
              validator: (v) => (v?.trim().length ?? 0) < 2
                  ? 'Informe o nome do evento.'
                  : null,
            ),
            const _Label('Atividade'),
            _TypePicker(
              types: o.types,
              value: _type,
              onChanged: (v) => setState(() => _type = v),
            ),
            const _Label('Data e horário'),
            Material(
              color: context.pic.surfaceMuted,
              borderRadius: BorderRadius.circular(Radii.lg),
              child: ListTile(
                leading: const Icon(Icons.event_outlined),
                title: Text(
                  _startsAt == null
                      ? 'Escolher data e horário'
                      : Fmt.relativeDayTime(_startsAt!),
                ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: _pickWhen,
              ),
            ),
            const SizedBox(height: Space.lg),
            TextFormField(
              controller: _location,
              maxLength: 160,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Local (opcional)',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            if (supportsDistance)
              TextFormField(
                controller: _distance,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Distância (opcional)',
                  suffixText: 'km',
                  prefixIcon: Icon(Icons.straighten_rounded),
                ),
              ),
            if (supportsDistance) const SizedBox(height: Space.lg),
            TextFormField(
              controller: _url,
              keyboardType: TextInputType.url,
              maxLength: 255,
              decoration: const InputDecoration(
                labelText: 'Link do evento ou da inscrição (opcional)',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Lembrar do evento'),
              subtitle: const Text('Na véspera, às 19h, e 2 horas antes.'),
              value: _reminder,
              onChanged: (v) => setState(() => _reminder = v),
            ),
            TextFormField(
              controller: _notes,
              maxLength: 500,
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Observações (kit, largada, meta de tempo...)',
              ),
            ),
          ],
        );
      },
    );
  }
}
