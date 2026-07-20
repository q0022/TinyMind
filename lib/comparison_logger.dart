import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:characters/characters.dart';

class ComparisonLogger {
  static File? _logFile;
  static StringBuffer _rawBuffer = StringBuffer();
  static StringBuffer _outputBuffer = StringBuffer();
  static const int _flushThreshold = 1000;

  static Future<void> init() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final logDir = Directory(dir.path);
      if (!logDir.existsSync()) {
        logDir.createSync(recursive: true);
      }
      _logFile = File('${dir.path}/tinymind_comparison.log');
      
      // Clear log file if it exceeds 10MB to prevent disk bloating
      if (_logFile!.existsSync() && _logFile!.lengthSync() > 10 * 1024 * 1024) {
        _logFile!.writeAsStringSync('');
      }
      
      // Append initial session start
      final timestamp = DateTime.now().toIso8601String();
      _logFile!.writeAsStringSync(
        "\n=========================================\n"
        "SESSION STARTED AT $timestamp\n"
        "=========================================\n",
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      print("Failed to initialize comparison logger: $e");
    }
  }

  static void recordRawKey(String char) {
    _rawBuffer.write(char);
    _checkFlush();
  }

  static void recordRawBackspace() {
    final chars = _rawBuffer.toString().characters;
    if (chars.isNotEmpty) {
      _rawBuffer = StringBuffer(chars.skipLast(1).toString());
    }
  }

  static void recordOutputNormal(String char) {
    _outputBuffer.write(char);
    _checkFlush();
  }

  static void recordOutputBackspace() {
    final chars = _outputBuffer.toString().characters;
    if (chars.isNotEmpty) {
      _outputBuffer = StringBuffer(chars.skipLast(1).toString());
    }
  }

  static void recordOutputAutocorrect(int backspaces, String replacement) {
    var chars = _outputBuffer.toString().characters;
    for (int i = 0; i < backspaces; i++) {
      if (chars.isNotEmpty) {
        chars = chars.skipLast(1);
      }
    }
    _outputBuffer = StringBuffer(chars.toString());
    _outputBuffer.write(replacement);
    _checkFlush();
  }

  static void _checkFlush() {
    if (_rawBuffer.length >= _flushThreshold || _outputBuffer.length >= _flushThreshold) {
      flush();
    }
  }

  static void flush() {
    if (_rawBuffer.isEmpty && _outputBuffer.isEmpty) return;
    if (_logFile == null) return;
    
    final timestamp = DateTime.now().toIso8601String();
    final logBlock = """
=========================================
TIMESTAMP: $timestamp
--- RAW INPUT STREAM ---
"${_rawBuffer.toString()}"
--- ACTUAL COMMIT OUTPUT ---
"${_outputBuffer.toString()}"
=========================================
""";
    try {
      _logFile!.writeAsStringSync(logBlock, mode: FileMode.append, flush: true);
    } catch (e) {
      print("Failed writing comparison log: $e");
    }
    _rawBuffer.clear();
    _outputBuffer.clear();
  }
}
