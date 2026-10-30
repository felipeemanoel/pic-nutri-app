import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/app_update_repository.dart';

/// Plataforma e número do build instalado ("+N" do pubspec). Nulo fora de
/// Android/iOS ou quando não dá para ler (ex.: testes).
typedef InstalledBuild = ({String platform, int build});

final installedBuildProvider = FutureProvider<InstalledBuild?>((ref) async {
  if (kIsWeb) return null;
  final platform = switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    _ => null,
  };
  if (platform == null) return null;
  try {
    final info = await PackageInfo.fromPlatform();
    final build = int.tryParse(info.buildNumber);
    return build == null ? null : (platform: platform, build: build);
  } on Object {
    return null;
  }
});

/// Resultado da última verificação e se o convite opcional foi adiado.
class AppUpdateState {
  const AppUpdateState({this.info, this.dismissed = false});

  final AppUpdateInfo? info;
  final bool dismissed;

  bool get required => info?.status == AppUpdateStatus.required;

  /// Convite opcional visível agora.
  bool get optional => info?.status == AppUpdateStatus.optional && !dismissed;
}

/// Verifica se há atualização ao abrir o app e ao voltar para ele (no
/// máximo a cada [minInterval]). O convite opcional pode ser adiado até a
/// próxima verificação; a atualização obrigatória não pode.
class AppUpdateController extends Notifier<AppUpdateState> {
  static const minInterval = Duration(minutes: 30);

  DateTime? _lastCheck;

  @override
  AppUpdateState build() => const AppUpdateState();

  Future<void> check({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _lastCheck != null &&
        now.difference(_lastCheck!) < minInterval) {
      return;
    }
    _lastCheck = now;
    try {
      final installed = await ref.read(installedBuildProvider.future);
      if (installed == null) return;
      final info = await ref
          .read(appUpdateRepositoryProvider)
          .check(platform: installed.platform, build: installed.build);
      // Nova verificação: o convite opcional volta a aparecer.
      state = AppUpdateState(info: info);
    } on Object {
      // Sem conexão ou servidor fora: o app segue normalmente.
    }
  }

  /// "Agora não": esconde o convite opcional até a próxima verificação.
  void dismiss() => state = AppUpdateState(info: state.info, dismissed: true);
}

final appUpdateProvider = NotifierProvider<AppUpdateController, AppUpdateState>(
  AppUpdateController.new,
);
