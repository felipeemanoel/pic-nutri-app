# PicNutri — Identidade visual e Design System

> **Sua evolução, no seu ritmo.**
> Nutrição, evolução e inteligência, sem pressão estética: o app informa, não julga.

Código: `lib/core/design/` (tokens, cores semânticas, marca e componentes) e `lib/app/theme/app_theme.dart` (temas). Telas não definem cores, fontes ou raios próprios: usam `Theme.of(context)`, `context.pic` e os componentes abaixo.

## Marca

| Arquivo | Uso |
| --- | --- |
| `tool/brand/symbol.py` | Geometria oficial do símbolo (grade de 1024) |
| `tool/brand/generate.py` | Gera todos os ícones e o splash (`python3 tool/brand/generate.py`) |
| `assets/brand/picnutri_icon.svg` | Ícone com fundo esmeralda (referência) |
| `assets/brand/picnutri_symbol.svg` | Símbolo esmeralda sem fundo (referência) |
| `assets/brand/picnutri_icon_512.png` | Ícone 512 px (lojas, materiais) |
| `lib/core/design/brand_logo.dart` | `PicNutriSymbol`, `PicNutriAppIcon`, `PicNutriWordmark` (desenhados em código) |

**Símbolo**: um "P" cujo bojo é uma folha com a ponta subindo para a direita; a nervura vazada é uma linha de evolução. Sem balança, fita métrica ou silhuetas. Legível a partir de 16 px.

**Ícones gerados**

