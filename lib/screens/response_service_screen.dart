import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../models/emergency_report.dart';
import '../services/emergency_api_service.dart';
import '../widgets/section_title.dart';
import 'emergency_status_screen.dart';

class ResponseServiceScreen extends StatefulWidget {
  final EmergencyReport report;
  const ResponseServiceScreen({super.key, required this.report});

  @override
  State<ResponseServiceScreen> createState() => _ResponseServiceScreenState();
}

class _ResponseServiceScreenState extends State<ResponseServiceScreen> {
  late Future<List<ResponseService>> _future;
  String? _dispatchingId;

  @override
  void initState() {
    super.initState();
    _future = EmergencyApiService.instance.getNearbyServices(widget.report);
  }

  Future<void> _call(String phone) async {
    final ok = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not call $phone')));
    }
  }

  Future<void> _request(ResponseService s) async {
    setState(() => _dispatchingId = s.id);
    final updated =
        await EmergencyApiService.instance.dispatchService(widget.report, s);
    if (!mounted) return;
    setState(() => _dispatchingId = null);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (_) => EmergencyStatusScreen(report: updated)),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rec = widget.report.assessment?.recommendedServices ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Response Services')),
      body: FutureBuilder<List<ResponseService>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final services = snap.data ?? [];
          final recommended =
              services.where((s) => rec.contains(s.type)).toList();
          final others =
              services.where((s) => !rec.contains(s.type)).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
            children: [
              _infoBanner(),
              if (recommended.isNotEmpty) ...[
                const SectionTitle(title: 'Recommended for you'),
                ...recommended.map((s) => _serviceCard(s, highlight: true)),
              ],
              if (others.isNotEmpty) ...[
                const SectionTitle(title: 'Other services'),
                ...others.map((s) => _serviceCard(s)),
              ],
              if (services.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: Text('No services found nearby.')),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoBanner() {
    final sev = widget.report.assessment?.severity ?? 'Low';
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.support_agent_rounded,
              color: Colors.white, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$sev severity ${widget.report.type.label.toLowerCase()} emergency.\n'
              'Request a responder or call them directly.',
              style: const TextStyle(color: Colors.white, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceCard(ResponseService s, {bool highlight = false}) {
    final busy = _dispatchingId == s.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.card().copyWith(
        border: Border.all(
          color: highlight ? AppColors.primary : AppColors.border,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: highlight ? AppColors.primary : AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(s.icon,
                    color: highlight ? Colors.white : AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(s.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (s.distanceKm > 0) ...[
                          const Icon(Icons.route_rounded,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text('${s.distanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 12),
                        ],
                        const Icon(Icons.schedule_rounded,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text('~${s.etaMinutes} min',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _call(s.phone),
                  icon: const Icon(Icons.call_rounded, size: 18),
                  label: Text(s.phone),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _dispatchingId != null ? null : () => _request(s),
                  icon: busy
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Request'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
