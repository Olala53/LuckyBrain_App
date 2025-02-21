import 'dart:async';
import 'dart:math';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/game_result.dart';
import '../screens/statistics_screen.dart' show StatisticsScreen;

class NumberClickGame extends StatefulWidget {
  final String selectedLanguage;
  final bool isDarkMode;
  final bool isSoundEnabled;

  const NumberClickGame(
      {Key? key,
      required this.selectedLanguage,
      required this.isDarkMode,
      required this.isSoundEnabled})
      : super(key: key);

  @override
  _NumberClickGameState createState() => _NumberClickGameState();
}

class _NumberClickGameState extends State<NumberClickGame> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  int currentNumber = 1;
  int currentLevel = 1;
  int lives = 3;
  int _elapsedTime = 0;

  late List<int> numbers;
  late List<Color> tileColors;
  Timer? _roundTimer;

  late String _instruction;
  late String _title;
  late String _congratulationsMessage;
  late String _gameOverMessage;

  Future<void> _saveGameResult() async {
    int score = max(0, 100 - _elapsedTime);

    final result = GameResult(
      category: 'number_click',
      gameName: 'number_click_game',
      score: score,
      date: DateTime.now(),
    ).toMap();

    final box = await Hive.openBox<Map>('gameResults');
    await box.add(result);
  }

  @override
  void initState() {
    super.initState();
    _initializeTexts();
    _startNewLevel();
    Future.delayed(const Duration(seconds: 2), _playInstructionAudio);
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    _audioPlayer.dispose();
    _tts.stop();
    super.dispose();
  }

  void _initializeTexts() {
    if (widget.selectedLanguage == 'Polski') {
      _instruction = 'Kliknij liczby w odpowiedniej kolejności od 1 do 10';
      _title = 'Kliknij Liczby';
      _congratulationsMessage = 'Gratulacje! Ukończyłeś wszystkie poziomy!';
      _gameOverMessage = 'Koniec gry! Spróbuj ponownie.';
      _tts.setLanguage('pl-PL');
      _tts.setVolume(1.5);
      _tts.setSpeechRate(1);
    } else {
      _instruction = 'Click the numbers in the correct order from 1 to 10';
      _title = 'NumberClick';
      _congratulationsMessage = 'Congratulations! You completed all levels!';
      _gameOverMessage = 'Game Over! Try again.';
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

  Future<void> _playSound(String soundPath) async {
    if (widget.isSoundEnabled) {
      try {
        await _audioPlayer.play(soundPath, isLocal: true);
      } catch (e) {
        print('Error playing sound: $e');
      }
    }
  }

  void _startNewLevel() {
    setState(() {
      currentNumber = 1;
      lives = 3;
      numbers = List.generate(10, (index) => index + 1)..shuffle();
      tileColors = List.filled(numbers.length, Colors.grey);
    });
    _startTimer();
  }

  void _resetLevel() {
    setState(() {
      currentNumber = 1;
      lives = 3;
      tileColors = List.filled(numbers.length, Colors.grey);
    });
  }

  void _startTimer() {
    _elapsedTime = 0;
    _roundTimer?.cancel();
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime++;
      });
    });
  }

  void _stopTimer() {
    _roundTimer?.cancel();
  }

  void _onTileTap(int number) {
    if (number == currentNumber) {
      setState(() {
        tileColors[number - 1] = Colors.green;
        currentNumber++;
      });
      _playSound('assets/sounds/correct.mp3');
      if (currentNumber > numbers.length) {
        _stopTimer();
        if (currentLevel < 3) {
          setState(() {
            currentLevel++;
          });
          Future.delayed(const Duration(seconds: 2), _startNewLevel);
        } else {
          _showGameOverDialog(_congratulationsMessage);
        }
      }
    } else {
      setState(() {
        tileColors[number - 1] = Colors.red;
        lives--;
      });
      _playSound('assets/sounds/beep1.mp3');
      Timer(const Duration(milliseconds: 500), () {
        setState(() {
          tileColors[number - 1] = Colors.grey;
        });
      });

      if (lives == 0) {
        _stopTimer();
        Future.delayed(const Duration(seconds: 1), _resetLevel);
      }
    }
  }

  void _showGameOverDialog(String message) async {
    await _saveGameResult();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            widget.selectedLanguage == 'Polski' ? 'Koniec Gry' : 'Game Over'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                currentLevel = 1;
              });
              _startNewLevel();
            },
            child: Text(widget.selectedLanguage == 'Polski'
                ? 'Rozpocznij ponownie'
                : 'Restart'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StatisticsScreen(
                    selectedLanguage: widget.selectedLanguage,
                    isDarkMode: widget.isDarkMode,
                    isSoundEnabled: widget.isSoundEnabled,
                  ),
                ),
              );
            },
            child: Text(widget.selectedLanguage == 'Polski'
                ? 'Statystyki'
                : 'Statistics'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double availableHeight = screenHeight - kToolbarHeight - 120;
    int crossAxisCount = 5;
    int rowCount = (numbers.length / crossAxisCount).ceil();
    double maxTileWidth =
        (screenWidth - (crossAxisCount + 1) * 10) / crossAxisCount;
    double maxTileHeight = (availableHeight - (rowCount + 1) * 10) / rowCount;
    double scaleFactor = 1 - (currentLevel - 1) * 0.1;
    double tileSize =
        (maxTileWidth < maxTileHeight ? maxTileWidth : maxTileHeight) *
            scaleFactor;

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(_title, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        flexibleSpace: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 3.0),
            child: Text(
              '${widget.selectedLanguage == 'Polski' ? 'Czas' : 'Time'}: $_elapsedTime ${widget.selectedLanguage == 'Polski' ? 'sekund' : 'seconds'}  |  ${widget.selectedLanguage == 'Polski' ? 'Życia' : 'Lives'}: $lives',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          color: widget.isDarkMode ? Colors.grey[850] : Colors.lightBlue[100],
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '$currentLevel: $_instruction',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  padding: const EdgeInsets.all(10),
                  itemCount: numbers.length,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _onTileTap(numbers[index]),
                      child: Container(
                        width: tileSize,
                        height: tileSize,
                        decoration: BoxDecoration(
                          color: tileColors[numbers[index] - 1],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${numbers[index]}',
                            style: TextStyle(
                              fontSize: tileSize * 0.3,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
