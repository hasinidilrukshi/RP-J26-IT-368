import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/scan_result.dart';
import '../../services/api_service.dart';
import '../../services/user_session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/food_widgets.dart';
import 'food_picker_sheet.dart';
import 'recommendation_screen.dart';

/// Screen 5 – AI result: identified dish, confidence and likely ingredients.
class FoodAnalysisScreen extends StatefulWidget {
  final ScanResult scan;
  final Uint8List? imageBytes;
  const FoodAnalysisScreen({super.key, required this.scan, this.imageBytes});

  @override
  State<FoodAnalysisScreen> createState() => _FoodAnalysisScreenState();
}

class _FoodAnalysisScreenState extends State<FoodAnalysisScreen> {
  late ScanResult _scan;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _scan = widget.scan;
  }

  /// "Not this dish?" – re-evaluate the scan with the dish the user chose.
  Future<void> _correct(String foodKey) async {
    setState(() => _busy = true);
    try {
      final s = UserSession.instance;
      await s.ensureUser();
      final updated =
          await ApiService.instance.evaluateFood(userId: s.userId!, foodKey: foodKey, scanId: _scan.scanId);
      if (mounted) setState(() => _scan = updated);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseManually() async {
    final key = await showFoodPicker(context);
    if (key != null) _correct(key);
  }

  @override
  Widget build(BuildContext context) {
    final food = _scan.food;
    final rec = _scan.recommendation;
    final alternatives = _scan.detection?.alternatives ?? [];
    final conf = _scan.confidence;

    return Scaffold(
      appBar: AppBar(title: const Text('Food Analysis')),
      body: Stack(children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            FoodImage(bytes: widget.imageBytes, url: _scan.imageUrl, height: 190),
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(
                child: Text(_scan.recognized ? _scan.displayName : 'Unknown dish',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              ),
              if (_scan.recognized && conf > 0)
                Pill('${(conf * 100).round()}% confidence',
                    color: AppColors.textDark, background: AppColors.greyTint),
            ]),
            if (food != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(food.category, style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
              ),
            const SizedBox(height: 12),
            if (_scan.recognized)
              SectionCard(
                color: AppColors.successTint,
                borderColor: const Color(0xFFC8E6C9),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: const Row(children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  SizedBox(width: 10),
                  Text('Food identified successfully',
                      style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                ]),
              )
            else
              SectionCard(
                color: AppColors.amberTint,
                borderColor: const Color(0xFFF7D9A8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("We couldn't identify this dish",
                      style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFB26A00))),
                  const SizedBox(height: 4),
                  const Text('Try a clearer photo, or choose the dish from the list.',
                      style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
                  const SizedBox(height: 10),
                  OutlinedButton(onPressed: _chooseManually, child: const Text('Choose dish manually')),
                ]),
              ),
            if (rec != null) ...[
              const SizedBox(height: 18),
              const SectionTitle('Likely Ingredients'),
              SectionCard(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                child: Column(
                  children: [
                    for (var i = 0; i < rec.ingredients.length; i++) ...[
                      _IngredientRow(rec.ingredients[i]),
                      if (i < rec.ingredients.length - 1) const Divider(height: 1, color: AppColors.border),
                    ],
                  ],
                ),
              ),
            ],
            if (_scan.recognized) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                const Text('Not this dish?', style: TextStyle(fontSize: 12.5, color: AppColors.textGrey)),
                ...alternatives.map((a) => ActionChip(
                      label: Text(a.name, style: const TextStyle(fontSize: 12)),
                      onPressed: () => _correct(a.label),
                    )),
                ActionChip(
                  avatar: const Icon(Icons.search, size: 16),
                  label: const Text('Choose', style: TextStyle(fontSize: 12)),
                  onPressed: _chooseManually,
                ),
              ]),
            ],
            const SizedBox(height: 20),
            if (rec != null)
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => RecommendationScreen(scan: _scan, imageBytes: widget.imageBytes),
                )),
                child: const Text('Check My Compatibility'),
              ),
          ],
        ),
        if (_busy)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x66FFFFFF),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
          ),
      ]),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final IngredientFlag item;
  const _IngredientRow(this.item);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.amberTint, borderRadius: BorderRadius.circular(8)),
            child: Text(ingredientEmoji(item.name), style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name, style: const TextStyle(fontSize: 14.5, color: AppColors.textDark)),
              if (item.note != null)
                Text(item.note!, style: const TextStyle(fontSize: 11.5, color: AppColors.accent)),
            ]),
          ),
          Icon(item.conflict ? Icons.cancel : Icons.check,
              color: item.conflict ? AppColors.accent : AppColors.success, size: 20),
        ]),
      );
}
