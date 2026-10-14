/// Opção simples (valor + rótulo) vinda da API.
class ValueLabel {
  const ValueLabel(this.value, this.label);

  factory ValueLabel.fromJson(Map<String, dynamic> json) =>
      ValueLabel(json['value'] as String, json['label'] as String? ?? json['value'] as String);

  final String value;
  final String label;
}

List<ValueLabel> _options(Object? raw) =>
    (raw as List<dynamic>? ?? const []).cast<Map<String, dynamic>>().map(ValueLabel.fromJson).toList();

class ProfessionalCategoryOption {
  const ProfessionalCategoryOption({required this.value, required this.label, required this.specialties});

  factory ProfessionalCategoryOption.fromJson(Map<String, dynamic> json) => ProfessionalCategoryOption(
    value: json['value'] as String,
    label: json['label'] as String,
    specialties: _options(json['specialties']),
  );

  final String value;
  final String label;
  final List<ValueLabel> specialties;
}

/// Opções de busca e de compartilhamento.
class ProfessionalsMeta {
  const ProfessionalsMeta({required this.categories, required this.shareCategories, required this.cepLookup});

  factory ProfessionalsMeta.fromJson(Map<String, dynamic> json) => ProfessionalsMeta(
    categories: (json['categories'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ProfessionalCategoryOption.fromJson)
        .toList(),
    shareCategories: _options(json['share_categories']),
    cepLookup: json['cep_lookup'] as bool? ?? false,
  );

  final List<ProfessionalCategoryOption> categories;
  final List<ValueLabel> shareCategories;
  final bool cepLookup;

  List<ValueLabel> specialtiesOf(String? category) =>
      categories.where((c) => c.value == category).expand((c) => c.specialties).toList();
}

/// Profissional aprovado. Só dados cadastrados e conferidos pela equipe:
/// sem avaliações, disponibilidade ou distâncias estimadas.
class Professional {
  const Professional({
    required this.id,
    required this.category,
    required this.categoryLabel,
    required this.name,
    required this.councilLabel,
    required this.modalities,
    required this.acceptsNewClients,
    this.verifiedAt,
    this.specialties = const [],
    this.city,
    this.state,
    this.neighborhood,
    this.distanceKm,
    this.priceMin,
    this.priceMax,
    this.availabilityNotes,
    this.bio,
    this.match,
    this.hasPendingRequest = false,
  });

  factory Professional.fromJson(Map<String, dynamic> json) {
    final council = json['council'] as Map<String, dynamic>? ?? const {};
    final price = json['price'] as Map<String, dynamic>?;
    return Professional(
      id: json['id'] as String,
      category: json['category'] as String,
      categoryLabel: json['category_label'] as String? ?? '',
      name: json['name'] as String,
      councilLabel: council['label'] as String? ?? '',
      verifiedAt: DateTime.tryParse(council['verified_at'] as String? ?? ''),
      specialties: _options(json['specialties']),
      modalities: (json['modalities'] as List<dynamic>? ?? const []).cast<String>(),
      city: json['city'] as String?,
      state: json['state'] as String?,
      neighborhood: json['neighborhood'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      priceMin: (price?['min'] as num?)?.toDouble(),
      priceMax: (price?['max'] as num?)?.toDouble(),
      acceptsNewClients: json['accepts_new_clients'] as bool? ?? false,
      availabilityNotes: json['availability_notes'] as String?,
      bio: json['bio'] as String?,
      match: json['match'] as String?,
      hasPendingRequest: json['has_pending_request'] as bool? ?? false,
    );
  }

  final String id;
  final String category;
  final String categoryLabel;
  final String name;

  /// Ex.: "CRN-6 12345". Conferido pela equipe em [verifiedAt].
  final String councilLabel;
  final DateTime? verifiedAt;
  final List<ValueLabel> specialties;

  /// online e/ou in_person.
  final List<String> modalities;
  final String? city;
  final String? state;
  final String? neighborhood;

  /// Só quando o usuário compartilhou a localização e o endereço do
  /// profissional tem coordenadas conferidas.
  final double? distanceKm;
  final double? priceMin;
  final double? priceMax;
  final bool acceptsNewClients;
  final String? availabilityNotes;
  final String? bio;

  /// Como apareceu na busca: online ou in_person.
  final String? match;
  final bool hasPendingRequest;

  bool get online => modalities.contains('online');
  bool get inPerson => modalities.contains('in_person');

  String get place => [city, state].whereType<String>().where((s) => s.isNotEmpty).join('/');
}

class ProfessionalSearchResult {
  const ProfessionalSearchResult({
    required this.items,
    required this.inPersonCount,
    required this.onlineCount,
    required this.distanceAvailable,
    required this.suggestOnline,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    this.placeCity,
    this.placeState,
  });

