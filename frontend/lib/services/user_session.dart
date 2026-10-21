import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/health_profile.dart';
import 'api_service.dart';

/// Keeps the anonymous user id (stored on the phone) and the health profile.
class UserSession extends ChangeNotifier {
  UserSession._();
  static final UserSession instance = UserSession._();

  static const _kUserId = 'food_user_id';

  String? userId;
  HealthProfile profile = HealthProfile();
  bool profileCompleted = false;
  bool _loaded = false;

  /// Makes sure we have a user on the server; creates one on first launch.
  Future<void> ensureUser({bool refresh = false}) async {
    if (_loaded && !refresh) return;
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString(_kUserId);

    Map<String, dynamic>? user;
    if (userId != null) user = await ApiService.instance.getUser(userId!);
    if (user == null) {
      userId = await ApiService.instance.createUser();
      await prefs.setString(_kUserId, userId!);
      profile = HealthProfile();
      profileCompleted = false;
    } else {
      profile = HealthProfile.fromJson(user['profile'] as Map<String, dynamic>?);
      profileCompleted = user['profile_completed'] == true;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> saveProfile(HealthProfile p) async {
    await ensureUser();
    await ApiService.instance.saveProfile(userId!, p);
    profile = p.copy();
    profileCompleted = true;
    notifyListeners();
  }
}
