/// Catálogo de medicamentos para facilitar o cadastro e o acompanhamento.
/// Lista as canetas em uso no Brasil, inclusive as vendidas sem registro na
/// Anvisa (o PicNutri só acompanha, não vende). As doses são as apresentações
/// da bula, para a pessoa marcar a que já usa: o app não sugere nem calcula
/// doses. Produtos sem bula não têm lista de doses: a pessoa informa a dela.
///
/// Revisado em 28/10/2026 a partir das listas de registros da Anvisa
/// divulgadas na imprensa (jul. e set. de 2026) e das bulas dos fabricantes.
library;

/// Princípio ativo, com o rótulo exibido e a ordem dos grupos na lista.
enum MedicationIngredient {
  tirzepatide('tirzepatida'),
  semaglutide('semaglutida'),
  liraglutide('liraglutida'),
  dulaglutide('dulaglutida'),
  oralSemaglutide('semaglutida oral');

  const MedicationIngredient(this.label);

  final String label;

  /// Título do grupo na lista de escolha.
  String get groupTitle => switch (this) {
    tirzepatide => 'Tirzepatida',
    semaglutide => 'Semaglutida',
    liraglutide => 'Liraglutida',
    dulaglutide => 'Dulaglutida',
    oralSemaglutide => 'Comprimido',
  };
}

class KnownMedication {
  const KnownMedication({
    required this.id,
    required this.name,
    required this.ingredient,
    required this.form,
    required this.frequency,
    required this.doses,
    this.maker,
    this.purpose,
    this.genericEntry = false,
    this.irregular = false,
  });

  final String id;
  final String name;
  final MedicationIngredient ingredient;

  /// Valor da API: injection ou oral.
  final String form;

  /// Frequência mais comum na bula (pré-selecionada, pode ser trocada).
  final String frequency;

  /// Apresentações em mg.
  final List<double> doses;

  /// Fabricante ou empresa que comercializa no Brasil.
  final String? maker;

  /// Indicação principal em bula, em poucas palavras.
  final String? purpose;

  /// Entrada genérica por princípio ativo (genéricos, similares e outras
  /// marcas registradas que ainda não estão na lista). A pessoa pode digitar
  /// o nome que está na embalagem.
  final bool genericEntry;

  /// Sem registro na Anvisa: não há bula, então não há lista de doses.
  final bool irregular;

  static const other = 'other';

  static const _tirzepatide = [2.5, 5.0, 7.5, 10.0, 12.5, 15.0];
  static const _semaglutideDiabetes = [0.25, 0.5, 1.0, 2.0];
  static const _semaglutideNational = [0.25, 0.5, 1.0];
  static const _semaglutideWeight = [0.25, 0.5, 1.0, 1.7, 2.4];
  static const _liraglutideWeight = [0.6, 1.2, 1.8, 2.4, 3.0];
  static const _liraglutideDiabetes = [0.6, 1.2, 1.8];

