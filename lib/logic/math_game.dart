import 'package:flutter/material.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/game_result.dart';

void main() => runApp(const MathGameApp());

class MathGameApp extends StatelessWidget {
  const MathGameApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LanguageSelectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LanguageSelectionScreen extends StatefulWidget {
  @override
  _LanguageSelectionScreenState createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  bool _isDarkMode = false;
  bool _isSoundEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Language / Wybierz Język'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MathGame(
                      selectedLanguage: 'English',
                      isDarkMode: _isDarkMode,
                      isSoundEnabled: _isSoundEnabled,
                    ),
                  ),
                );
              },
              child: const Text('English'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MathGame(
                      selectedLanguage: 'Polski',
                      isDarkMode: _isDarkMode,
                      isSoundEnabled: _isSoundEnabled,
                    ),
                  ),
                );
              },
              child: const Text('Polski'),
            ),
            SwitchListTile(
              title: Text(_isDarkMode ? 'Dark Mode' : 'Light Mode'),
              value: _isDarkMode,
              onChanged: (bool value) {
                setState(() {
                  _isDarkMode = value;
                });
              },
            ),
            SwitchListTile(
              title: Text(_isSoundEnabled ? 'Sound Enabled' : 'Sound Disabled'),
              value: _isSoundEnabled,
              onChanged: (bool value) {
                setState(() {
                  _isSoundEnabled = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MathGame extends StatefulWidget {
  final String selectedLanguage;
  final bool isDarkMode;
  final bool isSoundEnabled;

  const MathGame(
      {Key? key,
      required this.selectedLanguage,
      required this.isDarkMode,
      required this.isSoundEnabled})
      : super(key: key);

  @override
  _MathGameState createState() => _MathGameState();
}

class _MathGameState extends State<MathGame> {
  int _score = 0;
  int _rounds = 0;
  int _firstNum = 0;
  int _secondNum = 0;
  int _correctAnswer = 0;
  int _currentLevel = 1;
  String _operation = '+';
  List<int> _options = [];
  final Random _random = Random();
  bool _showRestartButton = false;
  List<bool> _isSelected = [false, false, false, false];
  bool _shouldAdvanceLevel = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  String _instruction = '';

  Future<void> _saveGameResult() async {
    for (int level = 1; level <= 3; level++) {
      if (level == _currentLevel) {
        final result = GameResult(
          category: 'math_game',
          gameName: 'math_game_level_$level',
          score: _score,
          date: DateTime.now(),
        ).toMap();

        final box = await Hive.openBox<Map>('gameResults');
        await box.add(result);
      } else {
        final result = GameResult(
          category: 'math_game',
          gameName: 'math_game_level_$level',
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
    _generateQuestion();
    Future.delayed(Duration(seconds: 2), _playInstructionAudio);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _tts.stop();
    super.dispose();
  }

  void _setLanguageSpecificInstructions() async {
    if (widget.selectedLanguage == 'Polski') {
      _instruction = 'Wybierz poprawny wynik';
      await _tts.setLanguage('pl-PL');
      await _tts.setVolume(1.5);
      await _tts.setSpeechRate(1);
    } else {
      _instruction = 'Choose the correct result';
      await _tts.setLanguage('en-US');
      await _tts.setVolume(0.5);
    }
  }

  Future<void> _playInstructionAudio() async {
    if (widget.isSoundEnabled) {
      await _tts.speak(_instruction);
      await _tts.awaitSpeakCompletion(true);
    }
  }

  Future<void> _playSound(String sound) async {
    if (widget.isSoundEnabled) {
      await _audioPlayer.play('assets/sounds/$sound.mp3', isLocal: true);
    }
  }

  void _generateQuestion() {
    if (_random.nextBool()) {
      _firstNum = _random.nextInt(10);
      _secondNum = _random.nextInt(10 - _firstNum);
      _correctAnswer = _firstNum + _secondNum;
      _operation = '+';
    } else {
      _firstNum = _random.nextInt(10) + 1;
      _secondNum = _random.nextInt(_firstNum);
      _correctAnswer = _firstNum - _secondNum;
      _operation = '-';
    }

    _options = _generateUniqueOptions();
    _isSelected = [false, false, false, false];
  }

  List<int> _generateUniqueOptions() {
    Set<int> uniqueOptions = {_correctAnswer};

    while (uniqueOptions.length < 4) {
      uniqueOptions.add(_random.nextInt(11));
    }

    return uniqueOptions.toList()..shuffle();
  }

  void _handleAnswer(int selected, int index) async {
    if (_showRestartButton) return;

    setState(() {
      _isSelected[index] = true;

      if (selected == _correctAnswer) {
        _score++;
        _playSound('correct');
      } else {
        _playSound('beep1');
      }

      _rounds++;

      if (_rounds < 10) {
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() {
            _generateQuestion();
          });
        });
      } else {
        _handleGameEnd();
      }
    });
  }

  void _handleGameEnd() async {
    await _saveGameResult();

    if (_score >= 7 && _currentLevel < 3) {
      _shouldAdvanceLevel = true;
      _currentLevel++;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              widget.selectedLanguage == 'Polski'
                  ? 'Gratulacje!'
                  : 'Congratulations!',
            ),
            content: Text(widget.selectedLanguage == 'Polski'
                ? 'Świetnie! Przechodzisz do poziomu ${_getLevelName(_currentLevel)}!'
                : 'Great job! You\'re advancing to ${_getLevelName(_currentLevel)} level!'),
            actions: [
              TextButton(
                child: Text(widget.selectedLanguage == 'Polski'
                    ? 'Kontynuuj'
                    : 'Continue'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _restartGame();
                },
              ),
            ],
          );
        },
      );
    } else if (_score < 7) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              widget.selectedLanguage == 'Polski'
                  ? 'Spróbuj jeszcze raz'
                  : 'Try Again',
            ),
            content: Text(widget.selectedLanguage == 'Polski'
                ? 'Potrzebujesz więcej praktyki na tym poziomie.'
                : 'You need more practice at this level.'),
            actions: [
              TextButton(
                child: Text(widget.selectedLanguage == 'Polski'
                    ? 'Kontynuuj'
                    : 'Continue'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _restartGame();
                },
              ),
            ],
          );
        },
      );
    }

    _showRestartButton = true;
  }

  String _getLevelName(int level) {
    if (widget.selectedLanguage == 'Polski') {
      switch (level) {
        case 1:
          return 'łatwego';
        case 2:
          return 'średniego';
        case 3:
          return 'trudnego';
        default:
          return '';
      }
    } else {
      switch (level) {
        case 1:
          return 'Easy';
        case 2:
          return 'Medium';
        case 3:
          return 'Hard';
        default:
          return '';
      }
    }
  }

  void _generateQuestionMedium() {
    if (_random.nextBool()) {
      _firstNum = 10 + _random.nextInt(11);
      _secondNum = 10 + _random.nextInt(11 - (_firstNum - 10));
      _correctAnswer = _firstNum + _secondNum;
      _operation = '+';
    } else {
      _firstNum = 10 + _random.nextInt(11);
      _secondNum = _random.nextInt(_firstNum - 9);
      _correctAnswer = _firstNum - _secondNum;
      _operation = '-';
    }
    _options = _generateUniqueOptionsMedium();
    _isSelected = [false, false, false, false];
  }

  void _generateQuestionHard() {
    int operationType = _random.nextInt(3);

    switch (operationType) {
      case 0:
        _firstNum = 20 + _random.nextInt(31);
        _secondNum = 20 + _random.nextInt(31 - (_firstNum - 20));
        _correctAnswer = _firstNum + _secondNum;
        _operation = '+';
        break;
      case 1:
        _firstNum = 20 + _random.nextInt(31);
        _secondNum = _random.nextInt(_firstNum - 19);
        _correctAnswer = _firstNum - _secondNum;
        _operation = '-';
        break;
      case 2:
        _firstNum = 2 + _random.nextInt(9);
        _secondNum = 2 + _random.nextInt(9);
        _correctAnswer = _firstNum * _secondNum;
        _operation = '×';
        break;
    }
    _options = _generateUniqueOptionsHard();
    _isSelected = [false, false, false, false];
  }

  List<int> _generateUniqueOptionsMedium() {
    Set<int> uniqueOptions = {_correctAnswer};
    while (uniqueOptions.length < 4) {
      int variation = _random.nextInt(5) - 2;
      uniqueOptions.add(_correctAnswer + variation);
    }
    return uniqueOptions.toList()..shuffle();
  }

  List<int> _generateUniqueOptionsHard() {
    Set<int> uniqueOptions = {_correctAnswer};
    while (uniqueOptions.length < 4) {
      int variation = _random.nextInt(10) - 5;
      uniqueOptions.add(_correctAnswer + variation);
    }
    return uniqueOptions.toList()..shuffle();
  }

  void _setLevel(int level) {
    setState(() {
      _currentLevel = level;
      switch (level) {
        case 1:
          _generateQuestion();
          break;
        case 2:
          _generateQuestionMedium();
          break;
        case 3:
          _generateQuestionHard();
          break;
      }
    });
  }

  void _restartGame() {
    setState(() {
      _score = 0;
      _rounds = 0;
      _showRestartButton = false;

      switch (_currentLevel) {
        case 1:
          _generateQuestion();
          break;
        case 2:
          _generateQuestionMedium();
          break;
        case 3:
          _generateQuestionHard();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.selectedLanguage == 'Polski' ? 'Matematyka' : 'Math',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              widget.selectedLanguage == 'Polski'
                  ? 'Wynik: $_score / 10'
                  : 'Score: $_score / 10',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            DropdownButton<int>(
              value: _currentLevel,
              dropdownColor: Colors.black,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: const TextStyle(color: Colors.white),
              underline: Container(),
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
              ],
              onChanged: (int? newValue) {
                if (newValue != null) {
                  _setLevel(newValue);
                  _restartGame();
                }
              },
            ),
          ],
        ),
      ),
      backgroundColor:
          widget.isDarkMode ? Colors.grey[850] : Colors.lightBlue[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double screenWidth = constraints.maxWidth;
          final double screenHeight = constraints.maxHeight;
          final double tileHeight = screenHeight / 2.8;
          final double tileWidth = screenWidth / 2.1;
          final double childAspectRatio = tileWidth / tileHeight;

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  widget.selectedLanguage == 'Polski'
                      ? 'Wybierz poprawny wynik'
                      : 'Choose the correct result',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  '$_firstNum $_operation $_secondNum = ?',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 25),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15.0,
                      mainAxisSpacing: 15.0,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemCount: _options.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          if (!_isSelected[index]) {
                            _handleAnswer(_options[index], index);
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isSelected[index]
                                ? (_options[index] == _correctAnswer
                                    ? Colors.green
                                    : Colors.red)
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${_options[index]}',
                              style: TextStyle(
                                fontSize: 36,
                                color: _isSelected[index]
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_showRestartButton)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                    child: ElevatedButton(
                      onPressed: _restartGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          vertical: 15.0,
                          horizontal: 30.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        widget.selectedLanguage == 'Polski'
                            ? 'Zacznij od nowa'
                            : 'Restart Game',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
