import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'login_screen.dart';

class LanguageSelectionPage extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;
  final VoidCallback resetLanguage;

  LanguageSelectionPage({
    Key? key,
    required this.isDarkMode,
    required this.toggleTheme,
    required this.resetLanguage,
  }) : super(key: key);

  final FlutterTts _flutterTts = FlutterTts();

  Future<void> _speak(String text, String language) async {
    try {
      await _flutterTts.setLanguage(language);
      if (language == "pl-PL") {
        await _flutterTts
            .setVoice({"name": "pl-pl-x-mle#male_1-local", "locale": "pl-PL"});
      }
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint("TTS Error: $e");
    }
  }

  void _navigateToLogin(
      BuildContext context, String language, String languageCode) {
    String textToSpeak = language == 'Polski' ? 'Polski' : 'English';

    _speak(textToSpeak, languageCode);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(
          selectedLanguage: language,
          isDarkMode: isDarkMode,
          toggleTheme: toggleTheme,
          resetLanguage: resetLanguage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80.0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    'brain.jpg',
                    fit: BoxFit.contain,
                    height: 80.0,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'LuckyBrain',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
              color: Colors.white,
              onPressed: toggleTheme,
            ),
          ],
        ),
        backgroundColor: Colors.black,
      ),
      body: Container(
        color: isDarkMode ? Colors.grey[850] : Colors.lightBlue[100],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLanguageOption(
                context,
                'POLSKI',
                'pl-PL',
                'Polski',
                screenWidth,
              ),
              _buildLanguageOption(
                context,
                'ENGLISH',
                'en-US',
                'English',
                screenWidth,
              ),
            ],
          ),
        ),
      ),
    );
  }

  GestureDetector _buildLanguageOption(
    BuildContext context,
    String label,
    String languageCode,
    String language,
    double screenWidth,
  ) {
    return GestureDetector(
      onTap: () {
        _navigateToLogin(context, language, languageCode);
      },
      child: Container(
        width: screenWidth * 0.8,
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(vertical: 70),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 40,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              shadows: [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 3,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
