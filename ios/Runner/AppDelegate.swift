import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Mostra os lembretes também com o app aberto (flutter_local_notifications).
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Situação da permissão de notificações e atalho para as configurações do app.
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PicNutriNotificationSettings") else { return }
    let channel = FlutterMethodChannel(
      name: "br.com.picnutri/notification_settings",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "status":
        UNUserNotificationCenter.current().getNotificationSettings { settings in
          let status: String
          switch settings.authorizationStatus {
          case .authorized, .provisional, .ephemeral: status = "granted"
          case .notDetermined: status = "notDetermined"
          default: status = "denied"
          }
          DispatchQueue.main.async { result(status) }
        }
      case "open":
        let url: URL?
        if #available(iOS 16.0, *) {
          url = URL(string: UIApplication.openNotificationSettingsURLString)
        } else {
          url = URL(string: UIApplication.openSettingsURLString)
        }
        guard let target = url else { result(false); return }
        UIApplication.shared.open(target) { opened in result(opened) }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
