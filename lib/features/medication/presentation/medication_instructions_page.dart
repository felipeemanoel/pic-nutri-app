import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design/design_system.dart';
import '../../../shared/widgets/feedback.dart';
import '../data/injection_guides.dart';

/// Consulta às instruções do fabricante, separada do registro da aplicação.
/// Só referências da curadoria (bula oficial); não altera a prescrição.
class MedicationInstructionsPage extends StatelessWidget {
  const MedicationInstructionsPage({super.key, required this.medicationName});

  final String medicationName;

  static Future<void> open(BuildContext context, String medicationName) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => MedicationInstructionsPage(medicationName: medicationName)),
  );

  Future<void> _openSource(BuildContext context, InjectionGuide guide) async {
    try {
      if (!await launchUrl(Uri.parse(guide.sourceUrl), mode: LaunchMode.externalApplication) && context.mounted) {
        showMessage(context, 'Não foi possível abrir a bula. Tente novamente quando houver conexão.');
      }
    } on Object {
      if (context.mounted) showMessage(context, 'Não foi possível abrir a bula no navegador.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final guides = guidesForMedication(medicationName);
    return Scaffold(
      appBar: AppBar(title: const Text('Instruções do fabricante')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, Space.xxxl),
        children: [
          Text(medicationName, style: context.text.headlineSmall),
          const SizedBox(height: Space.sm),
          Text(
            'Referências da bula oficial de canetas preenchidas. Confira sempre a sua embalagem e siga a orientação do seu médico ou farmacêutico.',
            style: context.text.bodyMedium?.copyWith(color: context.pic.textSecondary),
          ),
          const SizedBox(height: Space.section),
          if (guides.isEmpty)
            const StatusBanner(
              message:
                  'O nome cadastrado não identifica um produto desta curadoria. Confira a marca no cadastro do medicamento.',
            )
          else
            for (final g in guides) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${g.brand} · ${g.manufacturer}', style: context.text.titleMedium),
                    const SizedBox(height: Space.xs),
                    Text(g.presentation, style: context.text.bodyMedium),
                    const SizedBox(height: Space.md),
                    Text('Dispositivo', style: context.text.titleSmall),
                    Text(g.deviceNote, style: context.text.bodyMedium),
                    const SizedBox(height: Space.md),
                    Text('Rodízio de regiões', style: context.text.titleSmall),
                    Text(g.rotationNote, style: context.text.bodyMedium),
                    const SizedBox(height: Space.md),
                    OutlinedButton.icon(
                      onPressed: () => _openSource(context, g),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Bula e imagens oficiais'),
                    ),
                    const SizedBox(height: Space.xs),
                    Text(
                      'Fonte: ${g.manufacturer} · Brasil. Consulta em ${InjectionGuide.reviewedOn}. ${g.sourceVersion}.',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.lg),
            ],
          const SizedBox(height: Space.md),
          Text(
            'Seringa ou frasco? Estas referências são de canetas preenchidas. Não use estas instruções para aspirar medicamento para uma seringa. Seringas e agulhas descartáveis são de uso único. Confira o dispositivo com seu médico ou farmacêutico.',
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }
}
