# Integrações do app

Todas as integrações ficam **desligadas** até serem configuradas. Sem configuração, a tela
correspondente não aparece ou informa que o recurso não está disponível, e nada é simulado.

As chaves privadas ficam só no servidor. No app vão apenas identificadores públicos, em
`env/*.json` (lidos com `--dart-define-from-file`).

## Login social (Google, Facebook e Apple)

| Plataforma | Botões |
| --- | --- |
| Android | E-mail e senha, Google, Facebook |
| iOS | E-mail e senha, Google, Facebook, Apple |

Cada botão só aparece com o provedor configurado no app (`env/*.json`) **e** habilitado no servidor (`GET /api/v1/auth/providers`). O app nunca pede a senha do provedor: abre o fluxo oficial e envia a credencial à API, que a valida. Regras de conta (vínculo, comprovação, e-mail ausente) e variáveis do servidor: `pic-nutri/docs/login-social.md`.

Valores públicos ficam em `env/<ambiente>.json` (Android e Dart) e em `ios/Flutter/Social.xcconfig` (iOS, fora do git; modelo em `Social.xcconfig.example`). Use apps/clientes separados para desenvolvimento e produção quando o provedor permitir.

### Google

1. Google Cloud Console → APIs e serviços → Credenciais → criar clientes OAuth:
   - **Web**: o ID vai em `GOOGLE_SERVER_CLIENT_ID` (é o "público" do ID token);
   - **Android**: pacote `br.com.picnutri` + SHA-1 da assinatura de debug, de upload e da chave de assinatura do Google Play (Play Console → Integridade do app);
   - **iOS**: bundle ID; o ID vai em `GOOGLE_IOS_CLIENT_ID` e o "iOS URL scheme" (`com.googleusercontent.apps.…`) em `GOOGLE_REVERSED_CLIENT_ID` no `Social.xcconfig`.
2. Tela de consentimento OAuth: escopos `openid`, `email` e `profile` apenas; publique o app (sai do modo de teste).
3. Servidor: `GOOGLE_CLIENT_IDS` = ID Web e ID iOS, separados por vírgula.

### Facebook (Meta)

1. developers.facebook.com → criar app do tipo **Consumidor** → produto **Login do Facebook**.
2. Configurações → Básico: anote o **ID do app**; Avançado: **Token do cliente**. Preencha `FACEBOOK_APP_ID` e `FACEBOOK_CLIENT_TOKEN` em `env/*.json` e no `Social.xcconfig`. A **chave secreta do app** vai só no servidor (`FACEBOOK_APP_SECRET`).
3. Plataforma Android: pacote `br.com.picnutri`, classe `br.com.picnutri.MainActivity` e **hashes de chave** (base64 do SHA-1) de debug, upload e da chave do Google Play:
   `keytool -exportcert -alias <alias> -keystore <arquivo> | openssl sha1 -binary | openssl base64`
4. Plataforma iOS: bundle ID `br.com.picnutri`. No iOS o app usa o **Limited Login** (token OIDC com nonce, sem rastreamento), então não pede a permissão de rastreamento (ATT).
5. Permissões: apenas `public_profile` e `email` (ambas sem revisão do app). Preencha a URL da Política de Privacidade e a **URL de instruções de exclusão de dados** (`https://<site>/excluir-conta`).
6. Coloque o app em modo **Ao vivo** para usuários reais; em desenvolvimento, só administradores/testadores do app conseguem entrar.

O Android lê os valores do Facebook dos mesmos `--dart-define-from-file` (via `build.gradle.kts`); a coleta automática de eventos e do ID de publicidade fica desligada no Android e no iOS.

### Apple (somente iOS)

1. Apple Developer → Identifiers → App ID `br.com.picnutri`: ative **Sign in with Apple**.
2. Xcode (Runner → Signing & Capabilities): adicione **Sign in with Apple** (cria o `Runner.entitlements`).
3. Keys → crie uma chave com **Sign in with Apple**; baixe o `.p8` (uma única vez) e anote o Key ID e o Team ID. Vão só no servidor: `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY_PATH`. Com a chave, o servidor revoga o acesso na exclusão da conta (exigência da App Store).
4. Services → **Sign in with Apple for Email Communication**: cadastre o domínio/remetente dos e-mails do PicNutri, senão e-mails para endereços `@privaterelay.appleid.com` não chegam (códigos de verificação incluídos).
5. Servidor: `APPLE_CLIENT_IDS` = bundle ID.

## Código de barras

- Usa a câmera (`mobile_scanner`) e permite digitar o código manualmente.
- Servidor: `OPEN_FOOD_FACTS_ENABLED=true`. A Open Food Facts é uma base aberta (licença ODbL), e o app mostra a atribuição.
- Produto sem todos os valores no rótulo abre o cadastro para o usuário completar com a embalagem. Nenhum valor é estimado.

## Push enviado pelo servidor (Firebase Cloud Messaging)

1. Crie um projeto no Firebase e registre os apps Android (`br.com.picnutri`) e iOS.
2. Preencha `FIREBASE_PROJECT_ID`, `FIREBASE_SENDER_ID`, `FIREBASE_ANDROID_API_KEY`, `FIREBASE_ANDROID_APP_ID`, `FIREBASE_IOS_API_KEY` e `FIREBASE_IOS_APP_ID`. Os valores estão nos arquivos de configuração do Firebase; os arquivos em si não são usados.
3. iOS:
   - no Xcode, adicione as capabilities **Push Notifications** e **Background Modes → Remote notifications** (o `Info.plist` já declara o modo);
   - envie a chave APNs (.p8) ao Firebase.
4. Servidor: `PUSH_DRIVER=fcm`, `FCM_PROJECT_ID` e `FCM_CREDENTIALS` (JSON da conta de serviço, fora do repositório). Para testar, rode `php artisan push:test email@conta`.

O Firebase exige **iOS 15** ou superior, por isso o deployment target do projeto passou para 15.0.

Sem essa configuração, o app continua funcionando: os lembretes locais disparam normalmente e as mensagens do servidor aparecem na central de notificações (sino no Início). Só o aviso push deixa de chegar. Veja `docs/notificacoes.md`.

## Assinaturas (Google Play e App Store)

1. Crie as assinaturas nas lojas, por exemplo `premium_mensal` e `premium_anual`.
2. Servidor:
   - `STORE_PRODUCTS=premium_mensal:premium,premium_anual:premium`;
   - Google Play: `GOOGLE_PLAY_PACKAGE`, `GOOGLE_PLAY_CREDENTIALS` (conta de serviço com acesso à Play Developer API) e `GOOGLE_PLAY_RTDN_TOKEN`;
   - App Store: `APP_STORE_BUNDLE_ID` e `APP_STORE_ROOT_CA` (certificado *Apple Root CA - G3*, de apple.com/certificateauthority). Em testes, `APP_STORE_ENVIRONMENTS=Production,Sandbox`.
3. Notificações das lojas:
   - Google Play: tópico do Pub/Sub com assinatura *push* para `https://API/api/v1/billing/webhooks/google-play?token=GOOGLE_PLAY_RTDN_TOKEN`;
   - App Store: App Store Server Notifications **v2** para `https://API/api/v1/billing/webhooks/app-store`.
4. iOS: adicione a capability **In-App Purchase**.

O plano só é liberado depois que o servidor confirma a compra com a loja. A compra fica vinculada à conta por um identificador opaco (`billing/account-token`).
