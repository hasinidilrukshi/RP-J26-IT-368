import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../theme/app_theme.dart';

/// Colours / icon / label for a SAFE | CAUTION | AVOID status.
class StatusStyle {
  final Color color, tint;
  final IconData icon;
  final String label;
  const StatusStyle(this.color, this.tint, this.icon, this.label);

  static StatusStyle of(String? status) {
    switch (status) {
      case 'SAFE':
        return const StatusStyle(AppColors.success, AppColors.successTint, Icons.check_circle, 'Safe');
      case 'AVOID':
        return const StatusStyle(AppColors.accent, AppColors.accentTint, Icons.warning_rounded, 'Avoid');
      case 'CAUTION':
        return const StatusStyle(Color(0xFFD9822B), AppColors.amberTint, Icons.error_rounded, 'Caution');
      default:
        return const StatusStyle(AppColors.textGrey, AppColors.greyTint, Icons.help_outline, 'Unknown');
    }
  }
}

class StatusBadge extends StatelessWidget {
  final String? status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = StatusStyle.of(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: s.tint, borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(s.icon, size: 13, color: s.color),
        const SizedBox(width: 4),
        Text(s.label, style: TextStyle(color: s.color, fontSize: 11.5, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// Shows the scanned food: local bytes if we have them, otherwise the server copy.
class FoodImage extends StatelessWidget {
  final Uint8List? bytes;
  final String? url;
  final double height;
  final double radius;
  final double? width;

  const FoodImage({super.key, this.bytes, this.url, this.height = 180, this.radius = 14, this.width});

  @override
  Widget build(BuildContext context) {
    Widget child;
    final full = ApiConfig.absolute(url);
    if (bytes != null) {
      child = Image.memory(bytes!, fit: BoxFit.cover);
    } else if (full != null) {
      child = Image.network(full, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder());
    } else {
      child = _placeholder();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(height: height, width: width ?? double.infinity, child: child),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.primaryTint,
        child: const Center(child: Icon(Icons.restaurant, color: AppColors.primary, size: 36)),
      );
}

/// White rounded card used everywhere.
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor ?? AppColors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 6),
        child: Row(children: [
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          ),
          if (trailing != null) trailing!,
        ]),
      );
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;
  final IconData? icon;
  const Pill(this.text,
      {super.key, this.color = AppColors.primary, this.background = AppColors.primaryTint, this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 5)],
          Text(text, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ]),
      );
}

/// Emoji for an ingredient name (keeps the APK free of image assets).
String ingredientEmoji(String name) {
  final n = name.toLowerCase();
  const map = <String, String>{
    'chicken': '🍗', 'sausage': '🌭', 'egg': '🥚', 'prawn': '🦐', 'maldive': '🐟',
    'fish': '🐟', 'mackerel': '🐟', 'tuna': '🐟', 'coconut milk': '🥥', 'coconut': '🥥',
    'milk': '🥛', 'butter': '🧈', 'margarine': '🧈', 'cheese': '🧀', 'bread': '🍞',
    'rice': '🍚', 'flour': '🌾', 'wheat': '🌾', 'kurakkan': '🌾', 'lentil': '🫘', 'dal': '🫘',
    'gram': '🫘', 'peas': '🫛', 'potato': '🥔', 'cassava': '🍠', 'onion': '🧅', 'garlic': '🧄',
    'ginger': '🫚', 'chili': '🌶️', 'chilli': '🌶️', 'pepper': '🌶️', 'curry': '🍛',
    'tomato': '🍅', 'cucumber': '🥒', 'carrot': '🥕', 'leek': '🥬', 'leaves': '🌿', 'leaf': '🌿',
    'gotu kola': '🌿', 'lime': '🍋', 'jaggery': '🍯', 'treacle': '🍯', 'sugar': '🍬',
    'jam': '🍓', 'salt': '🧂', 'oil': '🫒', 'yeast': '🍞', 'cardamom': '🌰', 'cinnamon': '🌰',
    'turmeric': '🟡', 'water': '💧', 'sambol': '🌶️', 'goraka': '🍈', 'colouring': '🎨',
  };
  for (final e in map.entries) {
    if (n.contains(e.key)) return e.value;
  }
  return '🍽️';
}

String formatScanTime(DateTime t) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final time = '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today, $time';
  if (diff == 1) return 'Yesterday, $time';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${t.day} ${months[t.month - 1]}, $time';
}

void showError(BuildContext context, Object e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.toString()), backgroundColor: AppColors.accent),
  );
}
