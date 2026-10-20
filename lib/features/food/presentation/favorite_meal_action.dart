import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/feedback.dart';
import '../data/food_repository.dart';
import '../data/nutrition_models.dart';

/// Salva uma refeição já registrada para reutilizar, sem registrar outra refeição.
Future<void> saveFavoriteMeal(
  BuildContext context,
  WidgetRef ref,
  Meal meal,
) async {
  var name = meal.displayName;
  final chosenName = await showDialog<String>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: const Text('Salvar refeição favorita'),
      content: TextFormField(
        initialValue: name,
        onChanged: (value) => name = value,
        maxLength: 80,
        decoration: const InputDecoration(
          labelText: 'Nome da refeição',
          helperText: 'Reutilize os mesmos alimentos e quantidades depois.',
          helperMaxLines: 2,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialog).pop(name.trim()),
          child: const Text('Salvar favorita'),
        ),
      ],
    ),
  );
  if (chosenName == null || !context.mounted) return;
  try {
    await ref
        .read(foodRepositoryProvider)
        .saveAsTemplate(meal.id, name: chosenName);
    ref.invalidate(mealTemplatesProvider);
    if (context.mounted) showMessage(context, 'Refeição salva nos favoritos.');
  } on Object catch (error) {
    if (context.mounted) showFailure(context, error);
  }
}
