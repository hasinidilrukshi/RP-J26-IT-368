import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/emergency_report.dart';

/// Round maroon icon tile, same style as the quick actions on the Home design.
class EmergencyTypeCard extends StatelessWidget {
  final EmergencyType type;
  final bool selected;
  final VoidCallback onTap;

  const EmergencyTypeCard({
    super.key,
    required this.type,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? Colors.white : AppColors.primary,
              ),
              child: Icon(
                type.icon,
                size: 22,
                color: selected ? AppColors.primary : Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              type.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
