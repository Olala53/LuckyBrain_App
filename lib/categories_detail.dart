import 'package:flutter/material.dart';
import 'categories.dart';
import 'categories_photo.dart';
import 'memory/memory_games_screen.dart';

class CategoriesDetail extends StatefulWidget {
  final Categories categories;
  final String selectedLanguage;
  final bool isDarkMode;
  final bool isSoundEnabled;

  const CategoriesDetail({
    Key? key,
    required this.categories,
    required this.selectedLanguage,
    required this.isDarkMode,
    required this.isSoundEnabled,
  }) : super(key: key);

  @override
  State<CategoriesDetail> createState() {
    return _CategoriesDetailState();
  }
}

class _CategoriesDetailState extends State<CategoriesDetail> {
  @override
  Widget build(BuildContext context) {
    final Map<String, String> translations = {
      'Memory': widget.selectedLanguage == 'Polski' ? 'Pamięć' : 'Memory',
      'Description for Memory': widget.selectedLanguage == 'Polski'
          ? 'Opis gry pamięciowej'
          : 'Description for Memory Game',
      'Start Memory Game': widget.selectedLanguage == 'Polski'
          ? 'Rozpocznij grę pamięciową'
          : 'Start Memory Game',
    };

    final categoryPhoto = CategoriesPhoto.samples.firstWhere(
      (photo) => photo.label == widget.categories.label,
      orElse: () => CategoriesPhoto('brain.jpg', 'LOGO'),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          translations[widget.categories.label] ?? widget.categories.label,
        ),
        backgroundColor: Colors.black12,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.asset(
                  categoryPhoto.imageUrl,
                  height: 200,
                  width: 200,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  translations[widget.categories.label] ??
                      widget.categories.label,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (widget.categories.label == 'Memory')
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MemoryGamesScreen(
                              selectedLanguage: widget.selectedLanguage,
                              isDarkMode: widget.isDarkMode,
                              isSoundEnabled: widget.isSoundEnabled),
                        ),
                      );
                    },
                    child: Text(
                      translations['Start Memory Game'] ?? 'Start Memory Game',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  translations['Description for ${widget.categories.label}'] ??
                      'Description for ${widget.categories.label}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
