import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RouteMapPage extends StatelessWidget {
  final Map<String, dynamic>? routeData;

  const RouteMapPage({super.key, this.routeData});

  @override
  Widget build(BuildContext context) {
    // Extract real data
    final recommendedRoute = routeData?["routes"]?["recommended_route"];
    final summary = recommendedRoute?["summary"];
    final List dynamicStops = recommendedRoute?["stops"] ?? [];
    final List<Map<String, dynamic>> stops = List<Map<String, dynamic>>.from(dynamicStops);
    
    // Create map markers and polyline coordinates dynamically from the ML backend output
    final List<LatLng> routePoints = [];
    final List<Marker> markers = [];
    
    final List<String> letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      final lat = stop["latitude"] as double;
      final lon = stop["longitude"] as double;
      final point = LatLng(lat, lon);
      
      routePoints.add(point);
      
      markers.add(
        Marker(
          point: point,
          width: 40,
          height: 40,
          child: Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300), 
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
                ),
                child: Center(
                  child: Text(
                    letters[i % letters.length], 
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Center map on Sri Lanka if no points exist
    final centerPoint = routePoints.isNotEmpty ? routePoints.first : const LatLng(7.8731, 80.7718);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF3E0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5D4037)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Route Map',
          style: GoogleFonts.exo(
            color: const Color(0xFF5D4037),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Stack(
        children: [
          // --- TOP SECTION: REAL INTERACTIVE FLUTTER MAP ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: centerPoint,
                initialZoom: 7.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.travelbuddy',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: const Color(0xFFE65100),
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),

          // Dynamic Map Legend Overlay (Top Right)
          if (stops.isNotEmpty)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stops', style: GoogleFonts.exo(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 5),
                    ...List.generate(stops.length, (index) {
                       return _buildLegendItem(letters[index % letters.length], stops[index]["place_name"].toString().split(' ').first);
                    }),
                  ],
                ),
              ),
            ),

          // --- BOTTOM SECTION: ROUTE OVERVIEW ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 15, bottom: 20),
                      height: 5,
                      width: 50,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  // Title and details
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Row(
                      children: [
                        const Icon(Icons.route_outlined, color: Color(0xFFE65100), size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'Trip Route Overview',
                          style: GoogleFonts.exo(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF5D4037)),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Text(
                      summary != null 
                          ? '${stops.length} stops • ${routeData?["benchmark"]?["solutions_evaluated"] ?? 7} days • ~${summary["total_cost_usd"]} USD Total'
                          : '5 stops • 7 days • 342 km total',
                      style: GoogleFonts.exo(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Dynamic Horizontal Cards
                  SizedBox(
                    height: 120, // Reduced height slightly to avoid overflow
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 25),
                      physics: const BouncingScrollPhysics(),
                      children: stops.isEmpty 
                        ? [const Center(child: Text("Generating route data..."))]
                        : stops.map((stop) => _buildStopCard(
                            title: stop["place_name"],
                            days: 'Day ${stop["day"]}',
                            nights: 'Stop ${stop["stop_number"]}',
                            vibe: stop["vibe"]
                          )).toList(),
                    ),
                  ),

                  const Spacer(),

                  // Start Navigation Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Container(
                      height: 55,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE65100),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: const Color(0xFFE65100).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Start Navigation', style: GoogleFonts.exo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25), // Safe area bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String letter, String city) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(color: Color(0xFFFFB300), shape: BoxShape.circle),
            child: Center(child: Text(letter, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 8),
          Text(city, style: GoogleFonts.exo(fontSize: 11, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildStopCard({required String title, required String days, required String nights, required String vibe}) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 15, bottom: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(title, style: GoogleFonts.exo(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF5D4037)), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 2),
            Text(days, style: GoogleFonts.exo(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFE65100))),
            Text(nights, style: GoogleFonts.exo(fontSize: 10, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(4)),
              child: Text(vibe, style: GoogleFonts.exo(fontSize: 9, color: const Color(0xFFE65100))),
            )
          ],
        ),
      ),
    );
  }
}
