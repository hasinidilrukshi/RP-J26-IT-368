/// The tourist's health profile, entered on setup and sent to the backend.
class HealthProfile {
  String diet; // vegetarian | vegan | non_vegetarian | no_preference
  List<String> allergies;
  String otherAllergy;
  List<String> restrictions;
  String otherRestriction;
  List<String> medicalConditions;
  String otherCondition;

  HealthProfile({
    this.diet = 'no_preference',
    List<String>? allergies,
    this.otherAllergy = '',
    List<String>? restrictions,
    this.otherRestriction = '',
    List<String>? medicalConditions,
    this.otherCondition = '',
  })  : allergies = allergies ?? [],
        restrictions = restrictions ?? [],
        medicalConditions = medicalConditions ?? [];

  factory HealthProfile.fromJson(Map<String, dynamic>? j) {
    if (j == null) return HealthProfile();
    List<String> list(dynamic v) => (v as List? ?? []).map((e) => e.toString()).toList();
    return HealthProfile(
      diet: (j['diet'] ?? 'no_preference').toString(),
      allergies: list(j['allergies']),
      otherAllergy: (j['other_allergy'] ?? '').toString(),
      restrictions: list(j['restrictions']),
      otherRestriction: (j['other_restriction'] ?? '').toString(),
      medicalConditions: list(j['medical_conditions']),
      otherCondition: (j['other_condition'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'diet': diet,
        'allergies': allergies,
        'other_allergy': otherAllergy,
        'restrictions': restrictions,
        'other_restriction': otherRestriction,
        'medical_conditions': medicalConditions,
        'other_condition': otherCondition,
      };

  HealthProfile copy() => HealthProfile.fromJson(toJson());

  // ---- labels used across the UI ----
  static const dietLabels = {
    'vegetarian': 'Vegetarian',
    'vegan': 'Vegan',
    'non_vegetarian': 'Non-vegetarian',
    'no_preference': 'No specific preference',
  };

  static const allergyLabels = {
    'peanuts': 'Peanuts',
    'tree_nuts': 'Tree nuts',
    'milk': 'Milk',
    'egg': 'Egg',
    'fish': 'Fish',
    'shellfish': 'Shellfish',
    'soy': 'Soy',
    'wheat_gluten': 'Wheat / Gluten',
    'sesame': 'Sesame',
    'coconut': 'Coconut',
  };

  static const restrictionLabels = {
    'gluten_free': 'Gluten-free',
    'low_sugar': 'Low sugar',
    'low_salt': 'Low salt',
    'low_fat': 'Low fat',
  };

  static const conditionLabels = {
    'diabetes': 'Diabetes',
    'hypertension': 'High blood pressure',
    'heart_disease': 'Heart disease',
    'high_cholesterol': 'High cholesterol',
    'kidney_disease': 'Kidney disease',
    'gastritis': 'Gastritis / IBS',
    'obesity': 'Weight management',
    'pregnancy': 'Pregnancy',
  };

  String get dietLabel => dietLabels[diet] ?? diet;

  /// Short chips for the "Your Dietary Profile" card.
  List<String> get summaryTags {
    final tags = <String>[];
    if (diet != 'no_preference') tags.add(dietLabel);
    tags.addAll(allergies.map((a) => '${allergyLabels[a] ?? a} Allergy'));
    if (otherAllergy.trim().isNotEmpty) tags.add('${otherAllergy.trim()} Allergy');
    return tags;
  }

  int get extraCount =>
      restrictions.length +
      medicalConditions.length +
      (otherRestriction.trim().isNotEmpty ? 1 : 0) +
      (otherCondition.trim().isNotEmpty ? 1 : 0);
}
