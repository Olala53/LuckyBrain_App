import 'package:flutter/material.dart';
import 'screens/language_selection_page.dart';
import '../hive_service.dart';
import 'package:hive/hive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.initHive();
  await Hive.openBox<Map>('gameResults');
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = ThemeData();

    return MaterialApp(
      title: 'LuckyBrain',
      theme: theme.copyWith(
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      ),
      home: LanguageSelectionPage(
        isDarkMode: _isDarkMode,
        toggleTheme: _toggleTheme,
        resetLanguage: () {},
      ),
    );
  }
}
