import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../plan/final_plan_page.dart';

class GeneratingRoutePage extends StatefulWidget {
  const GeneratingRoutePage({super.key});

  @override
  State<GeneratingRoutePage> createState() => _GeneratingRoutePageState();
}

class _GeneratingRoutePageState extends State<GeneratingRoutePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  final List<String> _loadingMessages = [
    'Analyzing your preferences...',
    'Finding the best historical sites...',
    'Checking weather in Ella...',
    'Optimizing route duration...',
    'Finalizing your Sri Lankan adventure...'
  ];
  
  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Cycle through messages
    _cycleMessages();
  }

  void _cycleMessages() async {
    for (int i = 0; i < _loadingMessages.length; i++) {
      if (!mounted) return;
      setState(() {
        _currentMessageIndex = i;
      });
      await Future.delayed(const Duration(milliseconds: 1500));
    }
    
    // Mock finishing the generation
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FinalPlanPage()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route Generated Successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0), // Creamy background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo/Icon
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 140, // Fixed width for perfect circle
                height: 140, // Fixed height for perfect circle
                padding: const EdgeInsets.all(15), // Reduced padding so image fits well
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRQjoOwAoSmEIRQCvOG3_xQjnUx6GhnSntPHANOU6FYjL4z9nBNKIkmwV0&s', // The new Travel logo
                    fit: BoxFit.contain, // Contain ensures the whole logo is visible
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.luggage_rounded,
                      color: Color(0xFFE65100),
                      size: 80,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 50),
            
            // Loading Text
            Text(
              'Curating Your Journey',
              style: GoogleFonts.exo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF5D4037),
              ),
            ),
            
            const SizedBox(height: 15),
            
            // Animated sub-messages
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                _loadingMessages[_currentMessageIndex],
                style: GoogleFonts.exo(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 50),
            
            // Custom Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE65100)),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
