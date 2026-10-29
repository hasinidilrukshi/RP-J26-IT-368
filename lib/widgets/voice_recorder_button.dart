import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../models/emergency_report.dart';
import '../services/emergency_api_service.dart';

enum _VoiceState { idle, recording, processing }

/// Tap to record a voice note -> sent to Whisper on the backend ->
/// returns the English transcript through [onResult].
class VoiceRecorderButton extends StatefulWidget {
  final ValueChanged<TranscriptionResult> onResult;
  final bool autoStart;
  final int maxSeconds;

  const VoiceRecorderButton({
    super.key,
    required this.onResult,
    this.autoStart = false,
    this.maxSeconds = 60,
  });

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  late final AnimationController _pulse;
  _VoiceState _state = _VoiceState.idle;
  Timer? _timer;
  int _seconds = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    if (kIsWeb) {
      setState(() => _error =
          'Voice SOS works in the mobile app. In the browser, please type your message.');
      return;
    }
    if (!await _recorder.hasPermission()) {
      setState(() => _error = 'Microphone permission is needed to record.');
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/sos_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
            encoder: AudioEncoder.aacLc, sampleRate: 16000, numChannels: 1),
        path: path,
      );
    } catch (e) {
      setState(() => _error = 'Could not start the microphone. Please type your message.');
      return;
    }
    _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds++);
      if (_seconds >= widget.maxSeconds) _stop();
    });
    _pulse.repeat(reverse: true);
    setState(() => _state = _VoiceState.recording);
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _pulse.stop();
    final path = await _recorder.stop();
    if (path == null || _seconds < 1) {
      setState(() {
        _state = _VoiceState.idle;
        _error = 'Recording was too short. Hold on and speak clearly.';
      });
      return;
    }
    setState(() => _state = _VoiceState.processing);
    try {
      final result = await EmergencyApiService.instance.transcribe(path);
      widget.onResult(result);
    } on VoiceException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not process the voice note. Please type your message.';
    } finally {
      // The temp file is cleaned up by the OS.
      if (mounted) setState(() => _state = _VoiceState.idle);
    }
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    _pulse.stop();
    await _recorder.cancel();
    setState(() => _state = _VoiceState.idle);
  }

  String get _time =>
      '0:${_seconds.toString().padLeft(2, '0')} / 0:${widget.maxSeconds.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final recording = _state == _VoiceState.recording;
    final processing = _state == _VoiceState.processing;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.card(),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: processing ? null : (recording ? _stop : _start),
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) => Container(
                    height: 64,
                    width: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: recording
                          ? AppColors.severityCritical
                          : AppColors.primary,
                      boxShadow: recording
                          ? [
                              BoxShadow(
                                color: const Color(0x55C62828),
                                blurRadius: 10 + 14 * _pulse.value,
                                spreadRadius: 2 + 6 * _pulse.value,
                              )
                            ]
                          : const [],
                    ),
                    child: child,
                  ),
                  child: processing
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : Icon(
                          recording ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 32),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recording
                          ? 'Listening… tap to stop'
                          : processing
                              ? 'Understanding your voice…'
                              : 'Speak instead of typing',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      recording
                          ? _time
                          : processing
                              ? 'Converting speech to text with AI'
                              : 'Any language – we translate it for responders',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (recording)
                IconButton(
                  tooltip: 'Cancel',
                  onPressed: _cancel,
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                ),
            ],
          ),
          if (recording) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _seconds / widget.maxSeconds,
                minHeight: 4,
                color: AppColors.severityCritical,
                backgroundColor: AppColors.border,
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.info_rounded,
                    size: 16, color: AppColors.severityHigh),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(_error!,
                        style: const TextStyle(fontSize: 12.5))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
