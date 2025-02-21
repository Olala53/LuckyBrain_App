import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/game_result.dart';
import '../screens/statistics_screen.dart' show StatisticsScreen;

class PuzzleGame extends StatefulWidget {
  final String selectedLanguage;
  final bool isDarkMode;
  final bool isSoundEnabled;

  const PuzzleGame(
      {Key? key,
      required this.selectedLanguage,
      required this.isDarkMode,
      required this.isSoundEnabled})
      : super(key: key);

  @override
  _PuzzleGameState createState() => _PuzzleGameState();
}

class _PuzzleGameState extends State<PuzzleGame> {
  List<Piece> _pieces = [];
  late ui.Image _image;
  bool _imageLoaded = false;
  int _rows = 2;
  int _cols = 2;
  int _currentLevel = 1;
  bool _levelCompleted = false;
  bool _showStartButton = true;
  AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;
  int _elapsedTime = 0;
  FlutterTts _tts = FlutterTts();
  bool _isFirstLevel = true;
  bool _instructionPlayed = false;

  late String _instruction;

  Future<void> _saveGameResult() async {
    for (int level = 1; level <= 4; level++) {
      if (level == _currentLevel) {
        int score = max(0, 100 - _elapsedTime);

        final result = GameResult(
          category: 'puzzle',
          gameName: 'puzzle_level_$level',
          score: score,
          date: DateTime.now(),
        ).toMap();

        final box = await Hive.openBox<Map>('gameResults');
        await box.add(result);
      } else {
        final result = GameResult(
          category: 'puzzle',
          gameName: 'puzzle_level_$level',
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
    _prepareNextLevel();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _tts.stop();
    _timer?.cancel();
    super.dispose();
  }

  void _setLanguageSpecificInstructions() {
    if (widget.selectedLanguage == 'Polski') {
      _instruction = 'Ułóż obrazek przesuwając elementy';
      _tts.setLanguage('pl-PL');
      _tts.setVolume(1.5);
      _tts.setSpeechRate(1);
    } else {
      _instruction = 'Arrange the picture by moving the pieces';
      _tts.setLanguage('en-US');
      _tts.setVolume(0.5);
    }
  }

  Future<void> _playInstructionAudio() async {
    if (widget.isSoundEnabled && _isFirstLevel && !_instructionPlayed) {
      await _tts.speak(_instruction);
      await _tts.awaitSpeakCompletion(true);
      setState(() {
        _instructionPlayed = true;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime++;
      });
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _elapsedTime = 0;
    });
  }

  void _prepareNextLevel() {
    setState(() {
      _showStartButton = true;
      _imageLoaded = false;
    });
    _resetTimer();
    Future.delayed(Duration(seconds: 2), _playInstructionAudio);
  }

  void _startLevel() {
    setState(() {
      _showStartButton = false;
    });
    _loadImageForLevel();
  }

  void _loadImageForLevel() async {
    final String imageName;
    switch (_currentLevel) {
      case 1:
        imageName = 'cat';
        _rows = 2;
        _cols = 2;
        break;
      case 2:
        imageName = 'dog';
        _rows = 3;
        _cols = 3;
        break;
      case 3:
        imageName = 'horse';
        _rows = 3;
        _cols = 3;
        break;
      case 4:
      default:
        imageName = 'stork';
        _rows = 4;
        _cols = 4;
        break;
    }

    final String imagePath = 'assets/puzzle/$imageName.jpg';
    final ByteData data = await DefaultAssetBundle.of(context).load(imagePath);
    final ui.Codec codec =
        await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo fi = await codec.getNextFrame();
    _image = fi.image;

    _createPuzzle();
    _resetTimer();
    _startTimer();

    setState(() {
      _imageLoaded = true;
    });
  }

  void _createPuzzle() {
    final pieces = <Piece>[];
    for (int y = 0; y < _rows; y++) {
      for (int x = 0; x < _cols; x++) {
        final correctPosition = Offset(x.toDouble(), y.toDouble());
        pieces.add(Piece(
          key: GlobalKey(),
          image: _image,
          src: Rect.fromLTWH(
            x * (_image.width / _cols),
            y * (_image.height / _rows),
            _image.width / _cols,
            _image.height / _rows,
          ),
          correctPosition: correctPosition,
          currentPosition: correctPosition,
        ));
      }
    }

    final positions = pieces.map((piece) => piece.correctPosition).toList();
    positions.shuffle();
    for (int i = 0; i < pieces.length; i++) {
      pieces[i].currentPosition = positions[i];
    }

    setState(() {
      _pieces = pieces;
    });
  }

  bool _isPuzzleSolved() {
    for (final piece in _pieces) {
      if (piece.currentPosition != piece.correctPosition) {
        return false;
      }
    }
    return true;
  }

  void _handlePieceDragEnd(Piece piece, DraggableDetails details,
      double pieceWidth, double pieceHeight) {
    setState(() {
      final newOffset = Offset(
        (details.offset.dx / pieceWidth).roundToDouble(),
        (details.offset.dy / pieceHeight).roundToDouble(),
      );

      if (newOffset.dx >= 0 &&
          newOffset.dx < _cols &&
          newOffset.dy >= 0 &&
          newOffset.dy < _rows) {
        final targetPiece = _pieces.firstWhere(
          (p) => p.currentPosition == newOffset,
          orElse: () => piece,
        );

        final tempPosition = piece.currentPosition;
        piece.currentPosition = targetPiece.currentPosition;
        targetPiece.currentPosition = tempPosition;

        if (_isPuzzleSolved()) {
          _showLevelCompleteDialog();
        }
      }
    });
  }

  void _showLevelCompleteDialog() {
    setState(() {
      _levelCompleted = true;
    });

    _timer?.cancel();

    Future.delayed(Duration(seconds: 2), () {
      if (_currentLevel < 4) {
        setState(() {
          _currentLevel++;
          _isFirstLevel = false;
        });
        _prepareNextLevel();
      } else {
        _showGameOverDialog();
      }
    });
  }

  void _showGameOverDialog() async {
    // Save game result
    await _saveGameResult();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.selectedLanguage == 'Polski'
              ? "Gratulacje!"
              : "Congratulations!"),
          content: Text(widget.selectedLanguage == 'Polski'
              ? "Ukończyłeś wszystkie poziomy."
              : "You've completed all levels."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _currentLevel = 1;
                  _isFirstLevel = true;
                });
                _prepareNextLevel();
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

  void _changeLevel(int level) {
    setState(() {
      _currentLevel = level;
      _isFirstLevel = level == 1;
    });
    _prepareNextLevel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.selectedLanguage == 'Polski' ? 'Puzzle' : 'Puzzle',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        flexibleSpace: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 3.0),
            child: Text(
              widget.selectedLanguage == 'Polski'
                  ? 'Czas: $_elapsedTime sekund'
                  : 'Time: $_elapsedTime seconds',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
        actions: [
          DropdownButton<int>(
            value: _currentLevel,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            iconSize: 24,
            elevation: 16,
            style: const TextStyle(color: Colors.white),
            dropdownColor: Colors.black,
            underline: Container(
              height: 2,
              color: Colors.white,
            ),
            onChanged: (int? newValue) {
              if (newValue != null) {
                _changeLevel(newValue);
              }
            },
            items: <int>[1, 2, 3, 4].map<DropdownMenuItem<int>>((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text(
                  widget.selectedLanguage == 'Polski'
                      ? ['Łatwy', 'Średni', 'Trudny', 'Ekspert'][value - 1]
                      : ['Easy', 'Medium', 'Hard', 'Expert'][value - 1],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      backgroundColor:
          widget.isDarkMode ? Colors.grey[850] : Colors.lightBlue[100],
      body: _showStartButton
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.selectedLanguage == 'Polski'
                        ? 'Poziom $_currentLevel: Ułóż obrazek przesuwając elementy'
                        : 'Level $_currentLevel: Arrange the picture by moving the pieces',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Set to black
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _startLevel,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 80, vertical: 20),
                      textStyle: const TextStyle(fontSize: 28),
                    ),
                    child: Text(widget.selectedLanguage == 'Polski'
                        ? 'Start'
                        : 'Start'),
                  ),
                ],
              ),
            )
          : _imageLoaded
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    final pieceWidth = constraints.maxWidth / _cols;
                    final pieceHeight = constraints.maxHeight / _rows;

                    return Center(
                      child: Stack(
                        children: _pieces.map((piece) {
                          return AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            left: piece.currentPosition.dx * pieceWidth,
                            top: piece.currentPosition.dy * pieceHeight,
                            child: Draggable<Piece>(
                              data: piece,
                              feedback: Opacity(
                                opacity: 0.7,
                                child:
                                    piece.buildPiece(pieceWidth, pieceHeight),
                              ),
                              childWhenDragging: Container(),
                              child: piece.buildPiece(pieceWidth, pieceHeight),
                              onDragEnd: (details) => _handlePieceDragEnd(
                                  piece, details, pieceWidth, pieceHeight),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                )
              : const Center(child: CircularProgressIndicator()),
    );
  }
}

class Piece {
  final ui.Image image;
  final Rect src;
  final Offset correctPosition;
  Offset currentPosition;

  Piece({
    required Key key,
    required this.image,
    required this.src,
    required this.correctPosition,
    required this.currentPosition,
  });

  Widget buildPiece(double width, double height) {
    return Container(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _ImagePainter(
          image: image,
          src: src,
        ),
        size: Size(width, height),
      ),
    );
  }
}

class _ImagePainter extends CustomPainter {
  final ui.Image image;
  final Rect src;

  _ImagePainter({required this.image, required this.src});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    final Rect dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