  factory ProfessionalSearchResult.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    final place = meta['place'] as Map<String, dynamic>?;
    return ProfessionalSearchResult(
      items: (json['data'] as List<dynamic>).cast<Map<String, dynamic>>().map(Professional.fromJson).toList(),
      inPersonCount: (meta['in_person_count'] as num?)?.toInt() ?? 0,
      onlineCount: (meta['online_count'] as num?)?.toInt() ?? 0,
      distanceAvailable: meta['distance_available'] as bool? ?? false,
      suggestOnline: meta['suggest_online'] as bool? ?? false,
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? 0,
      placeCity: place?['city'] as String?,
      placeState: place?['state'] as String?,
    );
  }

  final List<Professional> items;
  final int inPersonCount;
  final int onlineCount;
  final bool distanceAvailable;
  final bool suggestOnline;
  final int currentPage;
  final int lastPage;
  final int total;

  /// Cidade/UF usada na busca (por exemplo, resolvida a partir do CEP).
  final String? placeCity;
  final String? placeState;
}

/// Filtros da busca. A localização do aparelho só é usada na busca em
/// andamento: não é salva no perfil nem no servidor.
class ProfessionalFilter {
  const ProfessionalFilter({
    this.category,
    this.modality = 'any',
    this.city,
    this.state,
    this.cep,
    this.lat,
    this.lng,
    this.radiusKm = 30,
    this.specialty,
    this.acceptingOnly = false,
    this.page = 1,
  });

  final String? category;

  /// online, in_person ou any.
  final String modality;
  final String? city;
  final String? state;
  final String? cep;
  final double? lat;
  final double? lng;
  final double radiusKm;
  final String? specialty;
  final bool acceptingOnly;
  final int page;

  bool get usesLocation => lat != null && lng != null;

  ProfessionalFilter copyWith({
    String? Function()? category,
    String? modality,
    String? Function()? city,
    String? Function()? state,
    String? Function()? cep,
    double? Function()? lat,
    double? Function()? lng,
    double? radiusKm,
    String? Function()? specialty,
    bool? acceptingOnly,
    int? page,
  }) => ProfessionalFilter(
    category: category != null ? category() : this.category,
    modality: modality ?? this.modality,
    city: city != null ? city() : this.city,
    state: state != null ? state() : this.state,
    cep: cep != null ? cep() : this.cep,
    lat: lat != null ? lat() : this.lat,
    lng: lng != null ? lng() : this.lng,
    radiusKm: radiusKm ?? this.radiusKm,
    specialty: specialty != null ? specialty() : this.specialty,
    acceptingOnly: acceptingOnly ?? this.acceptingOnly,
    page: page ?? this.page,
  );

