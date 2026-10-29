import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app_colors.dart';
import 'core/app_theme.dart';
import 'screens/sos_screen.dart';
import 'services/location_service.dart';
import 'services/profile_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: AppColors.primaryDark,
    statusBarIconBrightness: Brightness.light,
  ));
  await ProfileStore.instance.load();
  runApp(const CeylonPathEmergencyApp());
  // Start GPS straight away so the location is ready before SOS is pressed.
  LocationService.instance.start();
}

class CeylonPathEmergencyApp extends StatelessWidget {
  const CeylonPathEmergencyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ceylon Path Emergency',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SosScreen(),
    );
  }
}
