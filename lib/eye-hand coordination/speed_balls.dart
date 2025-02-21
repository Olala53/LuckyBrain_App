import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/game_result.dart';
import '../screens/statistics_screen.dart' show StatisticsScreen;

class SpeedBallsGame extends StatefulWidget {
  final String selectedLanguage;
  final bool isDarkMode;
  final bool isSoundEnabled;

  const SpeedBallsGame(
      {Key? key,
      required this.selectedLanguage,
      required this.isDarkMode,
      required this.isSoundEnabled})
      : super(key: key);

  @override
  _SpeedBallsGameState createState() => _SpeedBallsGameState();
}

class _SpeedBallsGameState extends State<SpeedBallsGame> {
  final int _levelDuration = 15;
  int _score = 0;
  int _timeLeft = 15;
  Timer? _gameTimer;
  Timer? _circleTimer;
  List<Offset> _circles = [];
  bool _gameActive = false;
  bool _levelCompleted = false;
  double _circleSize = 120.0;
  int _circleFallSpeed = 60;
  int _circleSpawnRate = 800;
  int _maxCircles = 5;
  int _currentLevel = 1;
  late double _screenHeight;
  late double _screenWidth;
  Random _random = Random();
  AudioPlayer _audioPlayer = AudioPlayer();
  FlutterTts _tts = FlutterTts();

  late String _instruction;

