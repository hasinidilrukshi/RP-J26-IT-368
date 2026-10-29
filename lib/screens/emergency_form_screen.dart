import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../models/emergency_report.dart';
import '../widgets/emergency_type_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_title.dart';
import '../widgets/voice_recorder_button.dart';
import 'location_screen.dart';

class EmergencyFormScreen extends StatefulWidget {
  final String initialType;
  final bool startWithVoice;
  const EmergencyFormScreen({
    super.key,
    this.initialType = 'other',
    this.startWithVoice = false,
  });

  @override
  State<EmergencyFormScreen> createState() => _EmergencyFormScreenState();
}

class _EmergencyFormScreenState extends State<EmergencyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final EmergencyReport _report;

  final _descCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  TranscriptionResult? _voice;

  void _onVoice(TranscriptionResult r) {
    setState(() {
      _voice = r;
      _descCtrl.text = r.text;
      _report
        ..inputMode = 'voice'
        ..audioId = r.audioId
        ..voiceLanguage = r.languageName
        ..originalVoiceText = r.originalText;
      if (_report.emergencyType == 'other' &&
          r.previewType != null &&
          EmergencyType.all.any((t) => t.id == r.previewType)) {
        _report.emergencyType = r.previewType!;
      }
    });
  }

  Widget _voiceBanner(TranscriptionResult r) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.record_voice_over_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r.wasTranslated
                      ? 'Heard in ${r.languageName} · translated to English'
                      : 'Voice note understood (${r.duration.toStringAsFixed(0)} s)',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
          if (r.wasTranslated) ...[
            const SizedBox(height: 6),
            Text('“${r.originalText}”',
                style: const TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 6),
          const Text('Check the text below and fix anything that is wrong.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _report = EmergencyReport(emergencyType: widget.initialType);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    _report
      ..description = _descCtrl.text.trim()
      ..touristName = _nameCtrl.text.trim()
      ..phone = _phoneCtrl.text.trim()
      ..nationality = _countryCtrl.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LocationScreen(report: _report)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Emergency')),
      body: Form(
        key: _formKey,
        // SingleChildScrollView (not ListView) so every field is built and validated.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _StepIndicator(step: 1),
            const SectionTitle(title: '1. Tell us what happened'),
            VoiceRecorderButton(
              autoStart: widget.startWithVoice,
              onResult: _onVoice,
            ),
            if (_voice != null) ...[
              const SizedBox(height: 10),
              _voiceBanner(_voice!),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('or type your message',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ),
                  Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
            ),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText:
                    'e.g. My husband collapsed near Hakgala Gardens and is not breathing properly',
              ),
              validator: (v) => (v == null || v.trim().length < 10)
                  ? 'Please describe the situation in a few words'
                  : null,
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 16, color: AppColors.primary),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Our AI reads this message to judge how serious it is. Write in your own words.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SectionTitle(title: '2. Type of emergency'),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,
              children: EmergencyType.all
                  .map((t) => EmergencyTypeCard(
                        type: t,
                        selected: _report.emergencyType == t.id,
                        onTap: () =>
                            setState(() => _report.emergencyType = t.id),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 6),
            const Text(
              'Not sure? Choose "Not sure" and the AI will detect the type.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SectionTitle(title: '3. Condition of the person'),
            Container(
              decoration: AppTheme.card(),
              child: Column(
                children: [
                  _yesNo(
                    'Is the person conscious?',
                    Icons.visibility_rounded,
                    _report.isConscious,
                    (v) => setState(() => _report.isConscious = v),
                  ),
                  _divider(),
                  _yesNo(
                    'Breathing normally?',
                    Icons.air_rounded,
                    _report.isBreathingNormally,
                    (v) => setState(() => _report.isBreathingNormally = v),
                  ),
                  _divider(),
                  _yesNo(
                    'Heavy bleeding?',
                    Icons.bloodtype_rounded,
                    _report.hasHeavyBleeding,
                    (v) => setState(() => _report.hasHeavyBleeding = v),
                  ),
                  _divider(),
                  _yesNo(
                    'Still in immediate danger?',
                    Icons.warning_amber_rounded,
                    _report.isInDanger,
                    (v) => setState(() => _report.isInDanger = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              decoration: AppTheme.card(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sentiment_very_dissatisfied_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('Pain level',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      Text('${_report.painLevel} / 10',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _painColor(_report.painLevel))),
                    ],
                  ),
                  Slider(
                    value: _report.painLevel.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    activeColor: _painColor(_report.painLevel),
                    onChanged: (v) =>
                        setState(() => _report.painLevel = v.round()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: AppTheme.card(),
              child: Row(
                children: [
                  const Icon(Icons.groups_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('People affected',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    onPressed: _report.peopleAffected > 1
                        ? () => setState(() => _report.peopleAffected--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    color: AppColors.primary,
                  ),
                  Text('${_report.peopleAffected}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  IconButton(
                    onPressed: () => setState(() => _report.peopleAffected++),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SectionTitle(title: '4. Your contact details'),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Full name',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'Phone number (e.g. +94 77 123 4567)',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
              validator: (v) => (v == null || v.trim().length < 7)
                  ? 'Enter a valid phone number'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _countryCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Nationality (optional)',
                prefixIcon: Icon(Icons.flag_rounded),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Next: Confirm Location',
              icon: Icons.location_on_rounded,
              onPressed: _next,
            ),
          ],
          ),
        ),
      ),
    );
  }

  Color _painColor(int p) => p >= 8
      ? AppColors.severityCritical
      : p >= 5
          ? AppColors.severityHigh
          : p >= 3
              ? AppColors.severityMedium
              : AppColors.severityLow;

  Widget _divider() =>
      const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.border);

  Widget _yesNo(
      String q, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(q,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          _choice('Yes', value, () => onChanged(true)),
          const SizedBox(width: 6),
          _choice('No', !value, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _choice(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}

/// Small 3-step progress bar: Details -> Location -> Assessment
class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) => StepProgress(step: step);
}

class StepProgress extends StatelessWidget {
  final int step; // 1..3
  const StepProgress({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    const labels = ['Details', 'Location', 'Assessment'];
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: List.generate(3, (i) {
          final active = i < step;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(labels[i],
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: active
                              ? AppColors.primary
                              : AppColors.textSecondary)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
