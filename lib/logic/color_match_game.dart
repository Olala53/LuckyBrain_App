import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/game_result.dart';

void main() => runApp(const ColorMatchApp());

class ColorMatchApp extends StatelessWidget {
  const ColorMatchApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dopasuj Kolory',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ColorMatchGame(
        selectedLanguage: 'Polski',
        isDarkMode: false,
        isSoundEnabled: true,
      ),
    );
  }
}

class ColorMatchGame extends StatefulWidget {
  final String selectedLanguage;
  final bool isDarkMode;
  final bool isSoundEnabled;

  const ColorMatchGame(
      {Key? key,
      required this.selectedLanguage,
      required this.isDarkMode,
      required this.isSoundEnabled})
      : super(key: key);

  @override
  _ColorMatchGameState createState() => _ColorMatchGameState();
}

class _ColorMatchGameState extends State<ColorMatchGame> {
  final List<Color> fullColors = [
    Colors.red,
    Colors.green,
    Colors.yellow,
    Colors.blue
  ];
  final List<String> fullColorNames = [
    'CZERWONY',
    'ZIELONY',
    'ŻÓŁTY',
    'NIEBIESKI'
  ];
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  late List<Color> colors;
  late List<String> colorNames;
  late String targetColorName;
  late Color displayedTextColor;

  late String _instruction;
  late String _title;
  late String _scoreLabel;
  late String _fastestReactionLabel;

  int score = 0;
  int fastestReactionTime = 0;
  int round = 0;
  int level = 1;
  late int _startTime;

  String _dropdownTitle = 'Łatwy';

