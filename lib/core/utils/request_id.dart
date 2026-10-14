import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Identificador enviado como `client_request_id` em toda criação.
///
/// Gere um por ação do usuário e reutilize-o em novas tentativas da mesma
/// ação: a API devolve o registro já criado em vez de duplicá-lo.
String newRequestId() => _uuid.v4();
