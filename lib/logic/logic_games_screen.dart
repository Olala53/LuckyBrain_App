import 'package:flutter/material.dart';
import 'tic_tac_toe_game.dart';
import 'math_game.dart';
import 'color_match_game.dart';
import 'package:flutter_tts/flutter_tts.dart';

class LogicGamesScreen extends StatelessWidget {
  final String selectedLanguage;
  final bool isDarkMode;
  final bool isSoundEnabled;

  const LogicGamesScreen(
      {Key? key,
      required this.selectedLanguage,
      required this.isDarkMode,
      required this.isSoundEnabled})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FlutterTts _flutterTts = FlutterTts();

    Future<void> speakText(String text) async {
      if (isSoundEnabled) {
        await _flutterTts
            .setLanguage(selectedLanguage == 'Polski' ? 'pl-PL' : 'en-US');
        await _flutterTts.speak(text);
        await _flutterTts.setSpeechRate(1);
      }
    }

    Future<void> stopSpeaking() async {
      await _flutterTts.stop();
    }

    void _navigateToGame(
        BuildContext context, String textToSpeak, Widget gameWidget) {
      stopSpeaking();
      speakText(textToSpeak);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => gameWidget),
      ).then((_) {
        stopSpeaking();
      });
    }

    final Map<String, String> translations = {
      'title': selectedLanguage == 'Polski' ? 'Gry Logiczne' : 'Logic Games',
      'Tic-Tac-Toe Game':
          selectedLanguage == 'Polski' ? 'Kółko i Krzyżyk' : 'Tic-Tac-Toe Game',
      'Math Game':
          selectedLanguage == 'Polski' ? 'Gra Matematyczna' : 'Math Game',
      'Color Match Game': selectedLanguage == 'Polski'
          ? 'Dopasowywanie Kolorów'
          : 'Color Match Game',
    };

    final List<LogicGameItem> translatedLogicGames = [
      LogicGameItem(
        label: translations['Tic-Tac-Toe Game']!,
        widget: TicTacToeGame(
          selectedLanguage: selectedLanguage,
          isDarkMode: isDarkMode,
          isSoundEnabled: isSoundEnabled,
        ),
      ),
      LogicGameItem(
        label: translations['Math Game']!,
        widget: MathGame(
          selectedLanguage: selectedLanguage,
          isDarkMode: isDarkMode,
          isSoundEnabled: isSoundEnabled,
        ),
      ),
      LogicGameItem(
        label: translations['Color Match Game']!,
        widget: ColorMatchGame(
          selectedLanguage: selectedLanguage,
          isDarkMode: isDarkMode,
          isSoundEnabled: isSoundEnabled,
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          translations['title']!,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double itemWidth = (constraints.maxWidth / 2) - 20;
            final double itemHeight = (constraints.maxHeight / 2) - 20;

            return Container(
              color: isDarkMode ? Colors.grey[850] : Colors.lightBlue[100],
              child: Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: itemWidth / itemHeight,
                      ),
                      itemCount: translatedLogicGames.length - 1,
                      itemBuilder: (BuildContext context, int index) {
                        final EdgeInsets margin = index == 0
                            ? const EdgeInsets.fromLTRB(25, 25, 12, 15)
                            : const EdgeInsets.fromLTRB(12, 25, 25, 15);

                        final game = translatedLogicGames[index];
                        return GestureDetector(
                          onTap: () {
                            _navigateToGame(context, game.label, game.widget);
                          },
                          child: Container(
                            margin: margin,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue, width: 3),
                              borderRadius: BorderRadius.circular(15),
                              color:
                                  isDarkMode ? Colors.grey : Colors.grey[200],
                            ),
                            child: Center(
                              child: Text(
                                game.label.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
                    child: GestureDetector(
                      onTap: () {
                        final lastGame = translatedLogicGames.last;
                        _navigateToGame(
                            context, lastGame.label, lastGame.widget);
                      },
                      child: Container(
                        width: double.infinity,
                        height: itemHeight - 10,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue, width: 3),
                          borderRadius: BorderRadius.circular(15),
                          color: isDarkMode ? Colors.grey : Colors.grey[200],
                        ),
                        child: Center(
                          child: Text(
                            translatedLogicGames.last.label.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class LogicGameItem {
  final String label;
  final Widget widget;

  LogicGameItem({required this.label, required this.widget});
}
