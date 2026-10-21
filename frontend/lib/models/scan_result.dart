/// Data models mirroring the backend JSON for a food scan.

List<String> _strings(dynamic v) => (v as List? ?? []).map((e) => e.toString()).toList();
double _d(dynamic v) => v == null ? 0 : (v as num).toDouble();

class Nutrition {
  final String serving;
  final double calories, carbohydrates, protein, fat, sugar;

  Nutrition({
    required this.serving,
    required this.calories,
    required this.carbohydrates,
    required this.protein,
    required this.fat,
    required this.sugar,
  });

  factory Nutrition.fromJson(Map<String, dynamic>? j) {
    j ??= {};
    return Nutrition(
      serving: (j['serving'] ?? '100g').toString(),
      calories: _d(j['calories']),
      carbohydrates: _d(j['carbohydrates']),
      protein: _d(j['protein']),
      fat: _d(j['fat']),
      sugar: _d(j['sugar']),
    );
  }
}

class FoodInfo {
  final String key, name, category;
  final List<String> ingredients, allergens, benefits, healthConcerns;
  final bool vegetarian, vegan;
  final Nutrition nutrition;

  FoodInfo({
    required this.key,
    required this.name,
    required this.category,
    required this.ingredients,
    required this.allergens,
    required this.benefits,
    required this.healthConcerns,
    required this.vegetarian,
    required this.vegan,
    required this.nutrition,
  });

  factory FoodInfo.fromJson(Map<String, dynamic> j) => FoodInfo(
        key: (j['key'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        category: (j['category'] ?? '').toString(),
        ingredients: _strings(j['ingredients']),
        allergens: _strings(j['allergens']),
        benefits: _strings(j['benefits']),
        healthConcerns: _strings(j['health_concerns']),
        vegetarian: j['vegetarian'] == true,
        vegan: j['vegan'] == true,
        nutrition: Nutrition.fromJson(j['nutrition'] as Map<String, dynamic>?),
      );
}

class Reason {
  final String severity; // avoid | caution | info | ok
  final String text;
  Reason(this.severity, this.text);
}

class IngredientFlag {
  final String name;
  final bool conflict;
  final String? note;
  IngredientFlag(this.name, this.conflict, this.note);
}

class Recommendation {
  final String status; // SAFE | CAUTION | AVOID
  final String title;
  final int score;
  final List<Reason> reasons;
  final List<String> personalRisks, generalRisks, benefits, profileTags;
  final List<IngredientFlag> ingredients;
  final String note;

  Recommendation({
    required this.status,
    required this.title,
    required this.score,
    required this.reasons,
    required this.personalRisks,
    required this.generalRisks,
    required this.benefits,
    required this.profileTags,
    required this.ingredients,
    required this.note,
  });

  factory Recommendation.fromJson(Map<String, dynamic> j) => Recommendation(
        status: (j['status'] ?? 'CAUTION').toString(),
        title: (j['title'] ?? '').toString(),
        score: (j['score'] as num? ?? 0).toInt(),
        reasons: (j['reasons'] as List? ?? [])
            .map((r) => Reason((r['severity'] ?? 'info').toString(), (r['text'] ?? '').toString()))
            .toList(),
        personalRisks: _strings(j['personal_risks']),
        generalRisks: _strings(j['general_risks']),
        benefits: _strings(j['benefits']),
        profileTags: _strings(j['profile_tags']),
        ingredients: (j['ingredients'] as List? ?? [])
            .map((i) => IngredientFlag(
                  (i['name'] ?? '').toString(),
                  i['conflict'] == true,
                  i['note']?.toString(),
                ))
            .toList(),
        note: (j['note'] ?? '').toString(),
      );
}

class Alternative {
  final String label, name;
  final double confidence;
  Alternative(this.label, this.name, this.confidence);
}

class Detection {
  final bool detected;
  final String? label;
  final double confidence;
  final List<Alternative> alternatives;

  Detection({required this.detected, this.label, required this.confidence, required this.alternatives});

  factory Detection.fromJson(Map<String, dynamic>? j) {
    j ??= {};
    return Detection(
      detected: j['detected'] == true,
      label: j['label']?.toString(),
      confidence: _d(j['confidence']),
      alternatives: (j['alternatives'] as List? ?? [])
          .map((a) => Alternative(
                (a['label'] ?? '').toString(),
                (a['name'] ?? a['label'] ?? '').toString(),
                _d(a['confidence']),
              ))
          .toList(),
    );
  }
}

class ScanResult {
  final String? scanId;
  final String userId;
  final DateTime createdAt;
  final String? imageUrl;
  final Detection? detection;
  final bool recognized;
  final FoodInfo? food;
  final Recommendation? recommendation;

  ScanResult({
    required this.scanId,
    required this.userId,
    required this.createdAt,
    required this.imageUrl,
    required this.detection,
    required this.recognized,
    required this.food,
    required this.recommendation,
  });

  factory ScanResult.fromJson(Map<String, dynamic> j) => ScanResult(
        scanId: j['scan_id']?.toString(),
        userId: (j['user_id'] ?? '').toString(),
        createdAt: DateTime.tryParse((j['created_at'] ?? '').toString())?.toLocal() ?? DateTime.now(),
        imageUrl: j['image_url']?.toString(),
        detection: j['detection'] == null ? null : Detection.fromJson(j['detection'] as Map<String, dynamic>),
        recognized: j['recognized'] == true,
        food: j['food'] == null ? null : FoodInfo.fromJson(j['food'] as Map<String, dynamic>),
        recommendation: j['recommendation'] == null
            ? null
            : Recommendation.fromJson(j['recommendation'] as Map<String, dynamic>),
      );

  String get displayName => food?.name ?? 'Unknown food';
  double get confidence => detection?.confidence ?? 0;
}
