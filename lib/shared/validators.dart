/// Validações locais de formulário (a API valida de novo; aqui é só UX).
abstract final class Validators {
  static String? required(String? value, [String label = 'Campo']) =>
      (value == null || value.trim().isEmpty) ? '$label obrigatório' : null;

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe o e-mail';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
    return ok ? null : 'E-mail inválido';
  }

  static String? password(String? value) {
    if (value == null || value.length < 8) {
      return 'Use pelo menos 8 caracteres';
    }
    return null;
  }

  /// Número dentro de um intervalo, aceitando vírgula como separador decimal.
  static String? Function(String?) number({
    required double min,
    required double max,
    String unit = '',
    bool optional = false,
  }) => (value) {
    if (value == null || value.trim().isEmpty) {
      return optional ? null : 'Obrigatório';
    }
    final parsed = parseNumber(value);
    if (parsed == null) return 'Número inválido';
    if (parsed < min || parsed > max) {
      return 'Entre ${_fmt(min)} e ${_fmt(max)}${unit.isEmpty ? '' : ' $unit'}';
    }
    return null;
  };

  static double? parseNumber(String? value) =>
      value == null ? null : double.tryParse(value.trim().replaceAll(',', '.'));

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}
