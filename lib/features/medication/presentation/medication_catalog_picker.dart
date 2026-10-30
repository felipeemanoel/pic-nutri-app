import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';
import '../data/medication_catalog.dart';

/// Lista completa do catálogo, com busca e grupos por princípio ativo.
/// Devolve o medicamento escolhido (ou nulo, se a pessoa fechar).
Future<KnownMedication?> showMedicationCatalogPicker(BuildContext context) =>
    showModalBottomSheet<KnownMedication>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.9,
        child: _CatalogPicker(),
      ),
    );

class _CatalogPicker extends StatefulWidget {
  const _CatalogPicker();

  @override
  State<_CatalogPicker> createState() => _CatalogPickerState();
}

class _CatalogPickerState extends State<_CatalogPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final brands = KnownMedication.brands
        .where((m) => m.matches(_query))
        .toList();
    final generic = KnownMedication.genericEntries
        .where((m) => m.matches(_query))
        .toList();

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(Space.xs, Space.lg, Space.xs, Space.xs),
      child: Text(
        text,
        style: context.text.labelLarge?.copyWith(
          color: context.pic.textSecondary,
        ),
      ),
    );

    Widget tile(KnownMedication m, {String? title}) => ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.xs),
      leading: Icon(
        m.form == 'oral' ? Icons.medication_outlined : Icons.vaccines_outlined,
        color: context.colors.primary,
      ),
      title: Text(title ?? m.name),
      subtitle: Text(
        [
          m.ingredient.label,
          if (m.maker != null) m.maker!,
        ].join(' · '),
      ),
      onTap: () => Navigator.of(context).pop(m),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.page,
        0,
        Space.page,
        MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Escolha o medicamento',
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          TextField(
            autofocus: false,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Buscar pela marca ou princípio ativo',
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: Space.xl),
              children: [
                for (final ingredient in MedicationIngredient.values)
                  if (brands.any((m) => m.ingredient == ingredient)) ...[
                    header(ingredient.groupTitle),
                    for (final m in brands.where(
                      (m) => m.ingredient == ingredient,
                    ))
                      tile(m),
                  ],
                if (generic.isNotEmpty) ...[
                  header('Genérico, similar ou outra marca'),
                  for (final m in generic)
                    tile(m, title: 'Outra caneta de ${m.ingredient.label}'),
                ],
                if (brands.isEmpty && generic.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(Space.xl),
                    child: Text(
                      'Nenhum medicamento encontrado.',
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
