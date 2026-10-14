import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/labels.dart';
import '../../../shared/validators.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/data/account.dart';
import '../../food/data/nutrition_models.dart';
import '../data/profile_repository.dart';

/// Edição do perfil e das metas. Envia só o que mudou.
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final Account _account = ref.read(currentAccountProvider)!;
  late final Profile _p = _account.profile;

  late final _name = TextEditingController(text: _account.name);
  late final _height = TextEditingController(text: _num(_p.heightCm));
  late final _goalWeight = TextEditingController(text: _num(_p.goalWeightKg));
  late final _restrictions = TextEditingController(
    text: _p.dietaryRestrictions ?? '',
  );
  late final _calories = TextEditingController(
    text: _p.dailyCalorieGoal?.toString() ?? '',
  );
  late final _protein = TextEditingController(
    text: _p.proteinGoalG?.toString() ?? '',
  );
  late final _carbs = TextEditingController(
    text: _p.carbsGoalG?.toString() ?? '',
  );
  late final _fat = TextEditingController(text: _p.fatGoalG?.toString() ?? '');
  late final _water = TextEditingController(text: _p.waterGoalMl.toString());
  late String? _goal = _p.goal;
  late String? _activity = _p.activityLevel;
  late final Set<String> _preferences = {..._p.dietaryPreferences};
  late final Set<String> _allergies = {..._p.allergies};
  late final Set<String> _plannedMeals = {..._p.plannedMeals};
  late final _avoid = TextEditingController(text: _p.avoidFoods ?? '');
  late bool _medication = _p.medicationTrackingEnabled;
  bool _saving = false;
  Object? _error;

  static String _num(double? v) => v == null
      ? ''
      : (v == v.roundToDouble() ? v.toInt().toString() : v.toString());

  @override
  void dispose() {
    for (final c in [
      _name,
      _height,
      _goalWeight,
      _restrictions,
      _avoid,
      _calories,
      _protein,
      _carbs,
      _fat,
      _water,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _int(TextEditingController c) => Validators.parseNumber(c.text)?.round();

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(profileRepositoryProvider);
    final session = ref.read(sessionControllerProvider.notifier);
    try {
      if (_name.text.trim() != _account.name) {
        await repo.updateName(_name.text);
      }
      final restrictions = _restrictions.text.trim().isEmpty
          ? null
          : _restrictions.text.trim();
      final prefs = _preferences.toList()..sort();
      final originalPrefs = [..._p.dietaryPreferences]..sort();
      final changes = <String, Object?>{
        if (_goal != _p.goal) 'goal': _goal,
        if (_activity != _p.activityLevel) 'activity_level': _activity,
        if (Validators.parseNumber(_height.text) case final h?
            when h != _p.heightCm)
          'height_cm': h,
        if (Validators.parseNumber(_goalWeight.text) != _p.goalWeightKg)
          'goal_weight_kg': Validators.parseNumber(_goalWeight.text),
        if (prefs.join(',') != originalPrefs.join(','))
          'dietary_preferences': prefs,
        if (restrictions != _p.dietaryRestrictions)
          'dietary_restrictions': restrictions,
        if ((_allergies.toList()..sort()).join(',') != ([..._p.allergies]..sort()).join(','))
          'allergies': _allergies.toList()..sort(),
        if ((_avoid.text.trim().isEmpty ? null : _avoid.text.trim()) != _p.avoidFoods)
          'avoid_foods': _avoid.text.trim().isEmpty ? null : _avoid.text.trim(),
        if ((_plannedMeals.toList()..sort()).join(',') != ([..._p.plannedMeals]..sort()).join(','))
          'planned_meals': [
            for (final t in MealTypes.labels.keys)
              if (_plannedMeals.contains(t)) t,
          ],
        if (_int(_calories) != _p.dailyCalorieGoal)
          'daily_calorie_goal': _int(_calories),
        if (_int(_protein) != _p.proteinGoalG) 'protein_goal_g': _int(_protein),
        if (_int(_carbs) != _p.carbsGoalG) 'carbs_goal_g': _int(_carbs),
        if (_int(_fat) != _p.fatGoalG) 'fat_goal_g': _int(_fat),
        if ((_int(_water) ?? 2000) != _p.waterGoalMl)
          'water_goal_ml': _int(_water) ?? 2000,
        if (_medication != _p.medicationTrackingEnabled)
          'medication_tracking_enabled': _medication,
      };
      if (changes.isNotEmpty) {
        await repo.updateProfile(changes);
      }
      await session.reloadAccount();
      if (!mounted) return;
      showMessage(context, 'Perfil atualizado.');
      context.pop();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
      showFailure(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!_account.consents.healthData)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'A autorização para dados de saúde está revogada. '
                    'Só é possível alterar o nome e a meta de água.',
                  ),
                ),
              ),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(
                labelText: 'Nome',
                errorText: fieldError(_error, 'name'),
              ),
              validator: (v) => Validators.required(v, 'Nome'),
            ),
            const SizedBox(height: 20),
            Text('Objetivo', style: theme.textTheme.titleSmall),
            ChoiceList(
              options: Labels.goals,
              value: _goal,
              onChanged: (v) => setState(() => _goal = v),
            ),
            const SizedBox(height: 12),
            NumberField(
              controller: _height,
              label: 'Altura',
              unit: 'cm',
              min: 100,
              max: 250,
              decimal: false,
              optional: true,
            ),
            const SizedBox(height: 12),
            NumberField(
              controller: _goalWeight,
              label: 'Peso desejado (opcional)',
              unit: 'kg',
              min: 30,
              max: 300,
              optional: true,
            ),
            const SizedBox(height: 20),
            Text('Atividade física', style: theme.textTheme.titleSmall),
            ChoiceList(
              options: Labels.activityLevels,
              value: _activity,
              onChanged: (v) => setState(() => _activity = v),
            ),
            const SizedBox(height: 20),
            Text('Preferências alimentares', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in Labels.dietaryPreferences.entries)
                  FilterChip(
                    label: Text(entry.value),
                    selected: _preferences.contains(entry.key),
                    onSelected: (s) => setState(
                      () => s
                          ? _preferences.add(entry.key)
                          : _preferences.remove(entry.key),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 4),
            Text('Alergias e intolerâncias', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final entry in Labels.allergies.entries)
                  FilterChip(
                    label: Text(entry.value),
                    selected: _allergies.contains(entry.key),
                    onSelected: (s) => setState(
                      () => s ? _allergies.add(entry.key) : _allergies.remove(entry.key),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _restrictions,
              decoration: const InputDecoration(
                labelText: 'Outras restrições (opcional)',
                helperText: 'Ex.: restrição religiosa, orientação médica.',
              ),
              maxLength: 1000,
              maxLines: 3,
            ),
            TextFormField(
              controller: _avoid,
              decoration: const InputDecoration(
                labelText: 'Alimentos que prefere evitar (opcional)',
                helperText: 'Separe por vírgulas. Usado nas sugestões do assistente.',
              ),
              maxLength: 500,
            ),
            const SizedBox(height: 12),
            Text('Refeições que você costuma fazer', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'O início mostra as que ainda faltam registrar no dia.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final entry in MealTypes.labels.entries)
                  if (entry.key != 'other')
                    FilterChip(
                      label: Text(entry.value),
                      selected: _plannedMeals.contains(entry.key),
                      onSelected: (s) => setState(
                        () => s ? _plannedMeals.add(entry.key) : _plannedMeals.remove(entry.key),
                      ),
                    ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Dados de alergias e restrições são protegidos e usados só para personalizar sugestões.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Metas diárias (referências ajustáveis)',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            NumberField(
              controller: _calories,
              label: 'Calorias',
              unit: 'kcal',
              min: 800,
              max: 6000,
              decimal: false,
              optional: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: NumberField(
                    controller: _protein,
                    label: 'Proteínas',
                    unit: 'g',
                    min: 0,
                    max: 400,
                    decimal: false,
                    optional: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NumberField(
                    controller: _carbs,
                    label: 'Carboidratos',
                    unit: 'g',
                    min: 0,
                    max: 800,
                    decimal: false,
                    optional: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NumberField(
                    controller: _fat,
                    label: 'Gorduras',
                    unit: 'g',
                    min: 0,
                    max: 300,
                    decimal: false,
                    optional: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            NumberField(
              controller: _water,
              label: 'Água',
              unit: 'ml',
              min: 500,
              max: 6000,
              decimal: false,
            ),
            SwitchListTile(
              value: _medication,
              onChanged: (v) => setState(() => _medication = v),
              contentPadding: EdgeInsets.zero,
              title: const Text('Registrar uso de medicamento prescrito'),
            ),
            const SizedBox(height: 16),
            LoadingButton(label: 'Salvar', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
