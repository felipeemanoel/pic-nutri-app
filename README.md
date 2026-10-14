# PicNutri — App mobile

App Flutter (Android e iOS) do PicNutri.
Flutter 3.44 · Dart 3.12 · Riverpod 3 · GoRouter 18 · Dio 5 · flutter_secure_storage 11.

> Etapa atual: **base técnica**. Só existe uma tela técnica que consulta `GET /api/v1/health`.
> A arquitetura completa está no repositório do backend (`pic-nutri/docs/architecture.md`).

## Pré-requisitos (macOS)

```bash
brew tap leoafarias/fvm && brew install fvm   # fixa a versão do Flutter por projeto
fvm install                                   # instala a versão do .fvmrc (3.44.2)
xcode-select --install                        # + Xcode pela App Store
brew install cocoapods
# Android Studio com SDK da API 36 e um emulador; depois:
fvm flutter doctor --android-licenses
fvm flutter doctor
```

## Primeira execução

As pastas `android/` e `ios/` são geradas pelo Flutter na primeira vez
(o código em `lib/`, os testes e as configurações já existentes são mantidos):

```bash
fvm flutter create --org br.com --project-name picnutri --platforms android,ios .
fvm flutter pub get
dart format lib test integration_test
```

Depois, permita HTTP só para a API local no **simulador iOS** (Android já está configurado em
`android/app/src/debug/AndroidManifest.xml`): em `ios/Runner/Info.plist`, adicione

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsLocalNetworking</key>
  <true/>
</dict>
```

## Rodar

Com o backend no ar (`docker compose up -d` no projeto `pic-nutri`):

```bash
fvm flutter run --dart-define-from-file=env/dev.json       # emulador Android (API em 10.0.2.2:8080)
fvm flutter run --dart-define-from-file=env/dev-ios.json   # simulador iOS (API em localhost:8080)
```

| Arquivo | Ambiente | API |
| --- | --- | --- |
| `env/dev.json` | dev (Android) | `http://10.0.2.2:8080` |
| `env/dev-ios.json` | dev (iOS) | `http://localhost:8080` |
| `env/staging.json` | homologação | HTTPS obrigatório |
| `env/prod.json` | produção | HTTPS obrigatório |

Os arquivos `env/*.json` contêm só valores públicos. **Nenhum segredo vai para o app**:
tudo que está no binário pode ser extraído. Para um ajuste pessoal, use `env/<nome>.local.json` (ignorado pelo Git).

Identificadores separados por ambiente (`br.com.picnutri.dev`, `.staging`) serão configurados como
flavors Android e schemes iOS depois que as pastas nativas forem geradas.

## Qualidade

```bash
fvm dart format lib test integration_test
fvm flutter analyze
fvm flutter test
fvm flutter test integration_test --dart-define-from-file=env/dev.json   # com emulador aberto e API no ar
```

## Estrutura

```text
lib/
├── main.dart                 lê o ambiente, inicia erros (GlitchTip/Sentry) e o app
├── app/                      app.dart, router.dart (GoRouter), env.dart, theme/
├── core/
│   ├── network/              Dio (/api/v1) e interceptor do token
│   ├── storage/              TokenStorage (Keychain/Keystore)
│   ├── error/                AppFailure: tradução única dos erros da API
│   └── logging/              envio de erros sem dados pessoais
├── features/<feature>/
│   ├── data/                 modelos, repositórios, acesso à API
│   ├── domain/               (só quando houver regra local relevante)
│   └── presentation/         telas, widgets e providers
└── shared/widgets/           componentes reutilizáveis
```

## Regras

- O app não é fonte de verdade: autorização, cotas e cálculos oficiais vêm da API.
- Tokens só no `TokenStorage`; nunca em SharedPreferences, arquivos ou logs.
- Toda chamada de rede passa pelo `dioProvider`; todo erro vira `AppFailure`.
- Estimativas de IA sempre exibidas como aproximadas e editáveis; nada de orientação de dose.