  static const all = <KnownMedication>[
    // Tirzepatida
    KnownMedication(
      id: 'mounjaro',
      name: 'Mounjaro',
      ingredient: MedicationIngredient.tirzepatide,
      form: 'injection',
      frequency: 'weekly',
      doses: _tirzepatide,
      maker: 'Eli Lilly',
      purpose: 'diabetes tipo 2 e controle de peso',
    ),
    // Semaglutida: Novo Nordisk e parceria com a Eurofarma
    KnownMedication(
      id: 'ozempic',
      name: 'Ozempic',
      ingredient: MedicationIngredient.semaglutide,
      form: 'injection',
      frequency: 'weekly',
      doses: _semaglutideDiabetes,
      maker: 'Novo Nordisk',
      purpose: 'diabetes tipo 2',
    ),
    KnownMedication(
      id: 'wegovy',
      name: 'Wegovy',
      ingredient: MedicationIngredient.semaglutide,
      form: 'injection',
      frequency: 'weekly',
      doses: _semaglutideWeight,
      maker: 'Novo Nordisk',
      purpose: 'obesidade e sobrepeso',
    ),
    KnownMedication(
      id: 'poviztra',
      name: 'Poviztra',
      ingredient: MedicationIngredient.semaglutide,
      form: 'injection',
      frequency: 'weekly',
      doses: _semaglutideWeight,
      maker: 'Eurofarma / Novo Nordisk',
      purpose: 'obesidade e sobrepeso',
    ),
    KnownMedication(
      id: 'extensior',
      name: 'Extensior',
      ingredient: MedicationIngredient.semaglutide,
      form: 'injection',
      frequency: 'weekly',
      doses: _semaglutideDiabetes,
      maker: 'Eurofarma / Novo Nordisk',
      purpose: 'diabetes tipo 2',
    ),
    // Semaglutida: fabricantes nacionais e outros (registros de 2026)
    KnownMedication(
      id: 'ozivy',
      name: 'Ozivy',
      ingredient: MedicationIngredient.semaglutide,
      form: 'injection',
      frequency: 'weekly',
      doses: _semaglutideNational,
      maker: 'EMS',
      purpose: 'diabetes tipo 2',
    ),
    KnownMedication(
      id: 'ylumec',
      name: 'Yluméc',
      ingredient: MedicationIngredient.semaglutide,
      form: 'injection',
      frequency: 'weekly',
      doses: _semaglutideNational,
      maker: 'EMS',
    ),
    KnownMedication(
      id: 'semaclique',
      name: 'Semaclique',
      ingredient: MedicationIngredient.semaglutide,
      form: 'injection',
      frequency: 'weekly',
      doses: _semaglutideNational,
      maker: 'Germed',
    ),
    KnownMedication(
      id: 'zempneo',
      name: 'Zempneo',
      ingredient: MedicationIngredient.semaglutide,
      form: 'injection',
      frequency: 'weekly',
      doses: _semaglutideNational,
      maker: 'Brainfarma (Hypera)',
      purpose: 'diabetes tipo 2',
    ),
    KnownMedication(
      id: 'semavy',
      name: 'Semavy',
      ingredient: MedicationIngredient.semaglutide,
      form: 'injection',
      frequency: 'weekly',
      doses: _semaglutideNational,
      maker: 'Cosmed',
      purpose: 'diabetes tipo 2',
    ),
    KnownMedication(
      id: 'owozy',
      name: 'Owozy',
      ingredient: MedicationIngredient.semaglutide,
      form: 'injection',
      frequency: 'weekly',
      doses: _semaglutideNational,
      maker: 'Ávita Care',
      purpose: 'diabetes tipo 2',
    ),
    KnownMedication(
      id: 'seemasun',
      name: 'Seemasun',
      ingredient: MedicationIngredient.semaglutide,
      form: 'injection',
      frequency: 'weekly',
      doses: _semaglutideNational,
      maker: 'Sun Farmacêutica',
      purpose: 'diabetes tipo 2',
    ),
    KnownMedication(
      id: 'orsema',
      name: 'Orsema',
      ingredient: MedicationIngredient.semaglutide,
      form: 'injection',
      frequency: 'weekly',
      doses: _semaglutideNational,
      maker: 'Ranbaxy',
    ),
    // Liraglutida
    KnownMedication(
      id: 'saxenda',
      name: 'Saxenda',
      ingredient: MedicationIngredient.liraglutide,
      form: 'injection',
      frequency: 'daily',
      doses: _liraglutideWeight,
      maker: 'Novo Nordisk',
      purpose: 'obesidade e sobrepeso',
    ),
    KnownMedication(
      id: 'olire',
      name: 'Olire',
      ingredient: MedicationIngredient.liraglutide,
      form: 'injection',
      frequency: 'daily',
      doses: _liraglutideWeight,
      maker: 'EMS',
      purpose: 'obesidade e sobrepeso',
    ),
    KnownMedication(
      id: 'victoza',
      name: 'Victoza',
      ingredient: MedicationIngredient.liraglutide,
      form: 'injection',
      frequency: 'daily',
      doses: _liraglutideDiabetes,
      maker: 'Novo Nordisk',
      purpose: 'diabetes tipo 2',
    ),
    KnownMedication(
      id: 'lirux',
      name: 'Lirux',
      ingredient: MedicationIngredient.liraglutide,
      form: 'injection',
      frequency: 'daily',
      doses: _liraglutideDiabetes,
      maker: 'EMS',
      purpose: 'diabetes tipo 2',
    ),
    // Dulaglutida
    KnownMedication(
      id: 'trulicity',
      name: 'Trulicity',
      ingredient: MedicationIngredient.dulaglutide,
      form: 'injection',
      frequency: 'weekly',
      doses: [0.75, 1.5, 3, 4.5],
      maker: 'Eli Lilly',
      purpose: 'diabetes tipo 2',
    ),
    // Comprimido
    KnownMedication(
      id: 'rybelsus',
      name: 'Rybelsus',
      ingredient: MedicationIngredient.oralSemaglutide,
      form: 'oral',
      frequency: 'daily',
      doses: [3, 7, 14],
      maker: 'Novo Nordisk',
      purpose: 'diabetes tipo 2',
    ),
    // Genéricos, similares e marcas registradas que ainda não estão na lista
    KnownMedication(
      id: 'generic_tirzepatide',
      name: 'Tirzepatida',
      ingredient: MedicationIngredient.tirzepatide,
      form: 'injection',
      frequency: 'weekly',
      doses: _tirzepatide,
      genericEntry: true,
    ),
    KnownMedication(
      id: 'generic_semaglutide',
      name: 'Semaglutida',
      ingredient: MedicationIngredient.semaglutide,
      form: 'injection',
      frequency: 'weekly',
      doses: _semaglutideWeight,
      genericEntry: true,
    ),
    KnownMedication(
      id: 'generic_liraglutide',
      name: 'Liraglutida',
      ingredient: MedicationIngredient.liraglutide,
      form: 'injection',
      frequency: 'daily',
      doses: _liraglutideWeight,
      genericEntry: true,
    ),
    // Outras canetas de tirzepatida em uso (sem bula: a pessoa informa a dose).
    KnownMedication(
      id: 'irregular_tg',
      name: 'TG',
      ingredient: MedicationIngredient.tirzepatide,
      form: 'injection',
      frequency: 'weekly',
      doses: [],
      maker: 'Landerlan',
      irregular: true,
    ),
    KnownMedication(
      id: 'irregular_tg5',
      name: 'T.G. 5',
      ingredient: MedicationIngredient.tirzepatide,
      form: 'injection',
      frequency: 'weekly',
      doses: [],
      maker: 'Indufar',
      irregular: true,
    ),
    KnownMedication(
      id: 'irregular_lipoless',
      name: 'Lipoless',
      ingredient: MedicationIngredient.tirzepatide,
      form: 'injection',
      frequency: 'weekly',
      doses: [],
      maker: 'Laboratório Éticos',
      irregular: true,
    ),
    KnownMedication(
      id: 'irregular_lipoland',
      name: 'Lipoland',
      ingredient: MedicationIngredient.tirzepatide,
      form: 'injection',
      frequency: 'weekly',
      doses: [],
      maker: 'Landerlan',
      irregular: true,
    ),
    KnownMedication(
      id: 'irregular_synedica',
      name: 'Synedica',
      ingredient: MedicationIngredient.tirzepatide,
      form: 'injection',
      frequency: 'weekly',
      doses: [],
      irregular: true,
    ),
    KnownMedication(
      id: 'irregular_tirzec',
      name: 'Tirzec',
      ingredient: MedicationIngredient.tirzepatide,
      form: 'injection',
      frequency: 'weekly',
      doses: [],
      irregular: true,
    ),
    KnownMedication(
      id: 'irregular_tirzazep',
      name: 'Tirzazep',
      ingredient: MedicationIngredient.tirzepatide,
      form: 'injection',
      frequency: 'weekly',
      doses: [],
      maker: 'Royal Pharmaceuticals',
      irregular: true,
    ),
    KnownMedication(
      id: 'irregular_t36',
      name: 'T36',
      ingredient: MedicationIngredient.tirzepatide,
      form: 'injection',
      frequency: 'weekly',
      doses: [],
      maker: 'Scavone Hermanos',
      irregular: true,
    ),
  ];

