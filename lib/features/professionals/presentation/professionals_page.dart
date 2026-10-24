import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/env.dart';
import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../../notifications/presentation/notification_bell.dart';
import '../application/device_location.dart';
import '../data/professional_models.dart';
import '../data/professional_repository.dart';
import 'professional_widgets.dart';

/// Profissionais: busca entre nutricionistas e profissionais de educação
/// física com registro conferido pela equipe.
class ProfessionalsPage extends ConsumerWidget {
  const ProfessionalsPage({super.key});

  void _update(
    WidgetRef ref,
    ProfessionalFilter Function(ProfessionalFilter f) change,
  ) {
    final notifier = ref.read(professionalFilterProvider.notifier);
    notifier.set(
      change(ref.read(professionalFilterProvider)).copyWith(page: 1),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(professionalFilterProvider);
    final meta = ref.watch(professionalsMetaProvider).value;
    final results = ref.watch(professionalSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profissionais'),
        actions: [
          IconButton(
            tooltip: 'Minhas solicitações',
            icon: const Icon(Icons.inbox_outlined),
            onPressed: () => context.push(AppRoutes.contactRequests),
          ),
          const NotificationBell(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(professionalSearchProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.page,
            Space.sm,
            Space.page,
            Space.xxl,
          ),
          children: [
            Text(
              'Nutricionistas e profissionais de educação física com registro no conselho conferido pela equipe do PicNutri. '
              'Ao pedir contato, você escolhe se compartilha seu contato e quais dados do app — e pode revogar quando quiser.',
              style: context.text.bodySmall,
            ),
            const SizedBox(height: Space.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: filter.category == null,
                    onSelected: (_) => _update(
                      ref,
                      (f) => f.copyWith(
                        category: () => null,
                        specialty: () => null,
                      ),
                    ),
                  ),
                  for (final c
                      in meta?.categories ??
                          const <ProfessionalCategoryOption>[]) ...[
                    const SizedBox(width: Space.xs),
                    ChoiceChip(
                      label: Text(c.label),
                      selected: filter.category == c.value,
                      onSelected: (_) => _update(
                        ref,
                        (f) => f.copyWith(
                          category: () => c.value,
                          specialty: () => null,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Space.sm),
            // Filtros avançados e localização sob demanda: os resultados vêm primeiro.
            Row(
              children: [
                Expanded(
                  child: Text(_summary(filter), style: context.text.bodySmall),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      _openFilters(context, meta?.cepLookup ?? false),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: Text(
                    _activeFilters(filter) == 0
                        ? 'Filtros'
                        : 'Filtros (${_activeFilters(filter)})',
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.md),
            AsyncValueView<ProfessionalSearchResult>(
              value: results,
              onRetry: () => ref.invalidate(professionalSearchProvider),
              data: (r) => _Results(result: r, filter: filter),
            ),
            const SizedBox(height: Space.xl),
            const _ForProfessionals(),
          ],
        ),
      ),
    );
  }
}

int _activeFilters(ProfessionalFilter f) =>
    (f.modality != 'any' ? 1 : 0) +
    (f.usesLocation ? 1 : 0) +
    (f.specialty != null ? 1 : 0) +
    (f.acceptingOnly ? 1 : 0);

String _summary(ProfessionalFilter f) => [
  switch (f.modality) {
    'online' => 'Atendimento online',
    'in_person' => 'Atendimento presencial',
    _ => 'Presencial e online',
  },
  if (f.acceptingOnly) 'aceitando novos atendimentos',
].join(' · ');

/// Folha de filtros: modalidade, local, especialidade e disponibilidade.
Future<void> _openFilters(
  BuildContext context,
  bool cepLookup,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (sheet) => Consumer(
    builder: (context, ref, _) {
      final filter = ref.watch(professionalFilterProvider);
      final meta = ref.watch(professionalsMetaProvider).value;
      void update(ProfessionalFilter Function(ProfessionalFilter f) change) =>
          ref
              .read(professionalFilterProvider.notifier)
              .set(change(filter).copyWith(page: 1));
      return Padding(
        padding: EdgeInsets.fromLTRB(
          Space.page,
          0,
          Space.page,
          MediaQuery.viewInsetsOf(context).bottom + Space.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Filtros', style: context.text.titleLarge),
              const SizedBox(height: Space.lg),
              Text('Atendimento', style: context.text.titleSmall),
              const SizedBox(height: Space.sm),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'any', label: Text('Todos')),
                  ButtonSegment(value: 'in_person', label: Text('Presencial')),
                  ButtonSegment(value: 'online', label: Text('Online')),
                ],
                selected: {filter.modality},
                showSelectedIcon: false,
                onSelectionChanged: (s) =>
                    update((f) => f.copyWith(modality: s.first)),
              ),
              if (filter.modality != 'online') ...[
                const SizedBox(height: Space.lg),
                _PlaceCard(filter: filter, cepLookup: cepLookup),
              ],
              const SizedBox(height: Space.lg),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.xs,
                children: [
                  if (filter.category != null && meta != null)
                    _SpecialtyChip(
                      options: meta.specialtiesOf(filter.category),
                      selected: filter.specialty,
                    ),
                  FilterChip(
                    label: const Text('Aceitando novos atendimentos'),
                    selected: filter.acceptingOnly,
                    onSelected: (v) =>
                        update((f) => f.copyWith(acceptingOnly: v)),
                  ),
                ],
              ),
              const SizedBox(height: Space.xl),
              FilledButton(
                onPressed: () => Navigator.of(sheet).pop(),
                child: const Text('Ver resultados'),
              ),
            ],
          ),
        ),
      );
    },
  ),
);

class _Results extends ConsumerWidget {
  const _Results({required this.result, required this.filter});

