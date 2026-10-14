import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../data/professional_models.dart';

/// Rótulos de atendimento.
String modalityLabel(String modality) => switch (modality) {
  'online' => 'Online',
  'in_person' => 'Presencial',
  _ => 'Online ou presencial',
};

String? priceLabel(Professional p) {
  if (p.priceMin == null) return null;
  final min = 'R\$ ${Fmt.integer(p.priceMin!)}';
  return p.priceMax == null || p.priceMax == p.priceMin ? min : '$min a R\$ ${Fmt.integer(p.priceMax!)}';
}

/// Selo do registro conferido pela equipe.
class VerifiedCouncil extends StatelessWidget {
  const VerifiedCouncil({super.key, required this.professional});

  final Professional professional;

  @override
  Widget build(BuildContext context) {
    final verified = professional.verifiedAt;
    return Row(
      children: [
        Icon(Icons.verified_outlined, size: 16, color: context.pic.success),
        const SizedBox(width: Space.xs),
        Flexible(
          child: Text(
            verified == null
                ? professional.councilLabel
                : '${professional.councilLabel} · conferido em ${Fmt.shortDate(verified)}',
            style: context.text.bodySmall,
          ),
        ),
      ],
    );
  }
}

class ProfessionalCard extends StatelessWidget {
  const ProfessionalCard({super.key, required this.professional, required this.onTap});

  final Professional professional;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = professional;
    final price = priceLabel(p);
    final details = [
      p.modalities.map(modalityLabel).join(' e '),
      if (p.inPerson && p.place.isNotEmpty) p.place,
      if (p.distanceKm != null) 'a ${Fmt.decimal(p.distanceKm!)} km',
      ?price,
    ];
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: context.pic.brandContainer,
                foregroundColor: context.pic.onBrandContainer,
                child: Icon(p.category == 'nutritionist' ? Icons.restaurant_outlined : Icons.fitness_center_outlined),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: context.text.titleMedium),
                    Text(p.categoryLabel, style: context.text.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          const SizedBox(height: Space.sm),
          VerifiedCouncil(professional: p),
          const SizedBox(height: Space.xs),
          Text(details.join(' · '), style: context.text.bodySmall),
          if (p.specialties.isNotEmpty) ...[
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final s in p.specialties.take(3))
                  Chip(label: Text(s.label), visualDensity: VisualDensity.compact),
              ],
            ),
          ],
          if (!p.acceptsNewClients) ...[
            const SizedBox(height: Space.sm),
            Text(
              'Não está aceitando novos atendimentos no momento.',
              style: context.text.bodySmall?.copyWith(color: context.pic.warning),
            ),
          ],
        ],
      ),
    );
  }
}
