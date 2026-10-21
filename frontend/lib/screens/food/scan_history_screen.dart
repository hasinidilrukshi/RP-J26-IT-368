import 'package:flutter/material.dart';

import '../../models/scan_result.dart';
import '../../services/api_service.dart';
import '../../services/user_session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/food_widgets.dart';
import 'food_analysis_screen.dart';
import 'food_home_screen.dart';

/// All previous scans (swipe left to delete).
class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  List<ScanResult>? _scans;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = UserSession.instance;
      await s.ensureUser();
      final scans = await ApiService.instance.getScans(s.userId!, limit: 100);
      if (mounted) setState(() => _scans = scans);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _delete(ScanResult scan) async {
    setState(() => _scans!.remove(scan));
    try {
      await ApiService.instance.deleteScan(UserSession.instance.userId!, scan.scanId!);
    } catch (e) {
      if (mounted) {
        showError(context, e);
        _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_error != null) {
      body = Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));
    } else if (_scans == null) {
      body = const Center(child: CircularProgressIndicator(color: AppColors.primary));
    } else if (_scans!.isEmpty) {
      body = const Center(child: Text('No scans yet', style: TextStyle(color: AppColors.textGrey)));
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _scans!.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final s = _scans![i];
            return Dismissible(
              key: ValueKey(s.scanId),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) => _delete(s),
              child: ScanTile(
                scan: s,
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => FoodAnalysisScreen(scan: s)))
                    .then((_) => _load()),
              ),
            );
          },
        ),
      );
    }
    return Scaffold(appBar: AppBar(title: const Text('Scan History')), body: body);
  }
}
