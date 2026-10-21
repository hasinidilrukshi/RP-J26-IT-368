import 'package:flutter/material.dart';

import '../../models/scan_result.dart';
import '../../services/api_service.dart';
import '../../services/user_session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/food_widgets.dart';
import 'food_analysis_screen.dart';
import 'food_preferences_screen.dart';
import 'scan_food_screen.dart';
import 'scan_history_screen.dart';

/// Screen 2 – entry point of the food component.
class FoodHomeScreen extends StatefulWidget {
  const FoodHomeScreen({super.key});

  @override
  State<FoodHomeScreen> createState() => _FoodHomeScreenState();
}

class _FoodHomeScreenState extends State<FoodHomeScreen> {
  final session = UserSession.instance;
  List<ScanResult> _recent = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(firstTime: true);
  }

  Future<void> _load({bool firstTime = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await session.ensureUser();
      final scans = await ApiService.instance.getScans(session.userId!, limit: 5);
      if (!mounted) return;
      setState(() => _recent = scans);
      // Health profile is entered on setup (first use of the food module).
      if (firstTime && !session.profileCompleted) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _openPreferences(setup: true));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openPreferences({bool setup = false}) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => FoodPreferencesScreen(isSetup: setup)));
    if (mounted) setState(() {});
  }

  Future<void> _openScan() async {
    if (!session.profileCompleted) {
      await _openPreferences(setup: true);
      if (!session.profileCompleted) return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanFoodScreen()));
    _load();
  }

  Future<void> _openScanResult(ScanResult s) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => FoodAnalysisScreen(scan: s)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sri Lankan Food'),
        actions: [
          IconButton(
            tooltip: 'Scan history',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ScanHistoryScreen()))
                .then((_) => _load()),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _Banner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _ScanCard(onTap: _openScan),
                const SizedBox(height: 14),
                _ProfileCard(onTap: () => _openPreferences()),
                const SizedBox(height: 18),
                SectionTitle(
                  'Recent Scans',
                  trailing: TextButton(
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const ScanHistoryScreen()))
                        .then((_) => _load()),
                    child: const Text('View all', style: TextStyle(color: AppColors.textGrey, fontSize: 12.5)),
                  ),
                ),
                if (_loading && _recent.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  )
                else if (_error != null)
                  _ErrorBox(message: _error!, onRetry: _load)
                else if (_recent.isEmpty)
                  const SectionCard(
                    child: Text('No scans yet. Scan a street food dish to check if it suits you.',
                        style: TextStyle(color: AppColors.textGrey)),
                  )
                else
                  ..._recent.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ScanTile(scan: s, onTap: () => _openScanResult(s)),
                      )),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary, Color(0xFF9C2A1E)],
        ),
      ),
      child: Stack(children: [
        const Positioned(
          right: -10,
          bottom: -18,
          child: Text('🍛', style: TextStyle(fontSize: 120)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Taste the\nReal Sri Lanka',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic)),
            const Spacer(),
            Text('Local flavours  •  Rich culture  •  Safe to enjoy',
                style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}

class _ScanCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ScanCard({required this.onTap});

  @override
  Widget build(BuildContext context) => SectionCard(
        color: AppColors.primaryTint,
        borderColor: const Color(0xFFF3CDD2),
        onTap: onTap,
        child: Row(children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
            child: const Icon(Icons.photo_camera, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Scan Street Food',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              SizedBox(height: 4),
              Text("Identify food and check if it's suitable for your dietary needs.",
                  style: TextStyle(fontSize: 12.5, color: AppColors.textGrey)),
            ]),
          ),
          const Icon(Icons.chevron_right, color: AppColors.primary),
        ]),
      );
}

class _ProfileCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ProfileCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final session = UserSession.instance;
    final p = session.profile;
    final tags = p.summaryTags;
    return SectionCard(
      onTap: onTap,
      child: Row(children: [
        const CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primaryTint,
          child: Icon(Icons.person_pin, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Your Dietary Profile',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 4),
            if (!session.profileCompleted)
              const Text('Tap to set up allergies, diet and health conditions',
                  style: TextStyle(fontSize: 12.5, color: AppColors.accent))
            else ...[
              Text(
                  tags.isEmpty ? 'No dietary restrictions' : tags.join('  •  '),
                  style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600)),
              if (p.extraCount > 0)
                Text('+ ${p.extraCount} more (conditions / restrictions)',
                    style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
            ],
          ]),
        ),
        const Icon(Icons.chevron_right, color: AppColors.textGrey),
      ]),
    );
  }
}

/// A row in "Recent Scans" / history.
class ScanTile extends StatelessWidget {
  final ScanResult scan;
  final VoidCallback onTap;
  const ScanTile({super.key, required this.scan, required this.onTap});

  @override
  Widget build(BuildContext context) => SectionCard(
        padding: const EdgeInsets.all(10),
        onTap: onTap,
        child: Row(children: [
          FoodImage(url: scan.imageUrl, height: 64, width: 72, radius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(scan.displayName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: AppColors.textDark)),
              const SizedBox(height: 3),
              Text(formatScanTime(scan.createdAt),
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textGrey)),
              const SizedBox(height: 5),
              StatusBadge(scan.recommendation?.status),
            ]),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textGrey),
        ]),
      );
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => SectionCard(
        color: AppColors.accentTint,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(message, style: const TextStyle(color: AppColors.accent)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      );
}
