part of 'onboarding_page.dart';

/// Telas de pergunta do onboarding e seus componentes.
extension _Questions on _OnboardingPageState {
  Widget _title(String text, [String? subtitle]) => Padding(
    padding: const EdgeInsets.only(bottom: Space.xxl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            text,
            style: context.text.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: Space.sm),
          Text(
            subtitle,
            style: context.text.bodyLarge?.copyWith(
              color: context.pic.textSecondary,
            ),
          ),
        ],
      ],
    ),
  );

  List<Widget> _single(
    List<OnboardingOption> options,
    String? value,
    ValueChanged<String> onSelect, {
    bool Function(String value)? advanceFor,
  }) => [
    for (final option in options)
      OptionCard(
        option: option,
        selected: value == option.value,
        onTap: () => _choose(
          () => onSelect(option.value),
          advance: advanceFor?.call(option.value) ?? true,
        ),
      ),
  ];

  List<Widget> _multiple(List<OnboardingOption> options, Set<String> values) =>
      [
        for (final option in options)
          OptionCard(
            option: option,
            multiple: true,
            selected: values.contains(option.value),
            onTap: () => _update(
              () => values.contains(option.value)
                  ? values.remove(option.value)
                  : values.add(option.value),
            ),
          ),
      ];

  // ------------------------------------------------------------ Perguntas

  List<Widget> _welcome() => [
    const SizedBox(height: Space.xxxl),
    const Center(child: PicNutriWordmark(iconSize: 72, showTagline: true)),
    const SizedBox(height: Space.xxxl),
    _title(
      'Vamos montar o seu plano',
      'Responda algumas perguntas rápidas e o PicNutri se ajusta a você. Leva cerca de 2 minutos.',
    ),
    const _Highlight(
      icon: Icons.photo_camera_outlined,
      title: 'Registre por foto',
      text: 'Fotografe o prato e veja calorias e macros estimados.',
    ),
    const _Highlight(
      icon: Icons.track_changes_rounded,
      title: 'Metas feitas para você',
      text: 'Calorias, proteína e água calculadas com os seus dados.',
    ),
    const _Highlight(
      icon: Icons.insights_rounded,
      title: 'Veja a sua evolução',
      text: 'Peso, medidas e hábitos em gráficos simples.',
    ),
  ];

  List<Widget> _consentScreen() => [
    const SizedBox(height: Space.lg),
    Center(
      child: CircleAvatar(
        radius: 36,
        backgroundColor: context.pic.brandContainer,
        child: Icon(
          Icons.lock_outline_rounded,
          size: 34,
          color: context.pic.onBrandContainer,
        ),
      ),
    ),
    const SizedBox(height: Space.xxl),
    _title(
      'Seus dados de saúde, protegidos',
      'Para personalizar seu plano, vamos perguntar idade, altura, peso, alimentação'
          '${AppFeatures.medical ? ' e, se for o caso, uso de medicamento' : ''}. '
          'Esses dados só são usados com a sua autorização.',
    ),
    const _Highlight(
      icon: Icons.shield_outlined,
      title: 'Só com a sua autorização',
      text: 'Não compartilhamos seus dados sem você permitir.',
    ),
    const _Highlight(
      icon: Icons.tune_rounded,
      title: 'Metas de referência',
      text:
          'Usamos os dados para calcular totais e sugerir metas que você ajusta.',
    ),
    const _Highlight(
      icon: Icons.medical_information_outlined,
      title: 'Não substitui profissionais',
      text: 'O PicNutri não substitui médicos ou nutricionistas.',
    ),
    const _Highlight(
      icon: Icons.delete_outline_rounded,
      title: 'Você no controle',
      text: 'Revogue, exporte ou exclua seus dados quando quiser.',
    ),
    Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () => showLegalSummary(context),
        child: const Text('Como usamos seus dados'),
      ),
    ),
    const SizedBox(height: Space.lg),
    SizedBox(
      height: 56,
      child: LoadingButton(
        label: 'Autorizar e continuar',
        loading: _busy,
        onPressed: () => _answerConsent(granted: true),
      ),
    ),
    const SizedBox(height: Space.sm),
    SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: _busy ? null : () => _answerConsent(granted: false),
        child: const Text('Agora não'),
      ),
    ),
    const SizedBox(height: Space.md),
    Text(
      'Sem a autorização, você ainda pode explorar o app, mas o diário, a evolução e as metas ficam indisponíveis até você autorizar no Perfil.',
      style: context.text.bodySmall?.copyWith(color: context.pic.textSecondary),
    ),
  ];

  List<Widget> _goalScreen() => [
    _title(
      'Qual é o seu principal objetivo?',
      'O PicNutri se adapta a ele. Você pode mudar depois.',
    ),
    ..._single(OnboardingOptions.goals, _goal, (v) {
      _goal = v;
      if (v == 'medication_support') _support.add('prescribed_medication');
    }),
  ];

  List<Widget> _motivationsScreen() => [
    _title(
      'O que está te motivando?',
      'Pode escolher mais de uma. Isso ajuda a personalizar sua experiência.',
    ),
    ..._multiple(OnboardingOptions.motivations, _motivations),
  ];

  List<Widget> _supportScreen() => [
    _title(
      'Como o PicNutri pode te ajudar?',
      'Escolha o que fizer sentido. As próximas perguntas dependem disso.',
    ),
    ..._multiple(OnboardingOptions.support, _support),
    if (!_consent && _support.contains('prescribed_medication'))
      const StatusBanner(
        tone: BannerTone.warning,
        message:
            'O registro de medicamento precisa da autorização de dados de saúde. Você pode autorizar depois no Perfil.',
      ),
  ];

  List<Widget> _treatmentStageScreen() => [
    _title(
      'Em que momento do tratamento você está?',
      'A gente organiza o app para essa fase.',
    ),
    ..._single(
      OnboardingOptions.treatmentStage,
      _treatmentStage,
      (v) => _treatmentStage = v,
    ),
  ];

  List<Widget> _medicationNameScreen() {
    OnboardingOption option(KnownMedication m) {
      final details = [
        if (m.maker != null) m.maker!,
        if (m.purpose != null) m.purpose!,
        if (m.form == 'oral') 'comprimido',
      ].join(' · ');
      return OnboardingOption(
        m.id,
        m.name,
        subtitle: details.isEmpty ? null : details,
      );
    }
    void select(String v) {
      if (v != _medicationId) {
        _doseChoice = null;
        _frequency = KnownMedication.byId(v)?.frequency;
        _otherMedication.clear();
      }
      _medicationId = v;
    }

    bool advance(String v) =>
        v != KnownMedication.other &&
        !(KnownMedication.byId(v)?.genericEntry ?? false);

    final query = _medicationQuery;
    final brands = KnownMedication.brands.where((m) => m.matches(query)).toList();
    final selected = KnownMedication.byId(_medicationId);
    final askName = _medicationId == KnownMedication.other || (selected?.genericEntry ?? false);

    return [
      _title(
        _usingMedication
            ? 'Qual medicamento você usa?'
            : 'Qual medicamento foi prescrito?',
        'Usado só para organizar seus registros e lembretes.',
      ),
      TextFormField(
        initialValue: _medicationQuery,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search_rounded),
          hintText: 'Buscar pela marca ou princípio ativo',
        ),
        textInputAction: TextInputAction.search,
        onChanged: (v) => _update(() => _medicationQuery = v),
      ),
      const SizedBox(height: Space.md),
      for (final ingredient in MedicationIngredient.values)
        if (brands.any((m) => m.ingredient == ingredient)) ...[
          Padding(
            padding: const EdgeInsets.only(top: Space.sm, bottom: Space.xs, left: Space.xs),
            child: Text(
              ingredient.groupTitle,
              style: context.text.labelLarge?.copyWith(color: context.pic.textSecondary),
            ),
          ),
          ..._single(
            [for (final m in brands.where((m) => m.ingredient == ingredient)) option(m)],
            _medicationId,
            select,
            advanceFor: advance,
          ),
        ],
      Padding(
        padding: const EdgeInsets.only(top: Space.md, bottom: Space.xs, left: Space.xs),
        child: Text(
          'Genérico, similar ou outra marca',
          style: context.text.labelLarge?.copyWith(color: context.pic.textSecondary),
        ),
      ),
      ..._single(
        [
          for (final m in KnownMedication.genericEntries)
            OnboardingOption(
              m.id,
              'Outra caneta de ${m.ingredient.label}',
              subtitle: 'Genéricos, similares e outras marcas',
            ),
          const OnboardingOption(
            KnownMedication.other,
            'Outro medicamento',
            subtitle: 'Digite o nome',
          ),
        ],
        _medicationId,
        select,
        advanceFor: advance,
      ),
      if (askName) ...[
        const SizedBox(height: Space.sm),
        TextFormField(
          controller: _otherMedication,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          maxLength: 80,
          decoration: InputDecoration(
            labelText: _medicationId == KnownMedication.other
                ? 'Nome do medicamento'
                : 'Nome na embalagem (opcional)',
          ),
          onChanged: (_) => _update(() {}),
        ),
      ],
    ];
  }

  List<Widget> _frequencyScreen() {
    final oral = KnownMedication.byId(_medicationId)?.form == 'oral';
    return [
      _title(
        oral
            ? 'Com que frequência você toma?'
            : 'Com que frequência você aplica?',
        'Para organizar seus registros e lembretes no dia certo.',
      ),
      ..._single(
        OnboardingOptions.frequencies,
        _frequency,
        (v) => _frequency = v,
      ),
    ];
  }

  List<Widget> _doseScreen() {
    final known = KnownMedication.byId(_medicationId);
    final options = [
      for (final dose in known?.doses ?? const <double>[])
        OnboardingOption(dose.toString(), '${Fmt.decimal(dose)} mg'),
      const OnboardingOption('custom', 'Outra dose'),
      const OnboardingOption('unknown', 'Ainda não sei'),
    ];
    return [
      _title(
        _usingMedication
            ? 'Qual é a sua dose atual?'
            : 'Qual dose foi prescrita?',
        'Marque a dose indicada pelo seu médico.',
      ),
      ..._single(
        options,
        _doseChoice,
        (v) => _doseChoice = v,
        advanceFor: (v) => v != 'custom',
      ),
      if (_doseChoice == 'custom')
        TextFormField(
          controller: _customDose,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Dose',
            suffixText: 'mg',
          ),
          onChanged: (_) => _update(() {}),
        ),
      const SizedBox(height: Space.sm),
      const StatusBanner(
        tone: BannerTone.warning,
        message:
            'Doses e mudanças no tratamento são sempre definidas pelo seu médico. O PicNutri não sugere nem calcula doses.',
      ),
    ];
  }

  List<Widget> _treatmentStartScreen() => [
    _title('Quando você começou o tratamento?', 'Você pode mudar depois.'),
    WheelDatePicker(
      value: _treatmentStart ?? _today,
      min: DateTime(_today.year - 10),
      max: _today,
      onChanged: (d) => _update(() => _treatmentStart = d),
    ),
  ];

  List<Widget> _challengeScreen() => [
    _title(
      'Qual é a sua maior dificuldade hoje?',
      'Vamos destacar o que mais pode te ajudar.',
    ),
    ..._single(
      OnboardingOptions.challenges(medication: _medicationFlow),
      _challenge,
      (v) => _challenge = v,
    ),
  ];

  List<Widget> _guidanceScreen() => [
    _title(
      'Sua orientação atual',
      'Registre a dieta ou as orientações que você já recebeu. Ficam visíveis só para você.',
    ),
    Text('Quem orientou', style: context.text.titleSmall),
    const SizedBox(height: Space.sm),
    ..._single(
      [
        for (final e in Labels.guidanceSources.entries)
          OnboardingOption(e.key, e.value),
      ],
      _guidanceSource,
      (v) => _guidanceSource = v,
      advanceFor: (_) => false,
    ),
    const SizedBox(height: Space.sm),
    Form(
      key: _guidanceFormKey,
      child: TextFormField(
        controller: _guidance,
        decoration: const InputDecoration(
          labelText: 'Orientações (opcional)',
          helperText:
              'Ex.: 5 refeições por dia, 2 L de água, sem açúcar adicionado',
          alignLabelWithHint: true,
        ),
        maxLength: 3000,
        maxLines: 5,
      ),
    ),
  ];

  /// Recursos do app, com o que resolve a dificuldade escolhida em primeiro.
  List<Widget> _featuresScreen() {
    final features = <(String, _Feature)>[
      (
        'what_to_eat',
        const _Feature(
          Icons.menu_book_outlined,
          'Plano alimentar e receitas',
          'Monte a semana e veja o que comer em cada refeição.',
        ),
      ),
      (
        'tracking_progress',
        const _Feature(
          Icons.photo_camera_outlined,
          'Registro por foto',
          'Calorias e macros estimados a partir da foto do prato.',
        ),
      ),
      (
        'consistency',
        const _Feature(
          Icons.notifications_active_outlined,
          'Lembretes de água e refeições',
          'Avisos para você bater as metas do dia.',
        ),
      ),
      (
        'tracking_progress',
        const _Feature(
          Icons.insights_rounded,
          'Evolução',
          'Peso, medidas e fotos de progresso em gráficos.',
        ),
      ),
      (
        'hunger',
        const _Feature(
          Icons.auto_awesome_outlined,
          'Assistente',
          'Tire dúvidas sobre alimentação a qualquer hora.',
        ),
      ),
      if (_medicationFlow)
        (
          'dose_schedule',
          const _Feature(
            Icons.vaccines_outlined,
            'Acompanhamento do tratamento',
            'Lembretes, histórico das aplicações e sintomas.',
          ),
        ),
      if (AppFeatures.medical && _support.contains('find_professional'))
        (
          '',
          const _Feature(
            Icons.support_agent_outlined,
            'Profissionais',
            'Encontre nutricionistas e profissionais de educação física.',
          ),
        ),
    ];
    // Efeitos colaterais: o acompanhamento do tratamento registra sintomas.
    final focus = _challenge == 'side_effects' ? 'dose_schedule' : _challenge;
    int rank((String, _Feature) f) => f.$1 == focus ? 0 : 1;
    final ordered = [
      ...features.where((f) => rank(f) == 0),
      ...features.where((f) => rank(f) == 1),
    ];
    return [
      _title(
        'Vamos te ajudar a chegar lá!',
        'Conheça os recursos do PicNutri que vão te acompanhar até a sua meta.',
      ),
      for (final (_, feature) in ordered)
        Padding(
          padding: const EdgeInsets.only(bottom: Space.md),
          child: AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: context.pic.brandContainer,
                  child: Icon(
                    feature.icon,
                    color: context.pic.onBrandContainer,
                  ),
                ),
                const SizedBox(width: Space.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.title,
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: Space.xxs),
                      Text(
                        feature.text,
                        style: context.text.bodyMedium?.copyWith(
                          color: context.pic.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  List<Widget> _summaryScreen() {
    String join(Iterable<String> keys, Map<String, String> labels) =>
        keys.isEmpty
        ? 'Não informado'
        : keys.map((k) => labels[k] ?? k).join(', ');
    final dose = _dose;
    final about = [
      if (_birthDate != null) '${_ageOn(_birthDate!)} anos',
      if (_heightCm != null) '${_heightCm!.round()} cm',
      if (_weightKg != null) Fmt.kg(_weightKg!),
    ].join(' · ');

    final rows = <(String, String, OnboardingScreen)>[
      ('Objetivo', join(_goalsPayload, Labels.goals), OnboardingScreen.goal),
      (
        'Acompanhamento',
        join(_support, Labels.supportPreferences),
        OnboardingScreen.support,
      ),
      if (_consent) ...[
        if (_medicationFlow)
          (
            'Medicamento',
            _medicationId == null
                ? 'Para cadastrar depois'
                : [
                    _medicationName,
                    if (dose != null) '${Fmt.decimal(dose)} mg',
                  ].join(' · '),
            OnboardingScreen.treatmentStage,
          ),
        (
          'Sobre você',
          about.isEmpty ? 'Para completar depois' : about,
          OnboardingScreen.birthDate,
        ),
        if (_goalWeightKg != null)
          (
            'Meta de peso',
            [
              Fmt.kg(_goalWeightKg!),
              if (_paceApplies && _pace != null)
                '${Fmt.decimal(_pace!)} kg por semana',
            ].join(' · '),
            OnboardingScreen.goalWeight,
          ),
        (
          'Plano diário',
          _calories.text.isEmpty
              ? 'Água ${_water.text} ml'
              : '${_calories.text} kcal · água ${_water.text} ml',
          OnboardingScreen.targets,
        ),
      ],
    ];
    final pending =
        {..._skipped, ...OnboardingSteps.deferred(consent: _consent)}
            .where(OnboardingSteps.labels.containsKey)
            .map((s) => OnboardingSteps.labels[s]!)
            .toList();

    final calories = int.tryParse(_calories.text.trim());
    final waterMl = int.tryParse(_water.text.trim());
    final hasPlan = _consent && (calories != null || waterMl != null);
    final weight = _weightKg;
    final goalWeight = _goalWeightKg;

    return [
      _title(
        hasPlan ? 'Seu plano está pronto' : 'Tudo pronto!',
        hasPlan
            ? 'Montado com as suas respostas. Você pode mudar qualquer valor depois no Perfil.'
            : 'Confira suas respostas. Você pode mudar qualquer uma depois no Perfil.',
      ),
      if (hasPlan) ...[
        // Metas do dia em cartões grandes, sem promessa de resultado.
        if (calories != null)
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: context.pic.brandContainer,
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    color: context.pic.onBrandContainer,
                  ),
                ),
                const SizedBox(width: Space.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calorias por dia',
                        style: context.text.bodySmall?.copyWith(
                          color: context.pic.textSecondary,
                        ),
                      ),
                      Text(
                        '${Fmt.integer(calories)} kcal',
                        style: context.text.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: Space.sm),
        Row(
          children: [
            _MacroTile('Proteínas', _protein.text, 'g', context.pic.protein),
            const SizedBox(width: Space.sm),
            _MacroTile('Carboidratos', _carbs.text, 'g', context.pic.carbs),
            const SizedBox(width: Space.sm),
            _MacroTile('Gorduras', _fat.text, 'g', context.pic.fat),
          ],
        ),
        const SizedBox(height: Space.sm),
        Row(
          children: [
            _MacroTile(
              'Água por dia',
              waterMl == null ? '' : Fmt.decimal(waterMl / 1000),
              'L',
              context.pic.water,
            ),
            if (weight != null && goalWeight != null) ...[
              const SizedBox(width: Space.sm),
              _MacroTile(
                'Meta: ${Fmt.kg(goalWeight)}',
                Fmt.decimal(weight),
                'kg hoje',
                context.colors.primary,
              ),
            ],
          ],
        ),
        const SizedBox(height: Space.lg),
        Padding(
          padding: const EdgeInsets.only(left: Space.xs, bottom: Space.sm),
          child: Text('Suas respostas', style: context.text.titleSmall),
        ),
      ],
      AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.sm,
        ),
        child: Column(
          children: [
            for (final (label, value, screen) in rows)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  label,
                  style: context.text.bodySmall?.copyWith(
                    color: context.pic.textSecondary,
                  ),
                ),
                subtitle: Text(value, style: context.text.bodyLarge),
                trailing: _sequence.contains(screen)
                    ? TextButton(
                        onPressed: () => _update(() {
                          _forward = false;
                          _screen = screen;
                        }),
                        child: const Text('Editar'),
                      )
                    : null,
              ),
          ],
        ),
      ),
      if (pending.isNotEmpty) ...[
        const SizedBox(height: Space.md),
        StatusBanner(
          message:
              'Para completar depois: ${pending.join(', ')}. Vamos lembrar você no início.',
        ),
      ],
      if (!_consent) ...[
        const SizedBox(height: Space.md),
        const StatusBanner(
          tone: BannerTone.warning,
          message:
              'Diário, evolução e metas precisam da autorização de dados de saúde. Você pode autorizar no Perfil → Privacidade.',
        ),
      ],
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.progress, this.onBack, this.onSkip});

  final double progress;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Space.sm, Space.sm, Space.md, 0),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: onBack,
        ),
        Expanded(
          child: Semantics(
            label: 'Progresso',
            value: '${(progress * 100).round()}%',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.pill),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: progress),
                duration: Motion.slow,
                curve: Motion.curve,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: context.pic.surfaceMuted,
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 72,
          child: onSkip == null
              ? null
              : TextButton(onPressed: onSkip, child: const Text('Pular')),
        ),
      ],
    ),
  );
}

class _Highlight extends StatelessWidget {
  const _Highlight({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.lg),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: context.pic.brandContainer,
          child: Icon(icon, color: context.pic.onBrandContainer, size: 22),
        ),
        const SizedBox(width: Space.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                text,
                style: context.text.bodyMedium?.copyWith(
                  color: context.pic.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Feature {
  const _Feature(this.icon, this.title, this.text);

  final IconData icon;
  final String title;
  final String text;
}

class _MacroTile extends StatelessWidget {
  const _MacroTile(this.label, this.value, this.unit, this.color);

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: AppCard(
      padding: const EdgeInsets.all(Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(
            value.isEmpty ? '—' : '$value $unit',
            style: context.text.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: context.text.bodySmall?.copyWith(
              color: context.pic.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}
