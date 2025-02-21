import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'speed_game.dart';
import 'number_sound_game.dart';
import 'color_sound_game.dart';

class FocusGamesScreen extends StatefulWidget {
  final String selectedLanguage;
  final bool isDarkMode;
  final bool isSoundEnabled;

  const FocusGamesScreen(
      {Key? key,
      required this.selectedLanguage,
      required this.isDarkMode,
      required this.isSoundEnabled})
      : super(key: key);

  @override
  _FocusGamesScreenState createState() => _FocusGamesScreenState();
}

class _FocusGamesScreenState extends State<FocusGamesScreen> {
  final FlutterTts _tts = FlutterTts();
  final AudioCache _audioCache = AudioCache(prefix: 'assets/');
  late bool isSoundOn;

  final Map<String, String> translations = {};
  final List<FocusGameItem> translatedFocusGames = [];

  @override
  void initState() {
    super.initState();
    isSoundOn = widget.isSoundEnabled;
    translations.addAll({
      'title': widget.selectedLanguage == 'Polski'
          ? 'Gry Koordynacji Słuchowo - Ruchowej'
          : 'Ear - Hand Coordination Games',
      'Quick Click Game': widget.selectedLanguage == 'Polski'
          ? 'Gra Szybkościowa'
          : 'Quick Click Game',
      'Number Sound Game': widget.selectedLanguage == 'Polski'
          ? 'Gra Liczbowa'
          : 'Number Sound Game',
      'Sound Game':
          widget.selectedLanguage == 'Polski' ? 'Gra Dźwiękowa' : 'Sound Game',
    });
    translatedFocusGames.addAll([
      FocusGameItem(
        label: translations['Quick Click Game']!,
        widget: SpeedGame(
          selectedLanguage: widget.selectedLanguage,
          isDarkMode: widget.isDarkMode,
          isSoundEnabled: isSoundOn,
        ),
      ),
      FocusGameItem(
        label: translations['Number Sound Game']!,
        widget: NumberSequenceGame(
          selectedLanguage: widget.selectedLanguage,
          isDarkMode: widget.isDarkMode,
          isSoundEnabled: isSoundOn,
        ),
      ),
      FocusGameItem(
        label: translations['Sound Game']!,
        widget: SoundGame(
          selectedLanguage: widget.selectedLanguage,
          isDarkMode: widget.isDarkMode,
          isSoundEnabled: isSoundOn,
        ),
      ),
    ]);
  }

  Future<void> speak(String text) async {
    if (isSoundOn) {
      await _tts
          .setLanguage(widget.selectedLanguage == 'Polski' ? 'pl-PL' : 'en-US');
      await _tts.setSpeechRate(1);
      await _tts.speak(text);
    }
  }

  Future<void> playAudio(String filePath) async {
    if (isSoundOn) {
      await _audioCache.play(filePath);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              color:
                  widget.isDarkMode ? Colors.grey[850] : Colors.lightBlue[100],
              child: Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: itemWidth / itemHeight,
                      ),
                      itemCount: translatedFocusGames.length - 1,
                      itemBuilder: (BuildContext context, int index) {
                        final game = translatedFocusGames[index];
                        final EdgeInsets margin = index == 0
                            ? const EdgeInsets.fromLTRB(25, 25, 12, 15)
                            : const EdgeInsets.fromLTRB(12, 25, 25, 15);

                        return GestureDetector(
                          onTap: () {
                            if (isSoundOn) speak(game.label);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => game.widget,
                              ),
                            );
                          },
                          child: Container(
                            margin: margin,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue, width: 3),
                              borderRadius: BorderRadius.circular(15),
                              color: widget.isDarkMode
                                  ? Colors.grey
                                  : Colors.grey[200],
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
                        final lastGame = translatedFocusGames.last;
                        if (isSoundOn) speak(lastGame.label);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => lastGame.widget,
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: itemHeight - 10,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue, width: 3),
                          borderRadius: BorderRadius.circular(15),
                          color: widget.isDarkMode
                              ? Colors.grey
                              : Colors.grey[200],
                        ),
                        child: Center(
                          child: Text(
                            translatedFocusGames.last.label.toUpperCase(),
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

class FocusGameItem {
  final String label;
  final Widget widget;

  FocusGameItem({required this.label, required this.widget});
}
