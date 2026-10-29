import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../models/emergency_report.dart';
import '../services/emergency_api_service.dart';
import '../widgets/emergency_type_card.dart';
import '../widgets/section_title.dart';
import 'emergency_form_screen.dart';
import 'emergency_history_screen.dart';
import 'emergency_status_screen.dart';

/// Emergency hub (opened from the "SOS" tab of the Ceylon Path app).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<EmergencyReport>> _recent;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _recent = EmergencyApiService.instance.getHistory();
  }

  Future<void> _openForm([String type = 'other', bool voice = false]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              EmergencyFormScreen(initialType: type, startWithVoice: voice)),
    );
    if (mounted) setState(_load);
  }

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not call $number')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          setState(_load);
          await _recent;
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _header(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _sosButton(),
                  const SizedBox(height: 12),
                  _voiceButton(),
                  const SectionTitle(title: 'What happened?'),
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
                              onTap: () => _openForm(t.id),
                            ))
                        .toList(),
                  ),
                  const SectionTitle(title: 'Emergency Hotlines'),
                  _hotlines(),
                  SectionTitle(
                    title: 'Recent Reports',
                    actionText: 'View all',
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EmergencyHistoryScreen()),
                    ),
                  ),
                  _recentList(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 28),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          if (Navigator.canPop(context))
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
            ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ceylon Path',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('Emergency Help',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text('We assess your situation and connect you to help fast.',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5)),
              ],
            ),
          ),
          Container(
            height: 52,
            width: 52,
            decoration: const BoxDecoration(
                color: Color(0x33FFFFFF), shape: BoxShape.circle),
            child: const Icon(Icons.health_and_safety_rounded,
                color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _sosButton() {
    return GestureDetector(
      onTap: () => _openForm(),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.card(radius: 20),
        child: Row(
          children: [
            Container(
              height: 76,
              width: 76,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.severityCritical,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x55C62828),
                      blurRadius: 18,
                      spreadRadius: 4),
                ],
              ),
              alignment: Alignment.center,
              child: const Text('SOS',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: 1)),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Report an Emergency',
                      style: TextStyle(
                          fontSize: 16.5, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text(
                      'Tap to describe what happened. Our AI checks the severity and finds the right responder.',
                      style: TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _voiceButton() {
    return InkWell(
      onTap: () => _openForm('other', true),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.headerGradient,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            Icon(Icons.mic_rounded, color: Colors.white, size: 28),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Voice SOS',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                  SizedBox(height: 2),
                  Text('Just speak – any language',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
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

  Widget _recentList() {
    return FutureBuilder<List<EmergencyReport>>(
      future: _recent,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        final items = (snap.data ?? []).take(3).toList();
        if (items.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.card(),
            child: const Column(
              children: [
                Icon(Icons.verified_user_rounded,
                    color: AppColors.severityLow, size: 34),
                SizedBox(height: 8),
                Text('No emergencies reported. Stay safe!',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return Column(
          children: items
              .map((r) => ReportTile(
                    report: r,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EmergencyStatusScreen(report: r)),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

/// Shared list tile for a report (used on Home and History).
class ReportTile extends StatelessWidget {
  final EmergencyReport report;
  final VoidCallback onTap;

  const ReportTile({super.key, required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sev = report.assessment?.severity ?? 'Low';
    final d = report.createdAt;
    final date =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.card(),
          child: Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: const BoxDecoration(
                    color: AppColors.primarySoft, shape: BoxShape.circle),
                child: Icon(report.type.icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.type.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      '${EmergencyStatus.label(report.status)} • $date',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              SeverityChip(severity: sev),
            ],
          ),
        ),
      ),
    );
  }
}

class SeverityChip extends StatelessWidget {
  final String severity;
  const SeverityChip({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.severitySoftColor(severity),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        severity,
        style: TextStyle(
          color: AppColors.severityColor(severity),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
