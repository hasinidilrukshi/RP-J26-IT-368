import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FinalPlanPage extends StatelessWidget {
  const FinalPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                  Expanded( // ADDED EXPANDED HERE TO FIX OVERFLOW
                    child: Text(
                      'Aug 15 - Aug 22, • 7 Days • Budget: \$2,500',
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
            _buildSectionTitle('1. YOUR SELECTED DESTINATIONS'),
            const SizedBox(height: 15),
            
            // Kandy Card
            _buildDestinationCard(
              title: 'Kandy',
              subtitle: 'Cultural Capital',
              imageUrl: 'https://images.unsplash.com/photo-1625736312933-289895240974?auto=format&fit=crop&q=80&w=300', // Added auto=format&fit=crop
              alertText: 'Kandy Esala Perahera - happening during your visit!',
              alertColor: const Color(0xFFFFE0B2), // Light Orange
              alertTextColor: const Color(0xFFE65100),
              bullets: [
                'Visit the Temple of the Tooth Relic during evening rituals',
                'Take a peaceful walk around Kandy Lake (Kiri Muhuda)',
                'Explore Royal Botanical Gardens, Peradeniya\'s giant palms',
                'Shop for local crafts and spices at Kandy Central Market',
              ],
              hiddenGems: ['Bahiravokanda Vihara Buddha Statue', 'Udawattakele Forest'],
            ),
            
            // Ella Card
            _buildDestinationCard(
              title: 'Ella',
              subtitle: 'Scenic Highlands',
              imageUrl: 'https://images.unsplash.com/photo-1552423814-c4980227babc?auto=format&fit=crop&q=80&w=300', // Added auto=format&fit=crop
              alertText: 'Take the train from Kandy to Ella - one of the world\'s most scenic rail journeys & budget-friendly!',
              alertColor: const Color(0xFFE8F5E9), // Light Green
              alertTextColor: Colors.green.shade700,
              bullets: [
                'Hike Little Adam\'s Peak at sunrise for breathtaking vistas',
                'Visit Nine Arches Bridge & time it with a passing blue train',
                'Explore Ravana Falls and hear local mythological legends',
                'Try fresh Ceylon tea and local sweets at a hilltop café',
              ],
              hiddenGems: ['Demodara Loop', 'Ella Spice Garden'],
            ),

            // Sigiriya Card
            _buildDestinationCard(
              title: 'Sigiriya',
              subtitle: 'Historic Fortress',
              imageUrl: 'https://images.unsplash.com/photo-1588598198422-963473a2d713?auto=format&fit=crop&q=80&w=300',
              alertText: null, // No alert for this one
              bullets: [
                'Climb Sigiriya Rock Fortress (UNESCO World Heritage Site)',
                'Explore Pidurangala Rock at sunrise for unmatched fortress views',
                'Visit the historic Dambulla Cave Temple on the way back',
              ],
              hiddenGems: ['Minneriya elephant gathering', 'Hiriwadunna Village'],
            ),

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
            
            _buildSuggestedCard(
              title: 'Nuwara Eliya',
              description: 'Since you love cool climates, visit Little England! Colonial architecture, strawberry farms, and Gregory Lake boating.',
              imageUrl: 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?auto=format&fit=crop&q=80&w=300', // Changed to highly stable Cool image URL
            ),
            _buildSuggestedCard(
              title: 'Mirissa',
              description: 'Perfect beach stop before heading home. Whale watching (seasonal), Coconut Tree Hill, and fresh seafood sunset dining.',
              imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&q=80&w=300', // Added auto=format&fit=crop
            ),

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
                  _buildTipRow(Icons.train, 'Train Kandy → Ella', 'Scenic route · ~\$0.80 · budget-friendly', const Color(0xFFE8F5E9), Colors.green),
                  _buildTipRow(Icons.directions_bus, 'Bus Ella → Sigiriya', 'Via Dambulla · ~\$1.20 · easy transfer', const Color(0xFFE3F2FD), Colors.blue),
                  _buildTipRow(Icons.home, 'Guesthouse', 'Hill country · \$15-25/night', const Color(0xFFFFE0B2), const Color(0xFFE65100)),
                  _buildTipRow(Icons.restaurant, 'Local meals', 'Rice & curry spots · \$2-5/person', const Color(0xFFFFE0B2), const Color(0xFFE65100)),
                  
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
                            value: 0.72,
                            strokeWidth: 15,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE65100)),
                          ),
                        ),
                        Column(
                          children: [
                            Text('\$1,800', style: GoogleFonts.exo(fontWeight: FontWeight.bold, fontSize: 22, color: const Color(0xFFE65100))),
                            Text('of \$2,500', style: GoogleFonts.exo(fontSize: 10, color: Colors.grey)),
                            Text('72%', style: GoogleFonts.exo(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF5D4037))),
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
                  _buildRouteTimeline(1, 'Kandy', '2 days', ['Temple of the Tooth Relic', 'Royal Botanical Gardens, Peradeniya', 'Kandy Lake (Kiri Muhuda)']),
                  _buildRouteTimeline(2, 'Ella', '2 days', ['Nine Arches Bridge', 'Little Adam\'s Peak', 'Ravana Falls']),
                  _buildRouteTimeline(3, 'Sigiriya', '2 days', ['Sigiriya Rock Fortress', 'Pidurangala Rock', 'Dambulla Cave Temple']),
                  _buildRouteTimeline(4, 'Nuwara Eliya', '1 day', ['Gregory Lake', 'Tea Plantations'], isSuggested: true),
                  _buildRouteTimeline(5, 'Mirissa', '1 day', ['Whale Watching', 'Coconut Tree Hill'], isLast: true, isSuggested: true),
                ],
              ),
            ),

            const SizedBox(height: 35),

            // --- 5. ROUTE DESCRIPTION ---
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined, color: Color(0xFFE65100), size: 18),
                const SizedBox(width: 8),
                _buildSectionTitle('5. ROUTE DESCRIPTION'),
              ],
            ),
            const SizedBox(height: 15),
            
            _buildDescriptionCard(1, 'Aug 15-16', 'Kandy', 'Arrive in Kandy. Visit Temple of the Tooth Relic. Evening: Watch the Kandy Esala Perahera festival! Stay: Hotel & overnight in Kandy', 'Hotel & overnight in Kandy'),
            _buildDescriptionCard(2, 'Aug 17', 'Kandy → Ella', 'Morning: Take the scenic train to Ella (6hrs). The journey itself is a highlight! Stay: Guesthouse in Ella', 'Guesthouse in Ella'),
            _buildDescriptionCard(3, 'Aug 18', 'Ella', 'Sunrise hike to Little Adam\'s Peak. Visit Nine Arches Bridge & Ravana Falls. Stay: Ella', 'Stay: Ella'),
            _buildDescriptionCard(4, 'Aug 19', 'Ella → Sigiriya', 'Bus to Sigiriya via Dambulla. Visit Dambulla Cave Temple en route. Stay: Sigiriya', 'Stay: Sigiriya'),
            _buildDescriptionCard(5, 'Aug 20', 'Sigiriya', 'Early morning climb of Sigiriya Rock. Afternoon: Pidurangala Rock for sunset views. Stay: Sigiriya', 'Stay: Sigiriya'),
            _buildDescriptionCard(6, 'Aug 21', 'Sigiriya → Nuwara Eliya', 'Drive to Nuwara Eliya. Visit tea plantations & Gregory Lake. Stay: Nuwara Eliya', 'Stay: Nuwara Eliya'),
            _buildDescriptionCard(7, 'Aug 22', 'Nuwara Eliya → Mirissa', 'Travel to Mirissa. Sunset at Coconut Tree Hill. Fresh seafood dinner. Stay: Mirissa', 'Stay: Mirissa'),

            const SizedBox(height: 35),

            // --- VIEW MAP BUTTON ---
            Container(
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
    required String imageUrl,
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
            crossAxisAlignment: CrossAxisAlignment.start, // Align to top
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover),
              ),
              const SizedBox(width: 15),
              Expanded( // ADDED EXPANDED HERE
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title, 
                      style: GoogleFonts.exo(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFFE65100)),
                      maxLines: 1, // Prevent title overflow
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle, 
                      style: GoogleFonts.exo(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 2, // Prevent subtitle overflow
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

  Widget _buildSuggestedCard({required String title, required String description, required String imageUrl}) {
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
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(imageUrl, width: 70, height: 70, fit: BoxFit.cover),
          ),
          const SizedBox(width: 15),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.exo(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                Text(subtitle, style: GoogleFonts.exo(fontSize: 11, color: Colors.grey.shade600)),
              ],
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
