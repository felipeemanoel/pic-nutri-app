import '../app/features.dart';

/// Rótulos em português para os valores enviados/recebidos da API.
abstract final class Labels {
  static const goals = {
    'lose_weight': 'Emagrecimento',
    'maintain': 'Manutenção do peso',
    'gain_weight': 'Ganho de peso',
    'improve_habits': 'Melhorar hábitos alimentares',
    'nutrition_tracking': 'Acompanhamento nutricional',
    'medication_support': 'Acompanhamento durante uso de medicamento prescrito',
  };

  /// Objetivos oferecidos para escolha (sem os de medicamento quando o
  /// recurso está desligado). `goals` continua completo para exibição.
  static Map<String, String> get goalOptions => {
    for (final e in goals.entries)
      if (AppFeatures.medical || e.key != 'medication_support') e.key: e.value,
  };

  static const activityLevels = {
    'sedentary': 'Sedentário — pouca ou nenhuma atividade',
    'light': 'Leve — exercícios 1 a 3 vezes por semana',
    'moderate': 'Moderado — exercícios 3 a 5 vezes por semana',
    'active': 'Ativo — exercícios 6 a 7 vezes por semana',
    'very_active': 'Muito ativo — treino intenso ou trabalho físico',
  };

  static const sexes = {
    'female': 'Feminino',
    'male': 'Masculino',
    'unspecified': 'Prefiro não informar',
  };

  static const dietaryPreferences = {
    'omnivore': 'Onívoro',
    'vegetarian': 'Vegetariano',
    'vegan': 'Vegano',
    'pescatarian': 'Pescetariano',
    'low_carb': 'Low carb',
    'lactose_free': 'Sem lactose',
    'gluten_free': 'Sem glúten',
  };

  static const allergies = {
    'gluten': 'Glúten',
    'lactose': 'Lactose',
    'milk_protein': 'Proteína do leite',
    'egg': 'Ovo',
    'peanut': 'Amendoim',
    'tree_nuts': 'Castanhas e nozes',
    'soy': 'Soja',
    'fish': 'Peixe',
    'shellfish': 'Frutos do mar',
    'sesame': 'Gergelim',
  };

  static const supportPreferences = {
    'organize_eating': 'Quero organizar minha alimentação',
    'has_professional_plan': 'Já tenho dieta ou orientação profissional',
    'prescribed_medication': 'Uso medicamento prescrito',
    'find_professional': 'Quero acompanhamento profissional',
  };

  static Map<String, String> get supportOptions => {
    for (final e in supportPreferences.entries)
      if (AppFeatures.medical || !{'prescribed_medication', 'find_professional'}.contains(e.key))
        e.key: e.value,
  };

  static const guidanceSources = {
    'nutritionist': 'Nutricionista',
    'physician': 'Médico(a)',
    'physical_educator': 'Profissional de educação física',
    'other': 'Outro',
  };

  static const professionalCategories = {
    'nutritionist': 'Nutricionista',
    'physical_educator': 'Educação física / personal trainer',
  };

  static const careModalities = {
    'online': 'Online',
    'in_person': 'Presencial',
    'any': 'Tanto faz',
  };

  static String of(Map<String, String> map, String? key) =>
      key == null ? 'Não informado' : (map[key] ?? key);
}
