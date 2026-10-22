import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../map/route_map_page.dart';

class FinalPlanPage extends StatelessWidget {
  final Map<String, dynamic>? routeData;

  const FinalPlanPage({super.key, this.routeData});

  String _getImageForVibe(String vibeKeyword) {
    if (vibeKeyword == 'sunny' || vibeKeyword == 'beach') return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&q=80&w=300';
    if (vibeKeyword == 'cool' || vibeKeyword == 'nature') return 'https://tropicalessenceglobal.com/wp-content/uploads/2025/11/Inbound-scaled.jpg';
    if (vibeKeyword == 'historical' || vibeKeyword == 'culture') return 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR7qHVA2Kte3ttuw--FQizLZGQ-JByuv68Wb3nYvlEQAZFzOAODZzCuzhSU&s';
    if (vibeKeyword == 'wild' || vibeKeyword == 'wildlife') return 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRGo0jIvb3vzLeksjMSRvc_00uCjvTxbGnIhHbpRLHJ4BMEH6UAKDjfn8m9&s';
    if (vibeKeyword == 'tropical') return 'https://img.freepik.com/free-photo/beautiful-tropical-beach-sea_74190-6612.jpg?semt=ais_hybrid&w=740&q=80';
    return 'https://images.unsplash.com/photo-1588598198422-963473a2d713?auto=format&fit=crop&q=80&w=300'; // Default
  }

  @override
  Widget build(BuildContext context) {
    // Extract real data from Python backend, fallback to empty/defaults if null
    final recommendedRoute = routeData?["routes"]?["recommended_route"];
    final summary = recommendedRoute?["summary"];
    final List dynamicStops = recommendedRoute?["stops"] ?? [];
    
    // Safely cast dynamic list to List<Map<String, dynamic>>
    final List<Map<String, dynamic>> stops = List<Map<String, dynamic>>.from(dynamicStops);
    
    // Extract AI Data safely
    final List dynamicSuggestions = routeData?["ai_suggestions"] ?? [];
    final List<Map<String, dynamic>> suggestions = List<Map<String, dynamic>>.from(dynamicSuggestions);
    
    final List dynamicTips = routeData?["ai_tips"] ?? [];
    final List<Map<String, dynamic>> tips = List<Map<String, dynamic>>.from(dynamicTips);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0), // Creamy Background
      appBar: AppBar(
        backgroundColor: const Color(0xFFE65100),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
        title: Text(
          'Your Travel Plan',
          style: GoogleFonts.exo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOP SUMMARY BAR ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: Color(0xFFE65100), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      summary != null 
                        ? 'Your Route • ${summary["total_hours"]} Hrs Total • Est. Cost: \$${summary["total_cost_usd"]}'
                        : 'Aug 15 - Aug 22, • 7 Days • Budget: \$2,500',
                      style: GoogleFonts.exo(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: const Color(0xFF5D4037),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- 1. YOUR SELECTED DESTINATIONS ---
            _buildSectionTitle('1. YOUR GENERATED ROUTE (FROM NSGA-II)'),
            const SizedBox(height: 15),
            
            // Generate Dynamic Cards based on Python Output
            if (stops.isNotEmpty)
              ...stops.map((stop) {
                // Format the cost beautifully
                final cost = stop["cost_usd"] == 0.0 ? "Free Entry" : "\$${stop["cost_usd"]} Entry Fee";
                
                // Read the new visit duration from the backend, fallback if not present yet
                final duration = stop["visit_duration"] ?? "Recommended stop";

                return _buildDestinationCard(
                  title: stop["place_name"],
                  subtitle: 'Day ${stop["day"]} - Stop ${stop["stop_number"]}',
                  imageUrl: null, // Removed smart image selector
                  alertText: 'Vibe: ${stop["vibe"]} | Climate: ${stop["climate"]}',
                  alertColor: const Color(0xFFFFE0B2), 
                  alertTextColor: const Color(0xFFE65100),
                  bullets: [
                    'Cost: $cost',
                    'Time needed: $duration',
                    'Perfect spot for ${stop["vibe"].toString().toLowerCase()} lovers!',
                  ],
                  hiddenGems: [],
                );
              }),
              
            if (stops.isEmpty)
              const Center(child: Text("Waiting for algorithm to generate stops...")),

            const SizedBox(height: 35),

            // --- 2. SUGGESTED ADDITIONS ---
            _buildSectionTitle('2. SUGGESTED ADDITIONS'),
            Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 15),
              child: Text(
                'Based on your climate and budget preferences, we suggest adding:',
                style: GoogleFonts.exo(color: Colors.grey.shade700, fontSize: 13),
              ),
            ),
            
            if (suggestions.isNotEmpty)
              ...suggestions.map((suggestion) => _buildSuggestedCard(
                title: suggestion["name"],
                description: suggestion["description"],
                imageUrl: null, // Removed smart image selector for suggestions
              )),
              
            if (suggestions.isEmpty)
              const Center(child: Text("Waiting for Suggestions...")),

            const SizedBox(height: 35),

            // --- 3. BUDGET & TRAVEL TIPS ---
            _buildSectionTitle('3. BUDGET & TRAVEL TIPS'),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: Color(0xFFE65100), size: 20),
                      const SizedBox(width: 8),
                      Text('Smart Estimates & Tips', style: GoogleFonts.exo(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF5D4037))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  if (tips.isNotEmpty)
                    ...tips.map((tip) => _buildTipRow(Icons.check_circle_outline, tip["title"], '${tip["description"]} · Est: ${tip["cost"]}', const Color(0xFFE8F5E9), Colors.green)),

