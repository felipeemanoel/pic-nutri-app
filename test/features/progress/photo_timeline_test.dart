import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnutri/features/progress/data/body_models.dart';
import 'package:picnutri/features/progress/data/body_repository.dart';
import 'package:picnutri/features/progress/presentation/progress_photos.dart';

void main() {
  testWidgets('linha do tempo ordena datas e separa os ângulos', (
    tester,
  ) async {
    ProgressPhoto photo(String id, String pose, int day) => ProgressPhoto(
      id: id,
      pose: pose,
      poseLabel: pose,
      takenAt: DateTime(2026, 10, day),
      localDate: DateTime(2026, 10, day),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressPhotoBytesProvider.overrideWith(
            (ref, id) async => throw Exception('Imagem indisponível'),
          ),
        ],
        child: MaterialApp(
          home: PhotoTimelinePage(
            photos: [
              photo('new', 'front', 20),
              photo('back', 'back', 10),
              photo('old', 'front', 1),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Foto 1 de 2'), findsOneWidget);
    final slider = find.byType(Slider);
    await tester.tapAt(tester.getTopRight(slider) + const Offset(-20, 20));
    await tester.pumpAndSettle();
    expect(find.textContaining('Foto 2 de 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
