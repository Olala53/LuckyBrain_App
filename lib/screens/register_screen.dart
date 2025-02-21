import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class RegisterScreen extends StatefulWidget {
  final String selectedLanguage;
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const RegisterScreen({
    Key? key,
    required this.selectedLanguage,
    required this.isDarkMode,
    required this.toggleTheme,
  }) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late FlutterTts _flutterTts;
  bool _isSoundEnabled = true;
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _setVoiceSettings();
    _isDarkMode = widget.isDarkMode;
  }

  @override
  void didUpdateWidget(covariant RegisterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      setState(() {
        _isDarkMode = widget.isDarkMode;
      });
    }
  }

  Future<void> _setVoiceSettings() async {
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
    _nameController.dispose();
    _surnameController.dispose();
    _birthdateController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    if (_isSoundEnabled) {
      await _flutterTts.speak(text);
    }
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'name': _nameController.text,
        'surname': _surnameController.text,
        'birthdate': _birthdateController.text,
      });
    } else {
      _speak(widget.selectedLanguage == 'Polski'
          ? 'Proszę uzupełnić wszystkie pola poprawnie'
          : 'Please fill in all fields correctly');
    }
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
        actions: [
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
              color: Colors.white,
            ),
            onPressed: () {
              _speak(widget.selectedLanguage == 'Polski'
                  ? _isDarkMode
                      ? 'Tryb jasny'
                      : 'Tryb ciemny'
                  : _isDarkMode
                      ? 'Light mode'
                      : 'Dark mode');
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
        ],
        backgroundColor: Colors.black,
      ),
      body: Container(
        color: _isDarkMode ? Colors.grey[850] : Colors.lightBlue[100],
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Form(
          key: _formKey,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.selectedLanguage == 'Polski'
                      ? 'Zarejestruj się'
                      : 'Register',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _nameController,
                  label: widget.selectedLanguage == 'Polski'
                      ? 'Wpisz swoje imię'
                      : 'Enter your name',
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _surnameController,
                  label: widget.selectedLanguage == 'Polski'
                      ? 'Wpisz swoje nazwisko'
                      : 'Enter your surname',
                ),
                const SizedBox(height: 20),
                _buildDateField(),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _passwordController,
                  label: widget.selectedLanguage == 'Polski'
                      ? 'Hasło'
                      : 'Password',
                  obscureText: true,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 5.0,
                  ),
                  child: Text(
                    widget.selectedLanguage == 'Polski'
                        ? 'Zarejestruj'
                        : 'Register',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: _isDarkMode ? Colors.grey[700] : Colors.white,
        ),
        obscureText: obscureText,
        style: const TextStyle(
          color: Colors.black,
        ),
        validator: (value) {
          if (controller == _passwordController) {
            if (value == null || value.isEmpty) {
              return widget.selectedLanguage == 'Polski'
                  ? 'Uzupełnij to pole'
                  : 'Fill this field';
            }
            if (value.length < 8) {
              return widget.selectedLanguage == 'Polski'
                  ? 'Hasło musi mieć co najmniej 8 znaków'
                  : 'Password must be at least 8 characters long';
            }
            return null;
          }
          return value == null || value.isEmpty
              ? widget.selectedLanguage == 'Polski'
                  ? 'Uzupełnij to pole'
                  : 'Fill this field'
              : null;
        },
        onTap: () => _speak(label),
      ),
    );
  }

  Widget _buildDateField() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: TextFormField(
        controller: _birthdateController,
        decoration: InputDecoration(
          labelText: widget.selectedLanguage == 'Polski'
              ? 'Wpisz datę urodzenia'
              : 'Enter your birthdate',
          labelStyle: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: _isDarkMode ? Colors.grey[700] : Colors.white,
        ),
        readOnly: true,
        style: const TextStyle(
          color: Colors.black,
        ),
        onTap: () async {
          _speak(widget.selectedLanguage == 'Polski'
              ? 'Wybierz datę urodzenia'
              : 'Select your birthdate');
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            _birthdateController.text =
                "${date.year}-${date.month}-${date.day}";
            _speak(widget.selectedLanguage == 'Polski'
                ? 'Wybrano datę ${_birthdateController.text}'
                : 'Selected date ${_birthdateController.text}');
          }
        },
        validator: (value) => value == null || value.isEmpty
            ? widget.selectedLanguage == 'Polski'
                ? 'Uzupełnij to pole'
                : 'Fill this field'
            : null,
      ),
    );
  }
}
