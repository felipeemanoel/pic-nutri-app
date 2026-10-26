import 'dart:async';

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
import '../../medication/data/medication_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../progress/data/body_repository.dart';
import '../data/goal_suggestion.dart';
import '../data/onboarding_options.dart';
import '../domain/body_math.dart';
import '../domain/onboarding_flow.dart';
import 'widgets/onboarding_widgets.dart';
import 'widgets/option_card.dart';
import 'widgets/ruler_picker.dart';

export '../domain/onboarding_flow.dart';

part 'onboarding_body_questions.dart';
part 'onboarding_questions.dart';

// Valores iniciais das réguas (a pessoa ajusta antes de continuar).
const _defaultHeightCm = 165.0;
const _defaultWeightKg = 70.0;
const _defaultPace = 0.5;

/// Onboarding em perguntas curtas, com respostas por toque (cartões, régua,
/// roda de datas). O progresso fica salvo no servidor por etapa e pode ser
/// retomado; quase tudo pode ser pulado e completado depois no Perfil.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _finishRequestId = newRequestId();
  final _weightRequestId = newRequestId();
  final _startWeightRequestId = newRequestId();
  final _medicationRequestId = newRequestId();
  final _guidanceFormKey = GlobalKey<FormState>();
  final _targetsFormKey = GlobalKey<FormState>();
  bool _busy = false;
  OnboardingScreen _screen = OnboardingScreen.welcome;
  bool _forward = true;

  late bool _consent;
  final Set<String> _skipped = {};

  // Objetivo e motivação
  String? _goal;
  final Set<String> _motivations = {};
  final Set<String> _support = {};
  String? _challenge;

  // Tratamento
  String? _treatmentStage;
  String? _medicationId;
  final _otherMedication = TextEditingController();
  String? _frequency;
  String? _doseChoice;
  final _customDose = TextEditingController();
  DateTime? _treatmentStart;
  bool _medicationSaved = false;

  // Corpo
  bool _metric = true;
  DateTime? _birthDate;
  String? _sex;
  double? _heightCm;
  double? _weightKg;
  double? _startWeightKg;
  double? _goalWeightKg;
  double? _pace;
  String? _activity;
  bool _weightSaved = false;
  bool _startWeightSaved = false;

  // Orientação profissional
  final _guidance = TextEditingController();
  String? _guidanceSource;

  // Metas
  GoalSuggestion? _suggestion;
  Object? _suggestionError;
  bool _suggestionLoading = false;
  bool _editTargets = false;
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
    final goals = p.goals;
    _goal = goals.contains('medication_support')
        ? 'medication_support'
        : (goals.isEmpty ? null : goals.first);
    _motivations.addAll(p.motivations);
    _support.addAll(p.supportPreferences);
    _challenge = p.mainChallenge;
    _skipped.addAll(account.onboardingSkipped);
    _birthDate = p.birthDate;
    _sex = p.sex;
    _activity = p.activityLevel;
    _heightCm = p.heightCm;
    _weightKg = p.currentWeightKg;
    _weightSaved = p.currentWeightKg != null;
    _goalWeightKg = p.goalWeightKg;
    _pace = p.weeklyPaceKg;
    _guidance.text = p.professionalGuidance ?? '';
    _guidanceSource = p.professionalGuidanceSource;
    if (p.dailyCalorieGoal != null) _calories.text = '${p.dailyCalorieGoal}';
    if (p.proteinGoalG != null) _protein.text = '${p.proteinGoalG}';
    if (p.carbsGoalG != null) _carbs.text = '${p.carbsGoalG}';
    if (p.fatGoalG != null) _fat.text = '${p.fatGoalG}';
    _water.text = '${p.waterGoalMl}';
    // Medicamento já cadastrado numa tentativa anterior: não cadastra de novo.
    _medicationSaved = p.medicationTrackingEnabled;

    final saved = OnboardingSteps.resumeAt(account.onboardingStep);
    if (saved == null) return;
    for (final screen in _sequence) {
      if (screen.step == saved) {
        _screen = screen;
        break;
      }
    }
    if (_screen == OnboardingScreen.targets) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadSuggestion());
    }
  }

  @override
  void dispose() {
    for (final c in [
      _otherMedication,
      _customDose,
      _guidance,
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

  // ---------------------------------------------------------------- Fluxo

  bool get _medicationFlow =>
      AppFeatures.medical &&
      _consent &&
      _support.contains('prescribed_medication');

  bool get _usingMedication => _treatmentStage == 'using';

  /// Perder, ganhar ou manter, conforme o peso atual e a meta.
  String? get _direction {
    final current = _weightKg;
    final goal = _goalWeightKg;
    if (current == null || goal == null) {
      return switch (_goal) {
        'lose_weight' || 'gain_weight' => _goal,
        _ => null,
      };
    }
    if (goal < current - 0.05) return 'lose_weight';
    if (goal > current + 0.05) return 'gain_weight';
    return 'maintain';
  }

  bool get _paceApplies =>
      _direction == 'lose_weight' || _direction == 'gain_weight';

  /// Objetivos enviados à API; o primeiro define o cálculo das metas.
  List<String> get _goalsPayload => switch (_goal) {
    null => const [],
    'medication_support' => [?_direction, 'medication_support'],
    final goal => [goal],
  };

  List<OnboardingScreen> get _sequence => OnboardingFlow.screens(
    consent: _consent,
    support: _support,
    goal: _goal,
    treatmentStage: _treatmentStage,
    hasWeight: _weightKg != null,
    hasGoalWeight: _goalWeightKg != null,
    paceApplies: _paceApplies,
  );

  int get _index {
    final i = _sequence.indexOf(_screen);
    return i < 0 ? 0 : i;
  }

  void _back() {
    FocusManager.instance.primaryFocus?.unfocus();
    final seq = _sequence;
    final i = seq.indexOf(_screen);
    if (i <= 0) return;
    setState(() {
      _forward = false;
      _screen = seq[i - 1];
    });
  }

  /// Respostas obrigatórias antes de continuar (as demais têm padrão ou pulo).
  bool get _canContinue => switch (_screen) {
    OnboardingScreen.goal => _goal != null,
    OnboardingScreen.treatmentStage => _treatmentStage != null,
    OnboardingScreen.medicationName =>
      _medicationId != null &&
          (_medicationId != KnownMedication.other ||
              _otherMedication.text.trim().length >= 2),
    OnboardingScreen.medicationFrequency => _frequency != null,
    OnboardingScreen.medicationDose =>
      _doseChoice != null &&
          (_doseChoice != 'custom' ||
              (Validators.parseNumber(_customDose.text) ?? 0) > 0),
    OnboardingScreen.sex => _sex != null,
    OnboardingScreen.activity => _activity != null,
    OnboardingScreen.goalWeight => _goalWeightError == null,
    _ => true,
  };

  bool get _skippable => switch (_screen) {
    OnboardingScreen.welcome ||
    OnboardingScreen.consent ||
    OnboardingScreen.goal ||
    OnboardingScreen.support ||
    OnboardingScreen.projection ||
    OnboardingScreen.features ||
    OnboardingScreen.summary => false,
    _ => true,
  };

  /// Valores padrão das telas de régua/roda, gravados ao continuar.
  void _applyDefaults() {
    switch (_screen) {
      case OnboardingScreen.birthDate:
        _birthDate ??= _defaultBirthDate;
      case OnboardingScreen.height:
        _heightCm ??= _defaultHeightCm;
      case OnboardingScreen.weight:
        _weightKg ??= _defaultWeightKg;
      case OnboardingScreen.startWeight:
        _startWeightKg ??= _weightKg;
      case OnboardingScreen.goalWeight:
        _goalWeightKg ??= _defaultGoalWeight;
      case OnboardingScreen.pace:
        _pace ??= _defaultPace;
      case OnboardingScreen.treatmentStart:
        _treatmentStart ??= _today;
      default:
        break;
    }
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _defaultBirthDate => DateTime(_today.year - 30, 1, 1);

  double get _defaultGoalWeight {
    final current = _weightKg ?? _defaultWeightKg;
    final goal = switch (_goal) {
      'gain_weight' => current + 3,
      _ => current - 5,
    };
    return goal.clamp(30, 300).roundToDouble();
  }

  Future<void> _continue() async {
    if (_busy || !_canContinue) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (_screen == OnboardingScreen.guidance &&
        !(_guidanceFormKey.currentState?.validate() ?? true)) {
      return;
    }
    if (_screen == OnboardingScreen.targets &&
        !(_targetsFormKey.currentState?.validate() ?? true)) {
      setState(() => _editTargets = true);
      return;
    }
    if (_screen == OnboardingScreen.summary) return _finish();
    _applyDefaults();
    await _goNext();
  }

  /// Pula a pergunta atual (ou o bloco do medicamento inteiro).
  Future<void> _skip() async {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    switch (_screen) {
      case OnboardingScreen.motivations:
        _motivations.clear();
      case OnboardingScreen.challenge:
        _challenge = null;
      case OnboardingScreen.treatmentStage ||
          OnboardingScreen.medicationName ||
          OnboardingScreen.medicationFrequency ||
          OnboardingScreen.medicationDose:
        _medicationId = null;
        final seq = _sequence;
        final last = seq.lastIndexWhere(
          (s) => s.step == OnboardingSteps.medication,
        );
        if (last >= 0 && last < seq.length - 1) await _goTo(seq[last + 1]);
        return;
      case OnboardingScreen.treatmentStart:
        _treatmentStart = null;
      case OnboardingScreen.birthDate:
        _birthDate = null;
      case OnboardingScreen.sex:
        _sex = null;
      case OnboardingScreen.height:
        _heightCm = null;
      case OnboardingScreen.weight:
        _weightKg = null;
      case OnboardingScreen.startWeight:
        _startWeightKg = null;
      case OnboardingScreen.goalWeight:
        _goalWeightKg = null;
        _pace = null;
      case OnboardingScreen.pace:
        _pace = null;
      case OnboardingScreen.activity:
        _activity = null;
      case OnboardingScreen.targets:
        for (final c in [_calories, _protein, _carbs, _fat]) {
          c.clear();
        }
      case OnboardingScreen.guidance:
        _guidance.clear();
        _guidanceSource = null;
      default:
        break;
    }
    await _goNext();
  }

  Future<void> _goNext() async {
    final seq = _sequence;
    final i = seq.indexOf(_screen);
    if (i < 0 || i >= seq.length - 1) return;
    await _goTo(seq[i + 1]);
  }

  /// Avança; ao trocar de etapa, salva as respostas da etapa que terminou.
  Future<void> _goTo(OnboardingScreen next) async {
    final current = _screen;
    if (current.step != next.step) {
      final saved = await _saveStep(current.step, nextStep: next.step);
      if (!saved || !mounted) return;
    }
    setState(() {
      _forward = true;
      _screen = next;
    });
    if (next == OnboardingScreen.targets) await _loadSuggestion();
  }

  /// Escolha única: marca e segue sozinho, sem precisar tocar em Continuar.
  void _choose(VoidCallback update, {bool advance = true}) {
    setState(update);
    if (!advance) return;
    final screen = _screen;
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 260), () {
        if (mounted && _screen == screen && !_busy && _canContinue) {
          unawaited(_continue());
        }
      }),
    );
  }

  // ---------------------------------------------------------------- Dados

  bool _incomplete(String step) => switch (step) {
    OnboardingSteps.essentials =>
      _birthDate == null && _heightCm == null && _weightKg == null,
    OnboardingSteps.medication => _medicationId == null,
    OnboardingSteps.targets => _calories.text.trim().isEmpty,
    OnboardingSteps.guidance =>
      _guidance.text.trim().isEmpty && _guidanceSource == null,
    _ => false,
  };

  Future<bool> _saveStep(String step, {required String nextStep}) async {
    setState(() => _busy = true);
    try {
      if (OnboardingSteps.skippable(step)) {
        _incomplete(step) ? _skipped.add(step) : _skipped.remove(step);
      }
      if (step == OnboardingSteps.essentials) await _saveWeights();
      final account = await ref
          .read(profileRepositoryProvider)
          .saveOnboardingProgress(
            step: nextStep,
            data: _dataFor(step),
            skipped: {
              ..._skipped,
              ...OnboardingSteps.deferred(consent: _consent),
            }.toList(),
          );
      // O registro do tratamento precisa estar ativo antes do cadastro.
      if (step == OnboardingSteps.medication) await _saveMedication();
      ref.read(sessionControllerProvider.notifier).updateAccount(account);
      return true;
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveWeights() async {
    final body = ref.read(bodyRepositoryProvider);
    final start = _startWeightKg;
    final startedOn = _treatmentStart;
    if (!_startWeightSaved &&
        start != null &&
        startedOn != null &&
        startedOn.isBefore(_today) &&
        (start - (_weightKg ?? start)).abs() >= 0.1) {
      await body.saveWeight(
        weightKg: start,
        measuredAt: DateTime(
          startedOn.year,
          startedOn.month,
          startedOn.day,
          12,
        ),
        notes: 'Peso no início do tratamento',
        requestId: _startWeightRequestId,
      );
      _startWeightSaved = true;
    }
    final weight = _weightKg;
    if (weight != null && !_weightSaved) {
      await body.saveWeight(
        weightKg: weight,
        measuredAt: DateTime.now(),
        requestId: _weightRequestId,
      );
      _weightSaved = true;
    }
  }

  double? get _dose => switch (_doseChoice) {
    null || 'unknown' => null,
    'custom' => Validators.parseNumber(_customDose.text),
    final value => double.tryParse(value),
  };

  Future<void> _saveMedication() async {
    if (_medicationSaved || _medicationId == null) return;
    final known = KnownMedication.byId(_medicationId);
    final name = known?.name ?? _otherMedication.text.trim();
    if (name.length < 2) return;
    final (frequency, frequencyNote) = OnboardingOptions.apiFrequency(
      _frequency ?? known?.frequency ?? 'other',
    );
    final dose = _dose;
    final notes = [
      if (frequencyNote != null) 'Frequência: $frequencyNote',
      if (dose != null)
        'Dose ${_usingMedication ? 'atual' : 'prescrita'} informada no cadastro: ${Fmt.decimal(dose)} mg',
    ].join('. ');
    await ref
        .read(medicationRepositoryProvider)
        .saveMedication(
          name: name,
          form: known?.form ?? 'other',
          doseUnit: 'mg',
          frequency: frequency,
          notes: notes,
          startedOn: _usingMedication ? _treatmentStart : null,
          requestId: _medicationRequestId,
        );
    _medicationSaved = true;
    ref.invalidate(medicationsProvider);
  }

  int? _intOf(TextEditingController c) =>
      Validators.parseNumber(c.text)?.round();
  String? _textOf(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  /// Dados enviados ao concluir cada etapa (só o que pertence a ela).
  Map<String, Object?> _dataFor(String step) => switch (step) {
    OnboardingSteps.goals => {
      'goals': _goalsPayload,
      // Motivações são dados sensíveis: só com consentimento.
      if (_consent) 'motivations': _motivations.toList(),
    },
    OnboardingSteps.support =>
      _consent ? {'support_preferences': _support.toList()} : const {},
    OnboardingSteps.medication => {
      'medication_tracking_enabled': _medicationId != null,
    },
    OnboardingSteps.essentials => {
      'goals': _goalsPayload,
      'main_challenge': _challenge,
      'birth_date': ?_birthDate?.toIso8601String().substring(0, 10),
      'sex': ?_sex,
      'height_cm': ?_heightCm,
      'activity_level': ?_activity,
      'goal_weight_kg': _goalWeightKg,
      'weekly_pace_kg': _paceApplies ? _pace : null,
    },
    OnboardingSteps.targets => {
      'daily_calorie_goal': _intOf(_calories),
      'protein_goal_g': _intOf(_protein),
      'carbs_goal_g': _intOf(_carbs),
      'fat_goal_g': _intOf(_fat),
      'water_goal_ml': _intOf(_water) ?? 2000,
    },
    OnboardingSteps.guidance => {
      'professional_guidance': _textOf(_guidance),
      'professional_guidance_source': _guidanceSource,
    },
    _ => const {},
  };

  bool get _canSuggest =>
      _birthDate != null &&
      _sex != null &&
      _activity != null &&
      _goalsPayload.isNotEmpty &&
      _heightCm != null &&
      _weightKg != null;

  Future<void> _loadSuggestion() async {
    if (!_canSuggest) return;
    setState(() {
      _suggestion = null;
      _suggestionError = null;
      _suggestionLoading = true;
    });
    try {
      final suggestion = await ref
          .read(profileRepositoryProvider)
          .suggestGoals(
            sex: _sex!,
            birthDate: _birthDate!,
            heightCm: _heightCm!,
            weightKg: _weightKg!,
            activityLevel: _activity!,
            goal: _goalsPayload.first,
            weeklyPaceKg: _paceApplies ? _pace : null,
          );
      if (!mounted) return;
      setState(() {
        _suggestion = suggestion;
        // Não sobrescreve metas que a pessoa já informou (ex.: do profissional).
        if (_calories.text.isEmpty) {
          _calories.text = suggestion.caloriesKcal?.toString() ?? '';
        }
        if (_protein.text.isEmpty) {
          _protein.text = suggestion.proteinG?.toString() ?? '';
        }
        if (_carbs.text.isEmpty) {
          _carbs.text = suggestion.carbsG?.toString() ?? '';
        }
        if (_fat.text.isEmpty) _fat.text = suggestion.fatG?.toString() ?? '';
        if (suggestion.waterMl != null) {
          _water.text = suggestion.waterMl.toString();
        }
      });
    } on Object catch (error) {
      if (mounted) setState(() => _suggestionError = error);
    } finally {
      if (mounted) setState(() => _suggestionLoading = false);
    }
  }

  Future<void> _answerConsent({required bool granted}) async {
    setState(() => _busy = true);
    try {
      final profile = ref.read(profileRepositoryProvider);
      if (granted) await profile.setConsent('health_data', granted: true);
      _consent = granted;
      final account = await profile.saveOnboardingProgress(
        step: OnboardingSteps.goals,
        data: {'timezone': await deviceTimezone() ?? 'America/Sao_Paulo'},
      );
      ref.read(sessionControllerProvider.notifier).updateAccount(account);
      if (mounted) {
        setState(() {
          _forward = true;
          _screen = OnboardingScreen.goal;
        });
      }
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    try {
      final account = await ref
          .read(profileRepositoryProvider)
          .finishOnboarding(requestId: _finishRequestId);
      ref.read(sessionControllerProvider.notifier).updateAccount(account);
    } on Object catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------------- Tela

  @override
  Widget build(BuildContext context) {
    final seq = _sequence;
    final index = _index;
    final showHeader =
        _screen != OnboardingScreen.welcome &&
        _screen != OnboardingScreen.consent;
    final progress = seq.length <= 1 ? 1.0 : index / (seq.length - 1);

    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_busy) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              if (showHeader)
                _Header(
                  progress: progress,
                  onBack: _busy ? null : _back,
                  onSkip: _skippable && !_busy ? _skip : null,
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: Motion.medium,
                  switchInCurve: Motion.curve,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    final incoming = child.key == ValueKey(_screen);
                    final dx = (incoming == _forward) ? 0.06 : -0.06;
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: Offset(dx, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_screen),
                    child: ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(
                        Space.xxl,
                        Space.lg,
                        Space.xxl,
                        Space.xxl,
                      ),
                      children: _content(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _screen == OnboardingScreen.consent
            ? null
            : Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.xxl,
                      Space.sm,
                      Space.xxl,
                      Space.lg,
                    ),
                    child: SizedBox(
                      height: 56,
                      child: LoadingButton(
                        label: switch (_screen) {
                          OnboardingScreen.welcome => 'Começar',
                          OnboardingScreen.summary => 'Começar a usar',
                          _ => 'Continuar',
                        },
                        loading: _busy,
                        onPressed: _canContinue ? _continue : null,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  List<Widget> _content() => switch (_screen) {
    OnboardingScreen.welcome => _welcome(),
    OnboardingScreen.consent => _consentScreen(),
    OnboardingScreen.goal => _goalScreen(),
    OnboardingScreen.motivations => _motivationsScreen(),
    OnboardingScreen.support => _supportScreen(),
    OnboardingScreen.treatmentStage => _treatmentStageScreen(),
    OnboardingScreen.medicationName => _medicationNameScreen(),
    OnboardingScreen.medicationFrequency => _frequencyScreen(),
    OnboardingScreen.medicationDose => _doseScreen(),
    OnboardingScreen.treatmentStart => _treatmentStartScreen(),
    OnboardingScreen.challenge => _challengeScreen(),
    OnboardingScreen.birthDate => _birthDateScreen(),
    OnboardingScreen.sex => _sexScreen(),
    OnboardingScreen.height => _heightScreen(),
    OnboardingScreen.weight => _weightScreen(),
    OnboardingScreen.startWeight => _startWeightScreen(),
    OnboardingScreen.goalWeight => _goalWeightScreen(),
    OnboardingScreen.pace => _paceScreen(),
    OnboardingScreen.activity => _activityScreen(),
    OnboardingScreen.projection => _projectionScreen(),
    OnboardingScreen.targets => _targetsScreen(),
    OnboardingScreen.guidance => _guidanceScreen(),
    OnboardingScreen.features => _featuresScreen(),
    OnboardingScreen.summary => _summaryScreen(),
  };

  /// Para as telas (em onboarding_questions.dart) atualizarem o estado.
  void _update(VoidCallback fn) => setState(fn);
}
