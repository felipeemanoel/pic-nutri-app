import 'dart:io';

/// Identificadores públicos das integrações, definidos no build
/// (`--dart-define-from-file`). Nenhum é segredo: chaves privadas ficam só no
/// servidor. Valor vazio = integração desligada no app.
abstract final class Integrations {
  // Login com Google: ID do cliente "Web" (o servidor confere o "aud").
  static const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  // iOS: ID do cliente iOS (também precisa do URL scheme no Info.plist).
  static const googleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  // Firebase Cloud Messaging (push enviado pelo servidor).
  static const firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const firebaseSenderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const firebaseAndroidApiKey = String.fromEnvironment('FIREBASE_ANDROID_API_KEY');
  static const firebaseAndroidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const firebaseIosApiKey = String.fromEnvironment('FIREBASE_IOS_API_KEY');
  static const firebaseIosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const iosBundleId = String.fromEnvironment('IOS_BUNDLE_ID', defaultValue: 'br.com.picnutri');

  static bool get googleSignIn =>
      googleServerClientId.isNotEmpty && (!Platform.isIOS || googleIosClientId.isNotEmpty);

  /// Sign in with Apple nativo só existe no iOS.
  static bool get appleSignIn => Platform.isIOS;

  static bool get push {
    if (firebaseProjectId.isEmpty || firebaseSenderId.isEmpty) return false;
    if (Platform.isAndroid) return firebaseAndroidApiKey.isNotEmpty && firebaseAndroidAppId.isNotEmpty;
    if (Platform.isIOS) return firebaseIosApiKey.isNotEmpty && firebaseIosAppId.isNotEmpty;
    return false;
  }
}
