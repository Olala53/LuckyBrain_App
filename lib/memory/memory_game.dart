import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/game_result.dart';
import '../screens/statistics_screen.dart' show StatisticsScreen;

class MemoryGame extends StatefulWidget {
  final String selectedLanguage;
  final bool isDarkMode;
  final bool isSoundEnabled;

  const MemoryGame(
      {Key? key,
      required this.selectedLanguage,
      required this.isDarkMode,
      required this.isSoundEnabled})
      : super(key: key);

  @override
  _MemoryGameState createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> {
  final List<Color> _colors = [
    Colors.black,
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.red,
    Colors.yellow,
  ];

  List<String> _cards = [];
  List<bool> _selectedCards = List.generate(12, (_) => false);
  List<bool> _matchedCards = List.generate(12, (_) => false);
  int _firstSelectedIndex = -1;
  int _secondSelectedIndex = -1;
  bool _canFlip = true;
  bool _isGameStarted = false;

  Timer? _timer;
  int _elapsedSeconds = 0;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  late String _instruction;
  late String _title;
  late String _congratulationsMessage;
  late String _gameOverMessage;

  Future<void> _playInstructionAudio() async {
    if (widget.isSoundEnabled) {
      await _tts.speak(_instruction);
      await _tts.awaitSpeakCompletion(true);
    }
  }

  Future<void> _saveGameResult() async {
    int score = max(0, 100 - _elapsedSeconds);

    final result = GameResult(
      category: 'memory',
      gameName: 'memory_game',
      score: score,
      date: DateTime.now(),
    ).toMap();

    final box = await Hive.openBox<Map>('gameResults');
    await box.add(result);
  }

  @override
  void initState() {
    super.initState();
    _setupLanguage();
    _setupCards();
    Future.delayed(Duration(seconds: 2), _playInstructionAudio);
  }

  void _setupLanguage() {
    if (widget.selectedLanguage == 'Polski') {
      _instruction = 'Znajdź wszystkie pary kart';
      _title = 'Pamięć';
      _congratulationsMessage = 'Gratulacje! Ukończyłeś grę!';
      _gameOverMessage = 'Koniec gry! Spróbuj ponownie.';
      _tts.setLanguage('pl-PL');
      _tts.setVolume(1.5);
      _tts.setSpeechRate(1);
    } else {
      _instruction = 'Find all pairs of cards';
      _title = 'Memory';
      _congratulationsMessage = 'Congratulations! You completed the game!';
      _gameOverMessage = 'Game Over! Try again.';
      _tts.setLanguage('en-US');
      _tts.setVolume(0.5);
    }
  }

  void _showGameOverDialog(String message) async {
    await _saveGameResult();

    int score = max(0, 100 - _elapsedSeconds);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
            widget.selectedLanguage == 'Polski' ? 'Koniec Gry' : 'Game Over'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            SizedBox(height: 10),
            Text(widget.selectedLanguage == 'Polski'
                ? 'Twój czas: $_elapsedSeconds sekund\nWynik: $score punktów'
                : 'Your time: $_elapsedSeconds seconds\nScore: $score points'),
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

  void _setupCards() {
    _cards =
        List.generate(_colors.length, (index) => _colors[index].toString());
    _cards.addAll(
        List.generate(_colors.length, (index) => _colors[index].toString()));
    _cards.shuffle(Random());
  }

  Color _colorFromString(String colorString) {
    return _colors.firstWhere((color) => color.toString() == colorString,
        orElse: () => Colors.grey);
  }

  void _handleCardTap(int index) {
    if (!_isGameStarted) {
      _startTimer();
      _isGameStarted = true;
    }

    if (_canFlip && !_matchedCards[index] && !_selectedCards[index]) {
      setState(() {
        _selectedCards[index] = true;
        if (_firstSelectedIndex == -1) {
          _firstSelectedIndex = index;
        } else {
          _secondSelectedIndex = index;
          _canFlip = false;
          _checkMatch();
        }
      });
    }
  }

  void _checkMatch() {
    if (_cards[_firstSelectedIndex] == _cards[_secondSelectedIndex]) {
      setState(() {
        _matchedCards[_firstSelectedIndex] = true;
        _matchedCards[_secondSelectedIndex] = true;
        _resetSelection();
        if (_matchedCards.every((matched) => matched)) {
          _stopTimer();
          _showGameOverDialog(_congratulationsMessage);
        }
      });
      if (widget.isSoundEnabled) {
        _audioPlayer.play('assets/sounds/positive.mp3');
      }
    } else {
      Timer(Duration(seconds: 1), () {
        setState(() {
          _selectedCards[_firstSelectedIndex] = false;
          _selectedCards[_secondSelectedIndex] = false;
          _resetSelection();
        });
      });
    }
  }

  void _resetSelection() {
    _firstSelectedIndex = -1;
    _secondSelectedIndex = -1;
    _canFlip = true;
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _resetGame() {
    setState(() {
      _setupCards();
      _selectedCards = List.generate(12, (_) => false);
      _matchedCards = List.generate(12, (_) => false);
      _firstSelectedIndex = -1;
      _secondSelectedIndex = -1;
      _canFlip = true;
      _isGameStarted = false;
      _elapsedSeconds = 0;
    });
    Future.delayed(Duration(seconds: 2), _playInstructionAudio);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(_title, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        flexibleSpace: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 3.0),
            child: Text(
              '${widget.selectedLanguage == 'Polski' ? 'Czas' : 'Time'}: $_elapsedSeconds ${widget.selectedLanguage == 'Polski' ? 'sekund' : 'seconds'}',
              style: TextStyle(fontSize: 18, color: Colors.white),
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
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double cardWidth = constraints.maxWidth / 4;
                    final double cardHeight = constraints.maxHeight / 3;

                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: cardWidth / cardHeight,
                      ),
                      itemCount: _cards.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _handleCardTap(index),
                          child: Container(
                            margin: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey, width: 3),
                              borderRadius: BorderRadius.circular(15),
                              color:
                                  _selectedCards[index] || _matchedCards[index]
                                      ? _colorFromString(_cards[index])
                                      : (widget.isDarkMode
                                          ? Colors.grey
                                          : Colors.grey[300]),
                            ),
                          ),
                        );
                      },
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

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    _tts.stop();
    super.dispose();
  }
}
