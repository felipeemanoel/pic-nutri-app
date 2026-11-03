# PicNutri — Múltiplos idiomas: escopo

Data: 03/11/2026. App: `pic-nutri-app` (branch `feature/revisao-ux`). API: `pic-nutri`.

## Idiomas

| Idioma | Código | Bandeira | Situação |
|---|---|---|---|
| Português (Brasil) | `pt-BR` | 🇧🇷 | Modelo, completo |
| English | `en` | 🇺🇸 | Em andamento |
| Español | `es` | 🇪🇸 | Em andamento |
| Français | `fr` | 🇫🇷 | Em andamento |
| Deutsch | `de` | 🇩🇪 | Em andamento |
| 简体中文 (chinês simplificado) | `zh` | 🇨🇳 | Em andamento |
| 日本語 | `ja` | 🇯🇵 | Em andamento |

Ordem sugerida de lançamento: inglês e espanhol primeiro (maior alcance), depois francês e alemão, por último chinês e japonês (exigem mais revisão de layout e conteúdo).

## O que já ficou pronto (Fase 0, nesta entrega)

**Infraestrutura**

- `flutter gen-l10n` com arquivos `.arb` em `lib/l10n/`. O modelo é `app_pt.arb`; `l10n.yaml` configura a geração; `generate: true` no `pubspec.yaml`. O código gerado (`app_localizations*.dart`) sai no `flutter pub get`.
- `lib/core/i18n/app_language.dart`: a lista de idiomas, com bandeira, nome no próprio idioma e a marca `complete`.
- `lib/core/i18n/locale_controller.dart`: guarda a escolha no aparelho (armazenamento seguro, como o tema). Sem escolha, segue o idioma do aparelho.
- `lib/core/i18n/l10n.dart`: atalho `context.l10n.chave`. Em testes sem os delegates, cai no português.
- `MaterialApp` com os 7 idiomas: botões, calendários e diálogos do Material já saem traduzidos.
- Toda requisição à API leva `Accept-Language` com o idioma em uso (`pt-BR`, `en`...).
- iOS: `CFBundleLocalizations` no `Info.plist`. Android 13+: `locales_config.xml`, que permite trocar o idioma do app nas configurações do sistema.
- Flag `FEATURE_LANGUAGES` (padrão `true`). Com `false`, o seletor some e o app fica em português, como antes.

**Regra de segurança para o lançamento.** No modo automático, o app só usa idiomas com tradução concluída (`complete: true`). Um celular em inglês continua abrindo o app em português até o inglês ficar completo, para não mostrar telas meio traduzidas. A pessoa pode escolher um idioma em andamento no seletor; ele aparece com o aviso "Tradução em andamento". Quando o inglês estiver completo, a sugestão é trocar `AppLanguage.fallback` para inglês.

**Onde a pessoa escolhe**

1. **Login:** botão discreto com bandeira e sigla no canto superior direito. Também aparece no cadastro e nas telas de senha.
2. **Primeiro cadastro:** cartão "Idioma · 🇧🇷 Português (Brasil) · Alterar" na tela de boas-vindas do onboarding.
3. **Perfil › Preferências › Idioma:** mostra o idioma atual e abre a mesma lista.

A lista mostra a bandeira, o nome do idioma escrito nele mesmo e a opção "Usar o idioma do aparelho".

**Textos já migrados (piloto, 50 chaves):** tela de idioma, tela de boas-vindas do onboarding e botões Começar/Continuar, frases do login e cadastro, e a tela de Perfil inteira.

## O que falta

### Fase 1 — Textos do app (o maior volume)

Levantamento: cerca de **2.300 textos em 129 arquivos**.

| Módulo | Textos (aprox.) |
|---|---|
| Medicamento | 270 |
| Onboarding | 250 |
| Alimentação | 170 |
| Atividade física | 150 |
| Evolução | 145 |
| Profissionais | 125 |
| Planejamento e receitas | 125 |
| Assistente | 115 |
| Login e conta | 110 |
| IA (foto e texto) | 100 |
| Compartilhados (`shared/`, `labels.dart`, validações) | 90 |
| Início | 90 |
| Perfil, relatórios, lembretes, notificações e demais | 500 |

Itens da fase:

- Migrar os textos para os `.arb`, um módulo por vez, começando pelo caminho do novo usuário: login, onboarding, Início, Alimentação.
- `Fmt` (`core/utils/formatters.dart`) usa `pt_BR` fixo para números e datas. Passar a usar o idioma em uso, com testes de cada idioma.
- `shared/labels.dart` e `onboarding_options.dart` (opções de objetivo, atividade e afins) também vão para os `.arb`.
- Plurais e gênero com ICU (`{count, plural, ...}`), em vez de concatenar textos.
- Validações (`validators.dart`) e mensagens de erro (`core/error`).
- Notificações locais e lembretes: o texto é montado no aparelho e precisa sair no idioma em uso.
- Um teste que falhe quando surgir texto fixo em português em `presentation/`, para impedir regressões.
- Layout:
  - o alemão é cerca de 30% mais longo, então conferir as telas de 320 px (o teste do login já cobre esse tamanho);
  - chinês e japonês usam a fonte do sistema, porque a Inter do app só tem caracteres latinos;
  - conferir altura de linha e quebras.

