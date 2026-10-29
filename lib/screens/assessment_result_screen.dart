import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../models/emergency_report.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_title.dart';
import 'emergency_form_screen.dart' show StepProgress;
import 'response_service_screen.dart';

class AssessmentResultScreen extends StatelessWidget {
  final EmergencyReport report;
  const AssessmentResultScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final a = report.assessment ??
        const AssessmentResult(
          severity: 'Low',
          score: 0,
          summary: 'No assessment available.',
          recommendations: [],
          recommendedServices: [],
        );
    final color = AppColors.severityColor(a.severity);
    final critical = a.severity == 'Critical' || a.severity == 'High';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.popUntil(context, (r) => r.isFirst);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Severity Assessment'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
          children: [
            const StepProgress(step: 3),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: AppTheme.card(radius: 22),
              child: Column(
                children: [
                  SizedBox(
                    height: 130,
                    width: 230,
                    child: CustomPaint(
                      painter: _GaugePainter(a.score / 100, color),
                      child: Align(
                        alignment: const Alignment(0, 0.9),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${a.score}',
                                style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    color: color)),
                            const Text('Severity score',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.severitySoftColor(a.severity),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '${a.severity.toUpperCase()} SEVERITY',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(a.summary,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _ListenButton(result: a),
            const SectionTitle(title: 'AI analysis'),
            _AiCard(result: a, report: report),
            const SectionTitle(title: 'Recommended responders'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (a.authorities.isNotEmpty
                      ? a.authorities
                      : a.recommendedServices
                          .map((s) => ResponseService.typeLabels[s] ?? s)
                          .toList())
                  .map((label) => Chip(
                        avatar: const Icon(Icons.support_agent_rounded,
                            size: 18, color: AppColors.primary),
                        label: Text(label),
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.border),
                        labelStyle:
                            const TextStyle(fontWeight: FontWeight.w600),
                      ))
                  .toList(),
            ),
            const SectionTitle(title: 'What to do now'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.card(),
              child: Column(
                children: [
                  for (var i = 0; i < a.recommendations.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 24,
                            width: 24,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle),
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(a.recommendations[i],
                                  style: const TextStyle(height: 1.4))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            PrimaryButton(
              label: 'Find Nearby Responders',
              icon: Icons.near_me_rounded,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ResponseServiceScreen(report: report)),
              ),
            ),
            if (critical) ...[
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Call Ambulance 1990 Now',
                icon: Icons.call_rounded,
                color: AppColors.severityCritical,
                onPressed: () => launchUrl(Uri(scheme: 'tel', path: '1990')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Reads the response aloud (text-to-speech) – useful after a Voice SOS.
class _ListenButton extends StatefulWidget {
  final AssessmentResult result;
  const _ListenButton({required this.result});

  @override
  State<_ListenButton> createState() => _ListenButtonState();
}

class _ListenButtonState extends State<_ListenButton> {
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.45);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  String get _script {
    final a = widget.result;
    final steps = a.recommendations
        .asMap()
        .entries
        .map((e) => 'Step ${e.key + 1}. ${e.value}')
        .join(' ');
    final who = a.authorities.isNotEmpty
        ? 'Recommended help: ${a.authorities.join(', ')}.'
        : '';
    return 'This is a ${a.severity} severity emergency. $who $steps';
  }

  Future<void> _toggle() async {
    if (_speaking) {
      await _tts.stop();
      setState(() => _speaking = false);
    } else {
      setState(() => _speaking = true);
      await _tts.speak(_script);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: _speaking ? 'Stop reading' : 'Listen to instructions',
      icon: _speaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
      outlined: true,
      onPressed: _toggle,
    );
  }
}

/// Shows what the ML model detected from the tourist's message.
class _AiCard extends StatelessWidget {
  final AssessmentResult result;
  final EmergencyReport report;
  const _AiCard({required this.result, required this.report});

  @override
  Widget build(BuildContext context) {
    final a = result;
    final methodLabel = switch (a.method) {
      'ml' => 'NLP model',
      'offline' => 'Offline estimate',
      _ => 'Rule-based',
    };
    final methodColor =
        a.isMl ? AppColors.severityLow : AppColors.severityMedium;
    final typeLabel = a.predictedType != null
        ? EmergencyType.byId(a.predictedType!).label
        : (a.predictedTypeLabel ?? '—');

    Widget row(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13))),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13.5)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Assessed by',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.severitySoftColor(
                      a.isMl ? 'low' : 'medium'),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(methodLabel,
                    style: TextStyle(
                        color: methodColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.border),
          row(
              report.inputMode == 'voice'
                  ? Icons.record_voice_over_rounded
                  : Icons.keyboard_rounded,
              'Input',
              report.inputMode == 'voice'
                  ? 'Voice (${report.voiceLanguage ?? 'English'})'
                  : 'Typed message'),
          row(Icons.category_rounded, 'Detected type',
              a.typeConfidence != null
                  ? '$typeLabel (${a.typeConfidence}%)'
                  : typeLabel),
          if (a.confidence != null)
            row(Icons.speed_rounded, 'Severity confidence',
                '${a.confidence}%'),
          if (a.adjustments.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.severityHighSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Severity raised for safety: ${a.adjustments.join(', ')}.',
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value; // 0..1
  final Color color;
  _GaugePainter(this.value, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke,
        (size.width - stroke));
    final bg = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, bg);
    canvas.drawArc(rect, math.pi, math.pi * value.clamp(0.0, 1.0), false, fg);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value || old.color != color;
}
