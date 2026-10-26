import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/design_system.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/validators.dart';
import '../../domain/body_math.dart';

/// Alternância Métrico / Imperial.
class UnitToggle extends StatelessWidget {
  const UnitToggle({super.key, required this.metric, required this.onChanged});

  final bool metric;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget segment(String label, bool value) {
      final selected = metric == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: GestureDetector(
            onTap: () {
              if (!selected) {
                HapticFeedback.selectionClick();
                onChanged(value);
              }
            },
            child: AnimatedContainer(
              duration: Motion.fast,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: Space.md),
              decoration: BoxDecoration(
                color: selected ? context.colors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(Radii.pill),
                boxShadow: selected ? Shadows.soft : null,
              ),
              child: Text(
                label,
                style: context.text.titleSmall?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? context.colors.onSurface
                      : context.pic.textSecondary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(Space.xs),
        decoration: BoxDecoration(
          color: context.pic.surfaceMuted,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Row(
          children: [segment('Métrico', true), segment('Imperial', false)],
        ),
      ),
    );
  }
}

/// Número grande com a unidade, que abre um teclado ao tocar.
class BigValue extends StatelessWidget {
  const BigValue({
    super.key,
    required this.text,
    this.unit,
    this.onTap,
    this.trailing,
    this.color,
  });

  final String text;
  final String? unit;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Semantics(
        button: onTap != null,
        hint: onTap != null ? 'Toque para digitar' : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  text,
                  style: context.text.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 64,
                    letterSpacing: -1.5,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: Space.xs),
                  Text(
                    unit!,
                    style: context.text.titleLarge?.copyWith(
                      color: context.pic.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (trailing != null) ...[
                  const SizedBox(width: Space.lg),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
      if (onTap != null)
        Text(
          'Toque no número para digitar',
          style: context.text.bodySmall?.copyWith(
            color: context.pic.textSecondary,
          ),
        ),
    ],
  );
}

/// Diálogo para digitar um número (alternativa à régua).
Future<double?> askNumber(
  BuildContext context, {
  required String title,
  required String unit,
  required double min,
  required double max,
  double? initial,
  bool decimal = true,
}) => showDialog<double>(
  context: context,
  builder: (context) => _NumberDialog(
    title: title,
    unit: unit,
    min: min,
    max: max,
    initial: initial,
    decimal: decimal,
  ),
);

class _NumberDialog extends StatefulWidget {
  const _NumberDialog({
    required this.title,
    required this.unit,
    required this.min,
    required this.max,
    required this.initial,
    required this.decimal,
  });

  final String title;
  final String unit;
  final double min;
  final double max;
  final double? initial;
  final bool decimal;

  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(
    text: widget.initial == null
        ? ''
        : (widget.decimal
              ? Fmt.decimal(widget.initial!)
              : '${widget.initial!.round()}'),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, Validators.parseNumber(_controller.text));
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
        decoration: InputDecoration(suffixText: widget.unit),
        validator: Validators.number(
          min: widget.min,
          max: widget.max,
          unit: widget.unit,
        ),
        onFieldSubmitted: (_) => _submit(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _submit, child: const Text('OK')),
    ],
  );
}

/// Cartão do IMC com a faixa colorida e o marcador.
class BmiCard extends StatelessWidget {
  const BmiCard({super.key, required this.bmi});

  final double bmi;

  static const _min = 15.0;
  static const _max = 42.0;

