import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/core/error/app_failure.dart';

DioException _badResponse(int status, Object? data) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: data,
    ),
  );
}

void main() {
  group('AppFailure.fromDioException', () {
    test('mapeia validação com erros por campo e trace id', () {
      final failure = AppFailure.fromDioException(
        _badResponse(422, {
          'error': {
            'code': 'validation_failed',
            'message': 'Os dados enviados são inválidos.',
            'errors': {
              'name': ['Obrigatório.'],
            },
            'trace_id': '01JTRACE',
          },
        }),
      );

      expect(failure, isA<ValidationFailure>());
      final validation = failure as ValidationFailure;
      expect(validation.fieldErrors['name'], ['Obrigatório.']);
      expect(validation.traceId, '01JTRACE');
    });

    test('mapeia erro de negócio com código estável', () {
      final failure = AppFailure.fromDioException(
        _badResponse(409, {
          'error': {'code': 'quota_exceeded', 'message': 'Cota atingida.'},
        }),
      );

      expect(failure, isA<BusinessFailure>());
      expect(failure.code, 'quota_exceeded');
      expect(failure.message, 'Cota atingida.');
    });

    test('mapeia status conhecidos', () {
      expect(
        AppFailure.fromDioException(_badResponse(401, null)),
        isA<UnauthorizedFailure>(),
      );
      expect(
        AppFailure.fromDioException(_badResponse(403, null)),
        isA<ForbiddenFailure>(),
      );
      expect(
        AppFailure.fromDioException(_badResponse(404, null)),
        isA<NotFoundFailure>(),
      );
      expect(
        AppFailure.fromDioException(_badResponse(429, null)),
        isA<RateLimitedFailure>(),
      );
      expect(
        AppFailure.fromDioException(_badResponse(500, 'html')),
        isA<ServerFailure>(),
      );
    });

    test('mapeia falhas de rede e tempo esgotado', () {
      final options = RequestOptions(path: '/x');
      expect(
        AppFailure.fromDioException(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ),
        ),
        isA<NetworkFailure>(),
      );
      expect(
        AppFailure.fromDioException(
          DioException(
            requestOptions: options,
            type: DioExceptionType.receiveTimeout,
          ),
        ),
        isA<TimeoutFailure>(),
      );
    });

    test('mantém a mensagem de regras conhecidas fora do 4xx genérico', () {
      for (final (status, code) in [
        (429, 'quota_exceeded'),
        (503, 'ai_unavailable'),
        (403, 'health_consent_required'),
      ]) {
        final failure = AppFailure.fromDioException(
          _badResponse(status, {
            'error': {'code': code, 'message': 'Mensagem de $code'},
          }),
        );
        expect(failure, isA<BusinessFailure>());
        expect(failure.code, code);
        expect(failure.message, 'Mensagem de $code');
      }
    });

    test('nunca expõe a mensagem crua do servidor em erro 500', () {
      final failure = AppFailure.fromDioException(
        _badResponse(500, {
          'error': {
            'code': 'server_error',
            'message': 'SQLSTATE[HY000] detalhe interno',
          },
        }),
      );

      expect(failure.message, isNot(contains('SQLSTATE')));
    });
  });
}
