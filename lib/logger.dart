import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AppLogger {
  static File? _logFile;

  static Future<void> init() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final logDir = Directory(dir.path);
      if (!logDir.existsSync()) {
        logDir.createSync(recursive: true);
      }
      _logFile = File('${dir.path}/tinymind.log');
      
      // Clear log file if it exceeds 10MB to prevent disk bloating
      if (_logFile!.existsSync() && _logFile!.lengthSync() > 10 * 1024 * 1024) {
        _logFile!.writeAsStringSync('');
      }
      
      log("Dart Logger Initialized.");
    } catch (e) {
      print("Failed to initialize file logger: $e");
    }
  }

  static void log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logLine = "[$timestamp] [Dart] $message\n";
    print(logLine.trim()); // Still print to console/stdout
    
    if (_logFile != null) {
      try {
        _logFile!.writeAsStringSync(logLine, mode: FileMode.append, flush: true);
      } catch (e) {
        print("Failed writing log to file: $e");
      }
    }
  }

  static Future<void> openLogDirectory() async {
    if (_logFile != null) {
      final parentDir = _logFile!.parent.path;
      if (Platform.isMacOS) {
        await Process.run('open', [parentDir]);
      } else if (Platform.isWindows) {
        await Process.run('explorer.exe', [parentDir]);
      }
    }
  }
}
