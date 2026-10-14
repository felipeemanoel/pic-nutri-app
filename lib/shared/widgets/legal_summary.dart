import 'package:flutter/material.dart';

/// Resumo de como o app trata os dados. Reflete o funcionamento real do
/// sistema; os documentos jurídicos oficiais estão pendentes de publicação.
Future<void> showLegalSummary(
  BuildContext context,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.75,
    builder: (context, controller) => ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: const [
        _Title('Como usamos seus dados'),
        _Item(
          'O que coletamos',
          'Dados da conta (nome, e-mail), e os registros que você fizer: '
              'perfil, refeições, água, peso, medidas, medicamentos e fotos de refeições.',
        ),
        _Item(
          'Dados de saúde',
          'Peso, medidas, restrições alimentares e medicamentos são dados sensíveis. '
              'Só são coletados com o seu consentimento específico, que pode ser revogado no perfil.',
        ),
        _Item(
          'Para que usamos',
          'Para mostrar seus registros, calcular totais e indicadores e, quando você pedir, '
              'gerar estimativas com inteligência artificial.',
        ),
        _Item(
          'Inteligência artificial',
          'Fotos e perguntas enviadas à IA vão a um provedor externo apenas com o necessário '
              'para a resposta, sem nome ou e-mail. As estimativas são aproximadas e não são orientação médica.',
        ),
        _Item(
          'Seus direitos',
          'Você pode consultar, corrigir, exportar e excluir seus dados a qualquer momento, '
              'em Perfil > Privacidade.',
        ),
        _Item(
          'Segurança',
          'Conexão criptografada, senha protegida, acesso restrito à sua conta e '
              'registros técnicos sem dados pessoais.',
        ),
        SizedBox(height: 8),
        Text(
          'Os Termos de Uso e a Política de Privacidade completos estão em elaboração '
          'e serão apresentados para novo aceite quando publicados.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    ),
  ),
);

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

class _Item extends StatelessWidget {
  const _Item(this.title, this.body);

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(body),
      ],
    ),
  );
}
