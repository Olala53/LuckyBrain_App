import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/game_result.dart';
import '../screens/statistics_screen.dart';

class MemoryNumbersGameApp extends StatelessWidget {
  final String selectedLanguage;
  final bool isDarkMode;
  final bool isSoundEnabled;

  const MemoryNumbersGameApp(
      {Key? key,
      required this.selectedLanguage,
      required this.isDarkMode,
      required this.isSoundEnabled})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MemoryNumbersGame(
        selectedLanguage: selectedLanguage,
        isDarkMode: isDarkMode,
        isSoundEnabled: isSoundEnabled);
  }
}

class MemoryNumbersGame extends StatefulWidget {
  final String selectedLanguage;
  final bool isDarkMode;
  final bool isSoundEnabled;

  const MemoryNumbersGame({
    Key? key,
    required this.selectedLanguage,
    required this.isDarkMode,
    required this.isSoundEnabled,
  }) : super(key: key);

  @override
  _MemoryNumbersGameState createState() => _MemoryNumbersGameState();
}

class _MemoryNumbersGameState extends State<MemoryNumbersGame> {
  final List<int> numberSequence = [];
  final List<int> shuffledSequence = [];
  final List<int> userInput = [];
  int score = 0;
  int round = 0;
  int difficulty = 1;
  bool gameActive = false;
  bool sequenceDisplaying = false;
  bool userTurn = false;
  bool wrongSelection = false;
  int currentIndex = 0;
  late Timer _timer;
  List<Color> tileColors = [];
  bool showInitialInstruction = true;

  late AudioPlayer _audioPlayer;
  final FlutterTts _tts = FlutterTts();

  late String _instruction;
  late String _scoreText;
  late String _startButtonText;

  @override
  void initState() {
    super.initState();
    _setupLanguage();
    _resetGame();
    _audioPlayer = AudioPlayer();
    Future.delayed(const Duration(seconds: 2), _playInstructionAudio);
  }

  void _setupLanguage() {
    if (widget.selectedLanguage == 'Polski') {
      _instruction = 'Kliknij liczby w odpowiedniej kolejności';
      _scoreText = 'Wynik';
      _startButtonText = 'Start';
      _tts.setLanguage('pl-PL');
      _tts.setVolume(1.5);
      _tts.setSpeechRate(1);
    } else {
      _instruction = 'Click the numbers in the right order';
      _scoreText = 'Score';
      _startButtonText = 'Start';
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

  Future<void> _playSound(String soundName) async {
    if (widget.isSoundEnabled) {
      await _audioPlayer.play('assets/sounds/$soundName.mp3', isLocal: true);
    }
  }

  Future<void> _saveGameResult() async {
    int finalScore = ((score / 10) * 100).round();

    final result = GameResult(
      category: 'memory',
      gameName: 'memory_numbers',
      score: finalScore,
      date: DateTime.now(),
    ).toMap();

    final box = await Hive.openBox<Map>('gameResults');
    await box.add(result);
  }

  void _showGameOverDialog() async {
    await _saveGameResult();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
            widget.selectedLanguage == 'Polski' ? 'Koniec Gry' : 'Game Over'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.selectedLanguage == 'Polski'
                ? 'Twój wynik: $score/10'
                : 'Your score: $score/10'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: Text(widget.selectedLanguage == 'Polski'
                ? 'Zagraj ponownie'
                : 'Play Again'),
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

  void _resetGame() {
    setState(() {
      score = 0;
      round = 0;
      difficulty = 1;
      gameActive = false;
      sequenceDisplaying = false;
      wrongSelection = false;
      numberSequence.clear();
      shuffledSequence.clear();
      userInput.clear();
      tileColors = List.filled(3, Colors.white);
      showInitialInstruction = true;
    });
  }

  void _startGame() {
    setState(() {
      gameActive = true;
      showInitialInstruction = false;
    });
    _nextRound();
  }

  void _nextRound() {
    if (score < 7 && round > 0) {
      round--;
    } else {
      round++;
      if (round > 3) {
        difficulty++;
        round = 1;
        tileColors = List.filled(difficulty + 2, Colors.white);
      }
    }

    userInput.clear();
    wrongSelection = false;
    _generateSequence();
    _displaySequence();
  }

  void _generateSequence() {
    final random = Random();
    numberSequence.clear();
    for (int i = 0; i < difficulty + 2; i++) {
      numberSequence.add(random.nextInt(10));
    }
    shuffledSequence
      ..clear()
      ..addAll(numberSequence)
      ..shuffle();
  }

  void _displaySequence() {
    setState(() {
      sequenceDisplaying = true;
      userTurn = false;
      currentIndex = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (currentIndex < numberSequence.length) {
          currentIndex++;
        } else {
          timer.cancel();
          Future.delayed(const Duration(seconds: 1), () {
            setState(() {
              sequenceDisplaying = false;
            });
            Future.delayed(
                const Duration(seconds: 1), _displayShuffledSequence);
          });
        }
      });
    });
  }

  void _displayShuffledSequence() {
    setState(() {
      sequenceDisplaying = false;
      userTurn = true;
      currentIndex = 0;
      tileColors = List.filled(difficulty + 2, Colors.white);
    });
  }

  void _checkInput(int number, int index) {
    if (!gameActive || sequenceDisplaying || !userTurn || wrongSelection) {
      return;
    }

    userInput.add(number);

    setState(() {
      if (number == numberSequence[userInput.length - 1]) {
        tileColors[index] = Colors.green;
        _playSound('correct');
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() {
            tileColors[index] = Colors.white;
          });
        });
        if (userInput.length == numberSequence.length) {
          score++;
          if (score >= 10) {
            _showGameOverDialog();
          } else {
            Future.delayed(const Duration(milliseconds: 500), _nextRound);
          }
        }
      } else {
        tileColors[index] = Colors.red;
        _playSound('beep1');
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() {
            tileColors[index] = Colors.white;
          });
        });
        wrongSelection = true;
        _showGameOverDialog();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double itemSize =
        (MediaQuery.of(context).size.width - 40) / (difficulty + 2);

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
            widget.selectedLanguage == 'Polski'
                ? 'Zapamiętaj liczby'
                : 'MemoryNumber',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        flexibleSpace: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 3.0),
            child: Text(
              '$_scoreText: $score/10',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          color: widget.isDarkMode ? Colors.grey[850] : Colors.lightBlue[100],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (showInitialInstruction)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10.0),
                  child: Text(
                    _instruction,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(difficulty + 2, (index) {
                  return GestureDetector(
                    onTap: userTurn && !wrongSelection
                        ? () => _checkInput(shuffledSequence[index], index)
                        : null,
                    child: Container(
                      width: itemSize,
                      height: itemSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tileColors[index] == Colors.white
                            ? (widget.isDarkMode
                                ? Colors.grey
                                : Colors.grey[300])
                            : tileColors[index],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.black, width: 3),
                      ),
                      child: Text(
                        sequenceDisplaying && currentIndex > index
                            ? numberSequence[index].toString()
                            : userTurn
                                ? shuffledSequence[index].toString()
                                : '',
                        style: const TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 50),
              if (!gameActive)
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 80, vertical: 20),
                    textStyle: const TextStyle(fontSize: 28),
                  ),
                  child: Text(_startButtonText),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _audioPlayer.dispose();
    _tts.stop();
    super.dispose();
  }
}
