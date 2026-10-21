import 'package:flutter_test/flutter_test.dart';
import 'package:food_safety_ai/models/health_profile.dart';
import 'package:food_safety_ai/models/scan_result.dart';

void main() {
  test('health profile round-trips to JSON', () {
    final p = HealthProfile(diet: 'vegetarian', allergies: ['peanuts']);
    final back = HealthProfile.fromJson(p.toJson());
    expect(back.diet, 'vegetarian');
    expect(back.summaryTags, ['Vegetarian', 'Peanuts Allergy']);
  });

  test('scan result parses backend JSON', () {
    final s = ScanResult.fromJson({
      'scan_id': 'abc',
      'user_id': 'u1',
      'created_at': '2026-10-18T10:00:00+00:00',
      'recognized': true,
      'detection': {'detected': true, 'label': 'kottu', 'confidence': 0.92, 'alternatives': []},
      'food': {'key': 'kottu', 'name': 'Kottu Roti', 'nutrition': {'calories': 176}},
      'recommendation': {'status': 'AVOID', 'score': 20, 'reasons': [{'severity': 'avoid', 'text': 'x'}]},
    });
    expect(s.displayName, 'Kottu Roti');
    expect(s.recommendation!.status, 'AVOID');
    expect(s.food!.nutrition.calories, 176);
  });
}
