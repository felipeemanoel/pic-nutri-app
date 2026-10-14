# Integrações do app

Todas as integrações ficam **desligadas** até serem configuradas. Sem configuração, a tela
correspondente não aparece ou informa que o recurso não está disponível, e nada é simulado.

As chaves privadas ficam só no servidor. No app vão apenas identificadores públicos, em
`env/*.json` (lidos com `--dart-define-from-file`).

## Login com Google

1. No Google Cloud Console, crie os clientes OAuth:
   - **Web**: o ID vai em `GOOGLE_SERVER_CLIENT_ID`;
   - **Android**: cadastre o pacote `br.com.picnutri` e o SHA-1 da assinatura de debug e de release;
   - **iOS**: o ID vai em `GOOGLE_IOS_CLIENT_ID`.
2. iOS: no `ios/Runner/Info.plist`, adicione em `CFBundleURLTypes` o *reversed client ID* do cliente iOS (`com.googleusercontent.apps.…`).
3. Servidor: `GOOGLE_CLIENT_IDS` deve conter o ID Web e o ID iOS, separados por vírgula.

## Login com Apple (iOS)

1. No Apple Developer, ative **Sign in with Apple** no App ID.
2. No Xcode (Runner → Signing & Capabilities), adicione a capability **Sign in with Apple**.
3. Servidor: `APPLE_CLIENT_IDS` = bundle ID do app.

O botão aparece só no iOS. O nonce é conferido pelo servidor.

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
