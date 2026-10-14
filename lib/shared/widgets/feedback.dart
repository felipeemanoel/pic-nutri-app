import 'package:flutter/material.dart';

import '../../core/error/app_failure.dart';

/// Mensagem amigável para qualquer erro (falhas da API já vêm traduzidas).
String friendlyMessage(Object error) =>
    error is AppFailure ? error.message : 'Algo deu errado. Tente novamente.';

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void showFailure(BuildContext context, Object error) =>
    showMessage(context, friendlyMessage(error));

/// Erros de validação por campo vindos da API (`error.errors`).
String? fieldError(Object? error, String field) {
  if (error is ValidationFailure) {
    final messages = error.fieldErrors[field];
    if (messages != null && messages.isNotEmpty) return messages.first;
  }
  return null;
}

/// Pede confirmação antes de ações importantes ou destrutivas.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  )
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
