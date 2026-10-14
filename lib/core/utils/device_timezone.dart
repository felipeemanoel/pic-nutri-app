import 'package:flutter_timezone/flutter_timezone.dart';

/// Fuso IANA do aparelho (ex.: "America/Recife"), ou null se indisponível.
///
/// A API usa o fuso para definir a que dia pertence cada registro.
Future<String?> deviceTimezone() async {
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    return info.identifier.contains('/') ? info.identifier : null;
  } on Object {
    return null;
  }
}
