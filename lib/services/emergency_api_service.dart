import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/emergency_report.dart';
import 'profile_store.dart';

/// Error with a message that can be shown to the tourist as it is.
class SosException implements Exception {
  final String message;
  SosException(this.message);
  @override
  String toString() => message;
}

/// Talks to the Python (FastAPI) backend, which stores data in MongoDB.
///
/// If the backend cannot be reached, an on-phone estimate (red-flag words)
/// and the national hotlines are shown, so the tourist is never left without
/// a number to call.
class EmergencyApiService {
  EmergencyApiService._();
  static final EmergencyApiService instance = EmergencyApiService._();

  // ---------------------------------------------------------------------------
  // BACKEND ADDRESS
  // ---------------------------------------------------------------------------
  /// REAL PHONE: put your PC's Wi-Fi IP here (find it with `ipconfig`),
  /// e.g. 'http://192.168.1.5:8000'. Leave empty for emulator / Chrome.
  static const String manualServerUrl = '';

  /// Or pass it when running:  flutter run --dart-define=API_URL=http://192.168.1.5:8000
  static const String _envServerUrl = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_envServerUrl.isNotEmpty) return _envServerUrl;
    if (manualServerUrl.isNotEmpty) return manualServerUrl;
    if (kIsWeb) return 'http://localhost:8000'; // Chrome
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000'; // Android emulator -> PC
    }
    return 'http://localhost:8000'; // iOS simulator / desktop
  }

  static const Duration _timeout = Duration(seconds: 10);
  static const Duration _voiceTimeout = Duration(seconds: 90);
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// True when the last call fell back to offline mode.
  bool lastCallOffline = false;

  // In-memory history for offline mode.
  final List<EmergencyReport> _offlineHistory = [];

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  static String _detail(http.Response res, String fallback) {
    try {
      final d = jsonDecode(res.body)['detail'];
      if (d is String && d.isNotEmpty) return d;
    } catch (_) {}
    return fallback;
  }

  // ---------------------------------------------------------------------------
  // 1. ONE-STEP SOS: message OR voice + GPS  ->  assessment + who to call
  // ---------------------------------------------------------------------------
  /// [message] typed text (may be empty when [audioPath] is given).
  /// [audioPath] recorded voice note (mobile only).
  /// Throws [SosException] only for problems the tourist can fix
  /// (e.g. nothing was said). If the server is unreachable it returns an
  /// offline estimate instead of failing.
  Future<SosResponse> sendSos({
    String message = '',
    String? audioPath,
    Position? position,
  }) async {
    final profile = ProfileStore.instance;
    final text = message.trim();
    try {
      final req = http.MultipartRequest('POST', _uri('/api/sos'))
        ..fields.addAll({
          'message': text,
          if (position != null) 'latitude': position.latitude.toString(),
          if (position != null) 'longitude': position.longitude.toString(),
          if (position != null)
            'location_accuracy': position.accuracy.toStringAsFixed(1),
          'tourist_name': profile.name,
          'phone': profile.phone,
          'nationality': profile.nationality,
          'emergency_contact': profile.emergencyContact,
          'device_id': profile.deviceId,
        });
      if (audioPath != null && !kIsWeb) {
        req.files.add(await http.MultipartFile.fromPath('audio', audioPath));
      }
      final streamed = await req
          .send()
          .timeout(audioPath != null ? _voiceTimeout : _timeout);
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 200 || res.statusCode == 201) {
        lastCallOffline = false;
        return SosResponse.fromJson(
            Map<String, dynamic>.from(jsonDecode(res.body) as Map));
      }
      if (res.statusCode == 422 || res.statusCode == 400) {
        // e.g. "No speech detected" -> the tourist can try again
        throw SosException(
            _detail(res, 'We could not understand that. Please try again.'));
      }
      if (res.statusCode == 503 && text.isEmpty) {
        throw SosException(_detail(res,
            'Voice is not available right now. Please type what happened.'));
      }
      throw Exception('Server error ${res.statusCode}');
    } on SosException {
      rethrow;
    } catch (_) {
      // Server not reachable -> estimate on the phone
      if (text.isEmpty) {
        // voice could not be sent and there is no text to read
        lastCallOffline = true;
        final r = EmergencyReport(
          id: 'local-${DateTime.now().millisecondsSinceEpoch}',
          description: '(voice message – no connection)',
          inputMode: 'voice',
          emergencyType: 'other',
          latitude: position?.latitude,
          longitude: position?.longitude,
          locationAccuracy: position?.accuracy,
          status: EmergencyStatus.assessed,
          assessment: _offlineAssessment(''),
        );
        _offlineHistory.insert(0, r);
        return SosResponse(report: r, services: _defaultServices(r), offline: true);
      }
      return _offlineSos(text, position);
    }
  }

  SosResponse _offlineSos(String text, Position? position) {
    lastCallOffline = true;
    final a = _offlineAssessment(text);
    final r = EmergencyReport(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      description: text,
      emergencyType: a.predictedType ?? 'other',
      latitude: position?.latitude,
      longitude: position?.longitude,
      locationAccuracy: position?.accuracy,
      status: EmergencyStatus.assessed,
      assessment: a,
    );
    _offlineHistory.insert(0, r);
    return SosResponse(report: r, services: _defaultServices(r), offline: true);
  }

  // ---------------------------------------------------------------------------
  // 2. OPTIONAL answers / better GPS after the SOS  ->  re-assessment
  // ---------------------------------------------------------------------------
  /// Returns null if the server cannot be reached (the SOS itself is
  /// already saved, so nothing is lost).
  Future<SosResponse?> addDetails(
      EmergencyReport report, Map<String, dynamic> details) async {
    if (report.isLocal) return null;
    try {
      final res = await http
          .patch(_uri('/api/emergencies/${report.id}/details'),
              headers: _headers, body: jsonEncode(details))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return SosResponse.fromJson(
            Map<String, dynamic>.from(jsonDecode(res.body) as Map));
      }
    } catch (_) {}
    return null;
  }

  // ---------------------------------------------------------------------------
  // 3. Nearby response services for a report
  // ---------------------------------------------------------------------------
  Future<List<ResponseService>> getNearbyServices(EmergencyReport report) async {
    try {
      final res = await http
          .get(
            _uri('/api/services/nearby', {
              'lat': (report.latitude ?? 7.8731).toString(),
              'lng': (report.longitude ?? 80.7718).toString(),
              'emergency_type': report.emergencyType,
              if (report.assessment != null &&
                  report.assessment!.recommendedServices.isNotEmpty)
                'services': report.assessment!.recommendedServices.join(','),
            }),
            headers: _headers,
          )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data
            .map((e) => ResponseService.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      throw Exception('Server error ${res.statusCode}');
    } catch (_) {
      return _defaultServices(report);
    }
  }

  // ---------------------------------------------------------------------------
  // 4. Request a responder
  // ---------------------------------------------------------------------------
  Future<EmergencyReport> dispatchService(
      EmergencyReport report, ResponseService service) async {
    if (!report.isLocal) {
      try {
        final res = await http
            .post(_uri('/api/emergencies/${report.id}/dispatch'),
                headers: _headers, body: jsonEncode({'service_id': service.id}))
            .timeout(_timeout);
        if (res.statusCode == 200) {
          return EmergencyReport.fromJson(jsonDecode(res.body));
        }
      } catch (_) {}
    }
    report.assignedService = service;
    report.status = EmergencyStatus.dispatched;
    return report;
  }

  // ---------------------------------------------------------------------------
  // 5. Live status of a report
  // ---------------------------------------------------------------------------
  Future<EmergencyReport> getReport(EmergencyReport report) async {
    if (report.isLocal) return report;
    try {
      final res = await http
          .get(_uri('/api/emergencies/${report.id}'), headers: _headers)
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return EmergencyReport.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return report;
  }

  Future<EmergencyReport> cancelReport(EmergencyReport report) async {
    if (!report.isLocal) {
      try {
        final res = await http
            .patch(_uri('/api/emergencies/${report.id}/status'),
                headers: _headers, body: jsonEncode({'status': 'resolved'}))
            .timeout(_timeout);
        if (res.statusCode == 200) {
          return EmergencyReport.fromJson(jsonDecode(res.body));
        }
      } catch (_) {}
    }
    report.status = EmergencyStatus.resolved;
    return report;
  }

  // ---------------------------------------------------------------------------
  // 6. History (this phone's reports, or search by phone number)
  // ---------------------------------------------------------------------------
  Future<List<EmergencyReport>> getHistory({String? phone}) async {
    final query = <String, String>{
      if (phone != null && phone.isNotEmpty)
        'phone': phone
      else
        'device_id': ProfileStore.instance.deviceId,
    };
    try {
      final res = await http
          .get(_uri('/api/emergencies', query), headers: _headers)
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        lastCallOffline = false;
        return data
            .map((e) => EmergencyReport.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      throw Exception('Server error ${res.statusCode}');
    } catch (_) {
      lastCallOffline = true;
      return List.of(_offlineHistory);
    }
  }

  // ---------------------------------------------------------------------------
  // Offline helpers (used only when the backend cannot be reached).
  // Same red-flag idea as backend/severity_model.py: the words in the
  // message can only make the emergency MORE urgent.
  // ---------------------------------------------------------------------------
  static const String _person =
      r'(him|her|my (son|daughter|child|kid|baby|boy|girl|friend|brother|sister|wife|husband|mom|mother|dad|father)|(my )?\d+ ?(yr|year)s? old)';

  // (pattern, severity, score, type id or '', needs ambulance)
  static final List<(RegExp, String, int, String, bool)> _redFlags = [
    (RegExp(r"not breath|(can'?t|cannot|unable to) breath|stopped breathing"), 'Critical', 85, 'medical', true),
    (RegExp(r"unconscious|passed out|(won'?t|will not|doesn'?t|not) (wake|respond)|not (moving|talking|responding)|collapsed"), 'Critical', 80, 'medical', true),
    (RegExp(r"seizure|heart attack|stroke|(can'?t|cannot) feel my (arm|leg|face)"), 'Critical', 80, 'medical', true),
    (RegExp(r"(snake|something|it) bit|bitten by|getting numb"), 'Critical', 75, 'wildlife', true),
    (RegExp(r"drown|swept (away|out)|(can'?t|cannot) see (his|her) head|went under|rip current"), 'Critical', 85, 'ocean', true),
    (RegExp(r"\bgun\b|\bknife\b|knifepoint|break(ing)? (in|our door|the door)"), 'Critical', 80, 'crime', false),
    (RegExp(r"drugged|put something in my drink|spiked"), 'Critical', 75, 'crime', true),
    (RegExp('(missing|lost|(can\'?t|cannot) (find|see)) $_person|$_person (is )?missing'), 'Critical', 80, 'lost', false),
    (RegExp(r"tsunami|flood|water (is )?(up to|entering|inside|coming in)|landslide"), 'Critical', 75, 'lost', false),
    (RegExp(r"bleeding|dislocat|broken (leg|arm|bone)|fracture|(can'?t|cannot) walk|fell"), 'High', 60, 'medical', true),
    (RegExp(r"elephant|leopard|bear|crocodile|charging"), 'High', 60, 'wildlife', false),
    (RegExp(r"robbed|attacked|assault|following me|harass"), 'High', 60, 'crime', false),
    (RegExp(r"\blost\b|stuck|trapped|getting dark|can'?t find (the|my) way"), 'Medium', 40, 'lost', false),
    (RegExp(r"\bsea\b|beach|wave|current|boat|swim"), 'Medium', 40, 'ocean', false),
    (RegExp(r"stolen|stole|scam|cheated|passport"), 'Medium', 40, 'crime', false),
    (RegExp(r"snake|monkey|dog bit|sting|jellyfish"), 'Medium', 40, 'wildlife', false),
    (RegExp(r"fever|vomit|pain|sick|dizzy|injur|hurt"), 'Medium', 40, 'medical', false),
  ];

  static const Map<String, List<String>> _typeServices = {
    'medical': ['ambulance', 'hospital'],
    'wildlife': ['wildlife', 'ambulance'],
    'crime': ['police', 'tourist_police'],
    'lost': ['police', 'disaster'],
    'ocean': ['lifeguard', 'coast_guard', 'ambulance'],
    'other': ['police', 'tourist_police'],
  };

  static const Map<String, List<String>> _typeTips = {
    'medical': ['Do not give food or drink to a seriously injured person.'],
    'wildlife': ['Keep a safe distance from the animal and do not provoke it.'],
    'crime': ['Go to a busy, well-lit place and keep your passport copy safe.'],
    'lost': ['Stay where you are, keep warm and save phone battery.'],
    'ocean': [
      'Do not enter the water to rescue someone unless trained; throw something that floats.'
    ],
  };

  @visibleForTesting
  AssessmentResult offlineAssessmentForTest(String text) =>
      _offlineAssessment(text);

  AssessmentResult _offlineAssessment(String text) {
    const levels = ['Low', 'Medium', 'High', 'Critical'];
    final t = text.toLowerCase();
    var severity = text.isEmpty ? 'High' : 'Low'; // unknown voice -> treat as urgent
    var score = text.isEmpty ? 60 : 15;
    var type = 'other';
    var ambulance = false;
    final reasons = <String>[];

    for (final f in _redFlags) {
      if (f.$1.hasMatch(t)) {
        if (levels.indexOf(f.$2) > levels.indexOf(severity)) {
          severity = f.$2;
          score = f.$3;
        }
        if (type == 'other') type = f.$4;
        ambulance = ambulance || f.$5;
        if (f.$2 == 'Critical') reasons.add('urgent words in the message');
      }
    }

    final services = <String>[
      if (ambulance && type != 'ocean') 'ambulance',
      ...?_typeServices[type],
      if (ambulance) 'hospital',
    ].toSet().toList();

    return AssessmentResult(
      severity: severity,
      score: score,
      summary: text.isEmpty
          ? 'Your voice message could not be sent (no connection). Call a hotline below.'
          : '$severity severity '
              '${type == 'other' ? '' : '${EmergencyType.byId(type).label.toLowerCase()} '}'
              'emergency (offline estimate – server not reachable).',
      recommendations: [
        ...?_typeTips[type],
        'Call the first number below now.',
        'Keep your phone on and the line free so responders can call you.',
      ],
      recommendedServices: services,
      predictedType: type,
      predictedTypeLabel: EmergencyType.byId(type).label,
      method: 'offline',
      adjustments: reasons.toSet().toList(),
    );
  }

  List<ResponseService> _defaultServices(EmergencyReport r) {
    // Sri Lanka national numbers
    const all = [
      ResponseService(id: 'ambulance', name: 'Suwa Seriya Ambulance', type: 'ambulance',
          phone: '1990', distanceKm: 0, etaMinutes: 15, address: 'National free ambulance service'),
      ResponseService(id: 'police', name: 'Police Emergency', type: 'police',
          phone: '119', distanceKm: 0, etaMinutes: 15, address: 'Sri Lanka Police'),
      ResponseService(id: 'tourist_police', name: 'Tourist Police', type: 'tourist_police',
          phone: '+94112421052', distanceKm: 0, etaMinutes: 20, address: 'Sri Lanka Tourist Police, Colombo'),
      ResponseService(id: 'wildlife', name: 'Wildlife Hotline', type: 'wildlife',
          phone: '1992', distanceKm: 0, etaMinutes: 30, address: 'Wildlife conservation 24h'),
      ResponseService(id: 'coast_guard', name: 'Sri Lanka Coast Guard', type: 'coast_guard',
          phone: '106', distanceKm: 0, etaMinutes: 25, address: 'Maritime distress hotline'),
      ResponseService(id: 'lifeguard', name: 'Beach Lifeguards', type: 'lifeguard',
          phone: '119', distanceKm: 0, etaMinutes: 5, address: 'Alert the nearest lifeguard tower or call Police 119'),
      ResponseService(id: 'disaster', name: 'Disaster Management Centre', type: 'disaster',
          phone: '117', distanceKm: 0, etaMinutes: 30, address: 'Floods, landslides, storms'),
      ResponseService(id: 'tourism_hotline', name: 'Tourist Hotline (SLTDA)', type: 'tourist_police',
          phone: '1912', distanceKm: 0, etaMinutes: 20, address: 'Sri Lanka Tourism 24h hotline'),
    ];
    final rec = r.assessment?.recommendedServices ?? [];
    int rank(ResponseService s) {
      final i = rec.indexOf(s.type);
      return i < 0 ? 99 : i;
    }

    return (List.of(all)..sort((a, b) => rank(a).compareTo(rank(b))))
        .map((s) => ResponseService(
              id: s.id,
              name: s.name,
              type: s.type,
              phone: s.phone,
              distanceKm: s.distanceKm,
              etaMinutes: s.etaMinutes,
              address: s.address,
              recommended: rec.contains(s.type),
            ))
        .toList();
  }
}
