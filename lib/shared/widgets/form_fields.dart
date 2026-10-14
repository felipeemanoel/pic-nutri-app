import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/formatters.dart';
import '../validators.dart';

/// Campo numérico que aceita vírgula ou ponto decimal.
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.controller,
    required this.label,
    required this.min,
    required this.max,
    this.unit = '',
    this.decimal = true,
    this.optional = false,
    this.helper,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final double min;
  final double max;
  final String unit;
  final bool decimal;
  final bool optional;
  final String? helper;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      suffixText: unit.isEmpty ? null : unit,
      helperText: helper,
      errorText: errorText,
    ),
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    inputFormatters: [
      FilteringTextInputFormatter.allow(
        decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
      ),
    ],
    validator: Validators.number(
      min: min,
      max: max,
      unit: unit,
      optional: optional,
    ),
    onChanged: onChanged,
  );
}

/// Campo de data que abre o seletor nativo.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.initialPickerDate,
    this.validator,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? initialPickerDate;
  final String? Function(DateTime?)? validator;

  @override
  Widget build(BuildContext context) => FormField<DateTime>(
    initialValue: value,
    validator: validator,
    builder: (field) => InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? initialPickerDate ?? lastDate,
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (picked != null) {
          field.didChange(picked);
          onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: field.errorText,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(value == null ? 'Selecionar' : Fmt.shortDate(value!)),
      ),
    ),
  );
}

/// Lista de opções exclusivas com descrição (cartões selecionáveis).
class ChoiceList extends StatelessWidget {
  const ChoiceList({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final Map<String, String> options;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => RadioGroup<String>(
    groupValue: value,
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
    child: Column(
      children: [
        for (final entry in options.entries)
          RadioListTile<String>(
            value: entry.key,
            title: Text(entry.value),
            contentPadding: EdgeInsets.zero,
          ),
      ],
    ),
  );
}
