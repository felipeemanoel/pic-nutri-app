/// Consultas direcionadas: nunca envia texto arbitrário ao modelo.
/// Esta barreira de UX não substitui autorização, contexto e política no servidor.
abstract final class AssistantScope {
  static const refusal =
      'Esta pergunta não está disponível aqui. Posso ajudar com seus registros nesta conta e com o uso do PicNutri. Escolha um dos assuntos disponíveis.';
  static const description =
      'Consulte seus registros desta conta ou tire dúvidas sobre como usar o PicNutri.';
  static const suggestions = [
    'Como foi minha alimentação nesta semana?',
    'Quanto de água registrei hoje?',
    'Qual é minha meta de proteínas hoje?',
    'Como está minha evolução de peso?',
  ];

  static const questions = <String, List<String>>{
    'Olá!': ['oi', 'ola', 'bom dia', 'boa tarde', 'boa noite'],
    'Como foi minha alimentação nesta semana?': [
      'como foi minha alimentacao nesta semana',
      'como foi minha alimentacao essa semana',
      'como foi minha alimentacao na semana',
      'como foi minha semana',
      'resuma minha alimentacao nesta semana',
    ],
    'Como foi minha alimentação hoje?': [
      'como foi minha alimentacao hoje',
      'como esta minha alimentacao hoje',
      'o que eu comi hoje',
      'o que comi hoje',
      'quais refeicoes registrei hoje',
    ],
    'Quanto de água registrei hoje?': [
      'quanto de agua registrei hoje',
      'quanta agua bebi hoje',
      'quanto de agua bebi hoje',
      'estou bebendo agua suficiente',
      'como esta minha hidratacao hoje',
      'como esta minha hidratacao',
    ],
    'Qual é minha meta de proteínas hoje?': [
      'qual e minha meta de proteinas hoje',
      'qual minha meta de proteinas hoje',
      'quanto falta para minha meta de proteinas hoje',
      'como posso chegar a minha meta de proteinas hoje',
    ],
    'Como está minha evolução de peso?': [
      'como esta minha evolucao de peso',
      'como foi minha evolucao de peso',
      'qual e meu ultimo peso registrado',
      'qual meu ultimo peso registrado',
    ],
    'Quais são minhas metas registradas no PicNutri?': [
      'quais sao minhas metas',
      'quais sao minhas metas registradas no picnutri',
      'quais minhas metas',
      'quais sao minhas metas diarias',
    ],
    'Quais sintomas registrei nesta semana?': [
      'quais sintomas registrei nesta semana',
      'quais sintomas registrei essa semana',
      'mostre meus sintomas desta semana',
    ],
    'Quais aplicações de medicamento registrei nesta semana?': [
      'quais aplicacoes de medicamento registrei nesta semana',
      'quais aplicacoes registrei nesta semana',
      'qual foi minha ultima aplicacao registrada',
    ],
    'Quais são os dados do meu perfil nesta conta?': [
      'quais sao os dados do meu perfil nesta conta',
      'o que voce sabe sobre mim',
      'quais sao meus dados cadastrados',
      'qual e meu nome',
    ],
    'Quais refeições estão no meu plano alimentar desta semana?': [
      'quais refeicoes estao no meu plano alimentar desta semana',
      'qual e meu plano alimentar desta semana',
    ],
    'Como registrar uma refeição no PicNutri?': [
      'como registrar uma refeicao no picnutri',
      'como registro uma refeicao no app',
      'como registrar refeicao',
    ],
    'Como registrar água no PicNutri?': [
      'como registrar agua no picnutri',
      'como registro agua no app',
      'como registrar agua',
    ],
    'Como consultar meus relatórios no PicNutri?': [
      'como consultar meus relatorios no picnutri',
      'onde encontro meus relatorios',
    ],
  };

  static String normalize(String text) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const to = 'aaaaaeeeeiiiiooooouuuuc';
    var value = text.toLowerCase().trim();
    for (var i = 0; i < from.length; i++) {
      value = value.replaceAll(from[i], to[i]);
    }
    return value
        .replaceAll(RegExp(r'[?!.:,;]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Correspondência da pergunta inteira, sem aceitar instruções adicionais.
  static String? resolve(String text) {
    final normalized = normalize(text);
    for (final entry in questions.entries) {
      if (normalize(entry.key) == normalized ||
          entry.value.contains(normalized)) {
        return entry.key;
      }
    }
    return null;
  }
}
