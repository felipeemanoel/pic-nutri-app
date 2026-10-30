import 'package:flutter/material.dart';

import '../../../app/features.dart';

export '../../medication/data/medication_catalog.dart';

/// Uma opção de resposta do onboarding (cartão com ícone).
class OnboardingOption {
  const OnboardingOption(this.value, this.title, {this.subtitle, this.icon});

  final String value;
  final String title;
  final String? subtitle;
  final IconData? icon;
}

/// Opções das perguntas do onboarding. Os valores são os mesmos da API.
abstract final class OnboardingOptions {
  static List<OnboardingOption> get goals => [
    const OnboardingOption(
      'lose_weight',
      'Emagrecer',
      subtitle: 'Perder peso com saúde e sem radicalismo',
      icon: Icons.trending_down_rounded,
    ),
    const OnboardingOption(
      'maintain',
      'Manter meu peso',
      subtitle: 'Equilíbrio no dia a dia',
      icon: Icons.balance_rounded,
    ),
    const OnboardingOption(
      'gain_weight',
      'Ganhar peso',
      subtitle: 'Ganho gradual e com qualidade',
      icon: Icons.trending_up_rounded,
    ),
    const OnboardingOption(
      'improve_habits',
      'Comer melhor',
      subtitle: 'Melhorar hábitos e escolhas',
      icon: Icons.eco_outlined,
    ),
    if (AppFeatures.medical)
      const OnboardingOption(
        'medication_support',
        'Acompanhar meu tratamento',
        subtitle: 'Uso medicamento prescrito, como as canetas',
        icon: Icons.vaccines_outlined,
      ),
  ];

  static const motivations = [
    OnboardingOption(
      'confidence',
      'Me sentir mais confiante',
      icon: Icons.auto_awesome_outlined,
    ),
    OnboardingOption(
      'energy',
      'Ter mais disposição e energia',
      icon: Icons.bolt_outlined,
    ),
    OnboardingOption(
      'health_markers',
      'Melhorar meus exames',
      icon: Icons.monitor_heart_outlined,
    ),
    OnboardingOption(
      'clothes',
      'Voltar a usar as roupas que eu gosto',
      icon: Icons.checkroom_outlined,
    ),
    OnboardingOption(
      'special_event',
      'Tenho um evento especial chegando',
      icon: Icons.event_outlined,
    ),
    OnboardingOption('sleep', 'Dormir melhor', icon: Icons.bedtime_outlined),
    OnboardingOption(
      'long_term_health',
      'Cuidar da minha saúde a longo prazo',
      icon: Icons.favorite_outline,
    ),
  ];

  static List<OnboardingOption> get support => [
    const OnboardingOption(
      'organize_eating',
      'Quero organizar minha alimentação',
      icon: Icons.restaurant_menu_rounded,
    ),
    const OnboardingOption(
      'has_professional_plan',
      'Já tenho dieta ou orientação profissional',
      icon: Icons.assignment_outlined,
    ),
    if (AppFeatures.medical) ...const [
      OnboardingOption(
        'prescribed_medication',
        'Uso medicamento prescrito',
        subtitle: 'Ex.: canetas para emagrecimento ou diabetes',
        icon: Icons.vaccines_outlined,
      ),
      OnboardingOption(
        'find_professional',
        'Quero acompanhamento profissional',
        icon: Icons.support_agent_outlined,
      ),
    ],
  ];

  static const treatmentStage = [
    OnboardingOption(
      'using',
      'Já estou usando o medicamento',
      icon: Icons.vaccines_outlined,
    ),
    OnboardingOption(
      'not_started',
      'Ainda não comecei',
      icon: Icons.schedule_rounded,
    ),
  ];

  static const frequencies = [
    OnboardingOption('daily', 'Todo dia'),
    OnboardingOption('weekly', 'Uma vez por semana'),
    OnboardingOption('biweekly', 'A cada duas semanas'),
    OnboardingOption('monthly', 'Uma vez por mês'),
    OnboardingOption('other', 'Outro'),
    OnboardingOption('unknown', 'Ainda não sei'),
  ];

  /// Frequência do app → frequência aceita pela API (+ observação).
  static (String apiValue, String? note) apiFrequency(String value) =>
      switch (value) {
        'daily' => ('daily', null),
        'weekly' => ('weekly', null),
        'biweekly' => ('other', 'A cada duas semanas'),
        'monthly' => ('other', 'Uma vez por mês'),
        _ => ('other', null),
      };

  static List<OnboardingOption> challenges({required bool medication}) => [
    const OnboardingOption(
      'what_to_eat',
      'Não sei o que comer nem se estou comendo certo',
      icon: Icons.restaurant_outlined,
    ),
    const OnboardingOption(
      'consistency',
      'Começo bem, mas não consigo manter a rotina',
      icon: Icons.repeat_rounded,
    ),
    const OnboardingOption(
      'hunger',
      'Sinto muita fome ou vontade de doce',
      icon: Icons.cookie_outlined,
    ),
    const OnboardingOption(
      'tracking_progress',
      'Não vejo se estou evoluindo',
      icon: Icons.bar_chart_rounded,
    ),
    if (medication) ...const [
      OnboardingOption(
        'dose_schedule',
        'Me perco nos dias e horários das aplicações',
        icon: Icons.event_repeat_outlined,
      ),
      OnboardingOption(
        'side_effects',
        'Passo mal depois da aplicação',
        icon: Icons.sick_outlined,
      ),
    ],
  ];

  static const activity = [
    OnboardingOption(
      'sedentary',
      'Sedentário',
      subtitle: 'Pouca ou nenhuma atividade',
      icon: Icons.weekend_outlined,
    ),
    OnboardingOption(
      'light',
      'Levemente ativo',
      subtitle: 'Exercício 1 a 3 vezes por semana',
      icon: Icons.directions_walk_rounded,
    ),
    OnboardingOption(
      'moderate',
      'Moderadamente ativo',
      subtitle: 'Exercício 3 a 5 vezes por semana',
      icon: Icons.directions_bike_rounded,
    ),
    OnboardingOption(
      'active',
      'Ativo',
      subtitle: 'Exercício 6 a 7 vezes por semana',
      icon: Icons.fitness_center_rounded,
    ),
    OnboardingOption(
      'very_active',
      'Muito ativo',
      subtitle: 'Treino intenso ou trabalho físico',
      icon: Icons.local_fire_department_outlined,
    ),
  ];

  static const sexes = [
    OnboardingOption('female', 'Feminino', icon: Icons.female_rounded),
    OnboardingOption('male', 'Masculino', icon: Icons.male_rounded),
    OnboardingOption(
      'unspecified',
      'Prefiro não informar',
      subtitle: 'Sem essa informação, você define as metas manualmente',
    ),
  ];
}