Para marcar um idioma como `complete: true`, ele precisa ter todas as chaves traduzidas (o arquivo `build/l10n_untranslated.json` lista o que falta), revisão de um falante nativo e as telas principais conferidas no aparelho.

### Fase 2 — API (pic-nutri)

- Coluna `users.locale`, enviada no cadastro e no perfil. A API usa essa coluna para enviar push e e-mail no idioma certo, mesmo com o app fechado.
- Middleware que aplica `App::setLocale` a partir de `Accept-Language` ou de `users.locale`.
- Arquivos `lang/{en,es,fr,de,zh_CN,ja}/` para validação, autenticação, senhas e mensagens próprias. Hoje só existe `lang/pt_BR`.
- Opções que a API devolve com rótulos em português, como `ProfileController` e `MedicationController`: devolver códigos e traduzir no app, ou traduzir na API pelo locale.
- IA (`AI/Drivers/Prompts.php`): os prompts mandam usar "português do Brasil". Passar o idioma da pessoa para os nomes dos alimentos e para as respostas do assistente.
- Relatório CSV: separador `;` e formato de números conforme o idioma.
- E-mails (recuperação de senha, convites), notificações push e campanhas do painel em cada idioma.
- O painel administrativo (Filament) continua em português.

### Fase 3 — Conteúdo e dados

- **Base de alimentos.** A TACO é brasileira (nomes e porções em português).
  - Para outros idiomas: tabela de traduções dos nomes da TACO e mais fontes por país (Open Food Facts já é usado no código de barras; USDA FoodData Central para inglês).
  - Medidas caseiras por cultura (copo, colher, *cup*).
  - A busca precisa funcionar no idioma da pessoa.
- **Central de ajuda, artigos e receitas** (`database/data/help_articles.php`, `database/content/`): versões por idioma no banco e no painel.
  - Os artigos de saúde exigem revisão clínica em cada idioma.
  - Enquanto não houver versão no idioma da pessoa, mostrar o original com um aviso.
- **Avisos de segurança dos sintomas e do medicamento:** texto clínico, com tradução revisada por profissional e não só traduzida.
- **Medicamentos:** os nomes comerciais e as doses de bula variam por país, então revisar o catálogo por mercado.

### Fase 4 — Lojas, jurídico e país

- Ficha das lojas (Play e App Store) por idioma: título, descrição e capturas de tela traduzidas.
- Termos de uso e política de privacidade traduzidos.
  - Usuários na Europa (França, Alemanha) ficam sob a GDPR, além da LGPD: revisão jurídica do consentimento de dados de saúde.
  - Pedidos dos usuários europeus (acesso, portabilidade) também precisam ser atendidos.
- Assinaturas: os preços por país são definidos nas lojas. Conferir os textos do plano e o cancelamento em cada idioma.
- **Idioma não é país.** A área de Profissionais depende de CRN/CREF e CEP (ViaCEP), ou seja, é só do Brasil. Para quem não está no Brasil:
  - esconder a área ou mostrar só atendimento online;
  - decidir isso pelo país (cadastro ou região da loja), não pelo idioma.
- Unidades: o onboarding já tem métrico e imperial. Sugerir imperial por padrão para inglês dos EUA.

### Fase 5 — Lançamento gradual

1. Inglês e espanhol completos e revisados → `complete: true` → `fallback` passa a ser inglês.
2. Francês e alemão (junto com a revisão da GDPR).
3. Chinês e japonês (layout e conteúdo revisados). A distribuição na China continental não usa a Play Store e exige outra estratégia; Taiwan e Hong Kong usam o chinês tradicional (`zh-Hant`), que não está no escopo.

## Processo de tradução

- O `.arb` em português é o modelo. Toda chave nova entra nele com `description` (contexto para quem traduz).
- Tradução inicial com IA usando um glossário fixo (por exemplo: "Evolução" = *Progress*, "aplicação" = *dose*), seguida de revisão de um falante nativo. Os textos de saúde também passam por revisão clínica.
- Sugestão: uma ferramenta de tradução (Crowdin, Lokalise ou POEditor) ligada ao repositório, para que os tradutores trabalhem fora do código.
- QA por idioma: teste de widget das telas principais em cada idioma e conferência manual no iPhone e no Android.

## Para rodar no Mac

```
flutter pub get        # gera lib/l10n/app_localizations*.dart
flutter analyze
flutter test
```

O código desta fase não foi compilado no ambiente do Claude: não há Flutter disponível na sessão. Testes novos: `test/core/i18n/app_language_test.dart` (idiomas, igualdade de chaves e marcadores entre os `.arb`, e o seletor salvando a escolha).
