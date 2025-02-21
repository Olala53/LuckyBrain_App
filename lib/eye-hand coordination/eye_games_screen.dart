import 'package:flutter/material.dart';
import 'speed_balls.dart';
import 'puzzle_game.dart';
import 'coordination_game.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SpeedGamesScreen extends StatelessWidget {
  final String selectedLanguage;
  final bool isDarkMode;
  final bool isSoundEnabled;

  const SpeedGamesScreen(
      {Key? key,
      required this.selectedLanguage,
      required this.isDarkMode,
      required this.isSoundEnabled})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FlutterTts _flutterTts = FlutterTts();

    void speakText(String text) async {
      if (isSoundEnabled) {
        await _flutterTts
            .setLanguage(selectedLanguage == 'Polski' ? 'pl-PL' : 'en-US');
        await _flutterTts.speak(text);
        await _flutterTts.setSpeechRate(1);
      }
    }

    void stopSpeaking() async {
      await _flutterTts.stop();
    }

    final Map<String, String> translations = {
      'title': selectedLanguage == 'Polski'
          ? 'Gry Koordynacji Wzrokowo - Ruchowej'
          : 'Eye - Hand Coordination Games',
      'Speed Balls Game':
          selectedLanguage == 'Polski' ? 'Szybkie piłki' : 'Speed Balls Game',
      'Puzzle Game': selectedLanguage == 'Polski' ? 'Puzzle' : 'Puzzle Game',
      'Coordination Game': selectedLanguage == 'Polski'
          ? 'Gra Koordynacyjna'
          : 'Coordination Game',
    };

    final List<SpeedGameItem> translatedSpeedGames = [
      SpeedGameItem(
        label: translations['Speed Balls Game']!,
        widget: SpeedBallsGame(
          selectedLanguage: selectedLanguage,
          isDarkMode: isDarkMode,
          isSoundEnabled: isSoundEnabled,
        ),
      ),
      SpeedGameItem(
        label: translations['Puzzle Game']!,
        widget: PuzzleGame(
          selectedLanguage: selectedLanguage,
          isDarkMode: isDarkMode,
          isSoundEnabled: isSoundEnabled,
        ),
      ),
      SpeedGameItem(
        label: translations['Coordination Game']!,
        widget: GameScreen(
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
                      itemCount: translatedSpeedGames.length - 1,
                      itemBuilder: (BuildContext context, int index) {
                        final EdgeInsets margin = index == 0
                            ? const EdgeInsets.fromLTRB(25, 25, 12, 15)
                            : const EdgeInsets.fromLTRB(12, 25, 25, 15);

                        return GestureDetector(
                          onTap: () {
                            try {
                              stopSpeaking();
                              speakText(translatedSpeedGames[index].label);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      translatedSpeedGames[index].widget,
                                ),
                              ).then((_) {
                                stopSpeaking();
                              });
                            } catch (e) {
                              print('Navigation error: $e');
                            }
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
                                translatedSpeedGames[index].label.toUpperCase(),
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
                        try {
                          stopSpeaking();
                          speakText(translations['Coordination Game']!);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  translatedSpeedGames.last.widget,
                            ),
                          ).then((_) {
                            stopSpeaking();
                          });
                        } catch (e) {
                          print('Navigation error: $e');
                        }
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
                            translations['Coordination Game']!.toUpperCase(),
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

class SpeedGameItem {
  final String label;
  final Widget widget;

  SpeedGameItem({required this.label, required this.widget});
}
