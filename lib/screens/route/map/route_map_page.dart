import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RouteMapPage extends StatelessWidget {
  const RouteMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0), // Creamy Background
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
          // --- TOP SECTION: MAP IMAGE ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: InteractiveViewer(
              child: Image.network(
                'https://traveylo.com/img/Web%20pic/map.png', // Re-using the beautiful map from home
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF81D4FA), // Ocean blue fallback
                  child: const Center(child: Icon(Icons.map, size: 100, color: Colors.white54)),
                ),
              ),
            ),
          ),

          // Map Legend Overlay (Top Right)
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
                  _buildLegendItem('A', 'Colombo'),
                  _buildLegendItem('B', 'Negombo'),
                  _buildLegendItem('C', 'Sigiriya'),
                  _buildLegendItem('D', 'Kandy'),
                  _buildLegendItem('E', 'Galle'),
                ],
              ),
            ),
          ),

          // --- BOTTOM SECTION: ROUTE OVERVIEW (Draggable Sheet Style) ---
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
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
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
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                          style: GoogleFonts.exo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5D4037),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Text(
                      '5 stops • 7 days • 342 km total',
                      style: GoogleFonts.exo(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Horizontal Cards
                  SizedBox(
                    height: 160,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 25),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildStopCard(
                          title: 'Kandy',
                          days: 'Day 1-2',
                          nights: '2 nights',
                          imageUrl: 'https://images.unsplash.com/photo-1625736312933-289895240974?auto=format&fit=crop&q=80&w=300',
                        ),
                        _buildStopCard(
                          title: 'Ella',
                          days: 'Day 3-4',
                          nights: '2 nights',
                          imageUrl: 'https://images.unsplash.com/photo-1552423814-c4980227babc?auto=format&fit=crop&q=80&w=300',
                        ),
                        _buildStopCard(
                          title: 'Sigiriya',
                          days: 'Day 5',
                          nights: '1 night',
                          imageUrl: 'https://images.unsplash.com/photo-1588598198422-963473a2d713?auto=format&fit=crop&q=80&w=300',
                        ),
                      ],
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
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE65100).withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Start Navigation',
                            style: GoogleFonts.exo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
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
            child: Center(
              child: Text(letter, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          Text(city, style: GoogleFonts.exo(fontSize: 11, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildStopCard({required String title, required String days, required String nights, required String imageUrl}) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 15, bottom: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: GoogleFonts.exo(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF5D4037))),
                  const SizedBox(height: 2),
                  Text(days, style: GoogleFonts.exo(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFE65100))),
                  Text(nights, style: GoogleFonts.exo(fontSize: 10, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
