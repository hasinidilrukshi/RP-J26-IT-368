import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/emergency_report.dart';

class VoiceException implements Exception {
  final String message;
  VoiceException(this.message);
  @override
  String toString() => message;
}

/// Talks to the Python (FastAPI) backend, which stores data in MongoDB.
///
/// If the backend cannot be reached, a simple on-device rule-based
/// assessment is used so the app can still be demoed offline.
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

  // ---------------------------------------------------------------------------
  // 1. Submit report -> backend runs severity assessment -> returns saved report
  // ---------------------------------------------------------------------------
  Future<EmergencyReport> submitReport(EmergencyReport report) async {
    try {
      final res = await http
          .post(_uri('/api/emergencies'),
              headers: _headers, body: jsonEncode(report.toJson()))
          .timeout(_timeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        lastCallOffline = false;
        return EmergencyReport.fromJson(jsonDecode(res.body));
      }
      throw Exception('Server error ${res.statusCode}: ${res.body}');
    } catch (_) {
      // Offline fallback
      lastCallOffline = true;
      report.id = 'local-${DateTime.now().millisecondsSinceEpoch}';
      report.assessment = _localAssessment(report);
      report.status = EmergencyStatus.assessed;
      _offlineHistory.insert(0, report);
      return report;
    }
  }

  // ---------------------------------------------------------------------------
  // 1b. Voice note -> Whisper (speech to English text) on the backend
  // ---------------------------------------------------------------------------
  /// Throws [VoiceException] with a user-friendly message on failure.
  Future<TranscriptionResult> transcribe(String audioPath) async {
    try {
      final req = http.MultipartRequest('POST', _uri('/api/transcribe'))
        ..files.add(await http.MultipartFile.fromPath('audio', audioPath));
      final streamed =
          await req.send().timeout(const Duration(seconds: 90));
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode == 200) {
        return TranscriptionResult.fromJson(jsonDecode(res.body));
      }
      String msg = 'Could not process the voice note.';
      try {
        msg = jsonDecode(res.body)['detail']?.toString() ?? msg;
      } catch (_) {}
      throw VoiceException(msg);
    } on VoiceException {
      rethrow;
    } on TimeoutException {
      throw VoiceException('The server took too long. Please type your message.');
    } catch (_) {
      throw VoiceException(
          'Voice needs the server connection. Please type your message instead.');
    }
  }

  // ---------------------------------------------------------------------------
  // 2. Nearby response services for a report
  // ---------------------------------------------------------------------------
  Future<List<ResponseService>> getNearbyServices(EmergencyReport report) async {
    try {
      final res = await http
          .get(
            _uri('/api/services/nearby', {
              'lat': (report.latitude ?? 7.2906).toString(),
              'lng': (report.longitude ?? 80.6337).toString(),
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
  // 3. Request a responder
  // ---------------------------------------------------------------------------
  Future<EmergencyReport> dispatchService(
      EmergencyReport report, ResponseService service) async {
    try {
      final res = await http
          .post(_uri('/api/emergencies/${report.id}/dispatch'),
              headers: _headers, body: jsonEncode({'service_id': service.id}))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return EmergencyReport.fromJson(jsonDecode(res.body));
      }
      throw Exception('Server error ${res.statusCode}');
    } catch (_) {
      report.assignedService = service;
      report.status = EmergencyStatus.dispatched;
      return report;
    }
  }

  // ---------------------------------------------------------------------------
  // 4. Live status of a report
  // ---------------------------------------------------------------------------
  Future<EmergencyReport> getReport(EmergencyReport report) async {
    if (report.id == null || report.id!.startsWith('local-')) return report;
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
    try {
      final res = await http
          .patch(_uri('/api/emergencies/${report.id}/status'),
              headers: _headers, body: jsonEncode({'status': 'resolved'}))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return EmergencyReport.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    report.status = EmergencyStatus.resolved;
    return report;
  }

  // ---------------------------------------------------------------------------
  // 5. History
  // ---------------------------------------------------------------------------
  Future<List<EmergencyReport>> getHistory({String? phone}) async {
    try {
      final res = await http
          .get(
            _uri('/api/emergencies',
                phone != null && phone.isNotEmpty ? {'phone': phone} : null),
            headers: _headers,
          )
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
  // Offline helpers (used only when the backend / ML model can't be reached)
  // ---------------------------------------------------------------------------
  static const Map<String, List<String>> _keywords = {
    'Critical': ['not breathing', 'unconscious', 'collapsed', 'drowning',
      'knife', 'gun', 'heart attack', 'chest pain', 'kidnap', 'swept away',
      'attacked'],
    'High': ['bleeding', 'broken', 'fracture', 'elephant', 'bitten', 'stuck',
      'trapped', 'current', 'robbed', 'assault', 'fell', 'dark'],
    'Medium': ['snake', 'sting', 'stolen', 'pain', 'lost', 'fever', 'scam',
      'monkey'],
  };

  static const Map<String, List<String>> _typeServices = {
    'medical': ['ambulance', 'hospital'],
    'wildlife': ['wildlife'],
    'crime': ['police', 'tourist_police'],
    'lost': ['police'],
    'ocean': ['lifeguard', 'coast_guard'],
    'other': ['tourist_police'],
  };

  AssessmentResult _localAssessment(EmergencyReport r) {
    const levels = ['Low', 'Medium', 'High', 'Critical'];
    final text = r.description.toLowerCase();
    var severity = 'Low';
    for (final lvl in ['Critical', 'High', 'Medium']) {
      if (_keywords[lvl]!.any(text.contains)) {
        severity = lvl;
        break;
      }
    }
    var score = const {'Low': 15, 'Medium': 40, 'High': 65, 'Critical': 90}[severity]!;
    final reasons = <String>[];

    void raise(String lvl, int min, String why) {
      if (levels.indexOf(lvl) > levels.indexOf(severity)) {
        severity = lvl;
        reasons.add(why);
      }
      if (score < min) score = min;
    }

    if (!r.isBreathingNormally) raise('Critical', 85, 'not breathing normally');
    if (!r.isConscious) raise('Critical', 80, 'unconscious');
    if (r.hasHeavyBleeding) raise('High', 65, 'heavy bleeding');
    if (r.isInDanger) raise('High', 60, 'still in danger');
    if (r.painLevel >= 8) raise('High', 55, 'severe pain');
    if (r.peopleAffected >= 3) raise('High', 55, 'several people affected');

    final services = <String>[
      if (!r.isBreathingNormally || !r.isConscious || r.hasHeavyBleeding)
        'ambulance',
      ...?_typeServices[r.emergencyType],
    ].toSet().toList();

    final recs = <String>[
      if (!r.isBreathingNormally) 'Keep the airway open and start CPR if you are trained.',
      if (r.hasHeavyBleeding) 'Press firmly on the wound with a clean cloth.',
      if (!r.isConscious) 'Place the person on their side (recovery position).',
      if (r.isInDanger) 'Move to a safe place if you can do so safely.',
      'Keep your phone on and the line free so responders can call you.',
    ];

    return AssessmentResult(
      severity: severity,
      score: score,
      summary: '$severity severity ${r.type.label.toLowerCase()} emergency '
          '(offline estimate – AI model not reachable).',
      recommendations: recs,
      recommendedServices: services,
      method: 'offline',
      adjustments: reasons,
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

    return List.of(all)..sort((a, b) => rank(a).compareTo(rank(b)));
  }
}
