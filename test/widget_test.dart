import 'package:flutter_test/flutter_test.dart';
import 'package:ceylon_path_emergency/models/emergency_report.dart';

void main() {
  test('Emergency types match the ML dataset categories', () {
    final ids = EmergencyType.all.map((t) => t.id).toList();
    expect(ids, containsAll(['medical', 'wildlife', 'crime', 'lost', 'ocean']));
  });

  test('Report JSON round trip keeps the main fields', () {
    final r = EmergencyReport(
      touristName: 'Test',
      phone: '0771234567',
      emergencyType: 'medical',
      description: 'My friend collapsed',
    );
    final json = r.toJson();
    expect(json['tourist_name'], 'Test');
    expect(json['emergency_type'], 'medical');
    expect(json['input_mode'], 'text');
  });
}
