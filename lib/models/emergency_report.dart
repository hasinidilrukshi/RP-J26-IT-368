import 'package:flutter/material.dart';

/// Types of emergencies a tourist can report (fall detection is NOT part of this).
class EmergencyType {
  final String id;
  final String label;
  final IconData icon;

  const EmergencyType(this.id, this.label, this.icon);

  // Same categories as the ML dataset (+ "Other" = let the AI decide).
  static const List<EmergencyType> all = [
    EmergencyType('medical', 'Medical', Icons.medical_services_rounded),
    EmergencyType('wildlife', 'Wildlife', Icons.pets_rounded),
    EmergencyType('crime', 'Crime', Icons.local_police_rounded),
    EmergencyType('lost', 'Lost / Rescue', Icons.wrong_location_rounded),
    EmergencyType('ocean', 'Ocean Safety', Icons.pool_rounded),
    EmergencyType('other', 'Not sure', Icons.help_rounded),
  ];

  static EmergencyType byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all.last);
}

/// AI severity assessment returned by the backend.
class AssessmentResult {
  final String severity; // Low | Medium | High | Critical
  final int score; // 0 - 100
  final String summary;
  final List<String> recommendations;
  final List<String> recommendedServices; // e.g. ['ambulance', 'police']
  final List<String> authorities; // e.g. ['1990 Suwa Seriya Ambulance']
  final String? predictedType; // app type id detected by the AI
  final String? predictedTypeLabel;
  final int? confidence; // severity confidence %
  final int? typeConfidence;
  final String method; // 'ml' | 'rules' | 'offline'
  final List<String> adjustments; // why severity was raised

  const AssessmentResult({
    required this.severity,
    required this.score,
    required this.summary,
    required this.recommendations,
    required this.recommendedServices,
    this.authorities = const [],
    this.predictedType,
    this.predictedTypeLabel,
    this.confidence,
    this.typeConfidence,
    this.method = 'rules',
    this.adjustments = const [],
  });

  bool get isMl => method == 'ml';

