import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../models/emergency_report.dart';
import '../services/emergency_api_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_title.dart';
import '../widgets/report_tile.dart';
import 'response_service_screen.dart';

class EmergencyStatusScreen extends StatefulWidget {
  final EmergencyReport report;
  const EmergencyStatusScreen({super.key, required this.report});

  @override
  State<EmergencyStatusScreen> createState() => _EmergencyStatusScreenState();
}

class _EmergencyStatusScreenState extends State<EmergencyStatusScreen> {
  late EmergencyReport _report;
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _report = widget.report;
    // Poll the backend every 10 s for status updates from the admin dashboard.
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_report.status == EmergencyStatus.resolved) {
      _timer?.cancel();
      return;
    }
    final r = await EmergencyApiService.instance.getReport(_report);
    if (mounted) setState(() => _report = r);
  }

  Future<void> _markSafe() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as safe?'),
        content: const Text(
            'This will close the emergency and notify responders that help is no longer needed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes, I am safe',
                  style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _closing = true);
    final r = await EmergencyApiService.instance.cancelReport(_report);
    if (!mounted) return;
    setState(() {
      _report = r;
      _closing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = EmergencyStatus.flow.indexOf(_report.status);
    final s = _report.assignedService;
    final resolved = _report.status == EmergencyStatus.resolved;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Status'),
        actions: [
          IconButton(
              onPressed: _refresh, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          children: [
            // Summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.card(radius: 20),
              child: Row(
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: const BoxDecoration(
                        color: AppColors.primarySoft, shape: BoxShape.circle),
                    child: Icon(_report.type.icon,
                        color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_report.type.label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(
                          _report.id != null
                              ? 'Ref: ${_shortId(_report.id!)}'
                              : 'Not yet saved',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  SeverityChip(
                      severity: _report.assessment?.severity ?? 'Low'),
                ],
              ),
            ),
            const SectionTitle(title: 'Progress'),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              decoration: AppTheme.card(),
              child: Column(
                children: List.generate(EmergencyStatus.flow.length, (i) {
                  final done = i <= currentIndex;
                  final isLast = i == EmergencyStatus.flow.length - 1;
                  return _timelineRow(
                    EmergencyStatus.label(EmergencyStatus.flow[i]),
                    done: done,
                    current: i == currentIndex,
                    isLast: isLast,
                  );
                }),
              ),
            ),
            const SectionTitle(title: 'Assigned responder'),
            if (s != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: AppTheme.card(),
                child: Row(
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                      child: Icon(s.icon, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800)),
                          Text('ETA ~${s.etaMinutes} min • ${s.phone}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      onPressed: () =>
                          launchUrl(Uri(scheme: 'tel', path: s.phone)),
                      style: IconButton.styleFrom(
                          backgroundColor: AppColors.severityLow),
                      icon: const Icon(Icons.call_rounded, color: Colors.white),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.card(),
                child: Column(
                  children: [
                    const Text('No responder assigned yet.',
                        style: TextStyle(color: AppColors.textSecondary)),
                    if (!resolved) ...[
                      const SizedBox(height: 10),
                      PrimaryButton(
                        label: 'Choose a responder',
                        icon: Icons.near_me_rounded,
                        outlined: true,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ResponseServiceScreen(report: _report)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (_report.hasLocation || _report.address.isNotEmpty) ...[
              const SectionTitle(title: 'Reported location'),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: AppTheme.card(),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        [
                          if (_report.address.isNotEmpty) _report.address,
                          if (_report.hasLocation)
                            '${_report.latitude!.toStringAsFixed(5)}, ${_report.longitude!.toStringAsFixed(5)}',
                        ].join('\n'),
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 26),
            if (!resolved)
              PrimaryButton(
                label: 'I am safe now – close emergency',
                icon: Icons.verified_user_rounded,
                color: AppColors.severityLow,
                loading: _closing,
                onPressed: _markSafe,
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.severityLowSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.severityLow),
                    SizedBox(width: 8),
                    Text('This emergency is resolved',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.severityLow)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _shortId(String id) =>
      id.length > 8 ? id.substring(id.length - 8).toUpperCase() : id;

  Widget _timelineRow(String label,
      {required bool done, required bool current, required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                height: 24,
                width: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.primary : AppColors.surface,
                  border: Border.all(
                      color: done ? AppColors.primary : AppColors.border,
                      width: 2),
                ),
                child: done
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: done ? AppColors.primary : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 18),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                  color: done ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
