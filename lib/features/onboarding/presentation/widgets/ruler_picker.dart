import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/design_system.dart';

/// Régua horizontal para escolher um número arrastando (peso, altura).
///
/// O valor fica sempre no centro, marcado por uma linha; cada passo vibra de
/// leve. [reference] destaca a faixa entre ele e o valor atual (ex.: do peso
/// atual até a meta).
class RulerPicker extends StatefulWidget {
  const RulerPicker({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    required this.labelEvery,
    required this.labelFor,
    this.majorEvery,
    this.reference,
    this.semanticLabel,
  });

  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;

  /// A cada quantos passos aparece um número embaixo da régua.
  final int labelEvery;

  /// Marca mais alta a cada N passos (padrão: metade de [labelEvery]).
  final int? majorEvery;
  final String Function(double value) labelFor;
  final double? reference;
  final String? semanticLabel;

  @override
  State<RulerPicker> createState() => _RulerPickerState();
}

class _RulerPickerState extends State<RulerPicker> {
  static const _spacing = 12.0;
  late final ScrollController _controller;
  late int _index;
  bool _dragging = false;

  int get _count => ((widget.max - widget.min) / widget.step).round() + 1;

  int _indexOf(double value) =>
      ((value.clamp(widget.min, widget.max) - widget.min) / widget.step)
          .round();

  double _valueAt(int index) =>
      double.parse((widget.min + index * widget.step).toStringAsFixed(2));

  @override
  void initState() {
    super.initState();
    _index = _indexOf(widget.value);
    _controller = ScrollController(initialScrollOffset: _index * _spacing);
  }

  @override
  void didUpdateWidget(RulerPicker old) {
    super.didUpdateWidget(old);
    final target = _indexOf(widget.value);
    final rangeChanged =
        old.min != widget.min ||
        old.max != widget.max ||
        old.step != widget.step;
    // Valor digitado ou unidade trocada: reposiciona sem animação.
    if ((target != _index || rangeChanged) && !_dragging) {
      _index = target;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) _controller.jumpTo(_index * _spacing);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n is ScrollStartNotification && n.dragDetails != null) {
      _dragging = true;
    }
    if (n is ScrollUpdateNotification) {
      final i = (_controller.offset / _spacing).round().clamp(0, _count - 1);
      if (i != _index) {
        _index = i;
        HapticFeedback.selectionClick();
        widget.onChanged(_valueAt(i));
      }
    }
    if (n is ScrollEndNotification) {
      _dragging = false;
      final snapped = _index * _spacing;
      if ((_controller.offset - snapped).abs() > 0.5) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_controller.hasClients) {
            _controller.animateTo(
              snapped,
              duration: Motion.fast,
              curve: Motion.curve,
            );
          }
        });
      }
    }
    return false;
  }

  void _nudge(int delta) {
    final i = (_index + delta).clamp(0, _count - 1);
    if (i == _index) return;
    _index = i;
    _controller.jumpTo(i * _spacing);
    widget.onChanged(_valueAt(i));
  }

  @override
  Widget build(BuildContext context) {
    final pic = context.pic;
    final colors = context.colors;
    final major = widget.majorEvery ?? (widget.labelEvery ~/ 2).clamp(1, 1000);
    final ref = widget.reference;
    final low = ref == null ? null : (ref < widget.value ? ref : widget.value);
    final high = ref == null ? null : (ref < widget.value ? widget.value : ref);

    return Semantics(
      label: widget.semanticLabel,
      value: widget.labelFor(widget.value),
      increasedValue: widget.labelFor(
        _valueAt((_index + 1).clamp(0, _count - 1)),
      ),
      decreasedValue: widget.labelFor(
        _valueAt((_index - 1).clamp(0, _count - 1)),
      ),
      onIncrease: () => _nudge(1),
      onDecrease: () => _nudge(-1),
      child: SizedBox(
        height: 96,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.maxWidth / 2 - _spacing / 2;
            return Stack(
              alignment: Alignment.center,
              children: [
                NotificationListener<ScrollNotification>(
                  onNotification: _onScroll,
                  child: ShaderMask(
                    // Esmaece as pontas para dar sensação de roda.
                    shaderCallback: (rect) => const LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black,
                        Colors.black,
                        Colors.transparent,
                      ],
                      stops: [0, 0.15, 0.85, 1],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: ListView.builder(
                      controller: _controller,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: side),
                      itemExtent: _spacing,
                      itemCount: _count,
                      itemBuilder: (context, i) {
                        final value = _valueAt(i);
                        final isLabel = i % widget.labelEvery == 0;
                        final isMajor = isLabel || i % major == 0;
                        final inRange =
                            low != null &&
                            high != null &&
                            value >= low - 1e-6 &&
                            value <= high + 1e-6;
                        return Column(
                          children: [
                            SizedBox(
                              height: 28,
                              child: isLabel
                                  ? OverflowBox(
                                      maxWidth: 64,
                                      child: Text(
                                        widget.labelFor(value),
                                        maxLines: 1,
                                        style: context.text.bodyMedium
                                            ?.copyWith(
                                              color: pic.textSecondary,
                                            ),
                                      ),
                                    )
                                  : null,
                            ),
                            Expanded(
                              child: Container(
                                color: inRange
                                    ? colors.primary.withValues(alpha: 0.12)
                                    : null,
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  width: 2,
                                  height: isLabel ? 44 : (isMajor ? 36 : 26),
                                  decoration: BoxDecoration(
                                    color: pic.border,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                // Indicador central.
                IgnorePointer(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 4,
                      height: 60,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
