import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../medication/application/medication_overview.dart';
import '../../medication/domain/medication_schedule.dart';
import '../../medication/presentation/medication_forms.dart';

/// Destaque do Início para quem acompanha a medicação: quanto falta para a
/// próxima aplicação (pelo intervalo cadastrado), a última dose e o nível
/// estimado. Informativo: não sugere dose nem cobra atraso.
class NextDoseCard extends ConsumerStatefulWidget {
  const NextDoseCard({super.key});

  @override
  ConsumerState<NextDoseCard> createState() => _NextDoseCardState();
}

class _NextDoseCardState extends ConsumerState<NextDoseCard> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // A contagem muda de minuto em minuto.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(medicationOverviewProvider);
    return switch (overview) {
      AsyncData(value: final o?) => _Content(overview: o, now: DateTime.now()),
      AsyncData() => const _NoMedication(),
      // Sem os dados do medicamento, o Início segue com o restante.
      AsyncError() => const SizedBox.shrink(),
      _ => const SkeletonCard(lines: 3),
    };
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.overview, required this.now});

  final MedicationOverview overview;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final pic = context.pic;
    final med = overview.medication;
    final last = overview.lastDoseAt;
    final next = overview.nextDoseAt;
    final progress = MedicationSchedule.cycleProgress(med, now);
    final overdue = next != null && next.isBefore(now);
    final dose = overview.lastDose?.doseAmount;
    final level = overview.level;
    final levelMg = level == null
        ? null
        : MedicationLevel.rounded(level.at(now));

    final String eyebrow;
    final String headline;
    final String caption;
    if (last == null) {
      eyebrow = 'Medicação';
      headline = 'Registre sua primeira aplicação';
      caption = 'A contagem para a próxima começa a partir dela.';
    } else if (next == null) {
      eyebrow = 'Última aplicação';
      headline = Fmt.relativeDayTime(last);
      caption = 'Informe a frequência no cadastro para ver a próxima.';
    } else if (overdue) {
      eyebrow = 'Aplicação prevista';
      headline = Fmt.relativeDayTime(next);
      caption = 'Já aplicou? Registre para atualizar a contagem.';
    } else {
      eyebrow = 'Próxima aplicação';
      headline = MedicationSchedule.countdown(next.difference(now));
      caption = Fmt.relativeDayTime(next);
    }
    final accent = overdue ? pic.warning : context.colors.primary;

    return Material(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.card,
        side: BorderSide(color: pic.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(AppRoutes.progress),
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.vaccines_outlined, size: 20, color: accent),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      eyebrow,
                      style: context.text.labelLarge?.copyWith(
                        color: pic.textSecondary,
                      ),
                    ),
                  ),
                  _Pill(
                    label: [
                      med.name,
                      if (dose != null)
                        '${Fmt.decimal(dose)} ${overview.lastDose!.doseUnit}',
                    ].join(' · '),
                  ),
                ],
              ),
              const SizedBox(height: Space.md),
              Semantics(
                liveRegion: true,
                child: Text(
                  headline,
                  style:
                      (last != null && next != null && !overdue
                              ? context.text.displaySmall
                              : context.text.headlineSmall)
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            height: 1.05,
                            color: overdue ? pic.warning : null,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                ),
              ),
              const SizedBox(height: Space.xs),
              Text(
                caption,
                style: context.text.bodyMedium?.copyWith(
                  color: pic.textSecondary,
                ),
              ),
              if (progress != null) ...[
                const SizedBox(height: Space.lg),
                ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.pill),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    color: accent,
                    backgroundColor: pic.surfaceMuted,
                    semanticsLabel: 'Ciclo entre aplicações',
                    semanticsValue:
                        '${(progress.clamp(0.0, 1.0) * 100).round()}%',
                  ),
                ),
              ],
              if (last != null) ...[
                const SizedBox(height: Space.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Fact(
                        label: 'Última',
                        value: Fmt.relativeDayTime(last),
                      ),
                    ),
                    if (levelMg != null)
                      Expanded(
                        child: _Fact(
                          label: 'Nível estimado',
                          value: '~${Fmt.decimal(levelMg)} mg',
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: Space.lg),
              FilledButton.tonalIcon(
                onPressed: () => openDoseForm(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Registrar aplicação'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: context.text.bodySmall?.copyWith(
          color: context.pic.textSecondary,
        ),
      ),
      const SizedBox(height: Space.xxs),
      Text(
        value,
        style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    ],
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Flexible(
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.xs,
      ),
      decoration: BoxDecoration(
        color: context.pic.brandContainer,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.text.labelMedium?.copyWith(
          color: context.pic.onBrandContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

/// Acompanhamento ligado, mas sem medicamento cadastrado.
class _NoMedication extends StatelessWidget {
  const _NoMedication();

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: () => showMedicationForm(context),
    child: Row(
      children: [
        Icon(Icons.vaccines_outlined, color: context.colors.primary),
        const SizedBox(width: Space.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cadastre seu medicamento', style: context.text.titleSmall),
              Text(
                'Para ver a contagem até a próxima aplicação.',
                style: context.text.bodySmall,
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    ),
  );
}
