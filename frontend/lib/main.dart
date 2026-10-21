import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const FoodSafetyApp());
}

class FoodSafetyApp extends StatelessWidget {
  const FoodSafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ayubowan Traveler',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // On a wide browser window keep the phone-sized layout centred.
      builder: (context, child) => ColoredBox(
        color: const Color(0xFFEDE3DC),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: child,
          ),
        ),
      ),
      home: const MainShell(),
    );
  }
}