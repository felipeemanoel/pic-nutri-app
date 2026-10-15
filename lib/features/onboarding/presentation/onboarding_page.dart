import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/features.dart';
import '../../../core/design/design_system.dart';
import '../../../core/utils/device_timezone.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/request_id.dart';
import '../../../shared/labels.dart';
import '../../../shared/validators.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/legal_summary.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/data/account.dart';
import '../../profile/data/profile_repository.dart';
import '../../progress/data/body_repository.dart';
import '../data/goal_suggestion.dart';

/// Etapas do onboarding (mesmos códigos usados pela API para retomar).
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

  /// Sequência conforme as escolhas: só aparecem as perguntas que fazem
  /// sentido para cada pessoa.
  static List<String> sequence({required bool consent, required Set<String> support}) => [
    welcome,
    // Os parâmetros têm o mesmo nome das etapas: qualifica para não confundir.
    OnboardingSteps.consent,
    goals,
    OnboardingSteps.support,
    if (consent) essentials,
    if (consent) routine,
    if (consent && support.contains('has_professional_plan')) guidance,
    if (AppFeatures.medical && consent && support.contains('prescribed_medication')) medication,
    if (AppFeatures.medical && support.contains('find_professional')) care,
    if (consent) targets,
    summary,
  ];

  static bool skippable(String step) => labels.containsKey(step);
}