  @override
  Widget build(BuildContext context) {
    final band = BmiBand.of(bmi);
    final pic = context.pic;
    final healthy = band == BmiBand.healthy;
    final tone = switch (band) {
      BmiBand.healthy => pic.success,
      BmiBand.underweight || BmiBand.overweight => pic.warning,
      _ => pic.error,
    };
    final position = ((bmi - _min) / (_max - _min)).clamp(0.0, 1.0);
    // Cores das faixas: amarelo, verde, âmbar, laranja, laranja-escuro, vermelho.
    const segments = [
      (15.0, 18.5, Color(0xFFF2C94C)),
      (18.5, 25.0, PicPalette.success),
      (25.0, 30.0, Color(0xFFF2B33D)),
      (30.0, 35.0, Color(0xFFF59E5B)),
      (35.0, 40.0, Color(0xFFEF7D4A)),
      (40.0, 42.0, Color(0xFFE5646E)),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IMC',
                      style: context.text.labelLarge?.copyWith(
                        color: pic.textSecondary,
                      ),
                    ),
                    Text(
                      Fmt.decimal(bmi),
                      style: context.text.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                healthy ? Icons.check_circle_outline : Icons.info_outline,
                color: tone,
                size: 20,
              ),
              const SizedBox(width: Space.xs),
              Text(
                band.label,
                style: context.text.titleSmall?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return SizedBox(
                height: 22,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.pill),
                      child: Row(
                        children: [
                          for (final (from, to, color) in segments)
                            Expanded(
                              flex: ((to - from) * 10).round(),
                              child: Container(height: 8, color: color),
                            ),
                        ],
                      ),
                    ),
                    AnimatedPositioned(
                      duration: Motion.medium,
                      curve: Motion.curve,
                      left: position * width - 11,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.colors.onSurface,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: Space.md),
          Text(
            'O IMC é uma referência geral: não considera massa muscular, idade nem condições de saúde.',
            style: context.text.bodySmall?.copyWith(color: pic.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Roda de data (dia, mês, ano) no estilo do iOS, em português.
class WheelDatePicker extends StatelessWidget {
  const WheelDatePicker({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final DateTime value;
  final DateTime min;
  final DateTime max;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => AppCard(
    child: SizedBox(
      height: 216,
      child: CupertinoTheme(
        data: CupertinoThemeData(
          brightness: Theme.of(context).brightness,
          textTheme: CupertinoTextThemeData(
            dateTimePickerTextStyle: context.text.headlineSmall?.copyWith(
              color: context.colors.onSurface,
            ),
          ),
        ),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          dateOrder: DatePickerDateOrder.dmy,
          initialDateTime: value.isBefore(min)
              ? min
              : (value.isAfter(max) ? max : value),
          minimumDate: min,
          maximumDate: max,
          itemExtent: 44,
          onDateTimeChanged: (d) {
            HapticFeedback.selectionClick();
            onChanged(DateTime(d.year, d.month, d.day));
          },
        ),
      ),
    ),
  );
}

/// Curva da previsão de peso, do valor atual até a meta.
class ProjectionChart extends StatelessWidget {
  const ProjectionChart({
    super.key,
    required this.fromText,
    required this.toText,
    required this.descending,
    required this.endLabel,
  });

  final String fromText;
  final String toText;
  final bool descending;
  final String endLabel;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 160,
          child: CustomPaint(
            painter: _ProjectionPainter(
              descending: descending,
              line: context.colors.primary,
              fill: context.pic.chartFill,
              grid: context.pic.chartGrid,
              surface: context.colors.surface,
            ),
            child: Padding(
              // Os rótulos ficam ao lado dos pontos de início e fim.
              padding: const EdgeInsets.fromLTRB(Space.lg, 2, Space.lg, 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: descending
                        ? Alignment.topLeft
                        : Alignment.bottomLeft,
                    child: _Pill(fromText, muted: true),
                  ),
                  const Spacer(),
                  Align(
                    alignment: descending
                        ? Alignment.bottomRight
                        : Alignment.topRight,
                    child: _Pill(toText),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: Space.sm),
        Row(
          children: [
            Text('Hoje', style: context.text.bodySmall),
            const Spacer(),
            Text(endLabel, style: context.text.bodySmall),
          ],
        ),
      ],
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, {this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 6),
    decoration: BoxDecoration(
      color: muted ? context.pic.surfaceMuted : context.colors.primary,
      borderRadius: BorderRadius.circular(Radii.pill),
    ),
    child: Text(
      text,
      style: context.text.labelLarge?.copyWith(
        color: muted ? context.colors.onSurface : context.colors.onPrimary,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _ProjectionPainter extends CustomPainter {
  _ProjectionPainter({
    required this.descending,
    required this.line,
    required this.fill,
    required this.grid,
    required this.surface,
  });

  final bool descending;
  final Color line;
  final Color fill;
  final Color grid;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    const top = 18.0;
    final bottom = size.height - 18;
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = top + (bottom - top) * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Curva que desacelera perto da meta (perda mais rápida no começo).
    double yAt(double t) {
      final eased = 1 - math.pow(1 - t, 1.8).toDouble();
      return descending
          ? top + (bottom - top) * eased
          : bottom - (bottom - top) * eased;
    }

    final path = Path()..moveTo(0, yAt(0));
    for (var i = 1; i <= 40; i++) {
      final t = i / 40;
      path.lineTo(size.width * t, yAt(t));
    }
    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    for (final t in [0.0, 1.0]) {
      final c = Offset(size.width * t, yAt(t));
      canvas.drawCircle(c, 7, Paint()..color = surface);
      canvas.drawCircle(
        c,
        7,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(_ProjectionPainter old) =>
      old.descending != descending || old.line != line;
}
