part of 'onboarding_page.dart';

/// Perguntas sobre o corpo e a meta: data de nascimento, altura, peso (com
/// régua e IMC), meta, ritmo, atividade, previsão e plano diário.
extension _BodyQuestions on _OnboardingPageState {
  List<Widget> _birthDateScreen() {
    final value = _birthDate ?? _defaultBirthDate;
    return [
      _title(
        'Qual é a sua data de nascimento?',
        'A idade entra no cálculo do seu gasto de energia.',
      ),
      WheelDatePicker(
        value: value,
        min: DateTime(_today.year - 110),
        max: DateTime(_today.year - 13, _today.month, _today.day),
        onChanged: (d) => _update(() => _birthDate = d),
      ),
      const SizedBox(height: Space.lg),
      Center(
        child: Text(
          '${_ageOn(value)} anos',
          style: context.text.titleMedium?.copyWith(
            color: context.pic.textSecondary,
          ),
        ),
      ),
    ];
  }

  int _ageOn(DateTime birth) {
    final now = _today;
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  List<Widget> _sexScreen() => [
    _title(
      'Como você se identifica?',
      'Usado só na fórmula do gasto de energia, para as suas metas.',
    ),
    ..._single(OnboardingOptions.sexes, _sex, (v) => _sex = v),
  ];

  Widget _unitToggle() =>
      UnitToggle(metric: _metric, onChanged: (v) => _update(() => _metric = v));

  List<Widget> _heightScreen() {
    final cm = _heightCm ?? _defaultHeightCm;
    return [
      _title('Qual é a sua altura?'),
      _unitToggle(),
      const SizedBox(height: Space.xxl),
      BigValue(
        text: _metric ? '${cm.round()}' : BodyMath.feetInchesLabel(cm),
        unit: _metric ? 'cm' : null,
        onTap: () async {
          final typed = await askNumber(
            context,
            title: 'Altura',
            unit: 'cm',
            min: 100,
            max: 250,
            initial: cm,
            decimal: false,
          );
          if (typed != null) _update(() => _heightCm = typed);
        },
      ),
      const SizedBox(height: Space.xl),
      if (_metric)
        RulerPicker(
          value: cm,
          min: 100,
          max: 250,
          step: 1,
          labelEvery: 5,
          majorEvery: 5,
          labelFor: (v) => '${v.round()}',
          semanticLabel: 'Altura em centímetros',
          onChanged: (v) => _update(() => _heightCm = v),
        )
      else
        RulerPicker(
          value: BodyMath.cmToInches(cm).roundToDouble(),
          min: 39,
          max: 98,
          step: 1,
          labelEvery: 6,
          majorEvery: 3,
          labelFor: (v) => "${v.round() ~/ 12}'${v.round() % 12}\"",
          semanticLabel: 'Altura em pés e polegadas',
          onChanged: (v) => _update(() => _heightCm = BodyMath.inchesToCm(v)),
        ),
    ];
  }

  /// Régua de peso em kg ou lb, sempre guardando em kg.
  Widget _weightRuler({
    required double kg,
    required ValueChanged<double> onChanged,
    double? referenceKg,
  }) => _metric
      ? RulerPicker(
          value: kg,
          min: 30,
          max: 300,
          step: 0.1,
          labelEvery: 10,
          majorEvery: 5,
          labelFor: (v) => '${v.round()}',
          reference: referenceKg,
          semanticLabel: 'Peso em quilos',
          onChanged: onChanged,
        )
      : RulerPicker(
          value: _round1(BodyMath.kgToLb(kg)),
          min: 66,
          max: 660,
          step: 0.1,
          labelEvery: 10,
          majorEvery: 5,
          labelFor: (v) => '${v.round()}',
          reference: referenceKg == null ? null : BodyMath.kgToLb(referenceKg),
          semanticLabel: 'Peso em libras',
          onChanged: (lb) => onChanged(BodyMath.lbToKg(lb)),
        );

  double _round1(double v) => double.parse(v.toStringAsFixed(1));

  String _weightText(double kg) =>
      Fmt.decimal(_round1(_metric ? kg : BodyMath.kgToLb(kg)));

  String get _weightUnit => _metric ? 'kg' : 'lb';

  Future<double?> _typeWeight(String title, double kg) async {
    final typed = await askNumber(
      context,
      title: title,
      unit: _weightUnit,
      min: _metric ? 30 : 66,
      max: _metric ? 300 : 660,
      initial: _round1(_metric ? kg : BodyMath.kgToLb(kg)),
    );
    if (typed == null) return null;
    return _metric ? typed : BodyMath.lbToKg(typed);
  }

  List<Widget> _weightScreen() {
    final kg = _weightKg ?? _defaultWeightKg;
    final bmi = BodyMath.bmi(weightKg: kg, heightCm: _heightCm);
    return [
      _title('Qual é o seu peso atual?'),
      _unitToggle(),
      const SizedBox(height: Space.xxl),
      BigValue(
        text: _weightText(kg),
        unit: _weightUnit,
        onTap: () async {
          final typed = await _typeWeight('Peso atual', kg);
          if (typed != null) _update(() => _weightKg = typed);
        },
      ),
      const SizedBox(height: Space.xl),
      _weightRuler(kg: kg, onChanged: (v) => _update(() => _weightKg = v)),
      if (bmi != null) ...[
        const SizedBox(height: Space.xxl),
        BmiCard(bmi: bmi),
      ],
    ];
  }

  List<Widget> _startWeightScreen() {
    final current = _weightKg ?? _defaultWeightKg;
    final kg = _startWeightKg ?? current;
    final lost = kg - current;
    return [
      _title(
        'Qual era o seu peso quando começou?',
        'Assim você vê tudo o que já conquistou desde o início do tratamento.',
      ),
      _unitToggle(),
      const SizedBox(height: Space.xxl),
      BigValue(
        text: _weightText(kg),
        unit: _weightUnit,
        onTap: () async {
          final typed = await _typeWeight('Peso no início', kg);
          if (typed != null) _update(() => _startWeightKg = typed);
        },
      ),
      const SizedBox(height: Space.xl),
      _weightRuler(
        kg: kg,
        referenceKg: current,
        onChanged: (v) => _update(() => _startWeightKg = v),
      ),
      if (lost >= 0.5) ...[
        const SizedBox(height: Space.xxl),
        AppCard(
          color: context.pic.successContainer,
          child: Row(
            children: [
              Icon(Icons.celebration_outlined, color: context.pic.success),
              const SizedBox(width: Space.md),
              Expanded(
                child: Text(
                  'Você já perdeu ${_weightText(lost)} $_weightUnit. Que conquista!',
                  style: context.text.titleSmall,
                ),
              ),
            ],
          ),
        ),
      ],
    ];
  }

  String? get _goalWeightError {
    final current = _weightKg;
    final goal = _goalWeightKg ?? _defaultGoalWeight;
    if (current == null) return null;
    if (_goal == 'lose_weight' && goal >= current) {
      return 'Para emagrecer, escolha um peso menor que o atual.';
    }
    if (_goal == 'gain_weight' && goal <= current) {
      return 'Para ganhar peso, escolha um peso maior que o atual.';
    }
    return null;
  }

  List<Widget> _goalWeightScreen() {
    final current = _weightKg ?? _defaultWeightKg;
    final goal = _goalWeightKg ?? _defaultGoalWeight;
    final diff = goal - current;
    final goalBmi = BodyMath.bmi(weightKg: goal, heightCm: _heightCm);
    final error = _goalWeightError;
    return [
      _title(
        'Qual é a sua meta de peso?',
        'Você pode mudar depois, se quiser.',
      ),
      _unitToggle(),
      const SizedBox(height: Space.xxl),
      BigValue(
        text: _weightText(goal),
        unit: _weightUnit,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              diff <= 0
                  ? Icons.keyboard_double_arrow_left_rounded
                  : Icons.keyboard_double_arrow_right_rounded,
              color: context.pic.textSecondary,
            ),
            Text(
              _weightText(current),
              style: context.text.titleLarge?.copyWith(
                color: context.pic.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        onTap: () async {
          final typed = await _typeWeight('Meta de peso', goal);
          if (typed != null) _update(() => _goalWeightKg = typed);
        },
      ),
      const SizedBox(height: Space.xl),
      _weightRuler(
        kg: goal,
        referenceKg: current,
        onChanged: (v) => _update(() => _goalWeightKg = v),
      ),
      const SizedBox(height: Space.xxl),
      if (diff.abs() >= 0.1)
        Center(
          child: Column(
            children: [
              Text(
                '${diff < 0 ? '−' : '+'}${_weightText(diff.abs())} $_weightUnit',
                style: context.text.displaySmall?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                diff < 0 ? 'para perder' : 'para ganhar',
                style: context.text.titleMedium?.copyWith(
                  color: context.pic.textSecondary,
                ),
              ),
            ],
          ),
        ),
      if (error != null) ...[
        const SizedBox(height: Space.lg),
        StatusBanner(tone: BannerTone.warning, message: error),
      ] else if (goalBmi != null && goalBmi < 18.5) ...[
        const SizedBox(height: Space.lg),
        const StatusBanner(
          tone: BannerTone.warning,
          message:
              'Essa meta fica abaixo da faixa de peso adequado para a sua altura. Vale conversar com um profissional antes de seguir com ela.',
        ),
      ],
    ];
  }

  String _paceText(double pace) => _metric
      ? '${Fmt.decimal(pace)} kg'
      : '${Fmt.decimal(_round1(BodyMath.kgToLb(pace)))} lb';

  List<Widget> _paceScreen() {
    final pace = _pace ?? _defaultPace;
    final losing = _direction == 'lose_weight';
    final (label, icon, note) = switch (pace) {
      <= 0.3 => (
        'Gradual',
        Icons.directions_walk_rounded,
        'Mudanças pequenas e fáceis de manter.',
      ),
      <= 0.6 => (
        'Moderado',
        Icons.directions_bike_rounded,
        'O ritmo mais indicado para resultados duradouros.',
      ),
      _ => (
        'Acelerado',
        Icons.directions_run_rounded,
        'Exige mais esforço. Ritmos rápidos devem ter acompanhamento profissional.',
      ),
    };
    final date = BodyMath.projectedDate(
      currentKg: _weightKg,
      goalKg: _goalWeightKg,
      paceKgPerWeek: pace,
    );
    return [
      _title(
        losing
            ? 'Em que ritmo você quer emagrecer?'
            : 'Em que ritmo você quer ganhar peso?',
        'Ritmos graduais são mais fáceis de manter. Você pode mudar depois.',
      ),
      const SizedBox(height: Space.lg),
      Center(
        child: Text(
          '${_paceText(pace)} por semana',
          style: context.text.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(height: Space.xl),
      Center(
        child: CircleAvatar(
          radius: 36,
          backgroundColor: context.colors.surface,
          child: Icon(icon, size: 34, color: context.colors.onSurface),
        ),
      ),
      const SizedBox(height: Space.md),
      Center(
        child: Text(
          label,
          style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      const SizedBox(height: Space.lg),
      Slider(
        value: pace,
        min: 0.1,
        max: 1,
        divisions: 9,
        label: _paceText(pace),
        onChanged: (v) => _update(() => _pace = _round1(v)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.lg),
        child: Row(
          children: [
            Text(_paceText(0.1), style: context.text.bodySmall),
            const Spacer(),
            Text(_paceText(1), style: context.text.bodySmall),
          ],
        ),
      ),
      const SizedBox(height: Space.xl),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(note, style: context.text.bodyLarge),
            if (date != null) ...[
              const SizedBox(height: Space.sm),
              Text(
                'Nesse ritmo, você chega à meta por volta de ${Fmt.monthYear(date)}.',
                style: context.text.titleSmall?.copyWith(
                  color: context.colors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  List<Widget> _activityScreen() => [
    _title(
      'Qual é o seu nível de atividade física?',
      'Conte o que você faz numa semana comum.',
    ),
    ..._single(OnboardingOptions.activity, _activity, (v) => _activity = v),
  ];

  List<Widget> _projectionScreen() {
    final current = _weightKg!;
    final goal = _goalWeightKg!;
    final pace = _pace ?? _defaultPace;
    final date = BodyMath.projectedDate(
      currentKg: current,
      goalKg: goal,
      paceKgPerWeek: pace,
    );
    final losing = goal < current;
    final diff = (current - goal).abs();
    return [
      const SizedBox(height: Space.lg),
      Center(
        child: CircleAvatar(
          radius: 40,
          backgroundColor: context.colors.primary,
          child: Icon(
            losing ? Icons.trending_down_rounded : Icons.trending_up_rounded,
            color: context.colors.onPrimary,
            size: 40,
          ),
        ),
      ),
      const SizedBox(height: Space.xxl),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(text: losing ? 'Perder ' : 'Ganhar '),
            TextSpan(
              text: '${_weightText(diff)} $_weightUnit',
              style: TextStyle(color: context.colors.primary),
            ),
            const TextSpan(text: ' é totalmente possível'),
          ],
        ),
        textAlign: TextAlign.center,
        style: context.text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: Space.sm),
      if (date != null)
        Text(
          'No ritmo de ${_paceText(pace)} por semana, a previsão é chegar a ${_weightText(goal)} $_weightUnit por volta de ${Fmt.monthYear(date)}.',
          textAlign: TextAlign.center,
          style: context.text.bodyLarge?.copyWith(
            color: context.pic.textSecondary,
          ),
        ),
      const SizedBox(height: Space.xxl),
      ProjectionChart(
        fromText: '${_weightText(current)} $_weightUnit',
        toText: '${_weightText(goal)} $_weightUnit',
        descending: losing,
        endLabel: date == null ? 'Meta' : Fmt.monthYear(date),
      ),
      const SizedBox(height: Space.xl),
      _Highlight(
        icon: Icons.checklist_rounded,
        title: 'Constância faz a diferença',
        text: _medicationFlow
            ? 'Registrar refeições, água e aplicações ajuda você e seu médico a acompanhar o tratamento.'
            : 'Registrar refeições, água e peso mostra o que está funcionando e onde ajustar.',
      ),
      Text(
        'É uma estimativa. O ritmo real varia de pessoa para pessoa e costuma ser mais rápido no começo.',
        textAlign: TextAlign.center,
        style: context.text.bodySmall?.copyWith(
          color: context.pic.textSecondary,
        ),
      ),
    ];
  }

  List<Widget> _targetsScreen() {
    final suggestion = _suggestion;
    final calories = _intOf(_calories);
    final water = _intOf(_water);
    return [
      _title(
        'Seu plano diário',
        'Calculado com os seus dados. Ajuste quando quiser.',
      ),
      if (_support.contains('has_professional_plan'))
        const Padding(
          padding: EdgeInsets.only(bottom: Space.md),
          child: StatusBanner(
            message:
                'Se o seu profissional definiu metas, use os valores dele.',
          ),
        ),
      if (_suggestionLoading)
        const LoadingView(label: 'Calculando o seu plano')
      else if (_suggestionError != null)
        ErrorView(
          message: friendlyMessage(_suggestionError!),
          onRetry: _loadSuggestion,
        )
      else ...[
        AppCard(
          color: context.pic.brandContainer,
          child: Column(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: context.pic.onBrandContainer,
              ),
              const SizedBox(height: Space.xs),
              Text(
                calories == null ? '—' : Fmt.integer(calories),
                style: context.text.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.pic.onBrandContainer,
                ),
              ),
              Text(
                'kcal por dia',
                style: context.text.titleSmall?.copyWith(
                  color: context.pic.onBrandContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.md),
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
              water == null ? '' : Fmt.decimal(water / 1000),
              'L',
              context.pic.water,
            ),
          ],
        ),
        const SizedBox(height: Space.md),
        if (suggestion != null && suggestion.available)
          Text(
            'Como calculamos: ${suggestion.method}. ${suggestion.notes.join(' ')}',
            style: context.text.bodySmall?.copyWith(
              color: context.pic.textSecondary,
            ),
          )
        else
          Text(
            'Sem todos os dados, não calculamos uma sugestão. Informe as metas que você já conhece ou pule por agora.',
            style: context.text.bodySmall?.copyWith(
              color: context.pic.textSecondary,
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _update(() => _editTargets = !_editTargets),
            icon: Icon(_editTargets ? Icons.expand_less : Icons.edit_outlined),
            label: Text(_editTargets ? 'Fechar ajustes' : 'Ajustar valores'),
          ),
        ),
        if (_editTargets) _targetsForm(),
      ],
    ];
  }

  Widget _targetsForm() => Form(
    key: _targetsFormKey,
    child: Column(
      children: [
        NumberField(
          controller: _calories,
          label: 'Calorias por dia',
          unit: 'kcal',
          min: 800,
          max: 6000,
          decimal: false,
          optional: true,
          onChanged: (_) => _update(() {}),
        ),
        const SizedBox(height: Space.md),
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
                onChanged: (_) => _update(() {}),
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: NumberField(
                controller: _carbs,
                label: 'Carboidratos',
                unit: 'g',
                min: 0,
                max: 800,
                decimal: false,
                optional: true,
                onChanged: (_) => _update(() {}),
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: NumberField(
                controller: _fat,
                label: 'Gorduras',
                unit: 'g',
                min: 0,
                max: 300,
                decimal: false,
                optional: true,
                onChanged: (_) => _update(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.md),
        NumberField(
          controller: _water,
          label: 'Água por dia',
          unit: 'ml',
          min: 500,
          max: 6000,
          decimal: false,
          onChanged: (_) => _update(() {}),
        ),
      ],
    ),
  );
}
