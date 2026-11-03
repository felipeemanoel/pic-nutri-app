import 'package:flutter/material.dart';

import '../../../core/design/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../data/injection_guides.dart';
import '../data/injection_location.dart';
import '../data/medication_models.dart';
import 'injection_body_shape.dart';

/// Esquema de regiões, não um guia anatômico de pontos ou distâncias.
/// Na vista frontal, a esquerda da pessoa aparece à direita de quem olha.
class InjectionSiteMap extends StatefulWidget {
  const InjectionSiteMap({
    super.key,
    required this.sites,
    required this.selected,
    required this.onSelected,
    this.history = const [],
    this.historyAvailable = true,
    this.armRequiresHelper = false,
    this.bodyShape = const InjectionBodyShape(),
  });

  final InjectionBodyShape bodyShape;
  final List<Option> sites;
  final String? selected;
  final ValueChanged<String> onSelected;
  final List<MedicationDose> history;
  final bool armRequiresHelper;
  final bool historyAvailable;

  @override
  State<InjectionSiteMap> createState() => _InjectionSiteMapState();
}

class _InjectionSiteMapState extends State<InjectionSiteMap> {
  bool _back = false;
  List<Option> get sites => widget.sites;
  String? get selected => widget.selected;
  ValueChanged<String> get onSelected => widget.onSelected;
  List<MedicationDose> get history => widget.history;
  bool get historyAvailable => widget.historyAvailable;
  bool get armRequiresHelper => widget.armRequiresHelper;

