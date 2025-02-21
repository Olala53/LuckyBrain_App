import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../categories.dart';
import '../categories_detail.dart';
import '../categories_photo.dart';
import 'statistics_screen.dart';
import '../eye-hand coordination/eye_games_screen.dart';
import '../ear-hand coordination/ear_games_screen.dart';
import '../memory/memory_games_screen.dart';
import '../logic/logic_games_screen.dart';

class MyHomePage extends StatefulWidget {
  final String title;
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  final String selectedLanguage;
  final VoidCallback resetLanguage;

  const MyHomePage({
    Key? key,
    required this.title,
    required this.toggleTheme,
    required this.isDarkMode,
    required this.selectedLanguage,
    required this.resetLanguage,
  }) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late FlutterTts _flutterTts;
  bool _isSoundEnabled = true;
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _initTts();
    _isDarkMode = widget.isDarkMode;
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    if (widget.selectedLanguage == 'Polski') {
      await _flutterTts.setLanguage("pl-PL");
    } else {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setVoice({
        "name": "en-us-x-sfg#female_2-local",
        "locale": "en-US",
      });
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    if (_isSoundEnabled) {
      await _flutterTts.speak(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> translations = {
      'Eye-hand coordination': widget.selectedLanguage == 'Polski'
          ? 'Koordynacja wzrokowo-ruchowa'
          : 'Eye-hand coordination',
      'Ear-hand coordination': widget.selectedLanguage == 'Polski'
          ? 'Koordynacja słuchowo-ruchowa'
          : 'Ear-hand coordination',
      'Memory': widget.selectedLanguage == 'Polski' ? 'Pamięć' : 'Memory',
      'Logic': widget.selectedLanguage == 'Polski' ? 'Logika' : 'Logic',
    };

    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(context),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      toolbarHeight: 80.0,
      title: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              CategoriesPhoto.samples.isNotEmpty
                  ? CategoriesPhoto.samples[0].imageUrl
                  : 'brain.jpg',
              fit: BoxFit.contain,
              height: 80.0,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'LuckyBrain',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
            color: Colors.white,
          ),
          onPressed: () async {
            final message = widget.selectedLanguage == 'Polski'
                ? (_isDarkMode ? 'Tryb jasny' : 'Tryb ciemny')
                : (_isDarkMode ? 'Light mode' : 'Dark mode');

            await _speak(message);
            await Future.delayed(const Duration(milliseconds: 500));

            setState(() {
              _isDarkMode = !_isDarkMode;
            });
            widget.toggleTheme();
          },
        ),
        IconButton(
          icon: Icon(
            _isSoundEnabled ? Icons.volume_up : Icons.volume_off,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _isSoundEnabled = !_isSoundEnabled;
            });
            if (_isSoundEnabled) {
              _speak(widget.selectedLanguage == 'Polski'
                  ? 'Dźwięk włączony'
                  : 'Sound enabled');
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.bar_chart, size: 30, color: Colors.white),
          tooltip:
              widget.selectedLanguage == 'Polski' ? 'Statystyki' : 'Statistics',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StatisticsScreen(
                  selectedLanguage: widget.selectedLanguage,
                  isDarkMode: _isDarkMode,
                  isSoundEnabled: _isSoundEnabled,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      backgroundColor: Colors.black,
    );
  }

  Widget _buildBody(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double itemWidth = constraints.maxWidth / 2;
          final double itemHeight = constraints.maxHeight / 2;

          return Container(
            color: _isDarkMode ? Colors.grey[850] : Colors.lightBlue[100],
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: itemWidth / itemHeight,
              ),
              itemCount: Categories.samples.length,
              itemBuilder: (BuildContext context, int index) {
                return _buildCategoryTile(
                    context, index, itemWidth, itemHeight);
              },
            ),
          );
        },
      ),
    );
  }

  GestureDetector _buildCategoryTile(
      BuildContext context, int index, double itemWidth, double itemHeight) {
    final category = Categories.samples[index];
    final categoryPhoto = CategoriesPhoto.samples.firstWhere(
      (photo) => photo.label == category.label,
      orElse: () => CategoriesPhoto('brain.jpg', 'LOGO'),
    );

    final Map<String, String> tileTranslations = {
      'Eye - hand coordination': widget.selectedLanguage == 'Polski'
          ? 'Koordynacja oko-ręka'
          : 'Eye-hand coordination',
      'Ear - hand coordination': widget.selectedLanguage == 'Polski'
          ? 'Koordynacja ucho-ręka'
          : 'Ear-hand coordination',
      'Memory': widget.selectedLanguage == 'Polski' ? 'Pamięć' : 'Memory',
      'Logic': widget.selectedLanguage == 'Polski' ? 'Logika' : 'Logic',
    };

    final translatedLabel = tileTranslations[category.label] ?? category.label;

    return GestureDetector(
      onTap: () {
        _onCategoryTap(context, category);
      },
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue, width: 3),
          borderRadius: BorderRadius.circular(15),
          color: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Image.asset(
                categoryPhoto.imageUrl,
                fit: BoxFit.contain,
                width: itemWidth / 1.1,
                height: itemHeight / 1.8,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Text(
                translatedLabel,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCategoryTap(BuildContext context, Categories category) {
    String ttsText = '';

    if (category.label == 'Eye - hand coordination') {
      ttsText = widget.selectedLanguage == 'Polski'
          ? 'Koordynacja oko-ręka'
          : 'Eye-hand coordination';
      _speak(ttsText);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SpeedGamesScreen(
            selectedLanguage: widget.selectedLanguage,
            isDarkMode: _isDarkMode,
            isSoundEnabled: _isSoundEnabled,
          ),
        ),
      );
    } else if (category.label == 'Ear - hand coordination') {
      ttsText = widget.selectedLanguage == 'Polski'
          ? 'Koordynacja ucho-ręka'
          : 'Ear-hand coordination';
      _speak(ttsText);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FocusGamesScreen(
            selectedLanguage: widget.selectedLanguage,
            isDarkMode: _isDarkMode,
            isSoundEnabled: _isSoundEnabled,
          ),
        ),
      );
    } else if (category.label == 'Memory') {
      ttsText = widget.selectedLanguage == 'Polski' ? 'Pamięć' : 'Memory';
      _speak(ttsText);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MemoryGamesScreen(
            selectedLanguage: widget.selectedLanguage,
            isDarkMode: _isDarkMode,
            isSoundEnabled: _isSoundEnabled,
          ),
        ),
      );
    } else if (category.label == 'Logic') {
      ttsText = widget.selectedLanguage == 'Polski' ? 'Logika' : 'Logic';
      _speak(ttsText);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LogicGamesScreen(
            selectedLanguage: widget.selectedLanguage,
            isDarkMode: _isDarkMode,
            isSoundEnabled: _isSoundEnabled,
          ),
        ),
      );
    } else {
      ttsText = category.label;
      _speak(ttsText);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return CategoriesDetail(
              categories: category,
              selectedLanguage: widget.selectedLanguage,
              isDarkMode: _isDarkMode,
              isSoundEnabled: _isSoundEnabled,
            );
          },
        ),
      );
    }
  }
}
