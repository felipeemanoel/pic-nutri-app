import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/help/data/help_repository.dart';
import 'package:picnutri/features/onboarding/presentation/onboarding_page.dart';
import 'package:picnutri/features/professionals/data/professional_models.dart';
import 'package:picnutri/features/symptoms/data/symptom_models.dart';

void main() {
  group('Jornada inicial', () {
    test('sem autorização: só objetivo e forma de acompanhamento', () {
      final minimal = OnboardingFlow.screens(consent: false, support: {});
      expect(minimal, [
        OnboardingScreen.welcome,
        OnboardingScreen.consent,
        OnboardingScreen.goal,
        OnboardingScreen.support,
        OnboardingScreen.features,
        OnboardingScreen.summary,
      ]);
    });

    test('com autorização: uma pergunta por tela, meta logo após os dados', () {
      final full = OnboardingFlow.screens(
        consent: true,
        support: {'has_professional_plan', 'prescribed_medication'},
        goal: 'lose_weight',
        treatmentStage: 'using',
        hasWeight: true,
        hasGoalWeight: true,
        paceApplies: true,
        medicalFeatures: true,
      );
      expect(full, [
        OnboardingScreen.welcome,
        OnboardingScreen.goal,
        OnboardingScreen.motivations,
        OnboardingScreen.support,
        OnboardingScreen.treatmentStage,
        OnboardingScreen.medicationName,
        OnboardingScreen.medicationFrequency,
        OnboardingScreen.medicationDose,
        OnboardingScreen.treatmentStart,
        OnboardingScreen.challenge,
        OnboardingScreen.birthDate,
        OnboardingScreen.sex,
        OnboardingScreen.height,
        OnboardingScreen.weight,
        OnboardingScreen.startWeight,
        OnboardingScreen.goalWeight,
        OnboardingScreen.pace,
        OnboardingScreen.activity,
        OnboardingScreen.projection,
        OnboardingScreen.targets,
        OnboardingScreen.guidance,
        OnboardingScreen.features,
        OnboardingScreen.summary,
      ]);
      // As telas se agrupam nas etapas salvas pela API, sempre em ordem.
      final steps = [for (final s in full) s.step];
      final distinct = <String>[];
      for (final step in steps) {
        if (distinct.isEmpty || distinct.last != step) distinct.add(step);
      }
      expect(distinct.toSet().length, distinct.length);
    });

    test('sem meta de peso nem medicamento, pula régua de meta e ritmo', () {
      final seq = OnboardingFlow.screens(
        consent: true,
        support: {'organize_eating'},
        goal: 'improve_habits',
        hasWeight: true,
        medicalFeatures: true,
      );
      expect(seq, isNot(contains(OnboardingScreen.goalWeight)));
      expect(seq, isNot(contains(OnboardingScreen.pace)));
      expect(seq, isNot(contains(OnboardingScreen.projection)));
      expect(seq, isNot(contains(OnboardingScreen.treatmentStage)));
    });

    test(
      'quem ainda não começou o tratamento não informa data nem peso inicial',
      () {
        final seq = OnboardingFlow.screens(
          consent: true,
          support: {'prescribed_medication'},
          goal: 'medication_support',
          treatmentStage: 'not_started',
          hasWeight: true,
          medicalFeatures: true,
        );
        expect(seq, contains(OnboardingScreen.medicationDose));
        expect(seq, isNot(contains(OnboardingScreen.treatmentStart)));
        expect(seq, isNot(contains(OnboardingScreen.startWeight)));
      },
    );

    test('sem os recursos médicos, nada de medicamento', () {
      final seq = OnboardingFlow.screens(
        consent: true,
        support: {'prescribed_medication'},
        medicalFeatures: false,
      );
      expect(seq, isNot(contains(OnboardingScreen.treatmentStage)));
    });

    test('quem parou numa etapa que saiu do fluxo retoma na seguinte', () {
      expect(
        OnboardingSteps.resumeAt(OnboardingSteps.routine),
        OnboardingSteps.targets,
      );
      expect(
        OnboardingSteps.resumeAt(OnboardingSteps.care),
        OnboardingSteps.summary,
      );
      expect(
        OnboardingSteps.resumeAt(OnboardingSteps.goals),
        OnboardingSteps.goals,
      );
      expect(OnboardingSteps.resumeAt(null), isNull);
      expect(OnboardingSteps.deferred(consent: true), [
        OnboardingSteps.routine,
      ]);
      expect(OnboardingSteps.deferred(consent: false), isEmpty);
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
      final alert = SafetyAlert.fromJson({
        'level': 'urgent',
        'title': 'Procure atendimento',
        'message': '...',
        'article': 'sinais-de-alerta',
      });
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

      final byCity = filter
          .copyWith(cep: () => null, lat: () => null, lng: () => null)
          .toQuery();
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
        'professional': {
          'id': 'p',
          'name': 'Ana',
          'category_label': 'Nutricionista',
        },
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
      const share = ShareRequest(
        categories: ['weight_progress'],
        purpose: 'Primeira consulta',
        days: 30,
      );
      expect(share.toJson(), {
        'categories': ['weight_progress'],
        'purpose': 'Primeira consulta',
        'days': 30,
        'consent': true,
      });
    });
  });
}
