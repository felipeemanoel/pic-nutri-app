import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';
import '../data/injection_guides.dart';
import '../data/medication_models.dart';

/// Esquema de regiões, não um guia anatômico de pontos ou distâncias.
/// Na vista frontal, a esquerda da pessoa aparece à direita de quem olha.
class InjectionSiteMap extends StatelessWidget {
  const InjectionSiteMap({
    super.key,
    required this.sites,
    required this.selected,
    required this.onSelected,
    this.history = const [],
    this.historyAvailable = true,
    this.armRequiresHelper = false,
  });

  final List<Option> sites;
  final String? selected;
  final ValueChanged<String> onSelected;
  final List<MedicationDose> history;
  final bool armRequiresHelper;
  final bool historyAvailable;

  @override
  Widget build(BuildContext context) {
    final known = sites.where((s) => regionForSite(s.value) != null).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Onde foi a aplicação?', style: context.text.titleMedium),
        const SizedBox(height: Space.xs),
        Text(
          'Toque para registrar a região. Direita e esquerda são as do seu corpo. O desenho não indica um ponto exato nem confirma que a pele está adequada.',
          style: context.text.bodySmall,
        ),
        const SizedBox(height: Space.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.clamp(0.0, 360.0);
            return Center(
              child: SizedBox(
                width: width,
                height: 350,
                child: Row(
                  children: [
                    for (final back in [false, true])
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              back ? 'Costas' : 'Frente',
                              style: context.text.labelMedium,
                            ),
                            const SizedBox(height: Space.sm),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, box) => Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ExcludeSemantics(
                                        child: CustomPaint(
                                          painter: _BodyPainter(
                                            context.pic.surfaceMuted,
                                            context.pic.border,
                                          ),
                                        ),
                                      ),
                                    ),
                                    for (final site in known)
                                      if ((regionForSite(site.value) ==
                                              BodyRegion.upperArm) ==
                                          back)
                                        _target(
                                          context,
                                          site,
                                          box.maxWidth,
                                          box.maxHeight,
                                          back,
                                        ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        if (selected != null) ...[
          const SizedBox(height: Space.sm),
          Text(
            'Região selecionada: ${sites.where((s) => s.value == selected).firstOrNull?.label ?? selected}',
            style: context.text.titleSmall,
          ),
        ],
        if (armRequiresHelper)
          Padding(
            padding: const EdgeInsets.only(top: Space.sm),
            child: Text(
              'Mounjaro desta apresentação: a aplicação na parte posterior do braço deve ser feita por outra pessoa, conforme as instruções da Lilly.',
              style: context.text.bodySmall,
            ),
          ),
        const SizedBox(height: Space.sm),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.xs,
          children: [
            const Chip(
              avatar: Icon(Icons.history, size: 18),
              label: Text('Histórico registrado'),
            ),
            Chip(
              avatar: Icon(
                Icons.radio_button_checked,
                size: 18,
                color: context.pic.ai,
              ),
              label: const Text('Seleção atual'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _target(
    BuildContext context,
    Option site,
    double width,
    double height,
    bool back,
  ) {
    final region = regionForSite(site.value)!;
    final left = isLeftSite(site.value)!;
    final rightOfViewer = back ? !left : left;
    final x = switch (region) {
      BodyRegion.upperArm => rightOfViewer ? 0.80 : 0.20,
      _ => rightOfViewer ? 0.70 : 0.30,
    };
    final y = switch (region) {
      BodyRegion.abdomen => 0.43,
      BodyRegion.thigh => 0.68,
      BodyRegion.upperArm => 0.29,
    };
    final count = history.where((d) => d.injectionSite == site.value).length;
    final active = selected == site.value;
    return Positioned(
      left: (width * x - 24).clamp(0.0, width - 48),
      top: height * y - 24,
      width: 48,
      height: 48,
      child: Semantics(
        label: historyAvailable
            ? '${site.label}. $count registros no histórico carregado.'
            : '${site.label}. Histórico indisponível.',
        button: true,
        selected: active,
        child: Tooltip(
          message: site.label,
          child: Material(
            color: active ? context.pic.aiContainer : context.colors.surface,
            shape: CircleBorder(
              side: BorderSide(
                color: active ? context.pic.ai : context.pic.textSecondary,
                width: active ? 2 : 1,
              ),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => onSelected(site.value),
              child: ExcludeSemantics(
                child: Center(
                  child: active
                      ? Icon(Icons.check, color: context.pic.ai)
                      : historyAvailable && count > 0
                      ? Text('$count', style: context.text.labelLarge)
                      : Icon(
                          Icons.add,
                          size: 20,
                          color: context.pic.textSecondary,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  const _BodyPainter(this.fill, this.outline);
  final Color fill;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 180, size.height / 320);
    final paint = Paint()..color = fill;
    final head = Rect.fromCenter(
      center: const Offset(90, 28),
      width: 35,
      height: 40,
    );
    canvas.drawOval(head, paint);
    final body = Path()
      ..moveTo(76, 49)
      ..lineTo(104, 49)
      ..lineTo(131, 64)
      ..quadraticBezierTo(140, 74, 143, 90)
      ..lineTo(156, 156)
      ..quadraticBezierTo(158, 167, 148, 168)
      ..lineTo(129, 111)
      ..lineTo(124, 162)
      ..lineTo(120, 201)
      ..lineTo(114, 299)
      ..quadraticBezierTo(105, 309, 96, 300)
      ..lineTo(90, 216)
      ..lineTo(84, 300)
      ..quadraticBezierTo(75, 309, 66, 299)
      ..lineTo(60, 201)
      ..lineTo(56, 162)
      ..lineTo(51, 111)
      ..lineTo(32, 168)
      ..quadraticBezierTo(22, 167, 24, 156)
      ..lineTo(37, 90)
      ..quadraticBezierTo(40, 74, 49, 64)
      ..close();
    canvas.drawPath(body, paint);
    paint
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(body, paint);
    canvas.drawOval(head, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BodyPainter old) =>
      fill != old.fill || outline != old.outline;
}