| Plataforma | Arquivos | Tamanhos |
| --- | --- | --- |
| Android (legado) | `mipmap-*/ic_launcher.png` | 48, 72, 96, 144, 192 px |
| Android (adaptativo, 8+) | `mipmap-anydpi-v26/ic_launcher.xml` + `mipmap-*/ic_launcher_foreground.png` (fundo `@color/ic_launcher_background` #087F5B) | 108 dp: 108–432 px |
| Android 13+ (temático) | `mipmap-*/ic_launcher_monochrome.png` | 108–432 px |
| Splash Android ≤ 11 | `drawable/launch_background.xml` + `drawable-*/splash_symbol.png` | 96–384 px |
| Splash Android 12+ | `values-v31/styles.xml` (`windowSplashScreen*`) | ícone adaptativo |
| iOS | `AppIcon.appiconset` (sem transparência, o sistema aplica a máscara) | 20–1024 pt |
| Splash iOS | `LaunchImage.imageset` + fundo esmeralda no `LaunchScreen.storyboard` | 96/192/288 px |

**Uso do nome**: sempre "PicNutri" (P e N maiúsculos, sem espaço).

## Cores

### Tema claro

| Token | Hex | Uso |
| --- | --- | --- |
| Primary | `#087F5B` | Botões principais, ações, destaque |
| Primary Dark | `#066649` | Texto sobre Primary Light, estados pressionados |
| Primary Light | `#DDF5EA` | Fundos de destaque, indicador da navegação |
| Accent | `#65D6AD` | Detalhes e indicadores (nunca texto sobre branco: 1,8:1) |
| Background | `#F7F9F7` | Fundo das telas |
| Surface | `#FFFFFF` | Cartões, modais |
| Text Primary | `#1E2925` | Títulos e conteúdo |
| Text Secondary | `#68756F` | Descrições |
| Border | `#E4EAE6` | Bordas e divisores |
| Success / Warning / Error / Info | `#21865A` / `#B7791F` / `#C43D4B` / `#3478C8` | Estados reais |
| AI Primary / Light / Dark | `#7561D8` / `#EEEAFE` / `#5141A6` | Somente recursos de IA |

### Tema escuro

Fundo `#111815`, superfícies `#1B2420` / `#232E28`, texto `#F1F6F2` / `#B1BDB5`, ação `#65D6AD`, bordas `#344139`. Estados e IA ganham tons próprios (não é inversão automática): erro `#E07A86`, alerta `#E0B25C`, informação `#6FA8EA`, sucesso `#5CC48E`, IA `#B3A6F5` sobre `#2A2547`.

### Macronutrientes e água

| | Claro | Escuro |
| --- | --- | --- |
| Proteínas | `#3478C8` | `#6FA8EA` |
| Carboidratos | `#B7791F` | `#E0B25C` |
| Gorduras | `#B0577A` | `#DB8DAB` |
| Água | `#2B8FC4` | `#6CC0EA` |

Sempre acompanhados de rótulo e valor; a cor nunca é a única informação.

### Contraste (WCAG 2.1)

| Combinação | Razão | Resultado |
| --- | --- | --- |
| Branco sobre Primary | 5,0:1 | AA texto |
| Primary sobre Surface | 5,0:1 | AA texto |
| Text Secondary sobre Surface / Background | 4,8:1 / 4,6:1 | AA texto |
| Text Primary sobre Background | 14,2:1 | AAA |
| Primary Dark sobre Primary Light | 6,1:1 | AA texto |
| AI Dark sobre AI Light | 6,7:1 | AA texto |
| AI Primary sobre Surface | 4,7:1 | AA texto |
| Warning `#B7791F` sobre branco | 3,6:1 | só ícones/gráficos — texto usa `#8F5E14` (5,6:1) |
| Accent sobre Surface | 1,8:1 | só decorativo, nunca texto |
| Escuro: texto / secundário sobre superfície | 14,6:1 / 8,2:1 | AAA |
| Escuro: Accent sobre fundo | 10,1:1 | AAA |

Verificado também em `test/core/design/design_system_test.dart`.

## Tipografia

Inter (OFL 1.1, `assets/fonts/OFL.txt`), pesos 400/500/600/700, reduzida a caracteres latinos (≈80 KB por peso). Números em destaque usam algarismos tabulares.

| Estilo | Tamanho / peso | Uso |
| --- | --- | --- |
| displaySmall | 28 / 600 | Valor numérico principal |
| headlineSmall | 22 / 600 | Saudação, títulos de página |
| titleLarge | 20 / 600 | Barra superior, títulos de seção |
| titleMedium | 17 / 600 | Títulos de cartão |
| titleSmall | 15 / 600 | Subtítulos, itens |
| bodyLarge / bodyMedium | 16 / 15 | Texto |
| bodySmall | 13 (secundária) | Texto auxiliar |
| labelLarge | 15 / 600 | Botões |
| labelSmall | 12 / 500 | Rótulos de indicadores |

O tamanho de fonte do sistema é respeitado (sem `textScaler` fixo).

## Espaçamento, forma e movimento

- Espaços (`Space`): 4, 8, 12, 16, 20, 24, 32; margem lateral 20.
- Raios (`Radii`): controles 12, botões 14, cartões 16, diálogos 20, folhas 24.
- Cartões com borda de 1 px (`Border`) em vez de sombra; sombra suave (`Shadows.soft`) só quando agrega hierarquia.
- Áreas de toque ≥ 48 dp; botões principais com 52 dp de altura.
- Animações (`Motion`): 150/250/400 ms, `easeOutCubic`; desligadas quando o sistema pede menos movimento (`MediaQuery.disableAnimations`).

## Componentes (`lib/core/design/components`)

| Componente | Uso |
| --- | --- |
| `AppCard` | Cartão padrão (borda, raio 16, toque opcional) |
| `SectionHeader` | Título de seção com ação |
| `StatusBanner` | Aviso com tom `info`, `success`, `warning`, `error`, `ai`, `brand` (ícone + texto) |
| `AiBadge` | Selo "Estimativa por IA" |
| `ProgressRing` / `ProgressBar` | Progresso animado e acessível |
| `MetricValue` / `MetricTile` | Números em destaque |
| `MacroSummary` | Proteínas, carboidratos e gorduras |
| `QuickAction` | Ações rápidas do painel |
| `Skeleton` / `SkeletonCard` | Placeholders de carregamento |
| `LoadingView`, `ErrorView`, `EmptyState`, `AsyncValueView`, `LoadingButton`, `SectionCard` | Estados (em `lib/shared/widgets/state_views.dart`) |
| `DateLineChart`, `DailyBarChart`, `Sparkline` | Gráficos (fl_chart) com cores do tema |

## Ícones

Material Icons (já incluídos no Flutter): estilo *outlined* para itens inativos e *filled* apenas no item selecionado da navegação. IA sempre com `auto_awesome`.

## Regras de comunicação visual

- Variações de peso em cor neutra, com sinal (+/−); nada de vermelho para "subiu".
- Calorias sempre em relação à meta do usuário; acima da meta aparece como "acima da meta", sem alarme.
- Estimativas de IA sempre com o selo de IA e opção de corrigir.
- Estados vazios explicam o que fazer e oferecem uma ação; nunca números fictícios.
