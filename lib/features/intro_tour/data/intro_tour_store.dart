import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../auth/data/account.dart';
import '../../auth/data/auth_repository.dart';

/// Recibo local por conta: uma falha na API não deve prender nem repetir o guia.
/// O email é usado apenas para derivar a chave; não é armazenado em texto.
class IntroTourStore {
  IntroTourStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  final Map<String, String> _session = {};
  final Set<String> _syncing = {};

  String _key(String email) =>
      'picnutri.intro_tour.v1.${sha256.convert(utf8.encode(email.trim().toLowerCase()))}';

  Future<String?> readStatus(String email) async {
    final key = _key(email);
    if (_session.containsKey(key)) return _session[key];
    try {
      final status = await _storage.read(key: key);
      if (status == 'completed' || status == 'skipped') {
        _session[key] = status!;
        return status;
      }
    } on PlatformException {
      // O recibo da sessão continua válido se o armazenamento estiver indisponível.
    } on MissingPluginException {
      // Testes sem armazenamento nativo.
    }
    return null;
  }

  Future<void> writeStatus(String email, String status) async {
    if (status != 'completed' && status != 'skipped') {
      throw ArgumentError.value(status, 'status');
    }
    final key = _key(email);
    _session[key] = status;
    try {
      await _storage.write(key: key, value: status);
    } on PlatformException {
      // A sincronização com a conta ainda será tentada.
    } on MissingPluginException {
      // Idem em testes sem armazenamento nativo.
    }
  }

  /// Reenvia o recibo se a API ainda anunciar o guia como pendente.
  /// Não substitui o estado da sessão por uma resposta que pode chegar após logout.
  Future<void> sync(String email, AuthRepository repository) async {
    if (!_syncing.add(_key(email))) return;
    try {
      final status = await readStatus(email);
      if (status != null) await repository.introTour(status);
    } on Object {
      // Mantém o recibo para tentar novamente na próxima entrada no app.
    } finally {
      _syncing.remove(_key(email));
    }
  }

  Future<bool> shouldShow(Account account) async =>
      account.introTourPending && await readStatus(account.email) == null;
}

final introTourStoreProvider = Provider<IntroTourStore>(
  (ref) => IntroTourStore(),
);
