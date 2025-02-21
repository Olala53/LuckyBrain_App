import 'package:flutter/material.dart';
import 'memory_game.dart';
import 'memory_numbers.dart';
import 'click_numbers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class MemoryGamesScreen extends StatelessWidget {
  final String selectedLanguage;
  final bool isDarkMode;
  final bool isSoundEnabled;

  const MemoryGamesScreen(
      {Key? key,
      required this.selectedLanguage,
      required this.isDarkMode,
      required this.isSoundEnabled})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FlutterTts _flutterTts = FlutterTts();

    Future<void> speakText(String text) async {
      try {
        if (isSoundEnabled) {
          await _flutterTts
              .setLanguage(selectedLanguage == 'Polski' ? 'pl-PL' : 'en-US');
          await _flutterTts.setSpeechRate(1);
          await _flutterTts.speak(text);
        }
      } catch (e) {
        print("Error in TTS: $e");
      }
    }

    Future<void> stopSpeaking() async {
      try {
        await _flutterTts.stop();
      } catch (e) {
        print("Error stopping TTS: $e");
      }
    }

    final Map<String, String> translations = {
      'title': selectedLanguage == 'Polski' ? 'Gry Pamięciowe' : 'Memory Games',
      'Memory Card Game': selectedLanguage == 'Polski'
          ? 'Karty Pamięciowe'
          : 'Memory Card Game',
      'Memory Numbers Game': selectedLanguage == 'Polski'
          ? 'Zapamiętaj Liczby'
          : 'Memory Numbers Game',
      'Number Click Game': selectedLanguage == 'Polski'
          ? 'Gra w Klikanie Liczb'
          : 'Number Click Game',
    };

    final List<MemoryGameItem> translatedMemoryGames = [
      MemoryGameItem(
        label: translations['Memory Card Game']!,
        widget: MemoryGame(
          selectedLanguage: selectedLanguage,
          isDarkMode: isDarkMode,
          isSoundEnabled: isSoundEnabled,
        ),
      ),
      MemoryGameItem(
        label: translations['Memory Numbers Game']!,
        widget: MemoryNumbersGameApp(
          selectedLanguage: selectedLanguage,
          isDarkMode: isDarkMode,
          isSoundEnabled: isSoundEnabled,
        ),
      ),
      MemoryGameItem(
        label: translations['Number Click Game']!,
        widget: NumberClickGame(
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
                      itemCount: translatedMemoryGames.length - 1,
                      itemBuilder: (BuildContext context, int index) {
                        final game = translatedMemoryGames[index];
                        final EdgeInsets margin = index == 0
                            ? const EdgeInsets.fromLTRB(25, 25, 12, 15)
                            : const EdgeInsets.fromLTRB(12, 25, 25, 15);

                        return GestureDetector(
                          onTap: () {
                            try {
                              stopSpeaking();
                              speakText(game.label);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => game.widget,
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
                        try {
                          final lastGame = translatedMemoryGames.last;
                          stopSpeaking();
                          speakText(lastGame.label);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => lastGame.widget,
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
                            translatedMemoryGames.last.label.toUpperCase(),
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

class MemoryGameItem {
  final String label;
  final Widget widget;

  MemoryGameItem({required this.label, required this.widget});
}