  Future<void> _saveGameResult() async {
    for (int gameLevel = 1; gameLevel <= 3; gameLevel++) {
      if (gameLevel == level) {
        final result = GameResult(
          category: 'color_match',
          gameName: 'color_match_level_$gameLevel',
          score: score,
          date: DateTime.now(),
        ).toMap();

        final box = await Hive.openBox<Map>('gameResults');
        await box.add(result);
      } else {
        final result = GameResult(
          category: 'color_match',
          gameName: 'color_match_level_$gameLevel',
          score: 0,
          date: DateTime.now(),
        ).toMap();

        final box = await Hive.openBox<Map>('gameResults');
        await box.add(result);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeTexts();
    _startGame();
    Future.delayed(const Duration(seconds: 2), _playInstructionAudio);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _tts.stop();
    super.dispose();
  }

  void _initializeTexts() {
    if (widget.selectedLanguage == 'Polski') {
      _instruction = 'Wybierz kolor odpowiadający nazwie';
      _title = 'Dopasuj Kolory';
      _scoreLabel = 'Wynik';
      _fastestReactionLabel = 'Najszybsza reakcja';
      _dropdownTitle = 'Łatwy';
      _tts.setLanguage('pl-PL');
      _tts.setVolume(1.5);
      _tts.setSpeechRate(1);
    } else {
      _instruction = 'Choose a colour that matches the name';
      _title = 'Color Match';
      _scoreLabel = 'Score';
      _fastestReactionLabel = 'Fastest reaction';
      _dropdownTitle = 'Easy';
      _tts.setLanguage('en-US');
      _tts.setVolume(0.5);
    }
  }

  Future<void> _playInstructionAudio() async {
    if (widget.isSoundEnabled) {
      await _tts.speak(_instruction);
      await _tts.awaitSpeakCompletion(true);
    }
  }

  void _setRandomColors() {
    final random = Random();
    targetColorName = colorNames[random.nextInt(colorNames.length)];
    displayedTextColor = colors[random.nextInt(colors.length)];
    _startTime = DateTime.now().millisecondsSinceEpoch;
    setState(() {});
  }

  void _startGame() {
    score = 0;
    fastestReactionTime = 0;
    round = 0;
    level = 1;
    _updateLevelColors();
    _setRandomColors();
  }

  void _updateLevelColors() {
    switch (level) {
      case 1:
        colors = fullColors.sublist(0, 2);
        colorNames = fullColorNames.sublist(0, 2);
        break;
      case 2:
        colors = fullColors.sublist(0, 3);
        colorNames = fullColorNames.sublist(0, 3);
        break;
      default:
        colors = fullColors;
        colorNames = fullColorNames;
        break;
    }
  }

  void _setLevel(int newLevel) {
    setState(() {
      level = newLevel;
      _updateLevelColors();
      _setRandomColors();
      _dropdownTitle = _getLevelText();
    });
  }

  String _getLevelText() {
    switch (level) {
      case 1:
        return widget.selectedLanguage == 'Polski' ? 'Łatwy' : 'Easy';
      case 2:
        return widget.selectedLanguage == 'Polski' ? 'Średni' : 'Medium';
      case 3:
        return widget.selectedLanguage == 'Polski' ? 'Trudny' : 'Hard';
      default:
        return widget.selectedLanguage == 'Polski' ? 'Łatwy' : 'Easy';
    }
  }

  Future<void> _checkSelection(String selectedColorName) async {
    final reactionTime = DateTime.now().millisecondsSinceEpoch - _startTime;

    if (selectedColorName == targetColorName) {
      if (widget.isSoundEnabled) {
        await _audioPlayer.play('assets/sounds/correct.mp3', isLocal: true);
      }
      setState(() {
        score++;
        if (fastestReactionTime == 0 || reactionTime < fastestReactionTime) {
          fastestReactionTime = reactionTime;
        }
      });
    } else {
      if (widget.isSoundEnabled) {
        await _audioPlayer.play('assets/sounds/beep1.mp3', isLocal: true);
      }
    }

    round++;

    if (round >= 10) {
      await _saveGameResult();

      if (score < 7) {
        setState(() {
          round = 0;
          score = 0;
          _setRandomColors();
        });
      } else {
        setState(() {
          round = 0;
          score = 0;
          level++;
          _updateLevelColors();
          _setRandomColors();
        });
      }
    } else {
      _setRandomColors();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double itemSize =
        (MediaQuery.of(context).size.width - 80) / colors.length;

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        title: Text(_title, style: TextStyle(color: Colors.white)),
        actions: <Widget>[
          DropdownButton<int>(
            value: level,
            dropdownColor: Colors.black,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            underline: Container(),
            items: [
              DropdownMenuItem<int>(
                value: 1,
                child: Text(
                  widget.selectedLanguage == 'Polski' ? 'Łatwy' : 'Easy',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              DropdownMenuItem<int>(
                value: 2,
                child: Text(
                  widget.selectedLanguage == 'Polski' ? 'Średni' : 'Medium',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              DropdownMenuItem<int>(
                value: 3,
                child: Text(
                  widget.selectedLanguage == 'Polski' ? 'Trudny' : 'Hard',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
            onChanged: (int? newLevel) {
              if (newLevel != null) {
                _setLevel(newLevel);
              }
            },
          ),
        ],
        flexibleSpace: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 3.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_scoreLabel: $score / 10',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
                Text(
                  '$_fastestReactionLabel: ${fastestReactionTime > 0 ? '$fastestReactionTime ms' : 'N/A'}',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          color: widget.isDarkMode ? Colors.grey[850] : Colors.lightBlue[100],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _instruction,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Center(
                child: Stack(
                  children: [
                    Text(
                      targetColorName,
                      style: TextStyle(
                        fontSize: 40,
                        letterSpacing: 2.0,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 3
                          ..color = Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      targetColorName,
                      style: TextStyle(
                        fontSize: 40,
                        letterSpacing: 2.0,
                        color: displayedTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: colors.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final Color color = entry.value;

                  final double itemWidth =
                      (MediaQuery.of(context).size.width - 80) / colors.length;
                  final double itemHeight =
                      (level == 1 && index < 2) ? itemWidth / 2 : itemWidth;

                  return GestureDetector(
                    onTap: () => _checkSelection(colorNames[index]),
                    child: Container(
                      width: itemWidth,
                      height: itemHeight,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.black, width: 3),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (round >= 10) ...[
                const SizedBox(height: 50),
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 20),
                    textStyle: const TextStyle(fontSize: 24),
                  ),
                  child: Text(widget.selectedLanguage == 'Polski'
                      ? 'Rozpocznij ponownie'
                      : 'Restart Game'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
