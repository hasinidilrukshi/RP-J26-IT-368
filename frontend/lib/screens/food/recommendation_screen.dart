import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/scan_result.dart';
import '../../theme/app_theme.dart';
import '../../widgets/food_widgets.dart';
import 'ingredients_screen.dart';
import 'nutrition_screen.dart';

/// Screen 6 – personalised Safe / Caution / Avoid recommendation.
class RecommendationScreen extends StatelessWidget {
  final ScanResult scan;
  final Uint8List? imageBytes;
  const RecommendationScreen({super.key, required this.scan, this.imageBytes});

  @override
  Widget build(BuildContext context) {
    final rec = scan.recommendation!;
    final style = StatusStyle.of(rec.status);

    return Scaffold(
      appBar: AppBar(title: const Text('Dietary Recommendation')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          FoodImage(bytes: imageBytes, url: scan.imageUrl, height: 150),
          const SizedBox(height: 12),
          Text(scan.displayName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 12),

          // ---- verdict
          SectionCard(
            color: style.tint,
            borderColor: style.color.withAlpha(90),
            child: Row(children: [
              Icon(style.icon, color: style.color, size: 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(rec.title,
                      style: TextStyle(color: style.color, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  const Text('Based on your dietary profile',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textGrey)),
                ]),
              ),
              _ScoreRing(score: rec.score, color: style.color),
            ]),
          ),

          // ---- why
          const SizedBox(height: 18),
          const SectionTitle('Why?'),
          ...rec.reasons.map((r) => _ReasonRow(r)),

          // ---- personal risks
          if (rec.personalRisks.isNotEmpty) ...[
            const SizedBox(height: 14),
            const SectionTitle('Potential health risks for you'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rec.personalRisks
                  .map((r) => Pill(r,
                      color: AppColors.accent, background: AppColors.accentTint, icon: Icons.warning_amber_rounded))
                  .toList(),
            ),
          ],

          // ---- profile
          const SizedBox(height: 16),
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Your Profile',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 10),
              if (rec.profileTags.isEmpty)
                const Text('No dietary restrictions set', style: TextStyle(color: AppColors.textGrey))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: rec.profileTags
                      .map((t) => Pill(t,
                          color: AppColors.success, background: AppColors.successTint, icon: Icons.eco_outlined))
                      .toList(),
                ),
            ]),
          ),

          // ---- vendor note
          const SizedBox(height: 14),
          SectionCard(
            color: AppColors.amberTint,
            borderColor: const Color(0xFFF7D9A8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.amber),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(rec.note, style: const TextStyle(fontSize: 12.5, color: Color(0xFF8A5A00)))),
            ]),
          ),

          const SizedBox(height: 18),
          OutlinedButton.icon(
            icon: const Icon(Icons.list_alt),
            label: const Text('Ingredients'),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => IngredientsScreen(scan: scan, imageBytes: imageBytes))),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.local_fire_department_outlined),
            label: const Text('Nutrition'),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => NutritionScreen(scan: scan, imageBytes: imageBytes))),
          ),
        ],
      ),
    );
  }
}

class _ReasonRow extends StatelessWidget {
  final Reason reason;
  const _ReasonRow(this.reason);

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final Color color;
    switch (reason.severity) {
      case 'avoid':
        icon = Icons.cancel;
        color = AppColors.accent;
        break;
      case 'caution':
        icon = Icons.error;
        color = const Color(0xFFD9822B);
        break;
      case 'ok':
        icon = Icons.check_circle;
        color = AppColors.success;
        break;
      default:
        icon = Icons.info;
        color = AppColors.textGrey;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(reason.text, style: const TextStyle(fontSize: 14, color: AppColors.textDark))),
      ]),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final int score;
  final Color color;
  const _ScoreRing({required this.score, required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 54,
        height: 54,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: 54,
            height: 54,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 5,
              color: color,
              backgroundColor: Colors.white,
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$score', style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 16)),
            const Text('score', style: TextStyle(fontSize: 9, color: AppColors.textGrey)),
          ]),
        ]),
      );
}