  /// Parâmetros da API. A localização é arredondada (~100 m) antes do envio.
  Map<String, dynamic> toQuery() {
    String? clean(String? v) => v == null || v.trim().isEmpty ? null : v.trim();
    final cepDigits = cep?.replaceAll(RegExp(r'\D'), '');
    return {
      'category': ?category,
      if (modality != 'any') 'modality': modality,
      if (cepDigits != null && cepDigits.isNotEmpty) 'cep': cepDigits,
      if (cepDigits == null || cepDigits.isEmpty) ...{
        'city': ?clean(city),
        'state': ?clean(state)?.toUpperCase(),
      },
      if (usesLocation) ...{
        'lat': double.parse(lat!.toStringAsFixed(3)),
        'lng': double.parse(lng!.toStringAsFixed(3)),
        'radius_km': radiusKm,
      },
      'specialty': ?specialty,
      if (acceptingOnly) 'accepting_only': 1,
      if (page > 1) 'page': page,
    };
  }
}

class ShareGrant {
  const ShareGrant({
    required this.id,
    required this.categories,
    required this.purpose,
    required this.expiresAt,
    required this.active,
    required this.accesses,
    this.professionalId,
    this.professionalName,
    this.revokedAt,
    this.lastAccessAt,
  });

  factory ShareGrant.fromJson(Map<String, dynamic> json) {
    final pro = json['professional'] as Map<String, dynamic>?;
    return ShareGrant(
      id: json['id'] as String,
      professionalId: pro?['id'] as String?,
      professionalName: pro?['name'] as String?,
      categories: _options(json['categories']),
      purpose: json['purpose'] as String? ?? '',
      expiresAt: DateTime.parse(json['expires_at'] as String),
      revokedAt: DateTime.tryParse(json['revoked_at'] as String? ?? ''),
      active: json['active'] as bool? ?? false,
      accesses: (json['accesses'] as num?)?.toInt() ?? 0,
      lastAccessAt: DateTime.tryParse(json['last_access_at'] as String? ?? ''),
    );
  }

  final String id;
  final String? professionalId;
  final String? professionalName;
  final List<ValueLabel> categories;
  final String purpose;
  final DateTime expiresAt;
  final DateTime? revokedAt;
  final bool active;

  /// Quantas vezes o profissional consultou os dados.
  final int accesses;
  final DateTime? lastAccessAt;

  String get statusLabel => active
      ? 'Ativo'
      : revokedAt != null
      ? 'Revogado'
      : 'Expirado';
}

class ContactRequestItem {
  const ContactRequestItem({
    required this.id,
    required this.professionalId,
    required this.professionalName,
    required this.professionalCategory,
    required this.modality,
    required this.status,
    required this.statusLabel,
    required this.createdAt,
    this.message,
    this.reply,
    this.respondedAt,
    this.grant,
  });

  factory ContactRequestItem.fromJson(Map<String, dynamic> json) {
    final pro = json['professional'] as Map<String, dynamic>? ?? const {};
    final grant = json['grant'];
    return ContactRequestItem(
      id: json['id'] as String,
      professionalId: pro['id'] as String? ?? '',
      professionalName: pro['name'] as String? ?? '',
      professionalCategory: pro['category_label'] as String? ?? '',
      modality: json['modality'] as String,
      message: json['message'] as String?,
      status: json['status'] as String,
      statusLabel: json['status_label'] as String? ?? json['status'] as String,
      reply: json['reply'] as String?,
      respondedAt: DateTime.tryParse(json['responded_at'] as String? ?? ''),
      createdAt: DateTime.parse(json['created_at'] as String),
      grant: grant is Map<String, dynamic> ? ShareGrant.fromJson(grant) : null,
    );
  }

  final String id;
  final String professionalId;
  final String professionalName;
  final String professionalCategory;
  final String modality;
  final String? message;

  /// pending, accepted, declined ou canceled.
  final String status;
  final String statusLabel;
  final String? reply;
  final DateTime? respondedAt;
  final DateTime createdAt;
  final ShareGrant? grant;

  bool get pending => status == 'pending';
}

/// Autorização de compartilhamento escolhida pelo usuário no pedido de contato.
class ShareRequest {
  const ShareRequest({required this.categories, required this.purpose, required this.days});

  final List<String> categories;
  final String purpose;

  /// 7, 30 ou 90.
  final int days;

  Map<String, dynamic> toJson() => {'categories': categories, 'purpose': purpose, 'days': days, 'consent': true};
}
