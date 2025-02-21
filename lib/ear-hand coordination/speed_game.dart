import 'dart:async';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/game_result.dart';

class SpeedGame extends StatefulWidget {
  final String selectedLanguage;
  final bool isDarkMode;
  final bool isSoundEnabled;

  const SpeedGame(
      {Key? key,
      required this.selectedLanguage,
      required this.isDarkMode,
      required this.isSoundEnabled})
      : super(key: key);

  @override
  _SpeedGameState createState() => _SpeedGameState();
}

class _SpeedGameState extends State<SpeedGame> {
  final int _gridSize = 3;
  final int _totalRounds = 10;
  int _activeTileIndex = -1;
  int _score = 0;
  int _bestReactionTime = 0;
  int _currentRound = 0;
  int _currentLevel = 1;
  bool _gameActive = false;
  Timer? _timer;
  DateTime? _startTime;
  late Duration _tileDisplayDuration;
  Duration _intervalBetweenRounds = Duration(milliseconds: 1500);
  Duration _postHitDelay = Duration(milliseconds: 500);
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  late String _instruction;
  late String _title;

  Future<void> _saveGameResult() async {
    for (int level = 1; level <= 4; level++) {
      if (level == _currentLevel) {
        final result = GameResult(
          category: 'speed_game',
          gameName: 'speed_game_level_$level',
          score: _score,
          date: DateTime.now(),
        ).toMap();

        final box = await Hive.openBox<Map>('gameResults');
        await box.add(result);
      } else {
        final result = GameResult(
          category: 'speed_game',
          gameName: 'speed_game_level_$level',
          score: 0,
          date: DateTime.now(),
        ).toMap();

        final box = await Hive.openBox<Map>('gameResults');
        await box.add(result);
      }
    }
  }

  void _updateDifficultyForLevel() {
    _tileDisplayDuration = Duration(seconds: 5 - _currentLevel);
  }

  @override
  void initState() {
    super.initState();
    _updateDifficultyForLevel();
    _setLanguageSpecificTexts();

    Timer(Duration(seconds: 2), () {
      _playInstruction();
    });
  }

  void _setLanguageSpecificTexts() {
    if (widget.selectedLanguage == 'Polski') {
      _instruction = 'Kliknij żółty kafelek jak najszybciej';
      _title = 'Szybkość';
      _tts.setLanguage('pl-PL');
    } else {
      _instruction = 'Click the yellow tile as quickly as possible';
      _title = 'Speed';
      _tts.setLanguage('en-US');
    }
  }

  Future<void> _playInstruction() async {
    if (widget.isSoundEnabled) {
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

  void _startGame() {
    _updateDifficultyForLevel();
    setState(() {
      _score = 0;
      _bestReactionTime = 0;
      _currentRound = 0;
      _gameActive = true;
      _nextTile();
    });
  }

  void _restartGame() {
    setState(() {
      _score = 0;
      _bestReactionTime = 0;
      _currentRound = 0;
      _gameActive = false;
    });

    Timer(Duration(seconds: 2), () {
      _playInstruction();
      _startGame();
    });
  }

  void _nextTile() {
    if (_currentRound < _totalRounds) {
      setState(() {
        _activeTileIndex = Random().nextInt(_gridSize * _gridSize);
        _startTime = DateTime.now();
      });

      _playSound('highlight');

      _timer = Timer(_tileDisplayDuration, () {
        if (mounted && _gameActive) {
          setState(() {
            _activeTileIndex = -1;
          });

          _timer = Timer(_intervalBetweenRounds, () {
            if (mounted && _gameActive) {
              _currentRound++;
              _nextTile();
            }
          });
        }
      });
    } else {
      _saveGameResult().then((_) {
        if (_score >= 7) {
          _nextLevel();
        } else {
          _restartSameLevel();
        }
      });
    }
  }

  void _nextLevel() {
    if (_currentLevel < 4) {
      setState(() {
        _currentLevel++;
        _startGame();
      });
    } else {
      _stopGame();
    }
  }

  void _restartSameLevel() {
    setState(() {
      _currentRound = 0;
      _score = 0;
      _startGame();
    });
  }

  void _handleTileTap(int index) {
    if (_activeTileIndex == index && _startTime != null) {
      final reactionTime =
          DateTime.now().difference(_startTime!).inMilliseconds;
      if (_bestReactionTime == 0 || reactionTime < _bestReactionTime) {
        _bestReactionTime = reactionTime;
      }
      setState(() {
        _score++;
        _activeTileIndex = -1;
      });

      _playSound('success');

      _timer?.cancel();
      _timer = Timer(_postHitDelay, () {
        if (mounted && _gameActive) {
          _currentRound++;
          _nextTile();
        }
      });
    } else if (_gameActive) {
      _playSound('error');
    }
  }

  Future<void> _playSound(String type) async {
    if (widget.isSoundEnabled) {
      String assetPath;
      if (type == 'success') {
        assetPath = 'assets/sounds/correct.mp3';
      } else if (type == 'error') {
        assetPath = 'assets/sounds/beep1.mp3';
      } else if (type == 'highlight') {
        assetPath = 'assets/sounds/positive.mp3';
      } else {
        assetPath = 'assets/instruction_audio/quick.mp3';
      }

      try {
        await _audioPlayer.play(assetPath, isLocal: true);
      } catch (e) {
        print('Error playing sound: $e');
      }
    }
  }

  void _stopGame() {
    setState(() {
      _gameActive = false;
      _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _stopGame();
    _audioPlayer.dispose();
    _tts.stop();
    super.dispose();
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
                  _startGame();
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${widget.selectedLanguage == 'Polski' ? 'Wynik' : 'Score'}: $_score / 10',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
                Text(
                  '${widget.selectedLanguage == 'Polski' ? 'Czas reakcji' : 'Fastest Reaction'}: $_bestReactionTime ms',
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
                    final double tileWidth = constraints.maxWidth / _gridSize;
                    final double tileHeight = constraints.maxHeight / _gridSize;

                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _gridSize,
                        childAspectRatio: tileWidth / tileHeight,
                      ),
                      itemCount: _gridSize * _gridSize,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _handleTileTap(index),
                          child: Container(
                            margin: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey, width: 3),
                              borderRadius: BorderRadius.circular(15),
                              color: widget.isDarkMode
                                  ? (index == _activeTileIndex
                                      ? Colors.yellow
                                      : Colors.grey)
                                  : (index == _activeTileIndex
                                      ? Colors.yellow
                                      : Colors.grey[300]),
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
                  onPressed: _gameActive
                      ? _stopGame
                      : (_currentRound == _totalRounds
                          ? _restartGame
                          : _startGame),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 20),
                    textStyle: const TextStyle(fontSize: 24),
                  ),
                  child: Text(
                    _gameActive
                        ? '${widget.selectedLanguage == 'Polski' ? 'Zatrzymaj' : 'Stop'}'
                        : (_currentRound == _totalRounds
                            ? '${widget.selectedLanguage == 'Polski' ? 'Uruchom ponownie' : 'Restart'}'
                            : '${widget.selectedLanguage == 'Polski' ? 'Start' : 'Start'}'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
