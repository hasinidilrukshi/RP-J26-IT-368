import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_theme.dart';
import '../../widgets/food_widgets.dart';
import 'analyzing_screen.dart';

/// Screen 4 – take a photo or pick one from the gallery.
class ScanFoodScreen extends StatefulWidget {
  const ScanFoodScreen({super.key});

  @override
  State<ScanFoodScreen> createState() => _ScanFoodScreenState();
}

class _ScanFoodScreenState extends State<ScanFoodScreen> {
  final _picker = ImagePicker();
  Uint8List? _bytes;
  String _filename = 'food.jpg';

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, maxWidth: 1280, maxHeight: 1280, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _filename = file.name.isEmpty ? 'food.jpg' : file.name;
      });
      _analyze();
    } catch (e) {
      if (mounted) showError(context, 'Could not open ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e');
    }
  }

  void _analyze() {
    if (_bytes == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AnalyzingScreen(imageBytes: _bytes!, filename: _filename),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Street Food')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          GestureDetector(
            onTap: () => _pick(ImageSource.camera),
            child: CustomPaint(
              painter: _DashedBorderPainter(color: AppColors.accent),
              child: Container(
                height: 230,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.greyTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _bytes != null
                    ? FoodImage(bytes: _bytes, height: 230)
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFF3CDD2), width: 6),
                          ),
                          child: const Icon(Icons.photo_camera, color: AppColors.accent, size: 34),
                        ),
                        const SizedBox(height: 14),
                        const Text('Take a photo or upload\nan image of the food',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                      ]),
              ),
            ),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: () => _pick(ImageSource.camera),
            icon: const Icon(Icons.photo_camera),
            label: const Text('Camera'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _pick(ImageSource.gallery),
            icon: const Icon(Icons.image_outlined),
            label: const Text('Gallery'),
          ),
          if (_bytes != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: _analyze, child: const Text('Analyze this photo again')),
          ],
          const SizedBox(height: 20),
          const SectionCard(
            color: AppColors.greyTint,
            child: Row(children: [
              Icon(Icons.lightbulb_outline, color: AppColors.amber),
              SizedBox(width: 10),
              Expanded(
                child: Text('Take a clear, well-lit photo of a single dish from above for better results.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textGrey)),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)));
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 7), paint);
        d += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) => old.color != color;
}