  final ProfessionalSearchResult result;
  final ProfessionalFilter filter;

  void _page(WidgetRef ref, int page) => ref
      .read(professionalFilterProvider.notifier)
      .set(filter.copyWith(page: page));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestion = result.suggestOnline
        ? Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: StatusBanner(
              message: result.onlineCount > 0
                  ? 'Não encontramos atendimento presencial nessa região. Veja quem atende online.'
                  : 'Não encontramos atendimento presencial nessa região.',
              actionLabel:
                  filter.modality == 'online' || result.onlineCount == 0
                  ? null
                  : 'Só online',
              onAction: () => ref
                  .read(professionalFilterProvider.notifier)
                  .set(filter.copyWith(modality: 'online', page: 1)),
            ),
          )
        : null;

    if (result.items.isEmpty) {
      return Column(
        children: [
          ?suggestion,
          const EmptyState(
            icon: Icons.person_search_outlined,
            title: 'Nenhum profissional encontrado',
            message:
                'Ainda estamos cadastrando profissionais. Tente outra cidade, outra categoria ou o atendimento online.',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?suggestion,
        Text(
          result.total == 1
              ? '1 profissional'
              : '${result.total} profissionais',
          style: context.text.labelLarge,
        ),
        if (filter.usesLocation)
          Padding(
            padding: const EdgeInsets.only(top: Space.xs),
            child: Text(
              'A distância aparece só quando o endereço do profissional foi conferido.',
              style: context.text.bodySmall,
            ),
          ),
        const SizedBox(height: Space.sm),
        for (final p in result.items) ...[
          ProfessionalCard(
            professional: p,
            onTap: () => context.push(AppRoutes.professional(p.id)),
          ),
          const SizedBox(height: Space.sm),
        ],
        if (result.lastPage > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: result.currentPage > 1
                    ? () => _page(ref, result.currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text('Anterior'),
              ),
              Text(
                '${result.currentPage} de ${result.lastPage}',
                style: context.text.bodySmall,
              ),
              TextButton.icon(
                onPressed: result.currentPage < result.lastPage
                    ? () => _page(ref, result.currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                label: const Text('Próxima'),
              ),
            ],
          ),
      ],
    );
  }
}

/// Local da busca presencial: cidade/UF, CEP ou localização do aparelho.
class _PlaceCard extends ConsumerWidget {
  const _PlaceCard({required this.filter, required this.cepLookup});

  final ProfessionalFilter filter;
  final bool cepLookup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = [
      filter.city,
      filter.state,
    ].whereType<String>().where((s) => s.isNotEmpty).join('/');
    final label = filter.usesLocation
        ? 'Perto de você (até ${filter.radiusKm.round()} km)'
        : filter.cep != null && filter.cep!.isNotEmpty
        ? 'CEP ${filter.cep}'
        : place.isNotEmpty
        ? place
        : 'Qualquer local';
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.md,
      ),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _PlaceSheet(filter: filter, cepLookup: cepLookup),
      ),
      child: Row(
        children: [
          Icon(
            filter.usesLocation ? Icons.my_location : Icons.place_outlined,
            color: context.colors.primary,
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Atendimento presencial em',
                  style: context.text.bodySmall,
                ),
                Text(label, style: context.text.titleSmall),
              ],
            ),
          ),
          const Text('Alterar'),
        ],
      ),
    );
  }
}

class _PlaceSheet extends ConsumerStatefulWidget {
  const _PlaceSheet({required this.filter, required this.cepLookup});

  final ProfessionalFilter filter;
  final bool cepLookup;