  @override
  Widget build(BuildContext context) {
    final known = sites.where((s) => regionForSite(s.value) != null).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Mapa de aplicações', style: context.text.titleMedium),
        const SizedBox(height: Space.xs),
        Text(
          'Toque em uma região para escolher a posição e consultar seu histórico. Direita e esquerda são as do seu corpo.',
          style: context.text.bodySmall,
        ),
        const SizedBox(height: Space.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.clamp(0.0, 300.0);
            return Center(
              child: SizedBox(
                width: width,
                height: 390,
                child: Row(
                  children: [
                    for (final back in [_back])
                      Expanded(
                        child: Column(
                          children: [
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: false,
                                  label: Text('Frente'),
                                ),
                                ButtonSegment(
                                  value: true,
                                  label: Text('Costas'),
                                ),
                              ],
                              selected: {_back},
                              onSelectionChanged: (value) =>
                                  setState(() => _back = value.single),
                            ),
                            const SizedBox(height: Space.sm),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, box) => Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ExcludeSemantics(
                                        child: CustomPaint(
                                          key: const ValueKey('injection-body'),
                                          painter: _BodyPainter(
                                            context.pic.surfaceMuted,
                                            context.pic.border,
                                            widget.bodyShape,
                                            back,
                                          ),
                                        ),
                                      ),
                                    ),
                                    for (final site in known)
                                      if ((regionForSite(
                                                InjectionLocation.region(
                                                  site.value,
                                                ),
                                              ) ==
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
        if (history.any(
          (d) =>
              d.injectionSite?.startsWith('abdomen_') == true &&
              InjectionLocation.point(d.notes) == null,
        ))
          Text(
            'Há registros antigos de abdome sem subárea definida. Eles não são atribuídos a nenhuma das quatro áreas.',
            style: context.text.bodySmall,
          ),
        if (!historyAvailable)
          Text(
            'Histórico indisponível. As regiões sem marcação não indicam ausência de aplicações.',
            style: context.text.bodySmall,
          ),
        if (selected != null) ...[
          const SizedBox(height: Space.sm),
          Text(
            'Região selecionada: ${InjectionLocation.labels[selected] ?? sites.where((s) => s.value == selected).firstOrNull?.label ?? selected}',
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
              label: Text('Aplicações na região'),
            ),
            Chip(
              avatar: Icon(
                Icons.radio_button_checked,
                size: 18,
                color: context.pic.ai,
              ),
              label: const Text('Selecionado'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _choosePoint(BuildContext context, Option site) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .85,
        maxChildSize: .95,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(Space.lg),
          children: [
            Text(site.label, style: context.text.titleLarge),
            const SizedBox(height: Space.sm),
            Text(
              'Toque em uma posição para consultar as datas ou registrar uma aplicação.',
              style: context.text.bodySmall,
            ),
            const SizedBox(height: Space.md),
            if (!historyAvailable)
              const Text(
                'Histórico indisponível. As posições sem registros não significam que nunca foram usadas.',
              ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Mais à esquerda')),
                Expanded(
                  child: Text('Mais à direita', textAlign: TextAlign.end),
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            CustomPaint(
              painter: _RegionDetailPainter(
                regionForSite(site.value)!,
                context.pic.surfaceMuted,
                context.pic.border,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 22,
                ),
                child: Column(
                  children: [
                    for (var row = 0; row < 3; row++) ...[
                      Text(
                        const [
                          'Parte superior',
                          'Parte do meio',
                          'Parte inferior',
                        ][row],
                        style: context.text.labelLarge,
                      ),
                      Row(
                        children: [
                          for (var col = 0; col < 3; col++)
                            Expanded(
                              child: _pointTile(sheetContext, site, row, col),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: Space.md),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Como ler este mapa', style: context.text.labelLarge),
              children: [
                Text(
                  'O número identifica a posição, e a contagem mostra o histórico carregado. O desenho é uma referência sem escala anatômica. Siga os locais e distâncias indicados pelo seu profissional e pela bula.',
                  style: context.text.bodySmall,
                ),
              ],
            ),
            if (history.any(
              (d) =>
                  d.injectionSite == site.value &&
                  InjectionLocation.point(d.notes) == null,
            ))
              const Text(
                'Existem registros desta região sem posição definida; eles não são atribuídos a uma posição da grade.',
              ),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
    if (result != null) onSelected(result);
  }

  Widget _pointTile(BuildContext sheetContext, Option site, int row, int col) {
    final point = '${site.value}_p$row$col';
    final records =
        history.where((d) => InjectionLocation.point(d.notes) == point).toList()
          ..sort((a, b) => a.takenAt.compareTo(b.takenAt));
    final active = selected == point;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          backgroundColor: active
              ? context.pic.aiContainer
              : records.isNotEmpty
              ? context.pic.warningContainer
              : context.colors.surface,
          shape: const CircleBorder(),
        ),
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: sheetContext,
            builder: (dialogContext) => AlertDialog(
              title: Text('${site.label} · Posição ${row * 3 + col + 1}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(InjectionLocation.labels[point]!),
                    const SizedBox(height: Space.md),
                    if (!historyAvailable)
                      const Text('Histórico indisponível.')
                    else if (records.isEmpty)
                      const Text(
                        'Sem aplicações nesta posição no histórico carregado.',
                      ),
                    for (var i = 0; i < records.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${i + 1}ª aplicação · ${Fmt.shortDate(records[i].takenAt)} às ${Fmt.time(records[i].takenAt)} · ${records[i].medicationName ?? 'Medicamento registrado'}',
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Voltar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Selecionar posição'),
                ),
              ],
            ),
          );
          if (confirmed == true && sheetContext.mounted) {
            Navigator.pop(sheetContext, point);
          }
        },
        child: Column(
          children: [
            Text('${row * 3 + col + 1}', style: context.text.titleMedium),
            Text(
              historyAvailable
                  ? '${records.length} registros'
                  : 'Sem histórico',
              textAlign: TextAlign.center,
              style: context.text.labelSmall,
            ),
            if (records.isNotEmpty)
              Text(
                Fmt.shortDate(records.last.takenAt),
                style: context.text.labelSmall,
              ),
            if (active) const Icon(Icons.check_circle, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _target(
    BuildContext context,
    Option site,
    double width,
    double height,
    bool back,
  ) {
    final region = regionForSite(InjectionLocation.region(site.value))!;
    final left = isLeftSite(InjectionLocation.region(site.value))!;
    final rightOfViewer = back ? !left : left;
    final x = switch (region) {
      BodyRegion.upperArm =>
        .5 + (rightOfViewer ? 1 : -1) * widget.bodyShape.armX,
      BodyRegion.abdomen =>
        .5 + (rightOfViewer ? 1 : -1) * widget.bodyShape.abdomenX,
      BodyRegion.thigh =>
        .5 + (rightOfViewer ? 1 : -1) * widget.bodyShape.thighX,
    };
    final y = switch (region) {
      BodyRegion.abdomen => 0.45,
      BodyRegion.thigh => 0.70,
      BodyRegion.upperArm => 0.29,
    };
    bool matches(MedicationDose d) => d.injectionSite == site.value;
    final count = history.where(matches).length;
    final used = historyAvailable && count > 0;
    final active =
        selected != null && InjectionLocation.region(selected!) == site.value;
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
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Material(
              color: active
                  ? context.pic.aiContainer
                  : used
                  ? context.pic.warningContainer
                  : context.colors.surface,
              shape: CircleBorder(
                side: BorderSide(
                  color: active
                      ? context.pic.ai
                      : used
                      ? context.pic.warning
                      : context.pic.textSecondary,
                  width: active ? 2 : 1,
                ),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _choosePoint(context, site),
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
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  const _BodyPainter(this.fill, this.outline, this.shape, this.back);
  final Color fill;
  final Color outline;
  final InjectionBodyShape shape;
  final bool back;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 180, size.height / 320);
    final shoulder = shape.shoulder;
    final waist = shape.waist;
    final hip = shape.hip;
    final skin = Color.lerp(fill, const Color(0xffc7d2ce), .35)!;
    final stroke = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final body = Path()
      ..moveTo(80, 45)
      ..lineTo(80, 54)
      ..quadraticBezierTo(90 - shoulder, 55, 85 - shoulder, 77)
      ..lineTo(69 - shoulder, 166)
      ..quadraticBezierTo(68 - shoulder, 180, 78 - shoulder, 178)
      ..lineTo(98 - shoulder, 105)
      ..quadraticBezierTo(90 - waist, 127, 90 - waist, 148)
      ..quadraticBezierTo(87 - hip, 167, 90 - hip, 194)
      ..lineTo(66, 299)
      ..quadraticBezierTo(63, 309, 80, 306)
      ..lineTo(90, 211)
      ..lineTo(100, 306)
      ..quadraticBezierTo(117, 309, 114, 299)
      ..lineTo(90 + hip, 194)
      ..quadraticBezierTo(93 + hip, 167, 90 + waist, 148)
      ..quadraticBezierTo(90 + waist, 127, 82 + shoulder, 105)
      ..lineTo(102 + shoulder, 178)
      ..quadraticBezierTo(112 + shoulder, 180, 111 + shoulder, 166)
      ..lineTo(95 + shoulder, 77)
      ..quadraticBezierTo(90 + shoulder, 55, 100, 54)
      ..lineTo(100, 45)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          colors: [skin, const Color(0xfff3f6f4), skin],
        ).createShader(const Rect.fromLTWH(25, 0, 130, 320)),
    );
    canvas.drawPath(body, stroke);

    // Roupa mantém as regiões do mapa visíveis.
    final shorts = Path()
      ..moveTo(90 - hip, 173)
      ..quadraticBezierTo(90, 181, 90 + hip, 173)
      ..lineTo(90 + hip - 2, 209)
      ..lineTo(94, 211)
      ..lineTo(90, 201)
      ..lineTo(86, 211)
      ..lineTo(92 - hip, 209)
      ..close();
    canvas.drawPath(shorts, Paint()..color = const Color(0xffe5eee9));
    canvas.drawPath(shorts, stroke);
    if (shape.feminine) {
      final top = Path()
        ..moveTo(69, 59)
        ..lineTo(64, 106)
        ..quadraticBezierTo(90, 116, 116, 106)
        ..lineTo(111, 59)
        ..lineTo(105, 59)
        ..quadraticBezierTo(90, 91, 75, 59)
        ..close();
      canvas.drawPath(top, Paint()..color = const Color(0xffe5eee9));
      canvas.drawPath(top, stroke);
    }
    final head = Rect.fromCenter(
      center: const Offset(90, 28),
      width: 31,
      height: 39,
    );
    canvas.drawOval(head, Paint()..color = skin);
    canvas.drawOval(head, stroke);
    final hair = Path()
      ..moveTo(74, 29)
      ..cubicTo(68, 0, 112, 0, 106, 29)
      ..quadraticBezierTo(99, 13, 82, 19)
      ..close();
    canvas.drawPath(hair, Paint()..color = const Color(0xff687a72));
    if (back) {
      canvas.drawLine(const Offset(90, 78), const Offset(90, 147), stroke);
      if (shape.feminine) {
        canvas.drawOval(
          const Rect.fromLTWH(99, 25, 13, 37),
          Paint()..color = const Color(0xff687a72),
        );
      }
    } else {
      canvas.drawCircle(const Offset(84, 29), .9, Paint()..color = outline);
      canvas.drawCircle(const Offset(96, 29), .9, Paint()..color = outline);
      canvas.drawArc(const Rect.fromLTWH(86, 35, 8, 3), 0, 3.14, false, stroke);
      canvas.drawCircle(const Offset(90, 150), 1.3, Paint()..color = outline);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BodyPainter old) =>
      fill != old.fill ||
      outline != old.outline ||
      back != old.back ||
      shape.sex != old.shape.sex ||
      shape.fullness != old.shape.fullness;
}

class _RegionDetailPainter extends CustomPainter {
  const _RegionDetailPainter(this.region, this.fill, this.outline);
  final BodyRegion region;
  final Color fill;
  final Color outline;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    switch (region) {
      case BodyRegion.abdomen:
        path.moveTo(w * .14, 2);
        path.quadraticBezierTo(w * .5, h * .08, w * .86, 2);
        path.cubicTo(w * .98, h * .32, w * .80, h * .58, w * .94, h * .94);
        path.quadraticBezierTo(w * .5, h * 1.03, w * .06, h * .94);
        path.cubicTo(w * .20, h * .58, w * .02, h * .32, w * .14, 2);
        path.close();
      case BodyRegion.upperArm:
        path.addRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(w * .09, 0, w * .82, h),
            topLeft: Radius.circular(w * .4),
            topRight: Radius.circular(w * .4),
            bottomLeft: Radius.circular(w * .22),
            bottomRight: Radius.circular(w * .22),
          ),
        );
      case BodyRegion.thigh:
        path.moveTo(w * .06, h * .04);
        path.quadraticBezierTo(w * .5, -h * .04, w * .94, h * .04);
        path.lineTo(w * .78, h * .95);
        path.quadraticBezierTo(w * .5, h * 1.02, w * .22, h * .95);
        path.close();
    }
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_RegionDetailPainter old) =>
      old.region != region || old.fill != fill || old.outline != outline;
}
