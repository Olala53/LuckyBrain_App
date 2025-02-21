import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/game_result.dart';
import '../screens/statistics_screen.dart' show StatisticsScreen;

class GameScreen extends StatefulWidget {
  final String selectedLanguage;
  final bool isDarkMode;
  final bool isSoundEnabled;

  const GameScreen(
      {Key? key,
      required this.selectedLanguage,
      required this.isDarkMode,
      required this.isSoundEnabled})
      : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Offset squarePosition = Offset.zero;
  double squareSize = 300.0;
  int difficultyLevel = 1;
  int score = 0;
  bool gameOver = false;
  int commandIndex = 0;
  String currentCommand = '';
  bool commandCompleted = false;

  late final List<String> commands;

  Future<void> _saveGameResult() async {
    for (int level = 1; level <= 4; level++) {
      if (level == difficultyLevel) {
        final result = GameResult(
          category: 'coordination',
          gameName: 'coordination_level_$level',
          score: score,
          date: DateTime.now(),
        ).toMap();

        final box = await Hive.openBox<Map>('gameResults');
        await box.add(result);
      } else {
        final result = GameResult(
          category: 'coordination',
          gameName: 'coordination_level_$level',
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

    commands = widget.selectedLanguage == 'Polski'
        ? [
            'Kliknij na kwadrat prawą ręką',
            'Kliknij na kwadrat prawą ręką z zamkniętym prawym okiem',
            'Kliknij na kwadrat prawą ręką z zamkniętym lewym okiem',
            'Kliknij na kwadrat lewą ręką',
            'Kliknij na kwadrat lewą ręką z zamkniętym prawym okiem',
            'Kliknij na kwadrat lewą ręką z zamkniętym lewym okiem',
          ]
        : [
            'Click on the square with your right hand',
            'Click on the square with your right hand with your right eye closed',
            'Click on the square with your right hand with your left eye closed',
            'Click on the square with your left hand',
            'Click on the square with your left hand with your right eye closed',
            'Click on the square with your left hand with your left eye closed',
          ];

    _setSquareProperties();
    Future.delayed(const Duration(seconds: 2), () {
      _playCurrentCommand();
    });
  }

  void _setSquareProperties() {
    setState(() {
      switch (difficultyLevel) {
        case 1:
          squareSize = 350.0;
          break;
        case 2:
          squareSize = 220.0;
          break;
        case 3:
          squareSize = 100.0;
          break;
        case 4:
          squareSize = 60.0;
          break;
      }
      _setRandomSquarePosition();
    });
  }

  void _setRandomSquarePosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final random = Random();
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final maxX = screenWidth - squareSize;
      final maxY = screenHeight - squareSize - 300;

      setState(() {
        squarePosition = Offset(random.nextDouble() * maxX,
            100 + random.nextDouble() * (maxY - 100));
      });
    });
  }

  Future<void> _playCurrentCommand() async {
    if (widget.isSoundEnabled) {
      setState(() {
        currentCommand = commands[commandIndex];
        commandCompleted = false;
      });

      final String languageSuffix =
          widget.selectedLanguage == 'Polski' ? 'pl' : '';
      final String commandFileName =
          'assets/commands/command$commandIndex$languageSuffix.mp3';

      try {
        await _audioPlayer.play(commandFileName);
      } catch (e) {
        print("Audio file not found: $commandFileName");
      }
    }
  }

  Future<void> _playCorrectSound() async {
    if (widget.isSoundEnabled) {
      try {
        await _audioPlayer.play('assets/sounds/correct.mp3');
      } catch (e) {
        print("Audio file not found: assets/sounds/correct.mp3");
      }
    }
  }

  void _checkHit(Offset tapPosition) {
    if (commandCompleted) return;

    final dx = tapPosition.dx;
    final dy = tapPosition.dy;

    if (dx >= squarePosition.dx &&
        dx <= squarePosition.dx + squareSize &&
        dy >= squarePosition.dy &&
        dy <= squarePosition.dy + squareSize) {
      commandCompleted = true;
      _playCorrectSound().then((_) {
        setState(() {
          score++;
          if (commandIndex < commands.length - 1) {
            commandIndex++;
          } else {
            commandIndex = 0;
            if (difficultyLevel < 4) {
              difficultyLevel++;
            } else {
              gameOver = true;
            }
          }
        });
        _setSquareProperties();
        Future.delayed(const Duration(seconds: 1), () => _playCurrentCommand());
      });
    } else {
      setState(() {
        commandCompleted = true;
        if (difficultyLevel > 1) {
          difficultyLevel--;
        }
        commandIndex = 0;
      });
      _setSquareProperties();
      Future.delayed(const Duration(seconds: 1), () => _playCurrentCommand());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.selectedLanguage == 'Polski'
                  ? 'Koordynacja'
                  : 'Coordination',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${widget.selectedLanguage == 'Polski' ? 'Wynik' : 'Score'}: $score',
                style: const TextStyle(fontSize: 18, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        actions: [
          DropdownButton<int>(
            value: difficultyLevel,
            icon: const Icon(
              Icons.arrow_drop_down,
              color: Colors.white,
            ),
            dropdownColor: Colors.black,
            onChanged: (int? newValue) {
              if (newValue != null) {
                _saveGameResult().then((_) {
                  setState(() {
                    difficultyLevel = newValue;
                    score = 0;
                    _setSquareProperties();
                    commandIndex = 0;
                    _playCurrentCommand();
                  });
                });
              }
            },
            items: [
              DropdownMenuItem<int>(
                value: 1,
                child: Text(
                  widget.selectedLanguage == 'Polski' ? 'Łatwy' : 'Easy',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              DropdownMenuItem<int>(
                value: 2,
                child: Text(
                  widget.selectedLanguage == 'Polski' ? 'Średni' : 'Medium',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              DropdownMenuItem<int>(
                value: 3,
                child: Text(
                  widget.selectedLanguage == 'Polski' ? 'Trudny' : 'Hard',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              DropdownMenuItem<int>(
                value: 4,
                child: Text(
                  widget.selectedLanguage == 'Polski' ? 'Ekspert' : 'Expert',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
      body: gameOver
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.selectedLanguage == 'Polski'
                        ? 'Koniec gry'
                        : 'Game Over',
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${widget.selectedLanguage == 'Polski' ? 'Twój wynik' : 'Your score'}: $score',
                    style: const TextStyle(fontSize: 24, color: Colors.black),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _saveGameResult().then((_) {
                            setState(() {
                              score = 0;
                              difficultyLevel = 1;
                              gameOver = false;
                              commandIndex = 0;
                              _setSquareProperties();
                              _playCurrentCommand();
                            });
                          });
                        },
                        child: Text(widget.selectedLanguage == 'Polski'
                            ? 'Zagraj ponownie'
                            : 'Play Again'),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () {
                          _saveGameResult().then((_) {
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
                          });
                        },
                        child: Text(widget.selectedLanguage == 'Polski'
                            ? 'Statystyki'
                            : 'Statistics'),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : GestureDetector(
              onTapDown: (details) => _checkHit(details.localPosition),
              child: Container(
                color: widget.isDarkMode
                    ? Colors.grey[850]
                    : Colors.lightBlue[100],
                child: Stack(
                  children: [
                    Positioned(
                      top: 50,
                      left: 20,
                      right: 20,
                      child: Center(
                        child: Text(
                          currentCommand,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Positioned(
                      top: squarePosition.dy,
                      left: squarePosition.dx,
                      child: Container(
                        width: squareSize,
                        height: squareSize,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
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
    _audioPlayer.dispose();
    super.dispose();
  }
}
