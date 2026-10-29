import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/emergency_report.dart';
import '../services/emergency_api_service.dart';
import 'emergency_status_screen.dart';
import '../widgets/report_tile.dart';

class EmergencyHistoryScreen extends StatefulWidget {
  const EmergencyHistoryScreen({super.key});

  @override
  State<EmergencyHistoryScreen> createState() => _EmergencyHistoryScreenState();
}

class _EmergencyHistoryScreenState extends State<EmergencyHistoryScreen> {
  final _phoneCtrl = TextEditingController();
  late Future<List<EmergencyReport>> _future;
  String _filter = 'All';

  static const _filters = ['All', 'Critical', 'High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _load() {
    _future = EmergencyApiService.instance
        .getHistory(phone: _phoneCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Reports')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => setState(_load),
              decoration: InputDecoration(
                hintText: 'Search by phone (empty = this phone)',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded,
                      color: AppColors.primary),
                  onPressed: () => setState(_load),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filters[i];
                final sel = f == _filter;
                return ChoiceChip(
                  label: Text(f),
                  selected: sel,
                  showCheckmark: false,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                      color: sel ? AppColors.primary : AppColors.border),
                  labelStyle: TextStyle(
                    color: sel ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _filter = f),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: FutureBuilder<List<EmergencyReport>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary));
                }
                var items = snap.data ?? [];
                if (_filter != 'All') {
                  items = items
                      .where((r) =>
                          (r.assessment?.severity ?? 'Low') == _filter)
                      .toList();
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    setState(_load);
                    await _future;
                  },
                  child: items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            Icon(Icons.history_rounded,
                                size: 56, color: AppColors.border),
                            SizedBox(height: 10),
                            Center(
                              child: Text('No reports found',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                          itemCount: items.length,
                          itemBuilder: (_, i) => ReportTile(
                            report: items[i],
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => EmergencyStatusScreen(
                                        report: items[i])),
                              );
                              if (mounted) setState(_load);
                            },
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
