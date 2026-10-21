import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/scan_result.dart';
import '../../theme/app_theme.dart';
import '../../widgets/food_widgets.dart';

/// Typical ingredient breakdown with allergens and diet badges.
class IngredientsScreen extends StatelessWidget {
  final ScanResult scan;
  final Uint8List? imageBytes;
  const IngredientsScreen({super.key, required this.scan, this.imageBytes});

  @override
  Widget build(BuildContext context) {
    final food = scan.food!;
    final flags = scan.recommendation?.ingredients ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Ingredients')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          FoodImage(bytes: imageBytes, url: scan.imageUrl, height: 140),
          const SizedBox(height: 12),
          Text(food.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            Pill(food.vegetarian ? 'Vegetarian' : 'Non-vegetarian',
                color: food.vegetarian ? AppColors.success : AppColors.accent,
                background: food.vegetarian ? AppColors.successTint : AppColors.accentTint,
                icon: Icons.eco_outlined),
            Pill(food.vegan ? 'Vegan' : 'Not vegan',
                color: food.vegan ? AppColors.success : AppColors.textGrey,
                background: food.vegan ? AppColors.successTint : AppColors.greyTint),
            Pill(food.category, color: AppColors.textDark, background: AppColors.greyTint),
          ]),
          const SizedBox(height: 18),
          const SectionTitle('Typical Ingredients'),
          SectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(children: [
              for (final f in flags)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(ingredientEmoji(f.name), style: const TextStyle(fontSize: 22)),
                  title: Text(f.name),
                  subtitle: f.note == null
                      ? null
                      : Text(f.note!, style: const TextStyle(color: AppColors.accent, fontSize: 12)),
                  trailing: Icon(f.conflict ? Icons.cancel : Icons.check_circle,
                      color: f.conflict ? AppColors.accent : AppColors.success),
                ),
            ]),
          ),
          const SizedBox(height: 18),
          const SectionTitle('Allergens'),
          SectionCard(
            color: food.allergens.isEmpty ? AppColors.successTint : AppColors.accentTint,
            child: food.allergens.isEmpty
                ? const Text('No common allergens listed', style: TextStyle(color: AppColors.success))
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: food.allergens
                        .map((a) => Pill(a, color: AppColors.accent, background: Colors.white))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 14),
          const Text('Ingredients are typical for this dish and may differ between vendors.',
              style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
        ],
      ),
    );
  }
}
