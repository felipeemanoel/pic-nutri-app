import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../auth/application/session_controller.dart';
import 'professional_models.dart';

class ProfessionalRepository {
  const ProfessionalRepository(this._dio);

  final Dio _dio;

  Future<ProfessionalsMeta> meta() async {
    final r = await guard(() => _dio.get<Map<String, dynamic>>('professionals/meta'));
    return ProfessionalsMeta.fromJson(r.data!['data'] as Map<String, dynamic>);
  }

  Future<ProfessionalSearchResult> search(ProfessionalFilter filter) async {
    final r = await guard(
      () => _dio.get<Map<String, dynamic>>('professionals', queryParameters: filter.toQuery()),
    );
    return ProfessionalSearchResult.fromJson(r.data!);
  }

  Future<Professional> show(String id) async {
    final r = await guard(() => _dio.get<Map<String, dynamic>>('professionals/$id'));
    return Professional.fromJson(r.data!['data'] as Map<String, dynamic>);
  }

  /// Registra a solicitação. Nome e e-mail só seguem com o aceite
  /// ([shareContact]); dados de saúde só com [share].
  Future<ContactRequestItem> requestContact(
    String professionalId, {
    required String modality,
    required String requestId,
    String? message,
    String? phone,
    ShareRequest? share,
  }) async {
    final r = await guard(
      () => _dio.post<Map<String, dynamic>>(
        'professionals/$professionalId/contact-requests',
        data: {
          'modality': modality,
          'message': ?message,
          'contact_phone': ?phone,
          'share_contact': true,
          'share': ?share?.toJson(),
          'client_request_id': requestId,
        },
      ),
    );
    return ContactRequestItem.fromJson(r.data!['data'] as Map<String, dynamic>);
  }

  Future<List<ContactRequestItem>> myRequests() async {
    final r = await guard(() => _dio.get<Map<String, dynamic>>('contact-requests'));
    return (r.data!['data'] as List<dynamic>).cast<Map<String, dynamic>>().map(ContactRequestItem.fromJson).toList();
  }

  Future<void> cancelRequest(String id) => guard(() => _dio.delete<void>('contact-requests/$id'));

  Future<List<ShareGrant>> grants() async {
    final r = await guard(() => _dio.get<Map<String, dynamic>>('share-grants'));
    return (r.data!['data'] as List<dynamic>).cast<Map<String, dynamic>>().map(ShareGrant.fromJson).toList();
  }

  Future<void> revokeGrant(String id) => guard(() => _dio.delete<void>('share-grants/$id'));
}

final professionalRepositoryProvider = Provider<ProfessionalRepository>(
  (ref) => ProfessionalRepository(ref.watch(dioProvider)),
);

final professionalsMetaProvider = FutureProvider<ProfessionalsMeta>(
  (ref) => ref.watch(professionalRepositoryProvider).meta(),
);

/// Filtros da busca; começam pelas preferências informadas no cadastro.
final professionalFilterProvider = NotifierProvider<ProfessionalFilterController, ProfessionalFilter>(
  ProfessionalFilterController.new,
);

class ProfessionalFilterController extends Notifier<ProfessionalFilter> {
  @override
  ProfessionalFilter build() {
    final profile = ref.read(currentAccountProvider)?.profile;
    final categories = profile?.careCategories ?? const <String>[];
    return ProfessionalFilter(
      category: categories.length == 1 ? categories.first : null,
      modality: switch (profile?.careModality) {
        final m? when m == 'online' || m == 'in_person' => m,
        _ => 'any',
      },
      city: profile?.careCity,
      state: profile?.careState,
    );
  }

  void set(ProfessionalFilter filter) => state = filter;
}

final professionalSearchProvider = FutureProvider<ProfessionalSearchResult>(
  (ref) => ref.watch(professionalRepositoryProvider).search(ref.watch(professionalFilterProvider)),
);

final professionalProvider = FutureProvider.family<Professional, String>(
  (ref, id) => ref.watch(professionalRepositoryProvider).show(id),
);

final contactRequestsProvider = FutureProvider<List<ContactRequestItem>>(
  (ref) => ref.watch(professionalRepositoryProvider).myRequests(),
);

final shareGrantsProvider = FutureProvider<List<ShareGrant>>(
  (ref) => ref.watch(professionalRepositoryProvider).grants(),
);
