import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';

/// Executado antes de todos os testes: carrega formatos de data em pt-BR.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await initializeDateFormatting('pt_BR');
  await testMain();
}
