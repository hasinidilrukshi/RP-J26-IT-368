import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Removed: import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ThreatsPage extends StatefulWidget {
  const ThreatsPage({super.key});

  @override
  State<ThreatsPage> createState() => _ThreatsPageState();
}

class _ThreatsPageState extends State<ThreatsPage> {
  // Removed local notifications plugin

  @override
  void initState() {
    super.initState();
    // _initializeNotifications();
  }

  // This method is now disabled since we removed the package
  static Future<void> showHazardNotification(String title, String location, dynamic plugin) async {
    // Disabled
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0), // Creamy background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF3E0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5D4037)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Live Threats & Weather',
          style: GoogleFonts.exo(color: const Color(0xFF5D4037), fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Live Weather Section ---
            Text('Current Weather Alerts', style: GoogleFonts.exo(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF5D4037))),
            const SizedBox(height: 15),
            _buildWeatherCard(),

            const SizedBox(height: 30),

            // --- Admin Reported Hazards Section ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Active Hazard Reports', style: GoogleFonts.exo(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF5D4037))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(10)),
                  child: Text('Live Updates', style: GoogleFonts.exo(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                )
              ],
            ),
            const SizedBox(height: 15),
            
            // Mock data - eventually this will come from the backend/database
            _buildHazardCard(
              title: 'Landslide Warning',
              location: 'Ella Rock Trail',
              date: 'Oct 22, 2026',
              description: 'Heavy rainfall over the past 48 hours has weakened the soil on the main trail to Ella Rock. Please avoid the area until further notice by local authorities.',
              severity: 'High',
            ),
            _buildHazardCard(
              title: 'Elephant Crossing',
              location: 'Habarana Main Road',
              date: 'Oct 22, 2026',
              description: 'Herd of wild elephants frequently crossing the road near the national park entrance. Drive slowly and do not honk or flash headlights.',
              severity: 'Medium',
            ),
            _buildHazardCard(
              title: 'Flash Flood Watch',
              location: 'Kitulgala',
              date: 'Oct 21, 2026',
              description: 'Kelani river levels rising rapidly. White water rafting is temporarily suspended for safety.',
              severity: 'High',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)]), // Weather blue
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF0288D1).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          const Icon(Icons.thunderstorm, color: Colors.white, size: 50),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Heavy Rain Expected', style: GoogleFonts.exo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Central Province', style: GoogleFonts.exo(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 5),
                Text('Expect thunderstorms between 2 PM and 6 PM today. Take precautions if hiking.', style: GoogleFonts.exo(fontSize: 12, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHazardCard({required String title, required String location, required String date, required String description, required String severity}) {
    Color badgeColor = severity == 'High' ? Colors.red.shade600 : Colors.orange.shade600;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.shade100, width: 2), // Red outline for danger
        boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(Icons.warning_amber_rounded, color: badgeColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(title, style: GoogleFonts.exo(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF5D4037))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
                child: Text(severity.toUpperCase(), style: GoogleFonts.exo(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Colors.grey),
              const SizedBox(width: 5),
              Text(location, style: GoogleFonts.exo(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
              const Spacer(),
              const Icon(Icons.access_time, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(date, style: GoogleFonts.exo(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),
          Text(description, style: GoogleFonts.exo(fontSize: 13, color: Colors.grey.shade800, height: 1.4)),
        ],
      ),
    );
  }
}
