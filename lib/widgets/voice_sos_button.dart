import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../core/app_colors.dart';

/// Big round button: TAP = start talking, TAP AGAIN = send.
/// Stops and sends by itself after [maxSeconds].
/// The recorded file path is given to [onRecorded].
class VoiceSosButton extends StatefulWidget {
  final ValueChanged<String> onRecorded;
  final ValueChanged<String> onError;
  final bool enabled;
  final int maxSeconds;

  const VoiceSosButton({
    super.key,
    required this.onRecorded,
    required this.onError,
    this.enabled = true,
    this.maxSeconds = 30,
  });

  @override
  State<VoiceSosButton> createState() => _VoiceSosButtonState();
}

class _VoiceSosButtonState extends State<VoiceSosButton>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  late final AnimationController _pulse;
  Timer? _timer;
  int _seconds = 0;
  bool _recording = false;
  bool _busy = false; // starting / stopping

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (kIsWeb) {
      widget.onError('Voice SOS works in the mobile app. Please type instead.');
      return;
    }
    setState(() => _busy = true);
    try {
      if (!await _recorder.hasPermission()) {
        widget.onError('Please allow the microphone to use Voice SOS.');
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/sos_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
            encoder: AudioEncoder.aacLc, sampleRate: 16000, numChannels: 1),
        path: path,
      );
      _seconds = 0;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _seconds++);
        if (_seconds >= widget.maxSeconds) _stopAndSend();
      });
      _pulse.repeat(reverse: true);
      if (mounted) setState(() => _recording = true);
    } catch (_) {
      widget.onError('Could not start the microphone. Please type instead.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stopAndSend() async {
    if (!_recording) return;
    _timer?.cancel();
    _pulse.stop();
    setState(() {
      _recording = false;
      _busy = true;
    });
    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {
      path = null;
    }
    if (mounted) setState(() => _busy = false);
    if (path == null || _seconds < 1) {
      widget.onError('Too short. Tap the mic and speak for a few seconds.');
      return;
    }
    widget.onRecorded(path);
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    _pulse.stop();
    try {
      await _recorder.cancel();
    } catch (_) {}
    if (mounted) setState(() => _recording = false);
  }

  @override
  Widget build(BuildContext context) {
    final canTap = widget.enabled && !_busy;
    return Column(
      children: [
        Semantics(
          button: true,
          label: _recording ? 'Stop and send voice SOS' : 'Start voice SOS',
          child: GestureDetector(
            onTap: canTap ? (_recording ? _stopAndSend : _start) : null,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, child) => Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.enabled
                      ? AppColors.severityCritical
                      : AppColors.primaryLight,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x66C62828),
                      blurRadius: _recording ? 20 + 24 * _pulse.value : 22,
                      spreadRadius: _recording ? 4 + 14 * _pulse.value : 4,
                    ),
                  ],
                ),
                child: child,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _recording ? Icons.send_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 54,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _recording ? 'TAP TO SEND' : 'SPEAK',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_recording)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fiber_manual_record_rounded,
                  color: AppColors.severityCritical, size: 14),
              const SizedBox(width: 6),
              Text(
                'Listening… 0:${_seconds.toString().padLeft(2, '0')} '
                '(sends by itself at 0:${widget.maxSeconds})',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextButton(onPressed: _cancel, child: const Text('Cancel')),
            ],
          )
        else
          const Text(
            'Tap and say what happened – any language',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
      ],
    );
  }
}
