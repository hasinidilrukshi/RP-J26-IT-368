import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../services/emergency_api_service.dart';
import '../services/location_service.dart';
import '../widgets/voice_sos_button.dart';
import 'emergency_history_screen.dart';
import 'profile_screen.dart';
import 'sos_result_screen.dart';

/// Main screen. The tourist only has to SPEAK, TYPE, or TAP one phrase.
/// No forms: location, type, severity and responders are worked out
/// automatically.
class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  final _textCtrl = TextEditingController();
  bool _sending = false;
  String _sendingText = '';

  /// One tap = SOS sent with this sentence.
  static const _quick = [
    ('Not breathing / unconscious', Icons.monitor_heart_rounded,
        'Someone is unconscious and not breathing properly'),
    ('Bad injury / bleeding', Icons.personal_injury_rounded,
        'Someone fell and is badly injured and bleeding a lot, cannot walk'),
    ('Someone drowning', Icons.pool_rounded,
        'Someone is drowning in the sea, I cannot see his head'),
    ('Wild animal attack', Icons.pets_rounded,
        'A wild animal attacked us, someone is injured'),
    ('Attacked / robbed', Icons.local_police_rounded,
        'I was attacked and robbed, the man had a knife'),
    ('I am lost', Icons.wrong_location_rounded,
        'I am lost and cannot find my way back, it is getting dark'),
  ];

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _call(String number) async {
    var ok = false;
    try {
      ok = await launchUrl(Uri(scheme: 'tel', path: number));
    } catch (_) {}
    if (!ok) _toast('Could not call $number – please dial it yourself.');
  }

  /// Send an SOS from typed text, a quick phrase, or a voice note.
  Future<void> _send({String? text, String? audioPath}) async {
    if (_sending) return;
    final message = (text ?? _textCtrl.text).trim();
    if (audioPath == null && message.length < 2) {
      _toast('Type a few words, tap a button above, or use the mic.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _sendingText =
          audioPath != null ? 'Understanding your voice…' : 'Getting help…';
    });

    try {
      // use the GPS fix we already have; wait a few seconds only if none yet
      final pos = await LocationService.instance.waitForFix();
      final res = await EmergencyApiService.instance.sendSos(
        message: audioPath != null ? _textCtrl.text : message,
        audioPath: audioPath,
        position: pos,
      );
      if (!mounted) return;
      _textCtrl.clear();
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SosResultScreen(initial: res)),
      );
    } on SosException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Something went wrong. Call 1990 (ambulance) or 119 (police).');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              _header(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _LocationChip(),
                    const SizedBox(height: 26),
                    Center(
                      child: VoiceSosButton(
                        enabled: !_sending,
                        onRecorded: (path) => _send(audioPath: path),
                        onError: _toast,
                      ),
                    ),
                    const SizedBox(height: 26),
                    _orDivider('or tap what happened'),
                    const SizedBox(height: 12),
                    _quickGrid(),
                    const SizedBox(height: 18),
                    _orDivider('or type'),
                    const SizedBox(height: 12),
                    _typeBox(),
                    const SizedBox(height: 24),
                    const Text('Call directly',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 10),
                    _hotlines(),
                  ],
                ),
              ),
            ],
          ),
          if (_sending) _sendingOverlay(),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 14, 8, 22),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ceylon Path',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text('Emergency SOS',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text('Say or type what happened. We find the right help.',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'My reports',
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const EmergencyHistoryScreen())),
            icon: const Icon(Icons.history_rounded, color: Colors.white),
          ),
          IconButton(
            tooltip: 'My details',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
            icon: const Icon(Icons.person_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _orDivider(String text) => Row(
        children: [
          const Expanded(child: Divider(color: AppColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary)),
          ),
          const Expanded(child: Divider(color: AppColors.border)),
        ],
      );

  Widget _quickGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: _quick.map((q) {
        return InkWell(
          onTap: _sending ? null : () => _send(text: q.$3),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: AppTheme.card(radius: 14),
            child: Row(
              children: [
                Icon(q.$2, color: AppColors.severityCritical, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(q.$1,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _typeBox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _textCtrl,
            minLines: 1,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            decoration: const InputDecoration(
              hintText: 'e.g. my friend fell at Ella Rock and can\'t walk',
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 52,
          width: 52,
          child: IconButton.filled(
            tooltip: 'Send SOS',
            onPressed: _sending ? null : () => _send(),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.severityCritical,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.send_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _hotlines() {
    const lines = [
      ('Ambulance', '1990', Icons.emergency_rounded),
      ('Police', '119', Icons.local_police_rounded),
      ('Tourist', '1912', Icons.badge_rounded),
      ('Fire', '110', Icons.fire_truck_rounded),
    ];
    return Row(
      children: lines.map((l) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => _call(l.$2),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: AppTheme.card(radius: 14),
                child: Column(
                  children: [
                    Icon(l.$3, color: AppColors.primary, size: 22),
                    const SizedBox(height: 6),
                    Text(l.$2,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    Text(l.$1,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _sendingOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xCC2B1A1A),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 56,
              width: 56,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 4),
            ),
            const SizedBox(height: 18),
            Text(_sendingText,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Sending your message and GPS location',
                style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

/// Shows the automatic GPS status. Tap to fix (turn on GPS / allow).
class _LocationChip extends StatelessWidget {
  const _LocationChip();

  @override
  Widget build(BuildContext context) {
    final loc = LocationService.instance;
    return ListenableBuilder(
      listenable: loc,
      builder: (context, _) {
        final ok = loc.hasFix;
        final searching =
            loc.status == LocationStatus.searching && !loc.hasFix;
        final color = ok
            ? AppColors.severityLow
            : searching
                ? AppColors.severityMedium
                : AppColors.severityHigh;
        return InkWell(
          onTap: ok ? null : loc.fix,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.severitySoftColor(ok
                  ? 'low'
                  : searching
                      ? 'medium'
                      : 'high'),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                if (searching)
                  SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: color),
                  )
                else
                  Icon(ok ? Icons.my_location_rounded : Icons.location_off_rounded,
                      size: 18, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(loc.statusText,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: color)),
                ),
                if (ok)
                  const Text('sent with SOS',
                      style: TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
        );
      },
    );
  }
}
