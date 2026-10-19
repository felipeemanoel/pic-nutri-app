/// Credencial já obtida do provedor, no formato enviado à API.
class SocialCredentialData {
  const SocialCredentialData(this.provider, this.body);

  final String provider;
  final Map<String, dynamic> body;
}

/// Acesso de um provedor vinculado à conta.
class LinkedProvider {
  const LinkedProvider({
    required this.provider,
    required this.linkedAt,
    this.email,
    this.privateEmail = false,
    this.name,
  });

  factory LinkedProvider.fromJson(Map<String, dynamic> json) => LinkedProvider(
    provider: json['provider'] as String,
    email: json['email'] as String?,
    privateEmail: json['private_email'] as bool? ?? false,
    name: json['name'] as String?,
    linkedAt: DateTime.parse(json['linked_at'] as String).toLocal(),
  );

  final String provider;
  final String? email;

  /// Apple: e-mail de retransmissão privada.
  final bool privateEmail;
  final String? name;
  final DateTime linkedAt;
}

/// Meios de acesso da conta.
class SignInMethods {
  const SignInMethods({
    required this.hasPassword,
    required this.email,
    required this.providers,
  });

  factory SignInMethods.fromJson(Map<String, dynamic> json) => SignInMethods(
    hasPassword: json['has_password'] as bool? ?? true,
    email: json['email'] as String? ?? '',
    providers: (json['providers'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(LinkedProvider.fromJson)
        .toList(),
  );

  final bool hasPassword;
  final String email;
  final List<LinkedProvider> providers;

  bool isLinked(String provider) =>
      providers.any((p) => p.provider == provider);

  /// Sem senha local, o último provedor não pode ser removido.
  bool canUnlink(String provider) =>
      isLinked(provider) && (hasPassword || providers.length > 1);
}

/// Etapa pendente do login social devolvida pela API (`error.details`).
class SocialFlowStep {
  const SocialFlowStep({
    required this.code,
    required this.pendingToken,
    this.maskedEmail,
    this.methods = const [],
  });

  /// Lê a etapa de uma falha da API; `null` se não for uma etapa do fluxo.
  static SocialFlowStep? fromFailure(
    String? code,
    Map<String, dynamic> details,
  ) {
    final token = details['pending_token'];
    if (token is! String || !steps.contains(code)) return null;
    return SocialFlowStep(
      code: code!,
      pendingToken: token,
      maskedEmail: details['email'] as String?,
      methods: (details['methods'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }

  static const steps = {
    'terms_acceptance_required',
    'social_email_required',
    'account_link_required',
  };

  final String code;
  final String pendingToken;
  final String? maskedEmail;

  /// Formas de comprovar a conta existente: `password`, `email_code`.
  final List<String> methods;
}
