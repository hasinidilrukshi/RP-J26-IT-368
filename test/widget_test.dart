import 'package:flutter_test/flutter_test.dart';
import 'package:ceylon_path_emergency/models/emergency_report.dart';
import 'package:ceylon_path_emergency/services/emergency_api_service.dart';

void main() {
  test('Emergency types match the ML dataset categories', () {
    final ids = EmergencyType.all.map((t) => t.id).toList();
    expect(ids, containsAll(['medical', 'wildlife', 'crime', 'lost', 'ocean']));
  });

  test('SOS response from the server is parsed', () {
    final r = SosResponse.fromJson({
      'report': {
        'id': 'abc123',
        'description': 'my friend is not breathing',
        'emergency_type': 'medical',
        'latitude': 6.87,
        'longitude': 81.05,
        'location_accuracy': 12.0,
        'nearest_place': {'name': 'Ella', 'distance_km': 0.5},
        'assessment': {
          'severity': 'Critical',
          'score': 85,
          'summary': 'Critical severity medical emergency.',
          'recommendations': ['Start CPR if trained.'],
          'recommended_services': ['ambulance', 'hospital'],
          'method': 'ml',
        },
        'status': 'assessed',
      },
      'services': [
        {'id': 's1', 'name': 'Suwa Seriya', 'type': 'ambulance', 'phone': '1990', 'recommended': true},
        {'id': 's2', 'name': 'Police', 'type': 'police', 'phone': '119'},
      ],
    });
    expect(r.report.assessment!.severity, 'Critical');
    expect(r.report.placeLabel, 'near Ella (0.5 km)');
    expect(r.report.mapsUrl, contains('6.87,81.05'));
    expect(r.services.first.recommended, isTrue);
    expect(r.services.last.recommended, isFalse);
    expect(r.offline, isFalse);
  });

  group('Offline estimate (no server)', () {
    final api = EmergencyApiService.instance;

    test('urgent words -> Critical with ambulance', () {
      final a = api.offlineAssessmentForTest('my friend collapsed and is not breathing');
      expect(a.severity, 'Critical');
      expect(a.recommendedServices.first, 'ambulance');
    });

    test('drowning -> ocean services first', () {
      final a = api.offlineAssessmentForTest('my brother is drowning, i cant see his head');
      expect(a.severity, 'Critical');
      expect(a.predictedType, 'ocean');
      expect(a.recommendedServices.first, 'lifeguard');
    });

    test('missing child -> Critical', () {
      final a = api.offlineAssessmentForTest('lost my 8 year old at the perahera');
      expect(a.severity, 'Critical');
    });

    test('safe and only lost hotel -> not Critical', () {
      final a = api.offlineAssessmentForTest('cant find my hotel but i am safe');
      expect(a.severity, isNot('Critical'));
    });

    test('empty voice with no connection -> treated as urgent', () {
      final a = api.offlineAssessmentForTest('');
      expect(a.severity, 'High');
    });
  });
}
