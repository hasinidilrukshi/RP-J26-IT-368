import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/scan_result.dart';
import '../../services/api_service.dart';
import '../../services/user_session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/food_widgets.dart';
import 'food_analysis_screen.dart';

/// "Analyzing Food..." progress screen. Calls the backend and animates the steps.
class AnalyzingScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String filename;
  const AnalyzingScreen({super.key, required this.imageBytes, required this.filename});

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen> {
  static const _steps = [
    'Processing image',
    'Recognizing food',
    'Identifying ingredients',
    'Checking your profile',
    'Preparing recommendation...',
  ];
  int _done = 0;
  String? _foodName;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _wait(int ms) => Future.delayed(Duration(milliseconds: ms));

  void _retry() {
    setState(() {
      _done = 0;
      _error = null;
      _foodName = null;
    });
    _run();
  }

  Future<void> _run() async {
    final session = UserSession.instance;
    // Errors are converted to values right away so nothing is left unhandled
    // while the first steps animate.
    final Future<Object> future = session
        .ensureUser()
        .then<Object>((_) => ApiService.instance.analyzeFood(
              userId: session.userId!,
              imageBytes: widget.imageBytes,
              filename: widget.filename,
            ))
        .catchError((Object e) => e);

    // First two steps animate while the server is working.
    for (var i = 0; i < 2; i++) {
      await _wait(650);
      if (!mounted) return;
      setState(() => _done = i + 1);
    }

    final outcome = await future;
    if (!mounted) return;
    if (outcome is! ScanResult) {
      setState(() => _error = outcome.toString());
      return;
    }
    final result = outcome;
    setState(() => _foodName = result.recognized ? result.displayName : 'Unknown dish');

    for (var i = 2; i < _steps.length; i++) {
      await _wait(420);
      if (!mounted) return;
      setState(() => _done = i + 1);
    }
    await _wait(300);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => FoodAnalysisScreen(scan: result, imageBytes: widget.imageBytes),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food Analysis')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FoodImage(bytes: widget.imageBytes, height: 190),
          const SizedBox(height: 14),
          Text(_foodName ?? 'Identifying...',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 14),
          if (_error == null)
            SectionCard(
              color: AppColors.primaryTint,
              borderColor: const Color(0xFFF3CDD2),
              child: Row(children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                  child: const Icon(Icons.photo_camera, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Analyzing Food...',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary)),
                    SizedBox(height: 4),
                    Text('Our AI is checking the image and ingredients for your safety.',
                        style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
                  ]),
                ),
              ]),
            )
          else
            SectionCard(
              color: AppColors.accentTint,
              borderColor: const Color(0xFFF3CDD2),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.error_outline, color: AppColors.accent),
                  SizedBox(width: 8),
                  Text('Analysis failed', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.accent)),
                ]),
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Back'))),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(onPressed: _retry, child: const Text('Retry'))),
                ]),
              ]),
            ),
          const SizedBox(height: 18),
          for (var i = 0; i < _steps.length; i++) _StepRow(label: _steps[i], done: i < _done, active: i == _done),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String label;
  final bool done, active;
  const _StepRow({required this.label, required this.done, required this.active});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        child: Row(children: [
          SizedBox(
            width: 26,
            height: 26,
            child: done
                ? const CircleAvatar(
                    backgroundColor: AppColors.primary, child: Icon(Icons.check, size: 16, color: Colors.white))
                : active
                    ? const CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primary)
                    : Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFBDBDC6), width: 1.6),
                        ),
                      ),
          ),
          const SizedBox(width: 14),
          Text(label,
              style: TextStyle(
                fontSize: 15,
                color: done || active ? AppColors.textDark : AppColors.textGrey,
                fontWeight: done ? FontWeight.w600 : FontWeight.w400,
              )),
        ]),
      );
}
