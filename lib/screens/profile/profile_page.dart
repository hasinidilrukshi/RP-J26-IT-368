import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Controllers for the Admin Form
  final TextEditingController _hazardTitleController = TextEditingController();
  final TextEditingController _hazardLocationController = TextEditingController();
  final TextEditingController _hazardSeverityController = TextEditingController();
  final TextEditingController _hazardDescriptionController = TextEditingController();

  bool _isAdminLoggedIn = false;
  late AnimationController _logoAnimationController;
  late Animation<double> _logoScaleAnimation;

  @override
  void initState() {
    super.initState();
    // Setup smooth pulsing scale animation for the logo
    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _logoScaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _logoAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    super.dispose();
  }

  void _login() {
    if (_usernameController.text == 'admin' && _passwordController.text == 'admin123') {
      setState(() {
        _isAdminLoggedIn = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin Login Successful!'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Credentials'), backgroundColor: Colors.red));
    }
  }

  void _logout() {
    setState(() {
      _isAdminLoggedIn = false;
      _usernameController.clear();
      _passwordController.clear();
    });
  }

  void _publishHazard() async {
    if (_hazardTitleController.text.isEmpty || _hazardLocationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields!'), backgroundColor: Colors.red));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/hazards'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': _hazardTitleController.text,
          'location': _hazardLocationController.text,
          'severity': _hazardSeverityController.text.isNotEmpty ? _hazardSeverityController.text : 'Medium',
          'description': _hazardDescriptionController.text,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hazard Saved to Database Successfully!'), 
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          )
        );

        // Clear form after publishing
        _hazardTitleController.clear();
        _hazardLocationController.clear();
        _hazardSeverityController.clear();
        _hazardDescriptionController.clear();
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving to DB: $e'), 
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      body: _isAdminLoggedIn ? _buildAdminDashboard() : _buildLoginScreen(),
    );
  }

  Widget _buildLoginScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Force entire column to center
        children: [
          // Animated Logo!
          ScaleTransition(
            scale: _logoScaleAnimation,
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE65100).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  'https://dcassetcdn.com/design_img/3643574/770693/770693_20565344_3643574_0f8b19c0_image.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          
          Text('Admin Portal', style: GoogleFonts.exo(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFFE65100))),
          const SizedBox(height: 10),
          Text('Sign in to manage hazard alerts.', style: GoogleFonts.exo(fontSize: 14, color: Colors.grey.shade600), textAlign: TextAlign.center),
          
          const SizedBox(height: 50),
          
          // Username Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
            child: TextField(
              controller: _usernameController,
              decoration: const InputDecoration(border: InputBorder.none, hintText: 'Username', icon: Icon(Icons.person, color: Colors.grey)),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Password Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
            child: TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(border: InputBorder.none, hintText: 'Password', icon: Icon(Icons.lock, color: Colors.grey)),
            ),
          ),

          const SizedBox(height: 40),

          // Login Button
          GestureDetector(
            onTap: _login,
            child: Container(
              height: 55,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE65100),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: const Color(0xFFE65100).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Center(
                child: Text('Login as Admin', style: GoogleFonts.exo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Admin Dashboard', style: GoogleFonts.exo(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF5D4037))),
              IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: _logout),
            ],
          ),
          const SizedBox(height: 30),

          // Action Grid for Admin Duties
          Text('Quick Actions', style: GoogleFonts.exo(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF5D4037))),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickActionCard(Icons.warning_amber_rounded, 'Post Alert', Colors.orange),
              _buildQuickActionCard(Icons.group_rounded, 'Manage Users', Colors.blue),
              _buildQuickActionCard(Icons.analytics_rounded, 'App Analytics', Colors.green),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Add Hazard Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.3)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100)),
                    const SizedBox(width: 10),
                    Text('Post New Hazard Alert', style: GoogleFonts.exo(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF5D4037))),
                  ],
                ),
                const SizedBox(height: 20),
                _buildAdminTextField('Hazard Title (e.g. Flood Warning)', _hazardTitleController),
                const SizedBox(height: 15),
                _buildAdminTextField('Location (e.g. Kitulgala)', _hazardLocationController),
                const SizedBox(height: 15),
                _buildAdminTextField('Severity (High/Medium/Low)', _hazardSeverityController),
                const SizedBox(height: 15),
                _buildAdminTextField('Description...', _hazardDescriptionController, maxLines: 3),
                const SizedBox(height: 20),
                
                // Submit Button
                GestureDetector(
                  onTap: _publishHazard,
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(color: const Color(0xFF5D4037), borderRadius: BorderRadius.circular(15)),
                    child: Center(child: Text('Publish Alert & Send Notification', style: GoogleFonts.exo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAdminTextField(String hint, TextEditingController controller, {int maxLines = 1}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(border: InputBorder.none, hintText: hint, hintStyle: const TextStyle(fontSize: 13)),
      ),
    );
  }

  Widget _buildQuickActionCard(IconData icon, String title, MaterialColor color) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.27,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.shade50, shape: BoxShape.circle),
            child: Icon(icon, color: color.shade700, size: 24),
          ),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.exo(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF5D4037))),
        ],
      ),
    );
  }
}