  factory AssessmentResult.fromJson(Map<String, dynamic> json) =>
      AssessmentResult(
        severity: json['severity'] ?? 'Low',
        score: ((json['score'] ?? 0) as num).toInt(),
        summary: json['summary'] ?? '',
        recommendations: List<String>.from(json['recommendations'] ?? []),
        recommendedServices:
            List<String>.from(json['recommended_services'] ?? []),
        authorities: List<String>.from(json['authorities'] ?? []),
        predictedType: json['predicted_type'],
        predictedTypeLabel: json['predicted_type_label'],
        confidence: (json['confidence'] as num?)?.toInt(),
        typeConfidence: (json['type_confidence'] as num?)?.toInt(),
        method: json['method'] ?? 'rules',
        adjustments: List<String>.from(json['adjustments'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'severity': severity,
        'score': score,
        'summary': summary,
        'recommendations': recommendations,
        'recommended_services': recommendedServices,
        'authorities': authorities,
        'predicted_type': predictedType,
        'predicted_type_label': predictedTypeLabel,
        'confidence': confidence,
        'type_confidence': typeConfidence,
        'method': method,
        'adjustments': adjustments,
      };
}

/// Result of sending a voice note to Whisper (POST /api/transcribe).
class TranscriptionResult {
  final String audioId;
  final String text; // English (used by the AI)
  final String originalText; // in the language spoken
  final String language; // e.g. 'de'
  final String languageName; // e.g. 'German'
  final double duration;
  final String? previewSeverity;
  final String? previewType;

  const TranscriptionResult({
    required this.audioId,
    required this.text,
    required this.originalText,
    required this.language,
    required this.languageName,
    required this.duration,
    this.previewSeverity,
    this.previewType,
  });

  bool get wasTranslated => language != 'en';

  factory TranscriptionResult.fromJson(Map<String, dynamic> j) {
    final p = j['preview'] is Map ? Map<String, dynamic>.from(j['preview'])
        : <String, dynamic>{};
    return TranscriptionResult(
      audioId: j['audio_id'] ?? '',
      text: j['text'] ?? '',
      originalText: j['original_text'] ?? j['text'] ?? '',
      language: j['language'] ?? 'en',
      languageName: j['language_name'] ?? 'English',
      duration: ((j['duration'] ?? 0) as num).toDouble(),
      previewSeverity: p['severity'],
      previewType: p['predicted_type'],
    );
  }
}

/// A responder (hospital, police station, ambulance, ...).
class ResponseService {
  final String id;
  final String name;
  // ambulance | hospital | police | tourist_police | wildlife | forest |
  // coast_guard | lifeguard | disaster | fire
  final String type;
  final String phone;
  final double distanceKm;
  final int etaMinutes;
  final String address;

  const ResponseService({
    required this.id,
    required this.name,
    required this.type,
    required this.phone,
    required this.distanceKm,
    required this.etaMinutes,
    required this.address,
  });

  factory ResponseService.fromJson(Map<String, dynamic> json) =>
      ResponseService(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        name: json['name'] ?? '',
        type: json['type'] ?? 'hospital',
        phone: json['phone'] ?? '',
        distanceKm: ((json['distance_km'] ?? 0) as num).toDouble(),
        etaMinutes: ((json['eta_minutes'] ?? 0) as num).toInt(),
        address: json['address'] ?? '',
      );

  IconData get icon {
    switch (type) {
      case 'ambulance':
        return Icons.emergency_rounded;
      case 'police':
        return Icons.local_police_rounded;
      case 'tourist_police':
        return Icons.badge_rounded;
      case 'fire':
        return Icons.fire_truck_rounded;
      case 'wildlife':
        return Icons.pets_rounded;
      case 'forest':
        return Icons.forest_rounded;
      case 'coast_guard':
        return Icons.directions_boat_rounded;
      case 'lifeguard':
        return Icons.pool_rounded;
      case 'disaster':
        return Icons.flood_rounded;
      default:
        return Icons.local_hospital_rounded;
    }
  }

  static const Map<String, String> typeLabels = {
    'ambulance': 'Ambulance',
    'hospital': 'Hospital',
    'police': 'Police',
    'tourist_police': 'Tourist Police',
    'wildlife': 'Wildlife Dept.',
    'forest': 'Forest Dept.',
    'coast_guard': 'Navy / Coast Guard',
    'lifeguard': 'Lifeguards',
    'disaster': 'Disaster Mgmt.',
    'fire': 'Fire & Rescue',
  };
}

/// Status stages of an emergency (used by the status timeline).
class EmergencyStatus {
  static const String submitted = 'submitted';
  static const String assessed = 'assessed';
  static const String dispatched = 'dispatched';
  static const String onTheWay = 'on_the_way';
  static const String resolved = 'resolved';

  static const List<String> flow = [
    submitted,
    assessed,
    dispatched,
    onTheWay,
    resolved,
  ];

  static String label(String s) {
    switch (s) {
      case submitted:
        return 'Report submitted';
      case assessed:
        return 'Severity assessed';
      case dispatched:
        return 'Responder assigned';
      case onTheWay:
        return 'Help on the way';
      case resolved:
        return 'Resolved';
      default:
        return s;
    }
  }
}

/// Main emergency report document (matches the MongoDB `emergencies` collection).
class EmergencyReport {
  String? id;

  // Tourist info
  String touristName;
  String phone;
  String nationality;

  // Emergency details
  String emergencyType;
  String description;
  int peopleAffected;
  bool isConscious;
  bool isBreathingNormally;
  bool hasHeavyBleeding;
  bool isInDanger; // still in immediate danger?
  int painLevel; // 0 - 10

  // Voice input
  String inputMode; // 'text' | 'voice'
  String? audioId;
  String? voiceLanguage; // e.g. 'German'
  String? originalVoiceText;

  // Location
  double? latitude;
  double? longitude;
  String address;

  // Server-side fields
  AssessmentResult? assessment;
  String status;
  ResponseService? assignedService;
  DateTime createdAt;

  EmergencyReport({
    this.id,
    this.touristName = '',
    this.phone = '',
    this.nationality = '',
    this.emergencyType = 'medical',
    this.description = '',
    this.peopleAffected = 1,
    this.isConscious = true,
    this.isBreathingNormally = true,
    this.hasHeavyBleeding = false,
    this.isInDanger = false,
    this.painLevel = 0,
    this.inputMode = 'text',
    this.audioId,
    this.voiceLanguage,
    this.originalVoiceText,
    this.latitude,
    this.longitude,
    this.address = '',
    this.assessment,
    this.status = EmergencyStatus.submitted,
    this.assignedService,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  EmergencyType get type => EmergencyType.byId(emergencyType);

  bool get hasLocation => latitude != null && longitude != null;

  Map<String, dynamic> toJson() => {
        'tourist_name': touristName,
        'phone': phone,
        'nationality': nationality,
        'emergency_type': emergencyType,
        'description': description,
        'people_affected': peopleAffected,
        'is_conscious': isConscious,
        'is_breathing_normally': isBreathingNormally,
        'has_heavy_bleeding': hasHeavyBleeding,
        'is_in_danger': isInDanger,
        'pain_level': painLevel,
        'input_mode': inputMode,
        'audio_id': audioId,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      };

  factory EmergencyReport.fromJson(Map<String, dynamic> json) =>
      EmergencyReport(
        id: (json['id'] ?? json['_id'])?.toString(),
        touristName: json['tourist_name'] ?? '',
        phone: json['phone'] ?? '',
        nationality: json['nationality'] ?? '',
        emergencyType: json['emergency_type'] ?? 'other',
        description: json['description'] ?? '',
        peopleAffected: ((json['people_affected'] ?? 1) as num).toInt(),
        isConscious: json['is_conscious'] ?? true,
        isBreathingNormally: json['is_breathing_normally'] ?? true,
        hasHeavyBleeding: json['has_heavy_bleeding'] ?? false,
        isInDanger: json['is_in_danger'] ?? false,
        painLevel: ((json['pain_level'] ?? 0) as num).toInt(),
        inputMode: json['input_mode'] ?? 'text',
        audioId: json['audio_id'],
        voiceLanguage:
            json['voice'] is Map ? json['voice']['language_name'] : null,
        originalVoiceText:
            json['voice'] is Map ? json['voice']['original_text'] : null,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        address: json['address'] ?? '',
        assessment: json['assessment'] != null
            ? AssessmentResult.fromJson(
                Map<String, dynamic>.from(json['assessment']))
            : null,
        status: json['status'] ?? EmergencyStatus.submitted,
        assignedService: json['assigned_service'] != null
            ? ResponseService.fromJson(
                Map<String, dynamic>.from(json['assigned_service']))
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
            : null,
      );
}