/// Onboarding personalizado: boas-vindas, objetivos, forma de acompanhamento,
/// perguntas condicionais e resumo. O progresso fica salvo no servidor e pode
/// ser retomado; etapas não essenciais podem ser puladas.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _finishRequestId = newRequestId();
  final _weightRequestId = newRequestId();
  bool _busy = false;
  String _step = OnboardingSteps.welcome;

  late bool _consent;
  final Set<String> _skipped = {};
  final List<String> _goals = [];
  final Set<String> _support = {};

  // Dados básicos
  DateTime? _birthDate;
  String? _sex;
  String? _activity;
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _goalWeight = TextEditingController();
  bool _weightSaved = false;

  // Alimentação e rotina
  final Set<String> _preferences = {};
  final Set<String> _allergies = {};
  final Set<String> _plannedMeals = {'breakfast', 'lunch', 'dinner'};
  final _restrictions = TextEditingController();

  // Orientação profissional
  final _guidance = TextEditingController();
  String? _guidanceSource;

  // Medicamento
  bool _medicationTracking = false;

  // Atendimento
  final Set<String> _careCategories = {};
  String _careModality = 'any';
  final _careCity = TextEditingController();
  final _careState = TextEditingController();

  // Metas
  GoalSuggestion? _suggestion;
  Object? _suggestionError;
  bool _suggestionLoading = false;
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  final _water = TextEditingController(text: '2000');

  @override
  void initState() {
    super.initState();
    final account = ref.read(currentAccountProvider);
    _consent = account?.consents.healthData ?? false;
    if (account != null) _restore(account);
  }

  /// Retoma de onde a pessoa parou, com as respostas já salvas.
  void _restore(Account account) {
    final p = account.profile;
    _goals.addAll(p.goals);
    _support.addAll(p.supportPreferences);
    _skipped.addAll(account.onboardingSkipped);
    _birthDate = p.birthDate;
    _sex = p.sex;
    _activity = p.activityLevel;
    if (p.heightCm != null) _height.text = Fmt.decimal(p.heightCm!);
    if (p.currentWeightKg != null) {
      _weight.text = Fmt.decimal(p.currentWeightKg!);
      _weightSaved = true;
    }
    if (p.goalWeightKg != null) _goalWeight.text = Fmt.decimal(p.goalWeightKg!);
    _preferences.addAll(p.dietaryPreferences);
    _allergies.addAll(p.allergies);
    if (p.plannedMeals.isNotEmpty) {
      _plannedMeals
        ..clear()
        ..addAll(p.plannedMeals);
    }
    _restrictions.text = p.dietaryRestrictions ?? '';
    _guidance.text = p.professionalGuidance ?? '';
    _guidanceSource = p.professionalGuidanceSource;
    _medicationTracking = p.medicationTrackingEnabled;
    _careCategories.addAll(p.careCategories);
    _careModality = p.careModality ?? 'any';
    _careCity.text = p.careCity ?? '';
    _careState.text = p.careState ?? '';
    if (p.dailyCalorieGoal != null) _calories.text = '${p.dailyCalorieGoal}';
    if (p.proteinGoalG != null) _protein.text = '${p.proteinGoalG}';
    if (p.carbsGoalG != null) _carbs.text = '${p.carbsGoalG}';
    if (p.fatGoalG != null) _fat.text = '${p.fatGoalG}';
    _water.text = '${p.waterGoalMl}';

    final saved = account.onboardingStep;
    if (saved != null && _sequence.contains(saved)) _step = saved;
  }

  @override
  void dispose() {
    for (final c in [
      _height, _weight, _goalWeight, _restrictions, _guidance, _careCity, _careState,
      _calories, _protein, _carbs, _fat, _water,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _sequence => OnboardingSteps.sequence(consent: _consent, support: _support);

  int get _index => _sequence.indexOf(_step).clamp(0, _sequence.length - 1);

  String? get _nextStep {
    final seq = _sequence;
    final i = seq.indexOf(_step);
    return i >= 0 && i < seq.length - 1 ? seq[i + 1] : null;
  }

  void _back() {
    if (_index == 0) return;
    setState(() => _step = _sequence[_index - 1]);
  }

  // ---------------------------------------------------------------- Ações

  Future<void> _continue() async {
    if (_step == OnboardingSteps.summary) return _finish();
    if (_step == OnboardingSteps.goals && _goals.isEmpty) {
      showMessage(context, 'Escolha pelo menos um objetivo.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? true)) return;
    _skipped.remove(_step);
    await _advance(_dataFor(_step));
  }

  Future<void> _skip() async {
    _skipped.add(_step);
    await _advance(const {});
  }

  Future<void> _advance(Map<String, Object?> data) async {
    final next = _nextStep;
    if (next == null) return;
    setState(() => _busy = true);
    try {
      final profile = ref.read(profileRepositoryProvider);
      if (_step == OnboardingSteps.essentials && !_skipped.contains(_step)) await _saveWeight();
      final account = await profile.saveOnboardingProgress(
        step: next,
        data: data,
        skipped: _skipped.toList(),
      );
      ref.read(sessionControllerProvider.notifier).updateAccount(account);
      if (!mounted) return;
      setState(() => _step = next);
      if (next == OnboardingSteps.targets) await _loadSuggestion();
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveWeight() async {
    final weight = Validators.parseNumber(_weight.text);
    if (weight == null || _weightSaved) return;
    await ref.read(bodyRepositoryProvider).saveWeight(
      weightKg: weight,
      measuredAt: DateTime.now(),
      requestId: _weightRequestId,
    );
    _weightSaved = true;
  }

  Future<void> _grantConsent() async {
    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).setConsent('health_data', granted: true);
      _consent = true;
      await _advance({'timezone': await deviceTimezone() ?? 'America/Sao_Paulo'});
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _declineConsent() async {
    _consent = false;
    await _advance({'timezone': await deviceTimezone() ?? 'America/Sao_Paulo'});
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    try {
      final account = await ref.read(profileRepositoryProvider).finishOnboarding(requestId: _finishRequestId);
      ref.read(sessionControllerProvider.notifier).updateAccount(account);
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  int? _intOf(TextEditingController c) => Validators.parseNumber(c.text)?.round();
  String? _textOf(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  /// Dados enviados ao concluir cada etapa (só o que pertence a ela).
  Map<String, Object?> _dataFor(String step) => switch (step) {
    OnboardingSteps.goals => {'goals': _goals},
    // Preferências podem indicar uso de medicamento: só com consentimento.
    OnboardingSteps.support => _consent ? {'support_preferences': _support.toList()} : const {},
    OnboardingSteps.essentials => {
      'birth_date': ?_birthDate?.toIso8601String().substring(0, 10),
      'sex': ?_sex,
      'height_cm': ?Validators.parseNumber(_height.text),
      'activity_level': ?_activity,
      'goal_weight_kg': Validators.parseNumber(_goalWeight.text),
    },
    OnboardingSteps.routine => {
      'dietary_preferences': _preferences.toList(),
      'allergies': _allergies.toList(),
      'dietary_restrictions': _textOf(_restrictions),
      'planned_meals': _plannedMeals.toList(),
    },
    OnboardingSteps.guidance => {
      'professional_guidance': _textOf(_guidance),
      'professional_guidance_source': _guidanceSource,
    },
    OnboardingSteps.medication => {'medication_tracking_enabled': _medicationTracking},
    OnboardingSteps.care => {
      'care_preferences': {
        'categories': _careCategories.toList(),
        'modality': _careModality,
        'city': _textOf(_careCity),
        'state': _textOf(_careState)?.toUpperCase(),
      },
    },
    OnboardingSteps.targets => {
      'daily_calorie_goal': _intOf(_calories),
      'protein_goal_g': _intOf(_protein),
      'carbs_goal_g': _intOf(_carbs),
      'fat_goal_g': _intOf(_fat),
      'water_goal_ml': _intOf(_water) ?? 2000,
    },
    _ => const {},
  };

  bool get _canSuggest =>
      _birthDate != null &&
      _sex != null &&
      _activity != null &&
      _goals.isNotEmpty &&
      Validators.parseNumber(_height.text) != null &&
      Validators.parseNumber(_weight.text) != null;

  Future<void> _loadSuggestion() async {
    if (!_canSuggest) return;
    setState(() {
      _suggestion = null;
      _suggestionError = null;
      _suggestionLoading = true;
    });
    try {
      final suggestion = await ref.read(profileRepositoryProvider).suggestGoals(
        sex: _sex!,
        birthDate: _birthDate!,
        heightCm: Validators.parseNumber(_height.text)!,
        weightKg: Validators.parseNumber(_weight.text)!,
        activityLevel: _activity!,
        goal: _goals.first,
      );
      if (!mounted) return;
      setState(() {
        _suggestion = suggestion;
        // Não sobrescreve metas que a pessoa já informou (ex.: do profissional).
        if (_calories.text.isEmpty) _calories.text = suggestion.caloriesKcal?.toString() ?? '';
        if (_protein.text.isEmpty) _protein.text = suggestion.proteinG?.toString() ?? '';
        if (_carbs.text.isEmpty) _carbs.text = suggestion.carbsG?.toString() ?? '';
        if (_fat.text.isEmpty) _fat.text = suggestion.fatG?.toString() ?? '';
        if (suggestion.waterMl != null) _water.text = suggestion.waterMl.toString();
      });
    } on Object catch (error) {
      if (mounted) setState(() => _suggestionError = error);
    } finally {
      if (mounted) setState(() => _suggestionLoading = false);
    }
  }

  // ---------------------------------------------------------------- Tela

  @override
  Widget build(BuildContext context) {
    final seq = _sequence;
    final index = _index;
    final skippable = OnboardingSteps.skippable(_step);

    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(index == 0 ? 'Bem-vindo(a)' : 'Configuração inicial (${index + 1} de ${seq.length})'),
          leading: index > 0
              ? IconButton(tooltip: 'Voltar', icon: const Icon(Icons.arrow_back), onPressed: _busy ? null : _back)
              : null,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(value: (index + 1) / seq.length),
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(Space.xl),
              children: _content(),
            ),
          ),
        ),
        bottomNavigationBar: _step == OnboardingSteps.consent
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Space.xl, Space.sm, Space.xl, Space.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LoadingButton(
                        label: switch (_step) {
                          OnboardingSteps.welcome => 'Começar',
                          OnboardingSteps.summary => 'Concluir e ir para o início',
                          _ => 'Continuar',
                        },
                        loading: _busy,
                        onPressed: _continue,
                      ),
                      if (skippable)
                        TextButton(
                          onPressed: _busy ? null : _skip,
                          child: const Text('Pular por agora'),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  List<Widget> _content() => switch (_step) {
    OnboardingSteps.welcome => _welcome(),
    OnboardingSteps.consent => _consentStep(),
    OnboardingSteps.goals => _goalsStep(),
    OnboardingSteps.support => _supportStep(),
    OnboardingSteps.essentials => _essentialsStep(),
    OnboardingSteps.routine => _routineStep(),
    OnboardingSteps.guidance => _guidanceStep(),
    OnboardingSteps.medication => _medicationStep(),
    OnboardingSteps.care => _careStep(),
    OnboardingSteps.targets => _targetsStep(),
    _ => _summaryStep(),
  };

  Widget _title(String text, [String? subtitle]) => Padding(
    padding: const EdgeInsets.only(bottom: Space.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(text, style: context.text.headlineSmall)),
        if (subtitle != null) ...[
          const SizedBox(height: Space.xs),
          Text(subtitle, style: context.text.bodyMedium?.copyWith(color: context.pic.textSecondary)),
        ],
      ],
    ),
  );

  List<Widget> _welcome() => [
    const SizedBox(height: Space.lg),
    const Center(child: PicNutriWordmark(iconSize: 64, showTagline: true)),
    const SizedBox(height: Space.xxl),
    _title('Que bom ter você aqui', 'Algumas perguntas rápidas para deixar o PicNutri do seu jeito. Leva cerca de 2 minutos.'),
    const _Bullet(icon: Icons.restaurant_menu, text: 'Registre refeições por foto, texto ou busca no banco de alimentos.'),
    const _Bullet(icon: Icons.insights, text: 'Acompanhe peso, medidas e hábitos com gráficos claros.'),
    const _Bullet(icon: Icons.auto_awesome, text: 'Tire dúvidas com o assistente, sempre com estimativas sinalizadas.'),
    const _Bullet(icon: Icons.groups_outlined, text: 'Encontre nutricionistas e profissionais de educação física.'),
    const _Bullet(icon: Icons.save_outlined, text: 'Você pode pular etapas e continuar depois: suas respostas ficam salvas.'),
  ];

  List<Widget> _consentStep() => [
    _title(
      'Seus dados de saúde',
      'Para personalizar o acompanhamento, vamos perguntar sobre idade, altura, peso, '
          'alimentação e, se for o caso, uso de medicamento. Esses são dados de saúde e só são usados com a sua autorização.',
    ),
    const _Bullet(icon: Icons.lock_outline, text: 'Seus dados ficam protegidos e não são compartilhados sem a sua autorização.'),
    const _Bullet(icon: Icons.tune, text: 'Usamos esses dados para calcular totais e sugerir metas de referência, que você pode ajustar.'),
    const _Bullet(icon: Icons.medical_information_outlined, text: 'O PicNutri não substitui orientação de médicos ou nutricionistas.'),
    const _Bullet(icon: Icons.delete_outline, text: 'Você pode revogar a autorização, exportar ou excluir seus dados quando quiser.'),
    TextButton(onPressed: () => showLegalSummary(context), child: const Text('Como usamos seus dados')),
    const SizedBox(height: Space.lg),
    LoadingButton(label: 'Autorizar e continuar', loading: _busy, onPressed: _grantConsent),
    const SizedBox(height: Space.sm),
    OutlinedButton(onPressed: _busy ? null : _declineConsent, child: const Text('Agora não')),
    const SizedBox(height: Space.sm),
    Text(
      'Sem a autorização, você ainda pode explorar o app e buscar profissionais, mas o diário, a evolução e as metas ficam indisponíveis até você autorizar no Perfil.',
      style: context.text.bodySmall,
    ),
  ];

  List<Widget> _goalsStep() => [
    _title('Seus objetivos', 'Escolha um ou mais. O primeiro será o principal.'),
    for (final e in Labels.goalOptions.entries)
      CheckboxListTile(
        value: _goals.contains(e.key),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(e.value),
        subtitle: _goals.isNotEmpty && _goals.first == e.key ? const Text('Objetivo principal') : null,
        onChanged: (v) => setState(() => (v ?? false) ? _goals.add(e.key) : _goals.remove(e.key)),
      ),
  ];

  List<Widget> _supportStep() => [
    _title('Como você quer ser acompanhado(a)?', 'Escolha o que fizer sentido. As próximas perguntas dependem disso.'),
    for (final e in Labels.supportOptions.entries)
      CheckboxListTile(
        value: _support.contains(e.key),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(e.value),
        onChanged: (v) => setState(() => (v ?? false) ? _support.add(e.key) : _support.remove(e.key)),
      ),
    if (!_consent && _support.contains('prescribed_medication'))
      const StatusBanner(
        tone: BannerTone.warning,
        message: 'O registro de medicamento precisa da autorização de dados de saúde. Você pode autorizar depois no Perfil.',
      ),
  ];

  List<Widget> _essentialsStep() => [
    _title('Sobre você', 'Usado para estimar o gasto de energia e sugerir metas.'),
    DateField(
      label: 'Data de nascimento',
      value: _birthDate,
      firstDate: DateTime(DateTime.now().year - 110),
      lastDate: DateTime(DateTime.now().year - 13, DateTime.now().month, DateTime.now().day),
      initialPickerDate: DateTime(DateTime.now().year - 30),
      onChanged: (d) => setState(() => _birthDate = d),
    ),
    const SizedBox(height: Space.lg),
    Text('Sexo', style: context.text.titleSmall),
    Text('Usado só na fórmula de estimativa de gasto energético.', style: context.text.bodySmall),
    ChoiceList(options: Labels.sexes, value: _sex, onChanged: (v) => setState(() => _sex = v)),
    const SizedBox(height: Space.sm),
    NumberField(controller: _height, label: 'Altura', unit: 'cm', min: 100, max: 250, decimal: false, optional: true),
    const SizedBox(height: Space.md),
    NumberField(controller: _weight, label: 'Peso atual', unit: 'kg', min: 30, max: 300, optional: true),
    if (_goals.contains('lose_weight') || _goals.contains('gain_weight')) ...[
      const SizedBox(height: Space.md),
      NumberField(
        controller: _goalWeight,
        label: 'Peso desejado (opcional)',
        unit: 'kg',
        min: 30,
        max: 300,
        optional: true,
        helper: 'Uma meta gradual costuma ser mais sustentável.',
      ),
    ],
    const SizedBox(height: Space.lg),
    Text('Nível de atividade física', style: context.text.titleSmall),
    ChoiceList(options: Labels.activityLevels, value: _activity, onChanged: (v) => setState(() => _activity = v)),
  ];

  List<Widget> _routineStep() => [
    _title('Alimentação e rotina', 'Ajuda a personalizar sugestões e lembretes.'),
    Text('Refeições que você costuma fazer', style: context.text.titleSmall),
    const SizedBox(height: Space.xs),
    _chips(_mealLabels, _plannedMeals),
    const SizedBox(height: Space.lg),
    Text('Preferências', style: context.text.titleSmall),
    const SizedBox(height: Space.xs),
    _chips(Labels.dietaryPreferences, _preferences),
    const SizedBox(height: Space.lg),
    Text('Alergias ou intolerâncias', style: context.text.titleSmall),
    const SizedBox(height: Space.xs),
    _chips(Labels.allergies, _allergies),
    const SizedBox(height: Space.lg),
    TextFormField(
      controller: _restrictions,
      decoration: const InputDecoration(
        labelText: 'Outras restrições (opcional)',
        helperText: 'Ex.: evito frituras à noite',
      ),
      maxLength: 1000,
      maxLines: 3,
    ),
  ];

  static const _mealLabels = {
    'breakfast': 'Café da manhã',
    'morning_snack': 'Lanche da manhã',
    'lunch': 'Almoço',
    'afternoon_snack': 'Lanche da tarde',
    'dinner': 'Jantar',
    'supper': 'Ceia',
  };

  Widget _chips(Map<String, String> options, Set<String> selected) => Wrap(
    spacing: Space.sm,
    runSpacing: Space.sm,
    children: [
      for (final e in options.entries)
        FilterChip(
          label: Text(e.value),
          selected: selected.contains(e.key),
          onSelected: (v) => setState(() => v ? selected.add(e.key) : selected.remove(e.key)),
        ),
    ],
  );

  List<Widget> _guidanceStep() => [
    _title(
      'Sua orientação atual',
      'Registre a dieta ou as orientações que você já recebeu. Elas ficam visíveis só para você e ajudam a configurar metas e o plano alimentar.',
    ),
    Text('Quem orientou', style: context.text.titleSmall),
    ChoiceList(
      options: Labels.guidanceSources,
      value: _guidanceSource,
      onChanged: (v) => setState(() => _guidanceSource = v),
    ),
    const SizedBox(height: Space.md),
    TextFormField(
      controller: _guidance,
      decoration: const InputDecoration(
        labelText: 'Orientações (opcional)',
        helperText: 'Ex.: 5 refeições por dia, 2 L de água, sem açúcar adicionado',
        alignLabelWithHint: true,
      ),
      maxLength: 3000,
      maxLines: 6,
    ),
    const StatusBanner(
      message: 'Depois, você pode montar a semana em Alimentação → Plano alimentar, seguindo essas orientações.',
    ),
  ];

  List<Widget> _medicationStep() => [
    _title(
      'Medicamento prescrito',
      'O PicNutri ajuda a registrar aplicações, sintomas e a evolução durante o tratamento.',
    ),
    SwitchListTile(
      value: _medicationTracking,
      onChanged: (v) => setState(() => _medicationTracking = v),
      contentPadding: EdgeInsets.zero,
      title: const Text('Ativar registro do tratamento'),
      subtitle: const Text('Opcional. Mostra a área de aplicações e sintomas na Evolução.'),
    ),
    const SizedBox(height: Space.sm),
    const StatusBanner(
      tone: BannerTone.warning,
      message:
          'Doses, horários e mudanças no tratamento são sempre definidos pelo seu médico. O app não sugere nem calcula doses.',
    ),
  ];

  List<Widget> _careStep() => [
    _title('Preferências de atendimento', 'Usadas para começar a busca de profissionais com os filtros certos.'),
    Text('Tipo de profissional', style: context.text.titleSmall),
    const SizedBox(height: Space.xs),
    _chips(Labels.professionalCategories, _careCategories),
    const SizedBox(height: Space.lg),
    Text('Atendimento', style: context.text.titleSmall),
    ChoiceList(
      options: Labels.careModalities,
      value: _careModality,
      onChanged: (v) => setState(() => _careModality = v),
    ),
    if (_careModality != 'online') ...[
      const SizedBox(height: Space.md),
      Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: _careCity,
              decoration: const InputDecoration(labelText: 'Cidade (opcional)'),
              textCapitalization: TextCapitalization.words,
            ),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: TextFormField(
              controller: _careState,
              decoration: const InputDecoration(labelText: 'UF'),
              textCapitalization: TextCapitalization.characters,
              maxLength: 2,
              validator: (v) => (v ?? '').trim().isEmpty || v!.trim().length == 2 ? null : '2 letras',
            ),
          ),
        ],
      ),
    ],
  ];

  List<Widget> _targetsStep() {
    final suggestion = _suggestion;
    return [
      _title('Metas diárias', 'Referências para acompanhar seu dia. Ajuste como preferir.'),
      if (_support.contains('has_professional_plan'))
        const Padding(
          padding: EdgeInsets.only(bottom: Space.md),
          child: StatusBanner(message: 'Se o seu profissional definiu metas, use os valores dele.'),
        ),
      if (!_canSuggest)
        Text(
          'Sem os dados básicos completos, não calculamos sugestões. Preencha as metas que já conhece ou pule por agora.',
          style: context.text.bodySmall,
        )
      else if (_suggestionError != null)
        ErrorView(message: friendlyMessage(_suggestionError!), onRetry: _loadSuggestion)
      else if (_suggestionLoading)
        const LoadingView(label: 'Calculando sugestão')
      else if (suggestion != null)
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                suggestion.available
                    ? 'Como calculamos: ${suggestion.method}.'
                    : 'Não estimamos metas de calorias com os dados informados.',
                style: context.text.titleSmall,
              ),
              for (final note in suggestion.notes) Text('• $note'),
            ],
          ),
        ),
      const SizedBox(height: Space.lg),
      NumberField(controller: _calories, label: 'Calorias por dia', unit: 'kcal', min: 800, max: 6000, decimal: false, optional: true),
      const SizedBox(height: Space.md),
      Row(
        children: [
          Expanded(child: NumberField(controller: _protein, label: 'Proteínas', unit: 'g', min: 0, max: 400, decimal: false, optional: true)),
          const SizedBox(width: Space.sm),
          Expanded(child: NumberField(controller: _carbs, label: 'Carboidratos', unit: 'g', min: 0, max: 800, decimal: false, optional: true)),
          const SizedBox(width: Space.sm),
          Expanded(child: NumberField(controller: _fat, label: 'Gorduras', unit: 'g', min: 0, max: 300, decimal: false, optional: true)),
        ],
      ),
      const SizedBox(height: Space.md),
      NumberField(controller: _water, label: 'Água por dia', unit: 'ml', min: 500, max: 6000, decimal: false),
    ];
  }

  List<Widget> _summaryStep() {
    String join(Iterable<String> keys, Map<String, String> labels) =>
        keys.isEmpty ? 'Não informado' : keys.map((k) => labels[k] ?? k).join(', ');

    final rows = <(String, String, String?)>[
      ('Objetivos', join(_goals, Labels.goals), OnboardingSteps.goals),
      ('Acompanhamento', join(_support, Labels.supportPreferences), OnboardingSteps.support),
      if (_consent) ...[
        (
          'Dados básicos',
          _skipped.contains(OnboardingSteps.essentials)
              ? 'Para completar depois'
              : [
                  if (_birthDate != null) Fmt.shortDate(_birthDate!),
                  if (_height.text.isNotEmpty) '${_height.text} cm',
                  if (_weight.text.isNotEmpty) '${_weight.text} kg',
                  if (_activity != null) (Labels.activityLevels[_activity] ?? '').split(' — ').first,
                ].join(' · '),
          OnboardingSteps.essentials,
        ),
        ('Refeições', join(_plannedMeals, _mealLabels), OnboardingSteps.routine),
        if (_allergies.isNotEmpty) ('Alergias', join(_allergies, Labels.allergies), OnboardingSteps.routine),
        if (_support.contains('has_professional_plan'))
          ('Orientação profissional', _guidance.text.trim().isEmpty ? 'Não registrada' : 'Registrada', OnboardingSteps.guidance),
        if (_support.contains('prescribed_medication'))
          ('Medicamento', _medicationTracking ? 'Registro ativado' : 'Registro desativado', OnboardingSteps.medication),
        (
          'Metas',
          _calories.text.isEmpty ? 'Sem meta de calorias · água ${_water.text} ml' : '${_calories.text} kcal · água ${_water.text} ml',
          OnboardingSteps.targets,
        ),
      ],
      if (_support.contains('find_professional'))
        (
          'Atendimento',
          [join(_careCategories, Labels.professionalCategories), Labels.careModalities[_careModality] ?? ''].join(' · '),
          OnboardingSteps.care,
        ),
    ];
    final pending = _skipped.where(OnboardingSteps.labels.containsKey).map((s) => OnboardingSteps.labels[s]!).toList();

    return [
      _title('Tudo pronto', 'Confira suas escolhas. Você pode mudar qualquer uma depois no Perfil.'),
      for (final (label, value, step) in rows)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label, style: context.text.bodySmall),
          subtitle: Text(value, style: context.text.bodyLarge),
          trailing: step == null
              ? null
              : TextButton(onPressed: () => setState(() => _step = step), child: const Text('Editar')),
        ),
      if (pending.isNotEmpty) ...[
        const SizedBox(height: Space.md),
        StatusBanner(
          message: 'Para completar depois: ${pending.join(', ')}. Vamos lembrar você no início.',
        ),
      ],
      if (!_consent) ...[
        const SizedBox(height: Space.md),
        const StatusBanner(
          tone: BannerTone.warning,
          message: 'Diário, evolução e metas precisam da autorização de dados de saúde. Você pode autorizar no Perfil → Privacidade.',
        ),
      ],
    ];
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: context.colors.primary),
        const SizedBox(width: Space.md),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
