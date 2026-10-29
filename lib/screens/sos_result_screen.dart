import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../models/emergency_report.dart';
import '../services/emergency_api_service.dart';
import '../services/location_service.dart';
import '../services/profile_store.dart';
import '../widgets/section_title.dart';
import 'emergency_status_screen.dart';
import 'response_service_screen.dart';

/// Shown right after the SOS: how serious it is, WHO to call (one tap),
/// where the tourist is, and what to do now. Questions are OPTIONAL.
class SosResultScreen extends StatefulWidget {
  final SosResponse initial;
  const SosResultScreen({super.key, required this.initial});

  @override
  State<SosResultScreen> createState() => _SosResultScreenState();
}

class _SosResultScreenState extends State<SosResultScreen> {
  late SosResponse _res;
  final Map<String, bool> _answers = {};
  final _landmarkCtrl = TextEditingController();
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;
  bool _updating = false;
  DateTime _lastGpsSent = DateTime.fromMillisecondsSinceEpoch(0);

  EmergencyReport get _r => _res.report;
  AssessmentResult get _a =>
      _r.assessment ??
      const AssessmentResult(
        severity: 'High',
        score: 60,
        summary: 'Assessment not available – call a service below.',
        recommendations: [],
        recommendedServices: [],
      );

  @override
  void initState() {
    super.initState();
    _res = widget.initial;
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.45);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
    LocationService.instance.addListener(_onLocation);
    // the GPS may have been found after the SOS was sent
    WidgetsBinding.instance.addPostFrameCallback((_) => _onLocation());
  }

  @override
  void dispose() {
    LocationService.instance.removeListener(_onLocation);
    _tts.stop();
    _landmarkCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- helpers
  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _call(String phone) async {
    var ok = false;
    try {
      ok = await launchUrl(Uri(scheme: 'tel', path: phone));
    } catch (_) {}
    if (!ok) _toast('Could not call $phone – please dial it yourself.');
  }

  /// Sends a better GPS position to the server (at most every 20 s).
  Future<void> _onLocation() async {
    final p = LocationService.instance.position;
    if (p == null || _res.offline || _r.isLocal) return;
    final old = _r.locationAccuracy;
    final better = !_r.hasLocation || (old != null && p.accuracy < old / 2);
    if (!better) return;
    if (DateTime.now().difference(_lastGpsSent).inSeconds < 20) return;
    _lastGpsSent = DateTime.now();
    final res = await EmergencyApiService.instance.addDetails(_r, {
      'latitude': p.latitude,
      'longitude': p.longitude,
      'location_accuracy': p.accuracy,
    });
    if (res != null && mounted) setState(() => _res = res);
  }

  Future<void> _sendDetails(Map<String, dynamic> details) async {
    if (_res.offline || _r.isLocal) {
      _toast('No connection to the server. Please call a number above.');
      return;
    }
    setState(() => _updating = true);
    final before = _a.severity;
    final res = await EmergencyApiService.instance.addDetails(_r, details);
    if (!mounted) return;
    setState(() {
      _updating = false;
      if (res != null) _res = res;
    });
    if (res == null) {
      _toast('Could not update. Your SOS is already sent – call if needed.');
    } else if (_a.severity != before) {
      _toast('Updated: now ${_a.severity.toUpperCase()} severity');
    } else {
      _toast('Thank you – responders will see this.');
    }
  }

  Future<void> _answer(String key, bool value) async {
    setState(() => _answers[key] = value);
    await _sendDetails({key: value});
  }

  Future<void> _openMap() async {
    final url = _r.mapsUrl;
    if (url == null) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      _toast('Could not open maps.');
    }
  }

  String get _shareText {
    final where = _r.mapsUrl ?? 'location not available';
    return 'EMERGENCY (${_a.severity}): ${_r.description}\n'
        'My location: $where'
        '${_r.placeLabel != null ? ' (${_r.placeLabel})' : ''}';
  }

  Future<void> _shareSms() async {
    final to = ProfileStore.instance.emergencyContact;
    final uri = Uri.parse('sms:$to?body=${Uri.encodeComponent(_shareText)}');
    var ok = false;
    try {
      ok = await launchUrl(uri);
    } catch (_) {}
    if (!ok) {
      await Clipboard.setData(ClipboardData(text: _shareText));
      _toast('Message copied – paste it in any chat app.');
    }
  }

  Future<void> _toggleSpeak() async {
    if (_speaking) {
      await _tts.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    final steps = _a.recommendations
        .asMap()
        .entries
        .map((e) => 'Step ${e.key + 1}. ${e.value}')
        .join(' ');
    final first = _recommended.isNotEmpty
        ? 'Call ${_recommended.first.name}, number ${_recommended.first.phone.split('').join(' ')}.'
        : '';
    setState(() => _speaking = true);
    await _tts.speak('This is a ${_a.severity} emergency. $first $steps');
  }

  List<ResponseService> get _recommended {
    final rec = _res.services.where((s) => s.recommended).toList();
    return rec.isNotEmpty ? rec : _res.services.take(2).toList();
  }

  // -------------------------------------------------------------------- UI
  @override
  Widget build(BuildContext context) {
    final a = _a;
    final color = AppColors.severityColor(a.severity);
    final urgent = a.severity == 'Critical' || a.severity == 'High';
    final top = _recommended.isNotEmpty ? _recommended.first : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Emergency'),
        actions: [
          if (_updating)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
        children: [
          if (_res.offline) _offlineBanner(),
          _severityCard(a, color),
          const SizedBox(height: 14),
          if (top != null)
            SizedBox(
              height: 64,
              child: ElevatedButton.icon(
                onPressed: () => _call(top.phone),
                icon: const Icon(Icons.call_rounded, size: 28),
                label: Text('CALL ${top.name.toUpperCase()}  ${top.phone}',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      urgent ? AppColors.severityCritical : AppColors.primary,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          const SectionTitle(title: 'Who should respond'),
          ..._recommended.map(_serviceTile),
          TextButton.icon(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ResponseServiceScreen(report: _r))),
            icon: const Icon(Icons.list_rounded),
            label: const Text('All services & request a responder'),
          ),
          const SectionTitle(title: 'Your location'),
          _locationCard(),
          if (a.recommendations.isNotEmpty) ...[
            SectionTitle(
              title: 'What to do now',
              actionText: _speaking ? 'Stop' : 'Read aloud',
              onAction: _toggleSpeak,
            ),
            _stepsCard(a),
          ],
          if (!_res.offline && !_r.isLocal) ...[
            const SectionTitle(title: 'Can you tell us more? (optional)'),
            _questionsCard(),
          ],
          if (_r.inputMode == 'voice' &&
              _r.description.isNotEmpty &&
              !_r.isLocal) ...[
            const SectionTitle(title: 'What we understood'),
            _voiceCard(),
          ],
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => EmergencyStatusScreen(report: _r))),
            icon: const Icon(Icons.timeline_rounded),
            label: const Text('Track help  •  I am safe now'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _offlineBanner() => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.severityHighSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: AppColors.severityHigh),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No connection to the Ceylon Path server. This is an estimate '
                'on your phone – please CALL a number below.',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

  Widget _severityCard(AssessmentResult a, Color color) {
    final typeLabel = (a.predictedType == null || a.predictedType == 'other')
        ? 'Emergency'
        : EmergencyType.byId(a.predictedType!).label;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.severitySoftColor(a.severity),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(EmergencyType.byId(a.predictedType ?? 'other').icon,
                  color: color, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${a.severity.toUpperCase()} SEVERITY',
                        style: TextStyle(
                            color: color,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .5)),
                    Text(typeLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                  ],
                ),
              ),
              Text('${a.score}',
                  style: TextStyle(
                      color: color, fontSize: 30, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          Text(a.summary, style: const TextStyle(fontSize: 13.5, height: 1.35)),
          if (a.adjustments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Why: ${a.adjustments.join('; ')}',
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 6),
          Text(
            switch (a.method) {
              'ml' => 'Assessed by the AI model'
                  '${a.confidence != null ? ' (${a.confidence}% sure)' : ''}',
              'offline' => 'Estimated on your phone (offline)',
              _ => 'Assessed by safety rules',
            },
            style: const TextStyle(
                fontSize: 11.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _serviceTile(ResponseService s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: AppTheme.card(),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: const BoxDecoration(
                color: AppColors.primarySoft, shape: BoxShape.circle),
            child: Icon(s.icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14.5)),
                Text(
                  [
                    ResponseService.typeLabels[s.type] ?? s.type,
                    if (s.distanceKm > 0)
                      '${s.distanceKm.toStringAsFixed(1)} km',
                  ].join(' • '),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: s.phone.isEmpty ? null : () => _call(s.phone),
            icon: const Icon(Icons.call_rounded, size: 18),
            label: Text(s.phone),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.severityLow,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationCard() {
    final r = _r;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                  r.hasLocation
                      ? Icons.location_on_rounded
                      : Icons.location_off_rounded,
                  color: r.hasLocation
                      ? AppColors.primary
                      : AppColors.severityHigh),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.hasLocation
                          ? (r.placeLabel != null
                              ? 'GPS sent – ${r.placeLabel}'
                              : 'GPS location sent')
                          : 'GPS location not available',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      r.hasLocation
                          ? '${r.latitude!.toStringAsFixed(5)}, ${r.longitude!.toStringAsFixed(5)}'
                              '${r.locationAccuracy != null ? '  ±${r.locationAccuracy!.toStringAsFixed(0)} m' : ''}'
                          : 'Tell us a landmark below, or say it on the phone.',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (r.address.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Landmark: ${r.address}',
                style: const TextStyle(fontSize: 12.5)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (r.hasLocation) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openMap,
                    icon: const Icon(Icons.map_rounded, size: 18),
                    label: const Text('Map'),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareSms,
                  icon: const Icon(Icons.sms_rounded, size: 18),
                  label: Text(ProfileStore.instance.emergencyContact.isNotEmpty
                      ? 'Send to my contact'
                      : 'Share by SMS'),
                ),
              ),
            ],
          ),
          if (!_res.offline && !r.isLocal) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _landmarkCtrl,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendLandmark(),
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Add a landmark (optional)',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _sendLandmark,
                  icon: const Icon(Icons.send_rounded,
                      color: AppColors.primary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _sendLandmark() async {
    final t = _landmarkCtrl.text.trim();
    if (t.isEmpty) return;
    FocusScope.of(context).unfocus();
    _landmarkCtrl.clear();
    await _sendDetails({'address': t});
  }

  Widget _stepsCard(AssessmentResult a) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.card(),
      child: Column(
        children: [
          for (var i = 0; i < a.recommendations.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primary,
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(a.recommendations[i],
                          style: const TextStyle(height: 1.4))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _questionsCard() {
    // (key, question, value that means "more serious")
    const qs = [
      ('is_conscious', 'Is the person awake?', false),
      ('is_breathing_normally', 'Breathing normally?', false),
      ('has_heavy_bleeding', 'Heavy bleeding?', true),
      ('is_in_danger', 'Still in danger now?', true),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      decoration: AppTheme.card(),
      child: Column(
        children: [
          for (final q in qs)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                      child: Text(q.$2,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600))),
                  _choice('Yes', q.$1, true, q.$3 == true),
                  const SizedBox(width: 6),
                  _choice('No', q.$1, false, q.$3 == false),
                ],
              ),
            ),
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              'Skip these if you cannot answer – help is already being found.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _choice(String label, String key, bool value, bool serious) {
    final selected = _answers[key] == value;
    final c = serious ? AppColors.severityCritical : AppColors.primary;
    return GestureDetector(
      onTap: _updating ? null : () => _answer(key, value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }

  Widget _voiceCard() {
    final r = _r;
    final translated = r.voiceLanguage != null &&
        r.voiceLanguage != 'English' &&
        (r.originalVoiceText ?? '').isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.record_voice_over_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(translated
                  ? 'You spoke ${r.voiceLanguage} – translated'
                  : 'Your voice message'),
            ],
          ),
          if (translated) ...[
            const SizedBox(height: 6),
            Text('“${r.originalVoiceText}”',
                style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 6),
          Text(r.description, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
