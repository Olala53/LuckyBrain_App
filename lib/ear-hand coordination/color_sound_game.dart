import 'dart:async';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/game_result.dart';

class SoundGame extends StatefulWidget {
  final String selectedLanguage;
  final bool isDarkMode;
  final bool isSoundEnabled;

  const SoundGame(
      {Key? key,
      required this.selectedLanguage,
      required this.isDarkMode,
      required this.isSoundEnabled})
      : super(key: key);

  @override
  _SoundGameState createState() => _SoundGameState();
}

class _SoundGameState extends State<SoundGame> {
  final List<Color> _tileColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow
  ];
  final List<String> _audioPaths = [
    'sounds/red_sound.mp3',
    'sounds/blue_sound.mp3',
    'sounds/green_sound.mp3',
    'sounds/yellow_sound.mp3',
  ];
  final AudioCache _tileAudioCache = AudioCache(prefix: 'assets/');
  final FlutterTts _tts = FlutterTts();

  List<int> _sequence = [];
  int _currentStep = 0;
  int _score = 0;
  int _currentLevel = 1;
  int _sequencesInRound = 0;
  bool _isDisplayingSequence = false;
  bool _isGameActive = false;
  int _highlightedTile = -1;

  late String _instruction;
  late String _startButtonLabel;
  late String _gameInProgressLabel;

  Future<void> _saveGameResult() async {
    for (int level = 1; level <= 4; level++) {
      if (level == _currentLevel) {
        final result = GameResult(
          category: 'sound_game',
          gameName: 'sound_game_level_$level',
          score: _score,
          date: DateTime.now(),
        ).toMap();

        final box = await Hive.openBox<Map>('gameResults');
        await box.add(result);
      } else {
        final result = GameResult(
          category: 'sound_game',
          gameName: 'sound_game_level_$level',
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
    _preloadSounds();
    _initializeGame();
    _setLanguageSpecificTexts();
  }

  void _preloadSounds() {
    for (String path in _audioPaths) {
      _tileAudioCache.load(path);
    }
    _tileAudioCache.load('sounds/beep1.mp3');
  }

  void _setLanguageSpecificTexts() {
    if (widget.selectedLanguage == 'Polski') {
      _instruction = 'Odtwórz sekwencję dźwięków';
      _startButtonLabel = 'Start';
      _gameInProgressLabel = 'Gra w toku';
      _tts.setLanguage('pl-PL');
    } else {
      _instruction = 'Play a sequence of sounds';
      _startButtonLabel = 'Start';
      _gameInProgressLabel = 'Game in Progress';
      _tts.setLanguage('en-US');
    }
  }

  Future<void> _initializeGame() async {
    await Future.delayed(const Duration(seconds: 2));
    await _playInstruction();
  }

  Future<void> _playInstruction() async {
    if (widget.isSoundEnabled) {
      await _setMaleVoice();
      await _tts.speak(_instruction);
      await _tts.awaitSpeakCompletion(true);
    }
  }

  Future<void> _setMaleVoice() async {
    List<dynamic>? voices = await _tts.getVoices;

    if (voices != null) {
      String? maleVoice = voices.firstWhere(
        (voice) =>
            (voice['locale'] ==
                (widget.selectedLanguage == 'Polski' ? 'pl-PL' : 'en-US')) &&
            voice['gender'] == 'male',
        orElse: () => null,
      )?['name'];

      if (maleVoice != null) {
        await _tts.setVoice({
          'name': maleVoice,
          'locale': widget.selectedLanguage == 'Polski' ? 'pl-PL' : 'en-US'
        });
      }
    }
  }

  void _startGame() async {
    setState(() {
      _score = 0;
      _currentStep = 0;
      _sequencesInRound = 0;
      _isGameActive = true;
    });

    _generateNewSequence();
    _displaySequence();
  }

  void _generateNewSequence() {
    _sequence.clear();
    int sequenceLength = _currentLevel + 1;
    for (int i = 0; i < sequenceLength; i++) {
      _sequence.add(Random().nextInt(4));
    }
    _currentStep = 0;
  }

  Future<void> _displaySequence() async {
    setState(() {
      _isDisplayingSequence = true;
      _highlightedTile = -1;
    });

    for (int tileIndex in _sequence) {
      setState(() {
        _highlightedTile = tileIndex;
      });
      await _playTile(tileIndex);
      await Future.delayed(const Duration(milliseconds: 700));
    }

    setState(() {
      _isDisplayingSequence = false;
    });
  }

  Future<void> _playTile(int index) async {
    if (widget.isSoundEnabled) {
      try {
        if (widget.selectedLanguage == 'Polski') {
          await _tts.setVolume(1.5);
          await _tts.setSpeechRate(1);
        } else {
          await _tts.setVolume(0.5);
        }

        await _tileAudioCache.play(_audioPaths[index]);
      } catch (e) {
        debugPrint("Błąd podczas odtwarzania dźwięku: $e");
      }
    }
    setState(() {
      _highlightedTile = index;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _highlightedTile = -1;
    });
  }

  void _handleTileTap(int index) {
    if (!_isGameActive || _isDisplayingSequence) return;

    setState(() {
      _highlightedTile = index;
    });

    if (_sequence[_currentStep] == index) {
      _playTile(index);
      _currentStep++;

      if (_currentStep == _sequence.length) {
        _score++;
        _sequencesInRound++;

        if (_sequencesInRound == 10) {
          _evaluateRound();
          return;
        }

        _generateNewSequence();
        Future.delayed(const Duration(seconds: 1), _displaySequence);
      }
    } else {
      if (widget.isSoundEnabled) {
        _tileAudioCache.play('sounds/beep1.mp3');
      }
      _sequencesInRound++;

      Future.delayed(const Duration(seconds: 2), () {
        if (_sequencesInRound == 10) {
          _evaluateRound();
        } else {
          _generateNewSequence();
          _displaySequence();
        }
      });
    }
  }

  void _evaluateRound() async {
    await _saveGameResult();

    setState(() {
      if (_score >= 7) {
        if (_currentLevel < 4) {
          _currentLevel++;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.selectedLanguage == 'Polski'
              ? 'Kolejna runda!'
              : 'Next round!'),
          duration: const Duration(seconds: 2),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.selectedLanguage == 'Polski'
              ? 'Jeszcze raz.'
              : 'Once again.'),
          duration: const Duration(seconds: 2),
        ));
      }

      _sequencesInRound = 0;
      _score = 0;
      _generateNewSequence();
      Future.delayed(const Duration(seconds: 1), _displaySequence);
    });
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
              widget.selectedLanguage == 'Polski' ? 'Dźwięk' : 'Sound',
              style: const TextStyle(color: Colors.white),
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
                  _score = 0;
                  _sequencesInRound = 0;
                  if (_isGameActive) {
                    _generateNewSequence();
                    _displaySequence();
                  }
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
              '${widget.selectedLanguage == 'Polski' ? 'Wynik' : 'Score'}: $_score/10',
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
                    double itemWidth = constraints.maxWidth / 2;
                    double itemHeight = constraints.maxHeight / 2;

                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: itemWidth / itemHeight,
                      ),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _handleTileTap(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _highlightedTile == index
                                  ? _tileColors[index]
                                  : (widget.isDarkMode
                                      ? Colors.grey
                                      : Colors.grey[300]),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _isGameActive ? null : _startGame,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 20),
                    textStyle: const TextStyle(fontSize: 24),
                  ),
                  child: Text(
                      _isGameActive ? _gameInProgressLabel : _startButtonLabel),
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
    _tts.stop();
    super.dispose();
  }
}