  @override
  ConsumerState<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends ConsumerState<_PlaceSheet> {
  late final _city = TextEditingController(text: widget.filter.city);
  late final _state = TextEditingController(text: widget.filter.state);
  late final _cep = TextEditingController(text: widget.filter.cep);
  late double _radius = widget.filter.radiusKm;
  bool _locating = false;

  @override
  void dispose() {
    _city.dispose();
    _state.dispose();
    _cep.dispose();
    super.dispose();
  }

  void _apply(ProfessionalFilter filter) {
    ref.read(professionalFilterProvider.notifier).set(filter.copyWith(page: 1));
    Navigator.of(context).pop();
  }

  void _applyPlace() {
    String? clean(String v) => v.trim().isEmpty ? null : v.trim();
    _apply(
      widget.filter.copyWith(
        city: () => clean(_city.text),
        state: () => clean(_state.text)?.toUpperCase(),
        cep: () => clean(_cep.text),
        lat: () => null,
        lng: () => null,
      ),
    );
  }

  Future<void> _useLocation() async {
    setState(() => _locating = true);
    final location = ref.read(deviceLocationProvider);
    final result = await location.current();
    if (!mounted) return;
    setState(() => _locating = false);
    switch (result) {
      case LocationFound(:final lat, :final lng):
        _apply(
          widget.filter.copyWith(
            lat: () => lat,
            lng: () => lng,
            radiusKm: _radius,
            cep: () => null,
          ),
        );
      case LocationUnavailable(:final message, :final openSettings):
        if (openSettings) {
          final open = await confirmAction(
            context,
            title: 'Localização',
            message: message,
            confirmLabel: 'Abrir ajustes',
          );
          if (open) await location.openSettings();
        } else {
          showMessage(context, message);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.page,
        0,
        Space.page,
        MediaQuery.viewInsetsOf(context).bottom + Space.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Onde você quer ser atendido?',
              style: context.text.titleMedium,
            ),
            const SizedBox(height: Space.md),
            OutlinedButton.icon(
              onPressed: _locating ? null : _useLocation,
              icon: _locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: const Text('Usar minha localização'),
            ),
            const SizedBox(height: Space.xs),
            Text(
              'Usada só nesta busca, de forma aproximada. Não fica salva.',
              style: context.text.bodySmall,
            ),
            Row(
              children: [
                const Text('Raio'),
                Expanded(
                  child: Slider(
                    value: _radius,
                    min: 5,
                    max: 100,
                    divisions: 19,
                    label: '${_radius.round()} km',
                    onChanged: (v) => setState(() => _radius = v),
                  ),
                ),
                Text('${_radius.round()} km'),
              ],
            ),
            const Divider(height: Space.xl),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _city,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Cidade'),
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: TextField(
                    controller: _state,
                    maxLength: 2,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'UF',
                      counterText: '',
                    ),
                  ),
                ),
              ],
            ),
            if (widget.cepLookup) ...[
              const SizedBox(height: Space.sm),
              TextField(
                controller: _cep,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                  LengthLimitingTextInputFormatter(9),
                ],
                decoration: const InputDecoration(
                  labelText: 'Ou CEP',
                  helperText:
                      'O CEP é convertido na cidade; não calcula distância.',
                ),
              ),
            ],
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: _applyPlace,
              child: const Text('Buscar neste local'),
            ),
            TextButton(
              onPressed: () => _apply(
                widget.filter.copyWith(
                  city: () => null,
                  state: () => null,
                  cep: () => null,
                  lat: () => null,
                  lng: () => null,
                ),
              ),
              child: const Text('Qualquer local'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecialtyChip extends ConsumerWidget {
  const _SpecialtyChip({required this.options, required this.selected});

  final List<ValueLabel> options;
  final String? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = options.where((o) => o.value == selected).firstOrNull;
    return ActionChip(
      avatar: const Icon(Icons.tune, size: 18),
      label: Text(current?.label ?? 'Especialidade'),
      onPressed: () async {
        final choice = await showModalBottomSheet<String>(
          context: context,
          showDragHandle: true,
          builder: (sheet) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  title: const Text('Todas'),
                  onTap: () => Navigator.of(sheet).pop(''),
                ),
                for (final o in options)
                  ListTile(
                    title: Text(o.label),
                    trailing: o.value == selected
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => Navigator.of(sheet).pop(o.value),
                  ),
              ],
            ),
          ),
        );
        if (choice == null) return;
        final f = ref.read(professionalFilterProvider);
        ref
            .read(professionalFilterProvider.notifier)
            .set(
              f.copyWith(
                specialty: () => choice.isEmpty ? null : choice,
                page: 1,
              ),
            );
      },
    );
  }
}

/// Convite para profissionais se cadastrarem (análise pela equipe).
class _ForProfessionals extends ConsumerWidget {
  const _ForProfessionals();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = Uri.parse(ref.watch(appEnvProvider).apiBaseUrl);
    final url = Uri(
      scheme: api.scheme,
      host: api.host,
      port: api.hasPort ? api.port : null,
      path: '/profissionais/cadastro',
    ).toString();
    return AppCard(
      color: context.pic.surfaceMuted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'É nutricionista ou profissional de educação física?',
            style: context.text.titleSmall,
          ),
          const SizedBox(height: Space.xs),
          Text(
            'Envie seu cadastro com o registro no conselho. A equipe confere antes de publicar o perfil.',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: Space.sm),
          Text(
            url,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.primary,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: url));
                if (context.mounted) showMessage(context, 'Link copiado.');
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copiar link'),
            ),
          ),
        ],
      ),
    );
  }
}
