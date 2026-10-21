import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/health_profile.dart';
import '../models/scan_result.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// All HTTP calls to the Python backend.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final _client = http.Client();
  Uri _u(String path, [Map<String, String>? q]) =>
      Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: q);

  dynamic _decode(http.Response r) {
    final body = r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    final detail = body is Map && body['detail'] != null ? body['detail'].toString() : r.reasonPhrase;
    throw ApiException('Server error (${r.statusCode}): $detail');
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(ApiConfig.timeout);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Cannot reach the server at ${ApiConfig.baseUrl}. '
          'Check that the backend is running and the phone is on the same network.');
    }
  }

  // ---------------------------------------------------------------- users
  Future<String> createUser() => _guard(() async {
        final r = await _client.post(_u('/api/users'),
            headers: {'Content-Type': 'application/json'}, body: jsonEncode({}));
        return (_decode(r) as Map)['user_id'].toString();
      });

  /// Returns null if the user does not exist on the server.
  Future<Map<String, dynamic>?> getUser(String userId) => _guard(() async {
        final r = await _client.get(_u('/api/users/$userId'));
        if (r.statusCode == 404) return null;
        return Map<String, dynamic>.from(_decode(r) as Map);
      });

  Future<void> saveProfile(String userId, HealthProfile profile) => _guard(() async {
        final r = await _client.put(_u('/api/users/$userId/profile'),
            headers: {'Content-Type': 'application/json'}, body: jsonEncode(profile.toJson()));
        _decode(r);
      });

  // ---------------------------------------------------------------- food
  Future<ScanResult> analyzeFood({
    required String userId,
    required Uint8List imageBytes,
    String filename = 'food.jpg',
  }) =>
      _guard(() async {
        final req = http.MultipartRequest('POST', _u('/api/food/analyze'))
          ..fields['user_id'] = userId
          ..files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: filename));
        final streamed = await _client.send(req);
        final r = await http.Response.fromStream(streamed);
        return ScanResult.fromJson(Map<String, dynamic>.from(_decode(r) as Map));
      });

  /// Evaluate a specific dish (manual choice / "Not this dish?").
  Future<ScanResult> evaluateFood({required String userId, required String foodKey, String? scanId}) =>
      _guard(() async {
        final r = await _client.post(_u('/api/food/evaluate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': userId, 'food_key': foodKey, 'scan_id': scanId}));
        return ScanResult.fromJson(Map<String, dynamic>.from(_decode(r) as Map));
      });

  Future<List<FoodInfo>> getFoods({String search = ''}) => _guard(() async {
        final r = await _client.get(_u('/api/foods', search.isEmpty ? null : {'search': search}));
        return (_decode(r) as List).map((e) => FoodInfo.fromJson(Map<String, dynamic>.from(e))).toList();
      });

  // ---------------------------------------------------------------- scans
  Future<List<ScanResult>> getScans(String userId, {int limit = 20}) => _guard(() async {
        final r = await _client.get(_u('/api/scans', {'user_id': userId, 'limit': '$limit'}));
        return (_decode(r) as List).map((e) => ScanResult.fromJson(Map<String, dynamic>.from(e))).toList();
      });

  Future<void> deleteScan(String userId, String scanId) => _guard(() async {
        final r = await _client.delete(_u('/api/scans/$scanId', {'user_id': userId}));
        _decode(r);
      });
}