  Future<void> _saveGameResult() async {
    for (int level = 1; level <= 4; level++) {
      if (level == _currentLevel) {
        final result = GameResult(
          category: 'speed_balls',
          gameName: 'speed_balls_level_$level',
          score: _score,
          date: DateTime.now(),
        ).toMap();

        final box = await Hive.openBox<Map>('gameResults');
        await box.add(result);
      } else {
        final result = GameResult(
          category: 'speed_balls',
          gameName: 'speed_balls_level_$level',
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
    _setLanguageSpecificInstructions();
    Future.delayed(Duration(seconds: 2), _playInstructionAudio);
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _circleTimer?.cancel();
    _audioPlayer.dispose();
    _tts.stop();
    super.dispose();
  }

  void _setLanguageSpecificInstructions() async {
    if (widget.selectedLanguage == 'Polski') {
      _instruction = 'Kliknij na kulki jak najszybciej';
      await _tts.setLanguage('pl-PL');
      _tts.setVolume(1.5);
      _tts.setSpeechRate(1);
    } else {
      _instruction = 'Click on the balls as quickly as possible';
      await _tts.setLanguage('en-US');
      _tts.setVolume(0.5);
    }
  }

  Future<void> _playInstructionAudio() async {
    if (widget.isSoundEnabled) {
      await _tts.speak(_instruction);
      await _tts.awaitSpeakCompletion(true);
    }
  }

  void _startLevel() {
    setState(() {
      _score = 0;
      _timeLeft = _levelDuration;
      _circles.clear();
      _gameActive = true;
      _levelCompleted = false;
      _setDifficulty();
    });

    _gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          _endLevel();
        }
      });
    });

    _circleTimer =
        Timer.periodic(Duration(milliseconds: _circleSpawnRate), (timer) {
      _updateCircles();
      if (_circles.length < _maxCircles) _spawnNewCircle();
    });
  }

  void _endLevel() async {
    _gameTimer?.cancel();
    _circleTimer?.cancel();

    await _saveGameResult();

    setState(() {
      _gameActive = false;
      _levelCompleted = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(widget.selectedLanguage == 'Polski'
            ? 'Koniec Poziomu'
            : 'Level Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.selectedLanguage == 'Polski'
                ? 'Poziom $_currentLevel ukończony!\nTwój wynik: $_score punktów'
                : 'Level $_currentLevel completed!\nYour score: $_score points'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_currentLevel < 4) {
                _nextLevel();
              } else {
                _showGameOverDialog();
              }
            },
            child: Text(
                widget.selectedLanguage == 'Polski' ? 'Dalej' : 'Continue'),
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

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.selectedLanguage == 'Polski'
              ? "Gratulacje!"
              : "Congratulations!"),
          content: Text(widget.selectedLanguage == 'Polski'
              ? "Ukończyłeś wszystkie poziomy!"
              : "You've completed all levels!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _currentLevel = 1;
                });
                _startLevel();
              },
              child: Text(widget.selectedLanguage == 'Polski'
                  ? "Restartuj"
                  : "Restart"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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
                  ? "Statystyki"
                  : "Statistics"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context);
              },
              child:
                  Text(widget.selectedLanguage == 'Polski' ? "Wyjdź" : "Exit"),
            ),
          ],
        );
      },
    );
  }

  void _setDifficulty() {
    switch (_currentLevel) {
      case 1:
        _circleSize = 180.0;
        _circleFallSpeed = 50;
        _circleSpawnRate = 800;
        _maxCircles = 5;
        break;
      case 2:
        _circleSize = 150.0;
        _circleFallSpeed = 60;
        _circleSpawnRate = 700;
        _maxCircles = 6;
        break;
      case 3:
        _circleSize = 120.0;
        _circleFallSpeed = 70;
        _circleSpawnRate = 600;
        _maxCircles = 7;
        break;
      case 4:
        _circleSize = 100.0;
        _circleFallSpeed = 80;
        _circleSpawnRate = 550;
        _maxCircles = 8;
        break;
    }
  }

  void _nextLevel() {
    if (_currentLevel < 4) {
      setState(() {
        _currentLevel++;
        _startLevel();
      });
    } else {
      setState(() {
        _levelCompleted = false;
        _gameActive = false;
      });
    }
  }

  void _spawnNewCircle() {
    setState(() {
      _circles.add(Offset(_random.nextDouble() * _screenWidth, 0));
    });
  }

  void _updateCircles() {
    setState(() {
      for (int i = 0; i < _circles.length; i++) {
        _circles[i] = Offset(_circles[i].dx, _circles[i].dy + _circleFallSpeed);
        if (_circles[i].dy > _screenHeight) {
          _circles.removeAt(i);
        }
      }
    });
  }

  void _handleTap(Offset position) async {
    for (int i = 0; i < _circles.length; i++) {
      if ((position - _circles[i]).distance < _circleSize / 2) {
        setState(() {
          _circles.removeAt(i);
          _score++;
        });

        if (widget.isSoundEnabled) {
          await _audioPlayer.play('assets/sounds/correct.mp3', isLocal: true);
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _screenHeight = MediaQuery.of(context).size.height;
    _screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.selectedLanguage == 'Polski'
                  ? 'Szybkie piłki'
                  : 'Speed Balls',
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
            Text(
              widget.selectedLanguage == 'Polski'
                  ? 'Punkty: $_score'
                  : 'Score: $_score',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            Text(
              widget.selectedLanguage == 'Polski'
                  ? 'Czas: $_timeLeft sekund'
                  : 'Time: $_timeLeft seconds',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            DropdownButton<String>(
              value: widget.selectedLanguage == 'Polski'
                  ? 'Poziom $_currentLevel'
                  : 'Level $_currentLevel',
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              onChanged: (String? newValue) {
                setState(() {
                  _currentLevel = int.parse(newValue!.split(' ')[1]);
                  _startLevel();
                });
              },
              items: <String>[
                widget.selectedLanguage == 'Polski' ? 'Poziom 1' : 'Level 1',
                widget.selectedLanguage == 'Polski' ? 'Poziom 2' : 'Level 2',
                widget.selectedLanguage == 'Polski' ? 'Poziom 3' : 'Level 3',
                widget.selectedLanguage == 'Polski' ? 'Poziom 4' : 'Level 4',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      backgroundColor:
          widget.isDarkMode ? Colors.grey[850] : Colors.lightBlue[100],
      body: GestureDetector(
        onTapDown: (details) {
          if (_gameActive) {
            _handleTap(details.localPosition);
          }
        },
        child: Stack(
          children: [
            ..._circles.map((circle) => Positioned(
                  left: circle.dx - _circleSize / 2,
                  top: circle.dy - _circleSize / 2,
                  child: Container(
                    width: _circleSize,
                    height: _circleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                      border: Border.all(
                        color: Colors.black,
                        width: 4.0,
                      ),
                    ),
                  ),
                )),
            if (!_gameActive)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_levelCompleted)
                      Text(
                        widget.selectedLanguage == 'Polski'
                            ? 'Poziom $_currentLevel Ukończony!'
                            : 'Level $_currentLevel Completed!',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 10),
                    if (_currentLevel == 1)
                      Text(
                        widget.selectedLanguage == 'Polski'
                            ? 'Kliknij na kulki jak najszybciej'
                            : 'Click on the balls as quickly as possible',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 50),
                    ElevatedButton(
                      onPressed: _levelCompleted ? _nextLevel : _startLevel,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 80, vertical: 20),
                        textStyle: const TextStyle(fontSize: 28),
                      ),
                      child: Text(
                        _levelCompleted
                            ? (widget.selectedLanguage == 'Polski'
                                ? 'Następny Poziom'
                                : 'Next Level')
                            : (widget.selectedLanguage == 'Polski'
                                ? 'Start'
                                : 'Start'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
