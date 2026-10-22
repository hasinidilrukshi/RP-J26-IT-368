import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // Replace with your actual Gemini API Key
  static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';
  
  static Future<String> generateTravelPlanDescription(Map<String, dynamic> optimizedData, Map<String, dynamic> userPreferences) async {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
    
    // We pass the raw mathematical output from the NSGA-II to Gemini,
    // and ask it to format it into a beautiful, human-readable travel itinerary.
    final prompt = '''
      You are an expert Sri Lankan travel guide named TravelBuddy.
      I have used a machine learning algorithm to generate an optimized travel route.
      
      User Preferences:
      - Days: \${userPreferences['days']}
      - Budget: \$\${userPreferences['budget']} for \${userPreferences['people']} people
      - Climate Preference: \${userPreferences['climates']}
      
      Raw Algorithm Output (Recommended Route):
      \${optimizedData['routes']['recommended_route']['stops']}
      
      Task:
      Write a beautiful, exciting, day-by-day travel itinerary based EXACTLY on the stops provided in the Raw Algorithm Output.
      Do not add extra days or stops. 
      For each stop, write a short, exciting 2-sentence description of what they will do there, including the estimated cost.
      
      Format your response cleanly using markdown bullets.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? "I couldn't generate a description at this time.";
    } catch (e) {
      print("Gemini API Error: \$e");
      // Fallback text if the API fails
      return "Welcome to your Sri Lankan adventure! Based on your preferences, we've crafted an incredible route just for you. Explore ancient sites, relax in nature, and enjoy the local culture. Safe travels!";
    }
  }
}
