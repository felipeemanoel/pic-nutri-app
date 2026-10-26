import '../../../app/features.dart';

/// Etapas do onboarding salvas na API (pontos de retomada). Cada etapa reúne
/// uma ou mais telas de pergunta ([OnboardingScreen]).
abstract final class OnboardingSteps {
  static const welcome = 'welcome';
  static const consent = 'consent';
  static const goals = 'goals';
  static const support = 'support';
  static const essentials = 'essentials';
  static const routine = 'routine';
  static const guidance = 'guidance';
  static const medication = 'medication';
  static const care = 'care';
  static const targets = 'targets';
  static const summary = 'summary';

  static const labels = {
    essentials: 'Dados básicos',
    routine: 'Alimentação e rotina',
    guidance: 'Orientação profissional',
    medication: 'Medicamento prescrito',
    care: 'Preferências de atendimento',
    targets: 'Metas diárias',
  };

  /// Etapas deixadas para depois automaticamente (com consentimento): entram
  /// como "puladas", e o Início convida a completar no perfil.
  static List<String> deferred({required bool consent}) => [
    if (consent) routine,
  ];

  /// Quem parou numa etapa que saiu do fluxo retoma na seguinte equivalente.
  static String? resumeAt(String? saved) => switch (saved) {
    routine => targets,
    care => summary,
    _ => saved,
  };

  static bool skippable(String step) => labels.containsKey(step);
}

/// Telas do onboarding: uma pergunta por tela.
enum OnboardingScreen {
  welcome(OnboardingSteps.welcome),
  consent(OnboardingSteps.consent),
  goal(OnboardingSteps.goals),
  motivations(OnboardingSteps.goals),
  support(OnboardingSteps.support),
  treatmentStage(OnboardingSteps.medication),
  medicationName(OnboardingSteps.medication),
  medicationFrequency(OnboardingSteps.medication),
  medicationDose(OnboardingSteps.medication),
  treatmentStart(OnboardingSteps.medication),
  challenge(OnboardingSteps.essentials),
  birthDate(OnboardingSteps.essentials),
  sex(OnboardingSteps.essentials),
  height(OnboardingSteps.essentials),
  weight(OnboardingSteps.essentials),
  startWeight(OnboardingSteps.essentials),
  goalWeight(OnboardingSteps.essentials),
  pace(OnboardingSteps.essentials),
  activity(OnboardingSteps.essentials),
  projection(OnboardingSteps.essentials),
  targets(OnboardingSteps.targets),
  guidance(OnboardingSteps.guidance),
  features(OnboardingSteps.summary),
  summary(OnboardingSteps.summary);

  const OnboardingScreen(this.step);

  /// Etapa da API a que a tela pertence.
  final String step;
}

/// Quais telas aparecem, na ordem, conforme as respostas até aqui.
abstract final class OnboardingFlow {
  static bool wantsWeightGoal(String? goal) =>
      goal == 'lose_weight' ||
      goal == 'gain_weight' ||
      goal == 'medication_support';

  static List<OnboardingScreen> screens({
    required bool consent,
    required Set<String> support,
    String? goal,
    String? treatmentStage,
    bool hasWeight = false,
    bool hasGoalWeight = false,
    bool paceApplies = false,
    bool medicalFeatures = AppFeatures.medical,
  }) {
    final medication =
        medicalFeatures && consent && support.contains('prescribed_medication');
    final using = treatmentStage == 'using';
    final weightGoal = wantsWeightGoal(goal) && hasWeight;
    return [
      OnboardingScreen.welcome,
      // Quem já autorizou não vê o pedido de novo.
      if (!consent) OnboardingScreen.consent,
      OnboardingScreen.goal,
      // Motivações e dados do corpo são dados de saúde: só com autorização.
      if (consent) OnboardingScreen.motivations,
      OnboardingScreen.support,
      if (medication) ...[
        OnboardingScreen.treatmentStage,
        OnboardingScreen.medicationName,
        OnboardingScreen.medicationFrequency,
        OnboardingScreen.medicationDose,
        if (using) OnboardingScreen.treatmentStart,
      ],
      if (consent) ...[
        OnboardingScreen.challenge,
        OnboardingScreen.birthDate,
        OnboardingScreen.sex,
        OnboardingScreen.height,
        OnboardingScreen.weight,
        if (medication && using && hasWeight) OnboardingScreen.startWeight,
        if (weightGoal) OnboardingScreen.goalWeight,
        if (weightGoal && paceApplies) OnboardingScreen.pace,
        OnboardingScreen.activity,
        if (weightGoal && paceApplies && hasGoalWeight)
          OnboardingScreen.projection,
        OnboardingScreen.targets,
        if (support.contains('has_professional_plan'))
          OnboardingScreen.guidance,
      ],
      OnboardingScreen.features,
      OnboardingScreen.summary,
    ];
  }
}
