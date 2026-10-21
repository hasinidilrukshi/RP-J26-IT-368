import 'package:flutter/material.dart';

import '../../models/health_profile.dart';
import '../../services/user_session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/food_widgets.dart';

/// Screen 3 – dietary preference, allergies, medical conditions and restrictions.
class FoodPreferencesScreen extends StatefulWidget {
  /// true when shown automatically on first use.
  final bool isSetup;
  const FoodPreferencesScreen({super.key, this.isSetup = false});

  @override
  State<FoodPreferencesScreen> createState() => _FoodPreferencesScreenState();
}

class _FoodPreferencesScreenState extends State<FoodPreferencesScreen> {
  late HealthProfile _p;
  bool _saving = false;

  static const _dietIcons = {
    'vegetarian': '🥬',
    'vegan': '🌱',
    'non_vegetarian': '🍗',
    'no_preference': '🍽️',
  };
  static const _allergyIcons = {
    'peanuts': '🥜',
    'tree_nuts': '🌰',
    'milk': '🥛',
    'egg': '🥚',
    'fish': '🐟',
    'shellfish': '🦐',
    'soy': '🫘',
    'wheat_gluten': '🌾',
    'sesame': '🌼',
    'coconut': '🥥',
  };

  @override
  void initState() {
    super.initState();
    _p = UserSession.instance.profile.copy();
  }

  void _toggle(List<String> list, String v) {
    setState(() {
      if (list.contains(v)) {
        list.remove(v);
      } else {
        list.add(v);
      }
    });
  }

  Future<String?> _askText(String title, String initial) {
    final c = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. mustard'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await UserSession.instance.saveProfile(_p);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dietary profile saved'), backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food Preferences')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Text(
            widget.isSetup
                ? 'Welcome! Set up your health profile once so we can check every dish for you.'
                : 'Choose your dietary preferences and food restrictions.',
            style: const TextStyle(color: AppColors.textGrey, fontSize: 13.5),
          ),
          const SizedBox(height: 14),

          // ---------------- Dietary preference
          const SectionTitle('Dietary Preference'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 3.1,
            children: HealthProfile.dietLabels.entries
                .map((e) => _OptionTile(
                      emoji: _dietIcons[e.key]!,
                      label: e.value,
                      selected: _p.diet == e.key,
                      onTap: () => setState(() => _p.diet = e.key),
                    ))
                .toList(),
          ),

          // ---------------- Allergies
          const SizedBox(height: 16),
          const SectionTitle('Allergies'),
          const Text('Select all that apply', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.92,
            children: [
              ...HealthProfile.allergyLabels.entries.map((e) => _AllergyTile(
                    emoji: _allergyIcons[e.key]!,
                    label: e.value,
                    selected: _p.allergies.contains(e.key),
                    onTap: () => _toggle(_p.allergies, e.key),
                  )),
              _AllergyTile(
                emoji: '➕',
                label: _p.otherAllergy.isEmpty ? 'Other' : _p.otherAllergy,
                selected: _p.otherAllergy.isNotEmpty,
                onTap: () async {
                  final v = await _askText('Other allergy', _p.otherAllergy);
                  if (v != null) setState(() => _p.otherAllergy = v);
                },
              ),
              _AllergyTile(
                emoji: '⭕',
                label: 'None',
                selected: _p.allergies.isEmpty && _p.otherAllergy.isEmpty,
                onTap: () => setState(() {
                  _p.allergies.clear();
                  _p.otherAllergy = '';
                }),
              ),
            ],
          ),

          // ---------------- Medical conditions
          const SizedBox(height: 16),
          const SectionTitle('Medical Conditions'),
          _CheckGrid(
            labels: HealthProfile.conditionLabels,
            selected: _p.medicalConditions,
            onToggle: (k) => _toggle(_p.medicalConditions, k),
          ),
          _OtherField(
            hint: 'Other condition (optional)',
            initial: _p.otherCondition,
            onChanged: (v) => _p.otherCondition = v,
          ),

          // ---------------- Restrictions
          const SizedBox(height: 16),
          const SectionTitle('Dietary Restrictions'),
          _CheckGrid(
            labels: HealthProfile.restrictionLabels,
            selected: _p.restrictions,
            onToggle: (k) => _toggle(_p.restrictions, k),
          ),
          _OtherField(
            hint: 'Other restriction (optional)',
            initial: _p.otherRestriction,
            onChanged: (v) => _p.otherRestriction = v,
          ),

          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
                : const Text('Save'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your profile is used only to check food suitability. This app gives guidance, not medical advice.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String emoji, label;
  final bool selected;
  final VoidCallback onTap;
  const _OptionTile({required this.emoji, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.successTint : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.success : AppColors.border, width: selected ? 1.6 : 1),
          ),
          child: Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
            if (selected) const Icon(Icons.check_circle, color: AppColors.success, size: 20),
          ]),
        ),
      );
}

class _AllergyTile extends StatelessWidget {
  final String emoji, label;
  final bool selected;
  final VoidCallback onTap;
  const _AllergyTile({required this.emoji, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryTint : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.accent : AppColors.border, width: selected ? 1.6 : 1),
          ),
          child: Stack(children: [
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, height: 1.15)),
                ),
              ]),
            ),
            if (selected)
              const Positioned(
                top: 5,
                right: 5,
                child: CircleAvatar(radius: 5, backgroundColor: AppColors.accent),
              ),
          ]),
        ),
      );
}

class _CheckGrid extends StatelessWidget {
  final Map<String, String> labels;
  final List<String> selected;
  final ValueChanged<String> onToggle;
  const _CheckGrid({required this.labels, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 4.2,
        children: labels.entries.map((e) {
          final on = selected.contains(e.key);
          return InkWell(
            onTap: () => onToggle(e.key),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: on ? AppColors.primaryTint : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: on ? AppColors.primary : AppColors.border),
              ),
              child: Row(children: [
                Icon(on ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 20, color: on ? AppColors.primary : AppColors.textGrey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(e.value,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
                ),
              ]),
            ),
          );
        }).toList(),
      );
}

class _OtherField extends StatelessWidget {
  final String hint, initial;
  final ValueChanged<String> onChanged;
  const _OtherField({required this.hint, required this.initial, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextFormField(
          initialValue: initial,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
          ),
        ),
      );
}
