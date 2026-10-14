import 'package:dio/dio.dart';

/// Executa uma chamada à API convertendo erros do Dio em [AppFailure].
Future<T> guard<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (error) {
    throw AppFailure.fromDioException(error);
  }
}

/// Falha tratada e pronta para a interface.
///
/// Toda exceção de rede ou da API é convertida aqui, em um único lugar.
/// [message] é sempre segura para exibir ao usuário; [code] e [traceId]
/// vêm do formato padrão de erro do backend e ajudam no suporte.
sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.code, this.traceId});

  /// Converte um erro do Dio no tipo de falha correspondente.
  factory AppFailure.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const TimeoutFailure();
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badCertificate:
        return const NetworkFailure(
          'Não foi possível estabelecer uma conexão segura.',
        );
      case DioExceptionType.cancel:
        return const CancelledFailure();
      case DioExceptionType.badResponse:
        return _fromResponse(error.response);
      case DioExceptionType.unknown:
        return const UnknownFailure();
    }
  }

  final String message;
  final String? code;
  final String? traceId;

  /// Códigos cuja mensagem da API é exibida mesmo fora do 4xx genérico.
  static const _domainCodes = {
    'account_blocked',
    'social_login_unavailable',
    'social_token_invalid',
    'social_email_required',
    'store_billing_unavailable',
    'store_purchase_invalid',
    'store_purchase_in_use',
    'store_product_unknown',
    'plan_already_active',
    'health_consent_required',
    'medication_tracking_disabled',
    'quota_exceeded',
    'ai_unavailable',
    'ai_provider_error',
    'ai_capacity_reached',
    'professional_not_accepting',
    'contact_request_pending',
    'too_many_pending_requests',
    'cep_invalid',
    'cep_not_found',
    'cep_lookup_unavailable',
    'photo_limit_reached',
  };

  static AppFailure _fromResponse(Response<dynamic>? response) {
    final body = _ApiError.tryParse(response?.data);
    final status = response?.statusCode ?? 0;

    // Erros de regra com mensagem própria, mesmo em 403/429/5xx.
    if (body != null &&
        body.message != null &&
        _domainCodes.contains(body.code)) {
      return BusinessFailure(
        body.message!,
        code: body.code,
        traceId: body.traceId,
      );
    }

    return switch (status) {
      401 => UnauthorizedFailure(traceId: body?.traceId),
      403 => ForbiddenFailure(traceId: body?.traceId),
      404 => NotFoundFailure(traceId: body?.traceId),
      422 when body?.code == 'validation_failed' => ValidationFailure(
        body?.message ?? 'Verifique os dados informados.',
        fieldErrors: body?.fieldErrors ?? const {},
        traceId: body?.traceId,
      ),
      429 => RateLimitedFailure(traceId: body?.traceId),
      >= 500 => ServerFailure(code: body?.code, traceId: body?.traceId),
      _ => BusinessFailure(
        body?.message ?? 'Não foi possível concluir a operação.',
        code: body?.code,
        traceId: body?.traceId,
      ),
    };
  }

  @override
  String toString() => '$runtimeType(code: $code, traceId: $traceId)';
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([
    super.message = 'Sem conexão. Verifique sua internet e tente novamente.',
  ]);
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure()
    : super('O servidor demorou a responder. Tente novamente.');
}

final class CancelledFailure extends AppFailure {
  const CancelledFailure() : super('Operação cancelada.');
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure({super.traceId})
    : super('Sua sessão expirou. Entre novamente.', code: 'unauthenticated');
}

final class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure({super.traceId})
    : super('Você não tem permissão para esta ação.', code: 'forbidden');
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({super.traceId})
    : super('Conteúdo não encontrado.', code: 'not_found');
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(
    super.message, {
    this.fieldErrors = const {},
    super.traceId,
  }) : super(code: 'validation_failed');

  /// Erros por campo, como enviados pela API (`error.errors`).
  final Map<String, List<String>> fieldErrors;
}

final class RateLimitedFailure extends AppFailure {
  const RateLimitedFailure({super.traceId})
    : super(
        'Muitas tentativas em pouco tempo. Aguarde um instante.',
        code: 'too_many_requests',
      );
}

final class ServerFailure extends AppFailure {
  const ServerFailure({super.code, super.traceId})
    : super('Erro no servidor. Tente novamente mais tarde.');
}

/// Erro de regra de negócio com código estável vindo da API.
final class BusinessFailure extends AppFailure {
  const BusinessFailure(super.message, {super.code, super.traceId});
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure() : super('Algo deu errado. Tente novamente.');
}

/// Leitura defensiva do formato padrão de erro da API:
/// `{"error": {"code", "message", "errors", "trace_id"}}`.
class _ApiError {
  const _ApiError({this.code, this.message, this.traceId, this.fieldErrors});

  final String? code;
  final String? message;
  final String? traceId;
  final Map<String, List<String>>? fieldErrors;

  static _ApiError? tryParse(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    final error = data['error'];
    if (error is! Map<String, dynamic>) return null;

    Map<String, List<String>>? fieldErrors;
    final errors = error['errors'];
    if (errors is Map<String, dynamic>) {
      fieldErrors = {
        for (final entry in errors.entries)
          if (entry.value is List<dynamic>)
            entry.key: (entry.value as List<dynamic>)
                .whereType<String>()
                .toList(),
      };
    }

    return _ApiError(
      code: error['code'] is String ? error['code'] as String : null,
      message: error['message'] is String ? error['message'] as String : null,
      traceId: error['trace_id'] is String ? error['trace_id'] as String : null,
      fieldErrors: fieldErrors,
    );
  }
}
