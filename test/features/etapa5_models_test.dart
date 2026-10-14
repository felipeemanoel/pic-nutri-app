import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/help/data/help_repository.dart';
import 'package:picnutri/features/onboarding/presentation/onboarding_page.dart';
import 'package:picnutri/features/professionals/data/professional_models.dart';
import 'package:picnutri/features/symptoms/data/symptom_models.dart';

void main() {
  group('Jornada inicial', () {
    test('mostra só as perguntas que fazem sentido para as escolhas', () {
      final minimal = OnboardingSteps.sequence(consent: false, support: {});
      expect(minimal, [
        OnboardingSteps.welcome,
        OnboardingSteps.consent,
        OnboardingSteps.goals,
        OnboardingSteps.support,
        OnboardingSteps.summary,
      ]);

      final full = OnboardingSteps.sequence(
        consent: true,
        support: {'has_professional_plan', 'prescribed_medication', 'find_professional'},
      );
      expect(full, containsAllInOrder([
        OnboardingSteps.essentials,
        OnboardingSteps.routine,
        OnboardingSteps.guidance,
        OnboardingSteps.medication,
        OnboardingSteps.care,
        OnboardingSteps.targets,
        OnboardingSteps.summary,
      ]));
    });

    test('sem autorização de dados de saúde, nada de medicamento ou dados corporais', () {
      final seq = OnboardingSteps.sequence(consent: false, support: {'prescribed_medication', 'find_professional'});
      expect(seq, isNot(contains(OnboardingSteps.medication)));
      expect(seq, isNot(contains(OnboardingSteps.essentials)));
      expect(seq, contains(OnboardingSteps.care));
    });

    test('etapas obrigatórias não podem ser puladas', () {
      expect(OnboardingSteps.skippable(OnboardingSteps.goals), isFalse);
      expect(OnboardingSteps.skippable(OnboardingSteps.summary), isFalse);
      expect(OnboardingSteps.skippable(OnboardingSteps.routine), isTrue);
    });
  });

  group('Sintomas', () {
    test('lê item da linha do tempo com fatos próximos, sem causa', () {
      final item = SymptomItem.fromJson({
        'id': '01J',
        'source': 'medication_dose',
        'label': 'Náusea',
        'intensity': 2,
        'intensity_label': 'moderada',
        'occurred_at': '2026-10-20T12:00:00Z',
        'nearby': ['Registrado 3 h após o registro de Remédio X.'],
      });
      expect(item.editable, isFalse);
      expect(item.nearby.single, contains('após'));
    });

    test('alerta de segurança urgente', () {
      final alert = SafetyAlert.fromJson({'level': 'urgent', 'title': 'Procure atendimento', 'message': '...', 'article': 'sinais-de-alerta'});
      expect(alert.urgent, isTrue);
      expect(alert.article, 'sinais-de-alerta');
    });
  });

  test('artigo de saúde não revisado é identificado', () {
    final article = HelpArticle.fromJson({
      'slug': 'sinais-de-alerta',
      'category': 'health',
      'title': 'Sinais de alerta',
      'kind': 'health',
      'review': {'reviewed': false},
    });
    expect(article.isHealth, isTrue);
    expect(article.reviewed, isFalse);
  });

  group('Profissionais', () {
    test('lê o perfil público sem campos inventados', () {
      final p = Professional.fromJson({
        'id': '01JPROF0000000000000000000',
        'category': 'nutritionist',
        'category_label': 'Nutricionista',
        'name': 'Ana',
        'council': {'label': 'CRN-6 12345', 'verified_at': '2026-10-20'},
        'specialties': [
          {'value': 'sports', 'label': 'Nutrição esportiva'},
        ],
        'modalities': ['online', 'in_person'],
        'city': 'Recife',
        'state': 'PE',
        'distance_km': null,
        'price': null,
        'accepts_new_clients': true,
      });
      expect(p.place, 'Recife/PE');
      expect(p.distanceKm, isNull);
      expect(p.priceMin, isNull);
      expect(p.online && p.inPerson, isTrue);
      expect(p.verifiedAt, DateTime(2026, 10, 20));
    });

    test('filtro: CEP substitui cidade e localização é arredondada', () {
      const filter = ProfessionalFilter(
        category: 'nutritionist',
        modality: 'in_person',
        city: 'Recife',
        state: 'pe',
        cep: '50030-230',
        lat: -8.063123,
        lng: -34.871987,
      );
      final q = filter.toQuery();
      expect(q['cep'], '50030230');
      expect(q.containsKey('city'), isFalse);
      expect(q['lat'], -8.063);
      expect(q['lng'], -34.872);
      expect(q['radius_km'], 30);

      final byCity = filter.copyWith(cep: () => null, lat: () => null, lng: () => null).toQuery();
      expect(byCity['city'], 'Recife');
      expect(byCity['state'], 'PE');
      expect(byCity.containsKey('lat'), isFalse);
      expect(const ProfessionalFilter().toQuery(), isEmpty);
    });

    test('autorização de compartilhamento expirada ou revogada', () {
      final revoked = ShareGrant.fromJson({
        'id': '01JG',
        'professional': {'id': 'p', 'name': 'Ana'},
        'categories': [
          {'value': 'symptoms', 'label': 'Sintomas'},
        ],
        'purpose': 'Avaliação',
        'expires_at': '2026-11-20T00:00:00Z',
        'revoked_at': '2026-10-21T00:00:00Z',
        'active': false,
        'accesses': 2,
        'last_access_at': '2026-10-20T15:00:00Z',
      });
      expect(revoked.statusLabel, 'Revogado');
      expect(revoked.accesses, 2);

      final request = ContactRequestItem.fromJson({
        'id': '01JC',
        'professional': {'id': 'p', 'name': 'Ana', 'category_label': 'Nutricionista'},
        'modality': 'online',
        'status': 'pending',
        'status_label': 'Aguardando resposta',
        'created_at': '2026-10-20T15:00:00Z',
        'grant': null,
      });
      expect(request.pending, isTrue);
      expect(request.grant, isNull);
    });

    test('pedido de compartilhamento leva o consentimento explícito', () {
      const share = ShareRequest(categories: ['weight_progress'], purpose: 'Primeira consulta', days: 30);
      expect(share.toJson(), {'categories': ['weight_progress'], 'purpose': 'Primeira consulta', 'days': 30, 'consent': true});
    });
  });
}
