import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/scan_result.dart';
import '../../theme/app_theme.dart';
import '../../widgets/food_widgets.dart';

/// Nutrition, possible benefits and considerations (health risks).
class NutritionScreen extends StatefulWidget {
  final ScanResult scan;
  final Uint8List? imageBytes;
  const NutritionScreen({super.key, required this.scan, this.imageBytes});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  int _grams = 100; // database values are per 100 g

  String _fmt(double v) => v >= 100 ? v.round().toString() : v.toStringAsFixed(1).replaceAll('.0', '');

  @override
  Widget build(BuildContext context) {
    final food = widget.scan.food!;
    final rec = widget.scan.recommendation;
    final n = food.nutrition;
    final f = _grams / 100.0;
    final considerations = <String>{...?rec?.personalRisks, ...food.healthConcerns}.toList();
    final benefits = rec?.benefits.isNotEmpty == true ? rec!.benefits : food.benefits;

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          FoodImage(bytes: widget.imageBytes, url: widget.scan.imageUrl, height: 140),
          const SizedBox(height: 12),
          Text(food.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SectionCard(
            borderColor: const Color(0xFFF3CDD2),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(
                  child: Text('Nutrition', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
                for (final g in const [100, 200, 300])
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text('${g}g', style: const TextStyle(fontSize: 11.5)),
                      selected: _grams == g,
                      selectedColor: AppColors.primaryTint,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => _grams = g),
                    ),
                  ),
              ]),
              const Divider(color: AppColors.border),
              _NutRow('🔥', 'Calories', '~${_fmt(n.calories * f)} kcal'),
              _NutRow('💪', 'Protein', '${_fmt(n.protein * f)} g'),
              _NutRow('🍚', 'Carbohydrates', '${_fmt(n.carbohydrates * f)} g'),
              _NutRow('💧', 'Fat', '${_fmt(n.fat * f)} g'),
              _NutRow('🍬', 'Sugar', '${_fmt(n.sugar * f)} g', last: true),
            ]),
          ),
          const SizedBox(height: 4),
          Text('Values for $_grams g (database is per ${n.serving}).',
              style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey)),
          const SizedBox(height: 14),
          _BulletCard(
            title: 'Possible Benefits',
            icon: Icons.eco,
            color: AppColors.success,
            tint: AppColors.successTint,
            items: benefits,
          ),
          const SizedBox(height: 12),
          _BulletCard(
            title: 'Considerations',
            icon: Icons.warning_rounded,
            color: AppColors.primary,
            tint: AppColors.accentTint,
            items: considerations,
          ),
        ],
      ),
    );
  }
}

class _NutRow extends StatelessWidget {
  final String emoji, label, value;
  final bool last;
  const _NutRow(this.emoji, this.label, this.value, {this.last = false});

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryTint,
              child: Text(emoji, style: const TextStyle(fontSize: 15)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
        ),
        if (!last) const Divider(height: 1, color: AppColors.border),
      ]);
}

class _BulletCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color, tint;
  final List<String> items;
  const _BulletCard(
      {required this.title, required this.icon, required this.color, required this.tint, required this.items});

  @override
  Widget build(BuildContext context) => SectionCard(
        color: tint,
        borderColor: color.withAlpha(60),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(radius: 16, backgroundColor: color, child: Icon(icon, color: Colors.white, size: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 6),
              if (items.isEmpty)
                const Text('None listed', style: TextStyle(color: AppColors.textGrey))
              else
                ...items.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('•  $t', style: const TextStyle(fontSize: 13.5, color: AppColors.textDark)),
                    )),
            ]),
          ),
        ]),
      );
}
