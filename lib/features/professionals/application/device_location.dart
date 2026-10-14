import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Resultado de um pedido de localização.
sealed class LocationResult {
  const LocationResult();
}

final class LocationFound extends LocationResult {
  const LocationFound(this.lat, this.lng);

  final double lat;
  final double lng;
}

final class LocationUnavailable extends LocationResult {
  const LocationUnavailable(this.message, {this.openSettings = false});

  final String message;

  /// A permissão foi negada de vez: só pelos ajustes do aparelho.
  final bool openSettings;
}

/// Localização aproximada, pedida só quando o usuário toca em "Usar minha
/// localização". Usada apenas na busca em andamento; não é armazenada.
class DeviceLocation {
  const DeviceLocation();

  Future<LocationResult> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationUnavailable('A localização do aparelho está desligada. Ative-a ou busque pela cidade.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      switch (permission) {
        case LocationPermission.denied:
        case LocationPermission.unableToDetermine:
          return const LocationUnavailable('Sem permissão de localização. Você pode buscar pela cidade ou pelo CEP.');
        case LocationPermission.deniedForever:
          return const LocationUnavailable(
            'A permissão de localização foi negada. Para usar, libere nos ajustes do aparelho.',
            openSettings: true,
          );
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          break;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 15)),
      );
      return LocationFound(position.latitude, position.longitude);
    } on Exception {
      return const LocationUnavailable('Não foi possível obter a localização agora. Busque pela cidade ou pelo CEP.');
    }
  }

  Future<void> openSettings() => Geolocator.openAppSettings();
}

final deviceLocationProvider = Provider<DeviceLocation>((ref) => const DeviceLocation());