                  const SizedBox(height: 30),
                  // Mock Circular Chart
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: summary != null ? 0.8 : 0.0,
                            strokeWidth: 15,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE65100)),
                          ),
                        ),
                        Column(
                          children: [
                            Text('\$${summary != null ? summary["total_cost_usd"] : 0}', style: GoogleFonts.exo(fontWeight: FontWeight.bold, fontSize: 22, color: const Color(0xFFE65100))),
                            Text('Estimated', style: GoogleFonts.exo(fontSize: 10, color: Colors.grey)),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                      child: Text('You\'re saving 28%!', style: GoogleFonts.exo(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 35),

            // --- 4. YOUR ROUTE ---
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Color(0xFFE65100), size: 18),
                const SizedBox(width: 8),
                _buildSectionTitle('4. YOUR ROUTE'),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  if (stops.isNotEmpty)
                    ...List.generate(stops.length, (index) {
                      final stop = stops[index];
                      final isLast = index == stops.length - 1;
                      return _buildRouteTimeline(
                        index + 1, 
                        stop["place_name"], 
                        'Day ${stop["day"]}', 
                        ['Cost: \$${stop["cost_usd"]}', 'Vibe: ${stop["vibe"]}'],
                        isLast: isLast
                      );
                    }),
                  if (stops.isEmpty)
                    const Center(child: Text("Waiting for route data...")),
                ],
              ),
            ),

            const SizedBox(height: 35),

            // --- 5. ITINERARY OVERVIEW ---
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFFE65100), size: 18),
                const SizedBox(width: 8),
                _buildSectionTitle('5. ITINERARY OVERVIEW'),
              ],
            ),
            const SizedBox(height: 15),
            
            Container(
              width: double.infinity, // ADDED: Forces the container to take full width
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.3)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Text(
                routeData?["ai_description"] ?? "Loading AI description...",
                style: GoogleFonts.exo(
                  fontSize: 14,
                  color: const Color(0xFF5D4037),
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 35),

            // --- VIEW MAP BUTTON ---
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RouteMapPage(routeData: routeData)), // Passing real data!
                );
              },
              child: Container(
                height: 55,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(color: const Color(0xFFE65100).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('View Route Map', style: GoogleFonts.exo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.exo(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF5D4037), letterSpacing: 0.5),
    );
  }

  Widget _buildDestinationCard({
    required String title,
    required String subtitle,
    String? imageUrl, // Made imageUrl optional
    String? alertText,
    Color? alertColor,
    Color? alertTextColor,
    required List<String> bullets,
    required List<String> hiddenGems,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                ),
                const SizedBox(width: 15),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title, 
                      style: GoogleFonts.exo(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFFE65100)),
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle, 
                      style: GoogleFonts.exo(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (alertText != null) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: alertColor, borderRadius: BorderRadius.circular(8)),
              child: Text(alertText, style: GoogleFonts.exo(fontSize: 11, color: alertTextColor, fontWeight: FontWeight.w600)),
            ),
          ],
          const SizedBox(height: 15),
          ...bullets.map((bullet) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: Color(0xFFE65100), fontSize: 16, height: 1.2)),
                Expanded(child: Text(bullet, style: GoogleFonts.exo(fontSize: 12, color: const Color(0xFF5D4037), height: 1.4))),
              ],
            ),
          )),
          const SizedBox(height: 15),
          Text('NEARBY HIDDEN GEMS:', style: GoogleFonts.exo(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: hiddenGems.map((gem) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(5)),
              child: Text(gem, style: GoogleFonts.exo(fontSize: 10, color: const Color(0xFF5D4037))),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedCard({required String title, required String description, String? imageUrl}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(imageUrl, width: 70, height: 70, fit: BoxFit.cover),
            ),
            const SizedBox(width: 15),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.exo(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFE65100))),
                const SizedBox(height: 4),
                Text(description, style: GoogleFonts.exo(fontSize: 11, color: Colors.grey.shade600, height: 1.3)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE65100)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text('+ Add to Trip', style: GoogleFonts.exo(fontSize: 10, color: const Color(0xFFE65100), fontWeight: FontWeight.w600)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String title, String subtitle, Color bgColor, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.exo(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                  Text(subtitle, style: GoogleFonts.exo(fontSize: 11, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRouteTimeline(int step, String location, String duration, List<String> activities, {bool isLast = false, bool isSuggested = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: const Color(0xFFE65100), shape: BoxShape.circle),
                child: Center(child: Text('$step', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: const Color(0xFFE65100))),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align to top
                    children: [
                      Expanded( // ADDED EXPANDED HERE
                        child: Text(
                          location, 
                          style: GoogleFonts.exo(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFE65100)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFFFE0B2), borderRadius: BorderRadius.circular(4)),
                        child: Text(duration, style: GoogleFonts.exo(fontSize: 9, color: const Color(0xFFE65100), fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...activities.map((act) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.add, size: 12, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(child: Text(act, style: GoogleFonts.exo(fontSize: 11, color: const Color(0xFF5D4037)))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(int step, String date, String location, String desc, String stayInfo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: const Color(0xFFE65100), shape: BoxShape.circle),
            child: Center(child: Text('$step', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align to top
                  children: [
                    Text(date, style: GoogleFonts.exo(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 10),
                    Expanded( // ADDED EXPANDED HERE
                      child: Text(
                        location, 
                        style: GoogleFonts.exo(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFE65100)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(desc, style: GoogleFonts.exo(fontSize: 12, color: const Color(0xFF5D4037), height: 1.4)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.bed, size: 14, color: Color(0xFFE65100)),
                    const SizedBox(width: 6),
                    Text(stayInfo, style: GoogleFonts.exo(fontSize: 10, color: const Color(0xFFE65100), fontWeight: FontWeight.w600)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
