import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../models/emergency_report.dart';
import '../services/emergency_api_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_title.dart';
import 'assessment_result_screen.dart';
import 'emergency_form_screen.dart' show StepProgress;

class LocationScreen extends StatefulWidget {
  final EmergencyReport report;
  const LocationScreen({super.key, required this.report});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final _addressCtrl = TextEditingController();
  bool _locating = false;
  bool _submitting = false;
  String? _error;
  double? _accuracy;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Location services are turned off. Please enable GPS.';
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw 'Location permission denied. Enter your location manually below.';
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      widget.report
        ..latitude = pos.latitude
        ..longitude = pos.longitude;
      _accuracy = pos.accuracy;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _openMap() async {
    final r = widget.report;
    if (!r.hasLocation) return;
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${r.latitude},${r.longitude}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _submit() async {
    final r = widget.report;
    r.address = _addressCtrl.text.trim();
    if (!r.hasLocation && r.address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please allow GPS or type where you are.')));
      return;
    }
    setState(() => _submitting = true);
    final saved = await EmergencyApiService.instance.submitReport(r);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (EmergencyApiService.instance.lastCallOffline) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Server unreachable – showing an offline assessment.')));
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AssessmentResultScreen(report: saved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    return Scaffold(
      appBar: AppBar(title: const Text('Your Location')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
        children: [
          const StepProgress(step: 2),
          const SectionTitle(title: 'Current GPS location'),
          _mapCard(r),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.severityHighSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_rounded,
                      color: AppColors.severityHigh, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_error!,
                          style: const TextStyle(fontSize: 12.5))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Refresh',
                  icon: Icons.my_location_rounded,
                  outlined: true,
                  loading: false,
                  onPressed: _locating ? null : _getLocation,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: 'Open Map',
                  icon: Icons.map_rounded,
                  outlined: true,
                  onPressed: r.hasLocation ? _openMap : null,
                ),
              ),
            ],
          ),
          const SectionTitle(title: 'Landmark / address (optional)'),
          TextField(
            controller: _addressCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'e.g. Near Temple of the Tooth, Kandy – main entrance',
              prefixIcon: Icon(Icons.place_rounded),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Adding a landmark helps responders find you faster, especially in rural areas.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Submit & Assess Severity',
            icon: Icons.send_rounded,
            loading: _submitting,
            color: AppColors.severityCritical,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _mapCard(EmergencyReport r) {
    return Container(
      decoration: AppTheme.card(radius: 20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Stylised "map" header
          Container(
            height: 150,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE8F1E4), Color(0xFFD6E8F0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(size: Size.infinite, painter: _GridPainter()),
                if (_locating)
                  const CircularProgressIndicator(color: AppColors.primary)
                else
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          r.hasLocation
                              ? Icons.location_on_rounded
                              : Icons.location_off_rounded,
                          color: AppColors.primary,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.hasLocation
                            ? '${r.latitude!.toStringAsFixed(5)}, ${r.longitude!.toStringAsFixed(5)}'
                            : (_locating
                                ? 'Finding your location…'
                                : 'Location not available'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _accuracy != null
                            ? 'Accuracy ± ${_accuracy!.toStringAsFixed(0)} m'
                            : 'Latitude, Longitude',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (r.hasLocation)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.severityLow),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    final road = Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 10;
    canvas.drawLine(Offset(0, size.height * .7),
        Offset(size.width, size.height * .35), road);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
