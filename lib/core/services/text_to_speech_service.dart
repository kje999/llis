import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechService {
  static final TextToSpeechService _instance = TextToSpeechService._();
  static TextToSpeechService get instance => _instance;

  final FlutterTts _flutterTts = FlutterTts();
  bool isEnabled = true;
  bool isSpeaking = false;

  TextToSpeechService._() {
    _initTts();
  }

  void _initTts() {
    try {
      _flutterTts.setLanguage('en-US');
      _flutterTts.setSpeechRate(0.45);
      _flutterTts.setVolume(1.0);
      _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        isSpeaking = true;
      });

      _flutterTts.setCompletionHandler(() {
        isSpeaking = false;
      });

      _flutterTts.setErrorHandler((msg) {
        isSpeaking = false;
        debugPrint('TTS Error: $msg');
      });
    } catch (e) {
      debugPrint('TTS init error: $e');
    }
  }

  Future<void> speak(String text) async {
    if (!isEnabled) return;
    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      isSpeaking = false;
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }

  /// Format 6 numbers into natural spoken English
  static String formatSpokenNumbers(List<int> numbers) {
    if (numbers.length != 6) return numbers.join(', ');
    final wordList = numbers.map(_numberToWords).toList();
    return '${wordList[0]}, ${wordList[1]}, ${wordList[2]}, ${wordList[3]}, ${wordList[4]}, and ${wordList[5]}';
  }

  static String _numberToWords(int number) {
    const units = [
      '', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine',
      'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen',
      'seventeen', 'eighteen', 'nineteen'
    ];
    const tens = ['', '', 'twenty', 'thirty', 'forty', 'fifty'];

    if (number < 20) return units[number];
    final t = number ~/ 10;
    final u = number % 10;
    if (u == 0) return tens[t];
    return '${tens[t]}-${units[u]}';
  }
}
