import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/progress/data/body_models.dart';

void main() {
  Map<String, dynamic> progressJson({Map<String, dynamic>? trend, List<Map<String, dynamic>> doses = const []}) => {
    'weight': {'series': <dynamic>[], 'change_kg': null, 'previous_period_change_kg': null},
    'goal': null,
    'bmi': {'available': false, 'reason': 'missing_data', 'note': ''},
    'measurements': <dynamic>[],
    'trend': trend,
    'doses': doses,
  };

  test('lê tendência com estimativa e aplicações para o gráfico', () {
    final p = BodyProgress.fromJson(
      progressJson(
        trend: {
          'available': true,
          'weekly_change_kg': -0.5,
          'direction': 'down',
          'fast_change': false,
          'goal_estimate': {'goal_weight_kg': 76, 'date': '2026-12-25', 'weeks': 9},
          'note': 'Estimativa feita só com os seus registros',
        },
        doses: [
          {'date': '2026-10-20', 'taken_at': '2026-10-20T11:00:00Z', 'medication': 'Semaglutida', 'dose': '0,25 mg'},
        ],
      ),
    );
    expect(p.trend.available, isTrue);
    expect(p.trend.weeklyChangeKg, -0.5);
    expect(p.trend.goalWeeks, 9);
    expect(p.trend.goalDate, DateTime(2026, 12, 25));
    expect(p.doses.single.medication, 'Semaglutida');
  });

  test('sem dados suficientes, a tendência traz só a orientação', () {
    final p = BodyProgress.fromJson(
      progressJson(trend: {'available': false, 'reason': 'not_enough_data', 'message': 'Registre o peso'}),
    );
    expect(p.trend.available, isFalse);
    expect(p.trend.message, 'Registre o peso');
    expect(p.trend.goalDate, isNull);
    expect(p.doses, isEmpty);
  });

  test('versão antiga da API (sem tendência) não quebra', () {
    final json = progressJson()..remove('trend')..remove('doses');
    final p = BodyProgress.fromJson(json);
    expect(p.trend.available, isFalse);
  });

  test('foto de evolução com peso mais próximo', () {
    final photo = ProgressPhoto.fromJson({
      'id': '01JPHOTO',
      'pose': 'front',
      'pose_label': 'Frente',
      'taken_at': '2026-10-28T12:00:00Z',
      'local_date': '2026-10-28',
      'notes': null,
      'nearest_weight': {'weight_kg': 80.4, 'date': '2026-10-27'},
    });
    expect(photo.nearestWeightKg, 80.4);
    expect(photo.localDate, DateTime(2026, 10, 28));
    expect(PhotoPoses.labels[photo.pose], 'Frente');
  });
}