  /// Marcas (sem as entradas genéricas), na ordem dos grupos.
  static List<KnownMedication> get brands => [
    for (final ingredient in MedicationIngredient.values)
      ...all.where((m) => !m.genericEntry && m.ingredient == ingredient),
  ];

  static List<KnownMedication> get genericEntries =>
      all.where((m) => m.genericEntry).toList();

  static KnownMedication? byId(String? id) {
    for (final m in all) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Medicamento do catálogo pelo nome cadastrado (marca ou princípio ativo
  /// citado no nome, como "Semaglutida (genérico EMS)").
  static KnownMedication? byName(String name) {
    final n = normalize(name);
    if (n.isEmpty) return null;
    for (final m in brands) {
      final brand = normalize(m.name);
      if (n == brand || n.startsWith('$brand ')) return m;
    }
    for (final m in genericEntries) {
      if (n.contains(normalize(m.name))) return m;
    }
    return null;
  }

  /// Texto em minúsculas e sem acentos, para comparar nomes.
  static String normalize(String text) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const to = 'aaaaaeeeeiiiiooooouuuuc';
    final lower = text.toLowerCase().trim();
    final buffer = StringBuffer();
    for (final ch in lower.split('')) {
      final i = from.indexOf(ch);
      buffer.write(i < 0 ? ch : to[i]);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Busca simples por marca, princípio ativo ou fabricante.
  bool matches(String query) {
    final q = normalize(query);
    if (q.isEmpty) return true;
    return normalize(name).contains(q) ||
        normalize(ingredient.label).contains(q) ||
        normalize(maker ?? '').contains(q);
  }
}
