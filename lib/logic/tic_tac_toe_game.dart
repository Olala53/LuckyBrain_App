import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/game_result.dart';

class TicTacToeGame extends StatefulWidget {
  final String selectedLanguage;
  final bool isDarkMode;
  final bool isSoundEnabled;

  const TicTacToeGame(
      {Key? key,
      required this.selectedLanguage,
      required this.isDarkMode,
      required this.isSoundEnabled})
      : super(key: key);

  @override
  _TicTacToeGameState createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> {
  List<String> board = List.filled(9, '');
  bool playerTurn = true;
  bool gameOver = false;
  String result = '';
  Timer? _timer;
  Timer? _resultTimer;
  int _secondsElapsed = 0;
  int playerScore = 0;
  int computerScore = 0;
  int round = 1;
  static const int totalRounds = 5;
  List<int> winningLine = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  int _consecutiveWins = 0;
  String _difficulty = 'Easy';

  late String _instruction;
  late String _title;
  late String _gameStatus;

  Future<void> _saveGameResult() async {
    for (int level = 1; level <= 3; level++) {
      String currentDifficulty = level == 1
          ? 'Easy'
          : level == 2
              ? 'Medium'
              : 'Hard';

      if (_difficulty == currentDifficulty) {
        final result = GameResult(
          category: 'tic_tac_toe',
          gameName: 'tic_tac_toe_level_$level',
          score: playerScore,
          date: DateTime.now(),
        ).toMap();

        final box = await Hive.openBox<Map>('gameResults');
        await box.add(result);
      } else {
        final result = GameResult(
          category: 'tic_tac_toe',
          gameName: 'tic_tac_toe_level_$level',
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
    _initializeTexts();
    _startTimer();
    Future.delayed(Duration(seconds: 2), _playInstructionAudio);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resultTimer?.cancel();
    _audioPlayer.dispose();
    _tts.stop();
    super.dispose();
  }

  void _initializeTexts() {
    if (widget.selectedLanguage == 'Polski') {
      _instruction =
          'Ułóż trzy identyczne kształty w rzędzie (pionowo, poziomo lub po przekątnej)';
      _title = 'Kółko i krzyżyk';
      _gameStatus = 'Twoja kolej';
      _tts.setLanguage('pl-PL');
      _tts.setVolume(1.5);
      _tts.setSpeechRate(1);
    } else {
      _instruction =
          'Arrange three identical shapes in a row (vertically, horizontally or diagonally)';
      _title = 'Tic Tac Toe';
      _gameStatus = 'Your turn';
      _tts.setLanguage('en-US');
      _tts.setVolume(0.5);
      _tts.setSpeechRate(1);
    }
  }

  String _getDifficultyText(String difficulty) {
    if (widget.selectedLanguage == 'Polski') {
      switch (difficulty) {
        case 'Easy':
          return 'Łatwy';
        case 'Medium':
          return 'Średni';
        case 'Hard':
          return 'Trudny';
        default:
          return difficulty;
      }
    }
    return difficulty;
  }

  Future<void> _playInstructionAudio() async {
    if (widget.isSoundEnabled) {
      await _tts.speak(_instruction);
      await _tts.awaitSpeakCompletion(true);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsElapsed = 0;
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  void _checkConsecutiveWins() {
    if (playerTurn) {
      _consecutiveWins++;
      if (_consecutiveWins >= 5) {
        _consecutiveWins = 0;
        setState(() {
          switch (_difficulty) {
            case 'Easy':
              _difficulty = 'Medium';
              break;
            case 'Medium':
              _difficulty = 'Hard';
              break;
          }
        });
      }
    } else {
      _consecutiveWins = 0;
    }
  }

  void _onTap(int index) {
    if (board[index] == '' && !gameOver) {
      setState(() {
        board[index] = playerTurn ? 'O' : 'X';
        bool hasWon = _checkWinner(playerTurn ? 'O' : 'X');
        if (hasWon) {
          _timer?.cancel();
          setState(() {
            gameOver = true;
            playerTurn ? playerScore++ : computerScore++;
            result = playerTurn
                ? (widget.selectedLanguage == 'Polski'
                    ? 'Wygrywasz!'
                    : 'You win!')
                : (widget.selectedLanguage == 'Polski'
                    ? 'Komputer wygrywa!'
                    : 'Computer wins!');
            _checkConsecutiveWins();
          });
          _resultTimer?.cancel();
          _resultTimer = Timer(Duration(seconds: 2), () {
            _startNewRound();
          });
        } else if (board.every((element) => element != '')) {
          _timer?.cancel();
          setState(() {
            result = widget.selectedLanguage == 'Polski' ? 'Remis!' : 'Draw!';
            gameOver = true;
          });
          _resultTimer?.cancel();
          _resultTimer = Timer(Duration(seconds: 2), () {
            _startNewRound();
          });
        } else {
          setState(() {
            playerTurn = !playerTurn;
          });
          if (!playerTurn) _computerMove();
        }
      });
    }
  }

  void _computerMove() {
    Future.delayed(Duration(seconds: 1), () {
      if (!gameOver) {
        List<int> emptyIndices = [];
        for (int i = 0; i < board.length; i++) {
          if (board[i] == '') {
            emptyIndices.add(i);
          }
        }

        int moveIndex;
        if (_difficulty == 'Easy') {
          moveIndex = emptyIndices[Random().nextInt(emptyIndices.length)];
        } else if (_difficulty == 'Medium') {
          moveIndex = _findBestMove('X') ??
              emptyIndices[Random().nextInt(emptyIndices.length)];
        } else {
          moveIndex = _findBestMove('X') ??
              _findBestMove('O') ??
              emptyIndices[Random().nextInt(emptyIndices.length)];
        }

        setState(() {
          board[moveIndex] = 'X';
          bool hasWon = _checkWinner('X');
          if (hasWon) {
            _timer?.cancel();
            setState(() {
              result = widget.selectedLanguage == 'Polski'
                  ? 'Komputer wygrywa!'
                  : 'Computer wins!';
              computerScore++;
              gameOver = true;
            });
            _resultTimer?.cancel();
            _resultTimer = Timer(Duration(seconds: 2), () {
              _startNewRound();
            });
          }
          playerTurn = true;
        });
      }
    });
  }

  int? _findBestMove(String player) {
    const winningCombos = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (var combo in winningCombos) {
      int countPlayer = 0;
      int countEmpty = 0;
      int emptyIndex = -1;

      for (int index in combo) {
        if (board[index] == player) {
          countPlayer++;
        } else if (board[index] == '') {
          countEmpty++;
          emptyIndex = index;
        }
      }

      if (countPlayer == 2 && countEmpty == 1) {
        return emptyIndex;
      }
    }

    return null;
  }

  void _startNewRound() {
    if (round < totalRounds) {
      setState(() {
        board = List.filled(9, '');
        playerTurn = true;
        gameOver = false;
        result = '';
        winningLine = [];
        _startTimer();
        round++;
      });
    } else {
      setState(() {
        if (widget.selectedLanguage == 'Polski') {
          result =
              'Końcowy wynik - Gracz: $playerScore, Komputer: $computerScore';
        } else {
          result =
              'Final score - Player: $playerScore, Computer: $computerScore';
        }
        gameOver = true;
        _timer?.cancel();

        _saveGameResult().then((_) {
          Future.delayed(Duration(seconds: 3), () {
            _resetGame();
          });
        });
      });
    }
  }

  bool _checkWinner(String player) {
    const winningCombos = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (var combo in winningCombos) {
      if (board[combo[0]] == player &&
          board[combo[1]] == player &&
          board[combo[2]] == player) {
        setState(() {
          winningLine = combo;
        });
        return true;
      }
    }
    return false;
  }

  void _resetGame() {
    setState(() {
      board = List.filled(9, '');
      playerTurn = true;
      gameOver = false;
      result = '';
      round = 1;
      playerScore = 0;
      computerScore = 0;
      winningLine = [];
      _consecutiveWins = 0;
      _startTimer();
    });
  }

  String get gameStatus {
    if (gameOver) {
      return '$result (${widget.selectedLanguage == 'Polski' ? 'Czas' : 'Time'}: $_secondsElapsed s)';
    } else {
      return playerTurn
          ? _gameStatus
          : widget.selectedLanguage == 'Polski'
              ? "Kolej komputera"
              : "Computer's turn";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_title, style: TextStyle(color: Colors.white)),
            Text(
                widget.selectedLanguage == 'Polski'
                    ? 'Czas: $_secondsElapsed s'
                    : 'Time: $_secondsElapsed s',
                style: TextStyle(fontSize: 18, color: Colors.white)),
            Text(
                widget.selectedLanguage == 'Polski'
                    ? 'Ty $playerScore - $computerScore Komputer'
                    : 'You $playerScore - $computerScore Computer',
                style: TextStyle(fontSize: 18, color: Colors.white)),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        actions: [
          DropdownButton<String>(
            value: _difficulty,
            dropdownColor: Colors.black,
            items: ['Easy', 'Medium', 'Hard']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(_getDifficultyText(value),
                    style: TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null && newValue != _difficulty) {
                setState(() {
                  _difficulty = newValue;
                  _consecutiveWins = 0;
                  playerScore = 0;
                  computerScore = 0;
                  round = 1;
                  board = List.filled(9, '');
                  playerTurn = true;
                  gameOver = false;
                  result = '';
                  winningLine = [];
                  _startTimer();
                });
              }
            },
            style: TextStyle(color: Colors.white),
            icon: Icon(Icons.arrow_drop_down, color: Colors.white),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: widget.isDarkMode ? Colors.grey[850] : Colors.lightBlue[100],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double boardSize =
                min(constraints.maxWidth * 0.7, constraints.maxHeight * 0.7);
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      _instruction,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    width: boardSize,
                    height: boardSize,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1,
                      ),
                      itemCount: 9,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _onTap(index),
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(width: 2),
                              color: winningLine.contains(index)
                                  ? Colors.green
                                  : widget.isDarkMode
                                      ? Colors.grey[700]!
                                      : Colors.grey[300]!,
                            ),
                            child: Center(
                              child: Text(
                                board[index],
                                style: TextStyle(
                                  fontSize: 40,
                                  color: board[index] == 'O'
                                      ? Colors.blue
                                      : Colors.red,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      gameStatus,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
