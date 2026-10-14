import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/health_repository.dart';
import '../data/system_health.dart';

/// Estado da API; atualizado com `ref.invalidate(systemHealthProvider)`.
final systemHealthProvider = FutureProvider<SystemHealth>(
  (ref) => ref.watch(healthRepositoryProvider).fetch(),
);
