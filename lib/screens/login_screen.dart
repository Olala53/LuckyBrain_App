import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive/hive.dart';
import 'register_screen.dart';
import 'my_home_page.dart';
import '../models/account_model.dart';
import '../hive_service.dart';

class LoginScreen extends StatefulWidget {
  final String selectedLanguage;
  final bool isDarkMode;
  final VoidCallback toggleTheme;
  final VoidCallback? resetLanguage;

  const LoginScreen({
    Key? key,
    required this.selectedLanguage,
    required this.isDarkMode,
    required this.toggleTheme,
    this.resetLanguage,
  }) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Box<Account>? _accountsBox;
  late FlutterTts _flutterTts;
  bool _isSoundEnabled = true;
  late bool _isDarkMode;
  bool _isSpeaking = false;
  List<Account> _accounts = [];

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _initializeTts();
    _isDarkMode = widget.isDarkMode;
    _loadAccounts();
  }

  Future<void> _initializeTts() async {
    await _setVoiceSettings();
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  Future<void> _loadAccounts() async {
    try {
      _accountsBox = await HiveService.getAccountsBox();
      if (_accountsBox != null) {
        setState(() {
          _accounts = _accountsBox!.values.toList();
        });

        if (_accounts.isEmpty) {
          final exampleAccount = Account(
            name: 'Anna',
            surname: 'Nowak',
            birthdate: '1964-11-21',
          );

          await _accountsBox!.add(exampleAccount);
          setState(() {
            _accounts.add(exampleAccount);
          });
        }
      } else {
        print('Error: accountsBox is null');
        setState(() {
          _accounts = [];
        });
      }
    } catch (e) {
      print('Error loading accounts: $e');
      setState(() {
        _accounts = [];
      });
    }
  }

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      setState(() {
        _isDarkMode = widget.isDarkMode;
      });
    }
    if (oldWidget.selectedLanguage != widget.selectedLanguage) {
      _setVoiceSettings();
    }
  }

  Future<void> _setVoiceSettings() async {
    if (widget.selectedLanguage == 'Polski') {
      await _flutterTts.setLanguage("pl-PL");
    } else {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts
          .setVoice({"name": "en-us-x-sfg#female_2-local", "locale": "en-US"});
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    if (_isSoundEnabled) {
      if (_isSpeaking) {
        await _flutterTts.stop();
        await Future.delayed(const Duration(milliseconds: 100));
      }
      setState(() {
        _isSpeaking = true;
      });
      await _flutterTts.speak(text);
    }
  }

  Future<void> _handleAccountSelection(Account account) async {
    final message = widget.selectedLanguage == 'Polski'
        ? 'Wybrano konto ${account.name}'
        : 'Selected account ${account.name}';

    await _speak(message);
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MyHomePage(
            title: 'LuckyBrain',
            toggleTheme: widget.toggleTheme,
            isDarkMode: _isDarkMode,
            selectedLanguage: widget.selectedLanguage,
            resetLanguage: widget.resetLanguage ?? () {},
          ),
        ),
      );
    }
  }

  void _addNewAccount() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _flutterTts.stop();

    _speak(widget.selectedLanguage == 'Polski' ? 'Dodaj konto' : 'Add account');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterScreen(
          selectedLanguage: widget.selectedLanguage,
          isDarkMode: _isDarkMode,
          toggleTheme: widget.toggleTheme,
        ),
      ),
    );

    if (result != null && result is Map<String, String>) {
      final account = Account(
        name: result['name']!,
        surname: result['surname']!,
        birthdate: result['birthdate']!,
      );

      try {
        final box = await HiveService.getAccountsBox();
        await box.add(account);

        setState(() {
          _accounts.add(account);
        });

        await Future.delayed(const Duration(milliseconds: 500));
        await _flutterTts.stop();

        _speak(widget.selectedLanguage == 'Polski'
            ? 'Dodano nowe konto'
            : 'New account added');
      } catch (e) {
        print('Error saving account: $e');
      }
    }
  }

  void _confirmDeleteAccount(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.selectedLanguage == 'Polski'
              ? 'Czy na pewno chcesz usunąć to konto?'
              : 'Are you sure you want to delete this account?'),
          content: Container(
            height: 50,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(),
                    child: Text(
                      widget.selectedLanguage == 'Polski' ? 'NIE' : 'NO',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _deleteAccount(index);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(),
                    child: Text(
                      widget.selectedLanguage == 'Polski' ? 'TAK' : 'YES',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _deleteAccount(int index) async {
    await _accountsBox?.deleteAt(index);

    setState(() {
      _accounts.removeAt(index);
    });

    await Future.delayed(const Duration(milliseconds: 500));
    await _flutterTts.stop();

    _speak(widget.selectedLanguage == 'Polski'
        ? 'Usunięto konto'
        : 'Account deleted');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80.0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Image.asset(
                'brain.jpg',
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
        backgroundColor: Colors.black,
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
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        color: _isDarkMode ? Colors.grey[850] : Colors.lightBlue[100],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              widget.selectedLanguage == 'Polski' ? 'Konta' : 'Accounts',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 70),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _accounts.length,
                    itemBuilder: (context, index) {
                      final account = _accounts[index];
                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () => _handleAccountSelection(account),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                  color: Colors.white,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        child: Image.asset(
                                          'avatar.png',
                                          height: 100,
                                          width: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "${account.name} ${account.surname}",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        account.birthdate,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Tooltip(
                              message: widget.selectedLanguage == 'Polski'
                                  ? 'Usuń konto'
                                  : 'Delete account',
                              child: CircleAvatar(
                                backgroundColor: Colors.red,
                                radius: 16,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  onPressed: () => _confirmDeleteAccount(index),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: ElevatedButton(
                onPressed: _addNewAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 3.0,
                ),
                child: Text(
                  widget.selectedLanguage == 'Polski'
                      ? 'Dodaj konto'
                      : 'Add Account',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
