import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Placeholder for your EXISTING home page.
///
/// Keep your own home screen; just make its "Food" category button call
/// `onOpenFood` (or `MainShell.of(context)?.selectTab(MainShell.foodTab)`).
class HomeScreen extends StatelessWidget {
  final VoidCallback onOpenFood;
  const HomeScreen({super.key, required this.onOpenFood});

  @override
  Widget build(BuildContext context) {
    final List<(IconData, String, VoidCallback?)> categories = [
      (Icons.restaurant, 'Food', onOpenFood),
      (Icons.favorite, 'Nature', null),
      (Icons.temple_buddhist, 'Temples', null),
      (Icons.beach_access, 'Beach', null),
      (Icons.pets, 'Wildlife', null),
    ];
    return Scaffold(
      body: ListView(padding: EdgeInsets.zero, children: [
        Container(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 24, 20, 40),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hello, Traveler', style: TextStyle(color: Colors.white70, fontSize: 14)),
            SizedBox(height: 4),
            Text('Ayubowan...',
                style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final c in categories)
              InkWell(
                onTap: c.$3,
                borderRadius: BorderRadius.circular(40),
                child: Column(children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    child: Icon(c.$1, color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(c.$2, style: const TextStyle(fontSize: 12)),
                ]),
              ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text('Replace this file with your existing home page.',
              style: TextStyle(color: AppColors.textGrey)),
        ),
      ]),
    );
  }
}
