import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Tourist details saved ONCE on the phone (all optional) and sent
/// automatically with every SOS, so nothing has to be typed in an emergency.
class ProfileStore {
  ProfileStore._();
  static final ProfileStore instance = ProfileStore._();

  String name = '';
  String phone = '';
  String nationality = '';
  String emergencyContact = ''; // family / friend phone for "share location"
  String deviceId = ''; // anonymous id -> "my reports" without a login

  bool get hasProfile => name.isNotEmpty || phone.isNotEmpty;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      name = p.getString('name') ?? '';
      phone = p.getString('phone') ?? '';
      nationality = p.getString('nationality') ?? '';
      emergencyContact = p.getString('emergency_contact') ?? '';
      deviceId = p.getString('device_id') ?? '';
      if (deviceId.isEmpty) {
        deviceId = _newId();
        await p.setString('device_id', deviceId);
      }
    } catch (_) {
      // storage not available -> still works, just without saved details
      if (deviceId.isEmpty) deviceId = _newId();
    }
  }

  Future<void> save({
    required String name,
    required String phone,
    required String nationality,
    required String emergencyContact,
  }) async {
    this.name = name.trim();
    this.phone = phone.trim();
    this.nationality = nationality.trim();
    this.emergencyContact = emergencyContact.trim();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('name', this.name);
      await p.setString('phone', this.phone);
      await p.setString('nationality', this.nationality);
      await p.setString('emergency_contact', this.emergencyContact);
    } catch (_) {}
  }

  static String _newId() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(16).toRadixString(16)).join();
  }
}
