import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/feedback.dart';
import '../../auth/application/session_controller.dart';
import '../data/injection_guides.dart';
import '../data/injection_location.dart';
import '../data/medication_models.dart';
import '../data/medication_repository.dart';
import 'injection_body_shape.dart';
import 'injection_site_map.dart';

/// Consulta de referência, sem inferir apresentação a partir do nome do cadastro.
/// O perfil consultado ainda não é persistido pela API de medicamentos.
class InjectionGuidance extends ConsumerStatefulWidget {
  const InjectionGuidance({
    super.key,
    required this.medicationName,
    required this.sites,
    required this.site,
    this.point,
    required this.onSiteChanged,
    required this.takenAt,
    this.editingDoseId,
    this.onPresentationChanged,
  });

  /// Apresentação confirmada na embalagem (null = não informada).
  final ValueChanged<String?>? onPresentationChanged;

  final String medicationName;
  final List<Option> sites;
  final String? site;
  final String? point;
  final ValueChanged<String> onSiteChanged;
  final DateTime takenAt;
  final String? editingDoseId;

  @override
  ConsumerState<InjectionGuidance> createState() => _InjectionGuidanceState();
}

class _InjectionGuidanceState extends ConsumerState<InjectionGuidance> {
  InjectionGuide? _guide;
  bool _confirmed = false;

  Future<void> _openSource() async {
    final guide = _guide;
    if (guide == null) return;
    try {
      if (!await launchUrl(
        Uri.parse(guide.sourceUrl),
        mode: LaunchMode.externalApplication,
      )) {
        if (mounted) {
          showMessage(
            context,
            'Não foi possível abrir a bula. Tente novamente quando houver conexão.',
          );
        }
      }
    } on Object {
      if (mounted) {
        showMessage(context, 'Não foi possível abrir a bula no navegador.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final guide = _guide;
    final profile = ref.watch(currentAccountProvider)?.profile;
    final catalog = guidesForMedication(widget.medicationName);
    final history = ref.watch(recentDosesProvider);
    final records =
        (history.value ?? const <MedicationDose>[])
            .where(
              (d) =>
                  d.id != widget.editingDoseId &&
                  !d.takenAt.isAfter(widget.takenAt),
            )
            .toList()
          ..sort((a, b) => b.takenAt.compareTo(a.takenAt));
    final selectedRecords = records
        .where(
          (d) => widget.point != null
              ? InjectionLocation.point(d.notes) == widget.point
              : d.injectionSite == widget.site,
        )
        .toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InjectionSiteMap(
            bodyShape: InjectionBodyShape.fromProfile(
              sex: profile?.sex,
              weightKg: profile?.currentWeightKg,
              heightCm: profile?.heightCm,
            ),
            sites: widget.sites
                .where(
                  (s) => (_confirmed
                      ? guide?.allowedRegions.contains(
                              regionForSite(s.value),
                            ) ??
                            true
                      : true),
                )
                .toList(),
            selected: widget.point ?? widget.site,
            onSelected: widget.onSiteChanged,
            history: records,
            historyAvailable: history.hasValue && !history.hasError,
            armRequiresHelper:
                _confirmed && (guide?.armRequiresHelper ?? false),
          ),
          if (!widget.sites.any((s) => regionForSite(s.value) != null))
            Text(
              'O mapa aguarda locais compatíveis da API. A lista textual abaixo continua disponível.',
              style: context.text.bodySmall,
            ),
          if (history.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: Space.sm),
              child: Text('Carregando histórico de regiões…'),
            )
          else if (history.hasError)
            TextButton.icon(
              onPressed: () => ref.invalidate(recentDosesProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar carregar o histórico'),
            )
          else if (widget.site != null) ...[
            const SizedBox(height: Space.sm),
            Text(
              selectedRecords.isEmpty
                  ? 'Sem registros anteriores neste local no histórico carregado.'
                  : 'Histórico deste local (${selectedRecords.length} aplicações):',
              style: context.text.bodySmall,
            ),
            for (final dose in selectedRecords)
              Text(
                '${Fmt.shortDate(dose.takenAt)} às ${Fmt.time(dose.takenAt)} · ${dose.medicationName ?? 'Medicamento registrado'}',
                style: context.text.bodySmall,
              ),
          ],
          const SizedBox(height: Space.lg),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: Space.md),
            leading: const Icon(Icons.menu_book_outlined, size: 20),
            title: Text(
              'Referência do fabricante',
              style: context.text.titleSmall,
            ),
            subtitle: const Text('Apresentação, bula e cuidados'),
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Space.xs),
              Text(
                'Escolha o produto e confira a apresentação na embalagem. Esta consulta não altera sua prescrição.',
                style: context.text.bodySmall,
              ),
              const SizedBox(height: Space.md),
              DropdownButtonFormField<String>(
                initialValue: null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Produto e apresentação',
                ),
                selectedItemBuilder: (context) => [
                  const Text(
                    'Outro / não sei informar',
                    overflow: TextOverflow.ellipsis,
                  ),
                  for (final g in catalog)
                    Text(
                      '${g.brand} · ${g.manufacturer}',
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Outro / não sei informar'),
                  ),
                  for (final g in catalog)
                    DropdownMenuItem(
                      value: g.id,
                      child: Text(
                        '${g.brand} · ${g.manufacturer}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (id) {
                  setState(() {
                    _guide = catalog.where((g) => g.id == id).firstOrNull;
                    _confirmed = false;
                  });
                  widget.onPresentationChanged?.call(null);
                },
              ),
              if (catalog.isEmpty) ...[
                const SizedBox(height: Space.sm),
                Text(
                  'O nome cadastrado não identifica um produto desta curadoria. Confira a marca no cadastro do medicamento; o registro manual continua disponível.',
                  style: context.text.bodySmall,
                ),
              ],
              if (guide == null) ...[
                const SizedBox(height: Space.sm),
                Text(
                  'O mapa registra a região informada. Confirme a apresentação para consultar as orientações específicas do fabricante.',
                  style: context.text.bodySmall,
                ),
              ] else ...[
                const SizedBox(height: Space.md),
                Text(guide.presentation, style: context.text.titleSmall),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'Minha embalagem corresponde a este produto e apresentação',
                  ),
                  value: _confirmed,
                  onChanged: (v) {
                    setState(() => _confirmed = v ?? false);
                    widget.onPresentationChanged?.call(
                      _confirmed
                          ? '${guide.brand} · ${guide.presentation}'
                          : null,
                    );
                  },
                ),
                if (_confirmed) ...[
                  Text(guide.deviceNote, style: context.text.bodySmall),
                  const SizedBox(height: Space.sm),
                  Text(guide.rotationNote, style: context.text.bodySmall),
                  const SizedBox(height: Space.md),
                ],
                const SizedBox(height: Space.sm),
                OutlinedButton.icon(
                  onPressed: _openSource,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Bula e imagens oficiais'),
                ),
                Text(
                  'Fonte: ${guide.manufacturer} · Brasil. Consulta em ${InjectionGuide.reviewedOn}. ${guide.sourceVersion}.',
                  style: context.text.labelSmall,
                ),
              ],
              const SizedBox(height: Space.md),
              const Text(
                'Seringa ou frasco? As referências acima são de canetas preenchidas. Não use estas instruções para aspirar medicamento para uma seringa. Seringas e agulhas descartáveis são de uso único; não esterilize para reutilizar. Confira o dispositivo com seu médico ou farmacêutico.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
