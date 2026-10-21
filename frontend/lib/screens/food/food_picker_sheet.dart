import 'package:flutter/material.dart';

import '../../models/scan_result.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// Bottom sheet listing all dishes in the database. Returns the chosen food key.
Future<String?> showFoodPicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const _FoodPicker(),
  );
}

class _FoodPicker extends StatefulWidget {
  const _FoodPicker();

  @override
  State<_FoodPicker> createState() => _FoodPickerState();
}

class _FoodPickerState extends State<_FoodPicker> {
  List<FoodInfo> _all = [];
  String _query = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    ApiService.instance.getFoods().then((f) {
      if (mounted) setState(() => _all = f);
    }).catchError((Object e) {
      if (mounted) setState(() => _error = e.toString());
    }).whenComplete(() {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final items = _all.where((f) => f.name.toLowerCase().contains(q)).toList();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(children: [
        const SizedBox(height: 10),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search Sri Lankan dishes',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _error != null
                  ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(_error!)))
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) => ListTile(
                        title: Text(items[i].name),
                        subtitle: Text(items[i].category),
                        trailing: Icon(Icons.circle,
                            size: 10, color: items[i].vegetarian ? AppColors.success : AppColors.accent),
                        onTap: () => Navigator.pop(context, items[i].key),
                      ),
                    ),
        ),
      ]),
    );
  }
}
