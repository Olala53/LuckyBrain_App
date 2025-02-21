import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/game_result.dart';

class NumberSequenceGame extends StatefulWidget {
  final String selectedLanguage;
  final bool isDarkMode;
  final bool isSoundEnabled;

  const NumberSequenceGame(
      {Key? key,
      required this.selectedLanguage,
      required this.isDarkMode,
      required this.isSoundEnabled})
      : super(key: key);

  @override
  _NumberSequenceGameState createState() => _NumberSequenceGameState();
}

class _NumberSequenceGameState extends State<NumberSequenceGame> {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<int> currentSequence = [];
  List<int> userInput = [];
  int score = 0;
  int round = 1;
  int attempts = 0;
  int _currentLevel = 1;
  bool isAwaitingInput = false;
  List<bool?> tileColors = List.filled(10, null);

  late String _instruction;
  late String _title;

  Future<void> _saveGameResult() async {
    for (int level = 1; level <= 4; level++) {
      if (level == _currentLevel) {
        final result = GameResult(
          category: 'number_sequence',
          gameName: 'number_sequence_level_$level',
          score: score,
          date: DateTime.now(),
        ).toMap();

        final box = await Hive.openBox<Map>('gameResults');
        await box.add(result);
      } else {
        final result = GameResult(
          category: 'number_sequence',
          gameName: 'number_sequence_level_$level',
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
    _setLanguageSpecificTexts();
    _initializeGame();
  }

  void _setLanguageSpecificTexts() {
    if (widget.selectedLanguage == 'Polski') {
      _instruction = 'Kliknij liczby w odpowiedniej kolejności';
      _title = 'Liczby';
      _tts.setLanguage('pl-PL');
    } else {
      _instruction = 'Click the numbers in the right order';
      _title = 'Sequence';
      _tts.setLanguage('en-US');
    }
  }

  Future<void> _initializeGame() async {
    await Future.delayed(const Duration(seconds: 2));
    if (widget.isSoundEnabled) {
      await _playInstruction();
    }
    _startNewSequence();
  }

  Future<void> _playInstruction() async {
    await _setMaleVoice();

    if (widget.selectedLanguage == 'Polski') {
      await _tts.setVolume(1.5);
      await _tts.setSpeechRate(1);
    } else {
      await _tts.setVolume(0.5);
    }

    await _tts.speak(_instruction);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> _setMaleVoice() async {
    List<dynamic>? voices = await _tts.getVoices;

    if (voices != null) {
      String selectedLocale =
          widget.selectedLanguage == 'Polski' ? 'pl-PL' : 'en-US';

      String? selectedVoice = voices.firstWhere(
        (voice) => voice['locale'] == selectedLocale,
        orElse: () => null,
      )?['name'];

      if (selectedVoice != null) {
        await _tts.setVoice({'name': selectedVoice, 'locale': selectedLocale});
      } else {
        debugPrint('No voice found for locale $selectedLocale');
      }
    }
  }

  void _startNewSequence() {
    setState(() {
      currentSequence = _generateSequence();
      userInput.clear();
      isAwaitingInput = true;
      tileColors = List.filled(10, null);
    });
    _playSequence(currentSequence);
  }

  List<int> _generateSequence() {
    final random = Random();
    int baseLength = _currentLevel + 1;
    return List.generate(baseLength, (_) => random.nextInt(10) + 1);
  }

  Future<void> _playSequence(List<int> sequence) async {
    if (widget.selectedLanguage == 'Polski') {
      await _tts.setVolume(1.0);
    } else {
      await _tts.setVolume(0.5);
    }

    String sequenceText = sequence.join(', ');
    await _tts.speak(sequenceText);
    await _tts.awaitSpeakCompletion(true);
  }

  void _checkUserInput(int number) {
    if (!isAwaitingInput) return;

    setState(() {
      userInput.add(number);
    });

    if (userInput[userInput.length - 1] !=
        currentSequence[userInput.length - 1]) {
      tileColors[number - 1] = false;
      if (widget.isSoundEnabled) {
        _playSound('beep1.mp3');
      }
      isAwaitingInput = false;
      _handleRoundEnd(false);
      return;
    }

    tileColors[number - 1] = true;

    if (userInput.length == currentSequence.length) {
      score++;
      if (widget.isSoundEnabled) {
        _playSound('correct.mp3');
      }
      isAwaitingInput = false;
      _handleRoundEnd(true);
    }
  }

  void _handleRoundEnd(bool success) async {
    attempts++;
    if (attempts >= 10) {
      await _saveGameResult();

      if (score >= 8) {
        setState(() {
          if (_currentLevel < 4) {
            _currentLevel++;
          }
          score = 0;
          attempts = 0;
        });
      } else {
        setState(() {
          score = 0;
          attempts = 0;
        });
      }
    }

    Future.delayed(const Duration(seconds: 1), () {
      _startNewSequence();
    });
  }

  Future<void> _playSound(String soundPath) async {
    await _audioPlayer.play('assets/sounds/$soundPath', isLocal: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_title, style: const TextStyle(color: Colors.white)),
            DropdownButton<String>(
              value: widget.selectedLanguage == 'Polski'
                  ? 'Poziom $_currentLevel'
                  : 'Level $_currentLevel',
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              onChanged: (String? newValue) {
                setState(() {
                  _currentLevel = int.parse(newValue!.split(' ')[1]);
                  score = 0;
                  attempts = 0;
                  _startNewSequence();
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
        backgroundColor: Colors.black,
        flexibleSpace: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 3.0),
            child: Text(
              '${widget.selectedLanguage == 'Polski' ? 'Wynik' : 'Score'}: $score /10',
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
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _instruction,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    final number = index + 1;
                    final color = tileColors[index];
                    return GestureDetector(
                      onTap: () => _checkUserInput(number),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color == null
                              ? Colors.blueAccent
                              : color
                                  ? Colors.green
                                  : Colors.red,
                          border: Border.all(
                            color: Colors.black,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            number.toString(),
                            style: const TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(1.5, 1.5),
                                  blurRadius: 0,
                                  color: Colors.black,
                                ),
                              ],
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

  @override
  void dispose() {
    _audioPlayer.dispose();
    _tts.stop();
    super.dispose();
  }
}
