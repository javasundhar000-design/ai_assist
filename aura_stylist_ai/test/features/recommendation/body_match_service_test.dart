import 'package:aura_stylist_ai/features/recommendation/domain/services/body_match_service.dart';
import 'package:aura_stylist_ai/features/tryon/domain/entities/fit_type.dart';
import 'package:aura_stylist_ai/features/vision/domain/entities/body_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = BodyMatchService();

  test('athletic build scores structured fit highest', () {
    final scores = {
      for (final fit in FitType.values) fit: service.scoreFor(BodyType.athletic, fit),
    };
    final best = scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
    expect(best.key, FitType.structured);
  });

  test('broad build scores relaxed fit highest, slim fit lowest', () {
    final relaxed = service.scoreFor(BodyType.broad, FitType.relaxed);
    final slim = service.scoreFor(BodyType.broad, FitType.slim);
    expect(relaxed, greaterThan(slim));
  });

  test('average build scores regular fit highest', () {
    final scores = {
      for (final fit in FitType.values) fit: service.scoreFor(BodyType.average, fit),
    };
    final best = scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
    expect(best.key, FitType.regular);
  });

  test('every score is within 0-100', () {
    for (final bodyType in BodyType.values) {
      for (final fit in FitType.values) {
        final score = service.scoreFor(bodyType, fit);
        expect(score, inInclusiveRange(0, 100));
      }
    }
  });
}
