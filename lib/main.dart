import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:auto_updater/auto_updater.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'autocorrect_engine.dart';
import 'commands/slash_command.dart';
import 'language_mapper.dart';
import 'localization.dart';
import 'logger.dart';
import 'comparison_logger.dart';

part 'dashboard_tab.dart';
part 'settings_tab.dart';
part 'dictionary_tab.dart';

final GlobalKey<TinyMindAppState> tinyMindAppKey = GlobalKey<TinyMindAppState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLogger.init();
  await ComparisonLogger.init();

  // กำหนดค่า Launch at Startup
  LaunchAtStartup.instance.setup(
    appName: "TinyMind",
    appPath: Platform.resolvedExecutable,
    packageName: "com.tinymind.tinymind",
  );

  // ตั้งค่า Window Manager
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(900, 900),
    minimumSize: Size(900, 900),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden, // ซ่อน Title Bar หลัก เพื่อออกแบบ UI เอง
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    if (Platform.isMacOS) {
      try {
        const platform = MethodChannel('com.tinymind.app/keyboard');
        await platform.invokeMethod('showDockIcon');
      } catch (e) {
        // ignore
      }
    }
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setPreventClose(true); // ป้องกันไม่ให้กดปิดแล้วปิดโปรเจกต์ (ให้ซ่อนลง Tray แทน)
  });

  runApp(TinyMindApp(key: tinyMindAppKey));
}

class TinyMindApp extends StatefulWidget {
  const TinyMindApp({super.key});

  @override
  State<TinyMindApp> createState() => TinyMindAppState();
}

class TinyMindAppState extends State<TinyMindApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  Color _primaryColor = const Color(0xFF6366F1); // Default Indigo

  @override
  void initState() {
    super.initState();
    _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? true;
    final colorVal = prefs.getInt('primaryColorValue') ?? 0xFF6366F1;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      _primaryColor = Color(colorVal);
    });
  }

  void updateTheme(ThemeMode mode, Color primary) {
    setState(() {
      _themeMode = mode;
      _primaryColor = primary;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TinyMind - AI Autocorrection',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.light(
          primary: _primaryColor,
          secondary: _primaryColor.withOpacity(0.8),
          surface: const Color(0xFFF1F5F9), // slate 100
          background: const Color(0xFFF8FAFC), // slate 50
        ),
        fontFamily: 'SF Pro Display',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.dark(
          primary: _primaryColor,
          secondary: _primaryColor.withOpacity(0.8),
          surface: const Color(0xFF1E293B), // slate 800
          background: const Color(0xFF0F172A), // slate 900
        ),
        fontFamily: 'SF Pro Display',
      ),
      home: const MainDashboard(),
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> with WindowListener {
  // Method Channel สำหรับสื่อสารกับ macOS Native Swift
  static const _platform = MethodChannel('com.tinymind.app/keyboard');

  // ตัวแปรการตั้งค่า
  bool _isEnabled = true;
  bool _isAutoStart = false;
  bool _isLocalCorrection = true;
  bool _isAiCorrection = false;
  String _correctionMode = 'hybrid';
  String _ggufModelPath = '';
  bool _isModelLoading = false;
  bool _hasAccessibility = false;
  bool _isAutoSwitchOnLength = true;
  int _autoSwitchLength = 8;
  bool _isLayoutDecidedForCurrentWord = false;
  int _lastCheckedLen = 0;
  bool _continuousSwitchStopped = false;
  String _hotkeyModifier = 'Shift';
  String _hotkeyKey = 'Backspace';
  bool _useCustomHotkey = false;

  bool _useOSKeyboards = true;
  bool _useSlashCommands = true;
  bool _useCodeFilter = true;
  bool _isKoreanEnabled = false;
  bool _isJapaneseEnabled = false;
  bool _isChineseEnabled = false;
  String _activeAppMode = 'native';

  // ข้อมูลเวอร์ชันแอปและการตรวจเช็คอัปเดต
  static String currentVersion = '';
  bool _isUpdateAvailable = false;
  String _latestVersion = '';
  String _latestReleaseUrl = '';
  bool _isCheckingForUpdates = false;
  String? _updateCheckMessage;

  // ตัวแปรควบคุมธีมและการแสดงผล
  bool _isDarkMode = true;
  int _primaryColorValue = 0xFF6366F1; // Default Indigo
  String _displayLanguage = 'th';

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _surfaceColor {
    return _isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03);
  }

  Color get _borderColor {
    return _isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
  }

  Color get _dividerColor {
    return _isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
  }

  Color get _textColorPrimary {
    return _isDark ? Colors.white : Colors.black87;
  }

  Color get _textColorSecondary {
    return _isDark ? Colors.white70 : Colors.black54;
  }

  Color get _textColorTertiary {
    return _isDark ? Colors.white30 : Colors.black38;
  }

  void _changeThemeMode(bool isDark) {
    setState(() {
      _isDarkMode = isDark;
      _saveSetting('isDarkMode', isDark);
    });
    tinyMindAppKey.currentState?.updateTheme(
      isDark ? ThemeMode.dark : ThemeMode.light,
      Color(_primaryColorValue),
    );
  }

  void _changePrimaryColor(int colorValue) {
    setState(() {
      _primaryColorValue = colorValue;
      _saveSetting('primaryColorValue', colorValue);
    });
    tinyMindAppKey.currentState?.updateTheme(
      _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      Color(colorValue),
    );
  }

  // สำหรับระบบดาวน์โหลดโมเดลอัตโนมัติ
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadProgressText = '';

  // ข้อมูลสถิติ (Statistics)
  int _wordsCorrected = 0;
  int _layoutFixed = 0;
  int _aiRequests = 0;
  int _savedChars = 0;
  int _hotkeyCount = 0;

  bool _showTodayStatsOnly = true;
  int _todayWordsCorrected = 0;
  int _todayLayoutFixed = 0;
  int _todayAiRequests = 0;
  int _todaySavedChars = 0;
  int _todayHotkeyCount = 0;

  // ตัวแปร UI & Buffer
  String _currentBuffer = '';
  final List<String> _bufferLayouts = [];
  String _slashBuffer = '';
  final List<SlashCommand> _slashCommands = [TranslateShortCommand(), TranslateCommand()];
  String _fullSentenceBuffer = '';
  Timer? _debounceTimer;
  Map<String, String>? _lastReplacement;
  String _lastReplacementEndingChar = '';
  bool _canUndo = false;
  DateTime? _lastSwapTime;
  String? _lastSwappedWord;
  int _activeTab = 0; // 0: Dashboard, 1: Settings, 2: Dictionary

  final SystemTray _systemTray = SystemTray();

  int _lastOsKeystrokeCount = 0; // Track the exact OS keystrokes to sync with Swift

  // ประวัติการแก้ไขคำผิดล่าสุด
  List<Map<String, String>> _recentCorrections = [];

  // คำศัพท์ข้าม (Custom Skip/Ignore Words)
  List<String> _ignoredWords = [];
  final TextEditingController _ignoreWordController = TextEditingController();

  // คีย์ลัดคำย่อ (Text Shortcuts Expansion)
  Map<String, String> _textShortcuts = {};
  final TextEditingController _shortcutKeyController = TextEditingController();
  final TextEditingController _shortcutValueController = TextEditingController();
  int _dictionarySubTab = 0; // 0: Ignore List, 1: Text Shortcuts

  // Keyboard Sandbox (ลบเกิน / ลบขาด Test Area)
  final TextEditingController _sandboxController = TextEditingController(text: ' ' * 15);
  final FocusNode _sandboxFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initApp();

    AutocorrectEngine.onAiDecision = (original, decision, type) {
      if (!mounted) return;
      setState(() {
        _recentCorrections.removeWhere((item) => item['original'] == original);
        _recentCorrections.insert(0, {
          'original': original,
          'corrected': decision,
          'timestamp': DateTime.now().toString().substring(11, 19),
          'type': type,
        });
        if (_recentCorrections.length > 5) {
          _recentCorrections.removeLast();
        }
      });
      _saveHistory();
    };

    // ฟังเหตุการณ์จาก macOS Keyboard Hook
    _platform.setMethodCallHandler((call) async {
      if (!_isEnabled) return;

      if (call.arguments is Map) {
        final args = call.arguments as Map;
        if (args.containsKey('osKeystrokeCount')) {
          _lastOsKeystrokeCount = args['osKeystrokeCount'] as int;
        }
      }

      switch (call.method) {
        case 'onKey':
          final args = call.arguments as Map;
          final String char = args['char'];
          final String layout = args['layout'] ?? 'en';
          _handleKeyPress(char, layout: layout);
          break;
        case 'onBackspace':
          _handleBackspace();
          break;
        case 'clearBuffer':
          _clearBuffers();
          break;
        case 'onHotkey':
          _handleHotkey();
          break;
        case 'onEnterTriggered':
          await _handleEnterTriggered();
          break;
        case 'updateActiveApp':
          final args = call.arguments as Map;
          if (mounted) {
            setState(() {
              _activeAppMode = args['appMode'] ?? 'native';
            });
          }
          _clearBuffers();
          await _syncBufferStatus();
          AppLogger.log("Dart: updateActiveApp - appMode=$_activeAppMode, buffers cleared");
          break;
      }
    });

    // เริ่มการสืบค้นสิทธิ์ Accessibility ซ้ำทุก 2 วินาที จนกว่าจะอนุญาต
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_hasAccessibility && mounted) {
        _checkAccessibilityPermission();
      }
    });

    // ตรวจจับคีย์บอร์ดที่ติดตั้งในเครื่องทุก 10 วินาที
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _updateActiveKeyboards();
      }
    });
  }

  Future<void> _initAutoUpdater() async {
    if (Platform.isMacOS || Platform.isWindows) {
      try {
        await autoUpdater.setFeedURL('https://raw.githubusercontent.com/q0022/TinyMind/main/appcast.xml');
        await autoUpdater.setScheduledCheckInterval(7200);
        AppLogger.log("Sparkle AutoUpdater Initialized.");
      } catch (e) {
        AppLogger.log("Failed to initialize Sparkle AutoUpdater: $e");
      }
    }
  }

  Future<void> _initApp() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      currentVersion = packageInfo.version;
    });
    
    await _loadSettings();
    await _updateActiveKeyboards();
    await _initSystemTray();
    await _checkAccessibilityPermission();
    _initAutoUpdater();
    _checkForUpdates(); // เช็คเวอร์ชันอัปเดตจาก GitHub ในพื้นหลัง
  }

  Future<void> _checkForUpdates() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/q0022/TinyMind/releases/latest'),
        headers: {'User-Agent': 'TinyMind-App'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String tag = data['tag_name'] ?? '';
        final String url = data['html_url'] ?? '';

        if (_isNewerVersion(currentVersion, tag)) {
          setState(() {
            _isUpdateAvailable = true;
            _latestVersion = tag.replaceAll('v', '').trim();
            _latestReleaseUrl = url;
          });
          AppLogger.log("TinyMind Update: New version $_latestVersion available at $url");
        } else {
          AppLogger.log("TinyMind Update: App is up to date (current: $currentVersion, latest: $tag)");
        }
      }
    } catch (e) {
      AppLogger.log("TinyMind Update: Failed to check for updates: $e");
    }
  }

  Future<void> _manualCheckForUpdates() async {
    setState(() {
      _isCheckingForUpdates = true;
      _updateCheckMessage = AppTranslations.translate('checking_updates_status', _displayLanguage);
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/q0022/TinyMind/releases/latest'),
        headers: {'User-Agent': 'TinyMind-App'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String tag = data['tag_name'] ?? '';
        final String url = data['html_url'] ?? '';

        if (_isNewerVersion(currentVersion, tag)) {
          setState(() {
            _isUpdateAvailable = true;
            _latestVersion = tag.replaceAll('v', '').trim();
            _latestReleaseUrl = url;
            _updateCheckMessage = "${AppTranslations.translate('update_available', _displayLanguage)} (v$_latestVersion)";
          });
          
          if (Platform.isMacOS || Platform.isWindows) {
            try {
              await autoUpdater.checkForUpdates();
            } catch (e) {
              AppLogger.log("Failed to launch Sparkle update dialog: $e");
            }
          }
        } else {
          setState(() {
            _isUpdateAvailable = false;
            _updateCheckMessage = AppTranslations.translate('no_updates_status', _displayLanguage);
          });
        }
      } else {
        setState(() {
          _updateCheckMessage = "Error: HTTP ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _updateCheckMessage = "Error: $e";
      });
      AppLogger.log("TinyMind Update: Manual update check failed: $e");
    } finally {
      setState(() {
        _isCheckingForUpdates = false;
      });
    }
  }

  bool _isNewerVersion(String current, String remote) {
    final currentClean = current.replaceAll('v', '').trim();
    final remoteClean = remote.replaceAll('v', '').trim();

    final currentParts = currentClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final remoteParts = remoteClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLength = remoteParts.length > currentParts.length ? remoteParts.length : currentParts.length;
    for (int i = 0; i < maxLength; i++) {
      final remotePart = i < remoteParts.length ? remoteParts[i] : 0;
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      if (remotePart > currentPart) return true;
      if (remotePart < currentPart) return false;
    }
    return false;
  }

  void _launchUrl(String url) {
    try {
      if (Platform.isMacOS) {
        Process.run('open', [url]);
      } else if (Platform.isWindows) {
        Process.run('start', [url], runInShell: true);
      }
    } catch (e) {
      AppLogger.log("TinyMind Update: Failed to launch URL: $e");
    }
  }

  void updateState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _debounceTimer?.cancel();
    _ignoreWordController.dispose();
    _sandboxController.dispose();
    _sandboxFocusNode.dispose();
    super.dispose();
  }

  // โหลดค่าปรับแต่งจาก Shared Preferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isEnabled = prefs.getBool('isEnabled') ?? true;
      _isAutoStart = prefs.getBool('isAutoStart') ?? false;
      _isLocalCorrection = prefs.getBool('isLocalCorrection') ?? true;
      _isAiCorrection = prefs.getBool('isAiCorrection') ?? false;
      _ggufModelPath = prefs.getString('ggufModelPath') ?? '';
      
      // ตรวจสอบว่าไฟล์โมเดลมีอยู่จริงหรือไม่
      if (_ggufModelPath.isNotEmpty) {
        final file = File(_ggufModelPath);
        if (!file.existsSync()) {
          _ggufModelPath = '';
          _saveSetting('ggufModelPath', '');
        }
      }
      // หากไม่มีโมเดลอยู่จริง แต่สวิตช์ AI เปิดค้างอยู่ ให้รีเซ็ตสวิตช์เป็น ปิด (false)
      if (_ggufModelPath.isEmpty && _isAiCorrection) {
        _isAiCorrection = false;
        _saveSetting('isAiCorrection', false);
      }
      _isAutoSwitchOnLength = prefs.getBool('isAutoSwitchOnLength') ?? true;
      _autoSwitchLength = prefs.getInt('autoSwitchLength') ?? 8;

      // ค้นหาโมเดลในเครื่องโดยอัตโนมัติหากยังไม่ได้ตั้งค่า
      if (_ggufModelPath.isEmpty) {
        getApplicationSupportDirectory().then((dir) {
          final qwenFile = File('${dir.path}/models/qwen2.5-1.5b-instruct-q4_k_m.gguf');
          final smolFile = File('${dir.path}/models/smollm2-360m-instruct-q4_k_m.gguf');
          
          if (qwenFile.existsSync()) {
            setState(() {
              _ggufModelPath = qwenFile.path;
            });
            _saveSetting('ggufModelPath', qwenFile.path);
          } else if (smolFile.existsSync()) {
            setState(() {
              _ggufModelPath = smolFile.path;
            });
            _saveSetting('ggufModelPath', smolFile.path);
          } else {
            // เช็คในโฟลเดอร์พัฒนาของเครื่องพี่บอยเพื่อความรวดเร็วในการทดสอบ
            const qwenDevPath = '/Users/q0022/sites/TinyMind/assets/models/qwen2.5-1.5b-instruct-q4_k_m.gguf';
            const smolDevPath = '/Users/q0022/sites/TinyMind/assets/models/SmolLM2-360M-Instruct-Q4_K_M.gguf';
            final defaultPath = File(qwenDevPath).existsSync() ? qwenDevPath : smolDevPath;
            
            if (File(defaultPath).existsSync()) {
              setState(() {
                _ggufModelPath = defaultPath;
              });
              _saveSetting('ggufModelPath', defaultPath);
            }
          }
        });
      }

      // โหลดสถิติ
      _wordsCorrected = prefs.getInt('wordsCorrected') ?? 0;
      _layoutFixed = prefs.getInt('layoutFixed') ?? 0;
      _aiRequests = prefs.getInt('aiRequests') ?? 0;
      _savedChars = prefs.getInt('savedChars') ?? 0;
      _hotkeyCount = prefs.getInt('hotkeyCount') ?? 0;

      String todayStr = DateTime.now().toIso8601String().substring(0, 10);
      String savedDate = prefs.getString('statsDate') ?? '';
      if (savedDate != todayStr) {
        prefs.setString('statsDate', todayStr);
        prefs.setInt('wordsCorrected_$todayStr', 0);
        prefs.setInt('layoutFixed_$todayStr', 0);
        prefs.setInt('aiRequests_$todayStr', 0);
        prefs.setInt('savedChars_$todayStr', 0);
        prefs.setInt('hotkeyCount_$todayStr', 0);
        
        _todayWordsCorrected = 0;
        _todayLayoutFixed = 0;
        _todayAiRequests = 0;
        _todaySavedChars = 0;
        _todayHotkeyCount = 0;
      } else {
        _todayWordsCorrected = prefs.getInt('wordsCorrected_$todayStr') ?? 0;
        _todayLayoutFixed = prefs.getInt('layoutFixed_$todayStr') ?? 0;
        _todayAiRequests = prefs.getInt('aiRequests_$todayStr') ?? 0;
        _todaySavedChars = prefs.getInt('savedChars_$todayStr') ?? 0;
        _todayHotkeyCount = prefs.getInt('hotkeyCount_$todayStr') ?? 0;
      }

      // โหลดคำข้าม
      _ignoredWords = prefs.getStringList('ignoredWords') ?? [];

      // โหลดคลังคำศัพท์ภาษาอังกฤษของผู้ใช้
      final userEnList = prefs.getStringList('userEnWords') ?? [];
      AutocorrectEngine.userEnWords.clear();
      AutocorrectEngine.userEnWords.addAll(userEnList);

      // โหลดประวัติการแก้ล่าสุด
      final historyRaw = prefs.getString('recentCorrections');
      if (historyRaw != null) {
        _recentCorrections = List<Map<String, String>>.from(
          (jsonDecode(historyRaw) as List).map((item) => Map<String, String>.from(item)),
        );
      }

      // โหลดปุ่มลัด
      _hotkeyModifier = prefs.getString('hotkeyModifier') ?? 'Shift';
      _hotkeyKey = prefs.getString('hotkeyKey') ?? 'Backspace';
      _useCustomHotkey = prefs.getBool('useCustomHotkey') ?? false;
      _useOSKeyboards = prefs.getBool('useOSKeyboards') ?? true;
      _useSlashCommands = prefs.getBool('useSlashCommands') ?? true;
      _useCodeFilter = prefs.getBool('useCodeFilter') ?? true;
      AutocorrectEngine.isCodeFilterEnabled = _useCodeFilter;
      _isKoreanEnabled = prefs.getBool('isKoreanEnabled') ?? false;
      _isJapaneseEnabled = prefs.getBool('isJapaneseEnabled') ?? false;
      _isChineseEnabled = prefs.getBool('isChineseEnabled') ?? false;

      // โหลดธีม
      _isDarkMode = prefs.getBool('isDarkMode') ?? true;
      _primaryColorValue = prefs.getInt('primaryColorValue') ?? 0xFF6366F1;
      _displayLanguage = prefs.getString('displayLanguage') ?? 'th';
      _correctionMode = prefs.getString('correctionMode') ?? 'hybrid';
      AutocorrectEngine.correctionMode = _correctionMode;
      
      // โหลดคีย์ลัดคำย่อ
      final shortcutsJson = prefs.getString('textShortcuts') ?? '{}';
      try {
        _textShortcuts = Map<String, String>.from(jsonDecode(shortcutsJson));
      } catch (e) {
        _textShortcuts = {};
      }
    });

    // อัปเดต Hotkey ไปยังฝั่ง Native
    await _updateNativeHotkey();

    // อัปเดต ThemeMode ไปยัง TinyMindApp
    tinyMindAppKey.currentState?.updateTheme(
      _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      Color(_primaryColorValue),
    );

    if (_isAiCorrection && _ggufModelPath.isNotEmpty) {
      _initLocalLlama(_ggufModelPath);
    }
    _updateSystemTrayMenu();
  }

  // อัปเดตผังแป้นพิมพ์ที่เปิดใช้งานจากฝั่ง macOS
  Future<void> _updateActiveKeyboards() async {
    if (_useOSKeyboards) {
      try {
        final List<dynamic>? result = await _platform.invokeMethod('getEnabledLanguages');
        if (result != null) {
          final List<String> osLangs = result.map((e) => e.toString().toLowerCase()).toList();
          AppLogger.log("Dart: OS Enabled Languages: $osLangs");
          setState(() {
            _isKoreanEnabled = osLangs.contains('ko');
            _isJapaneseEnabled = osLangs.contains('ja') || osLangs.contains('jp');
            _isChineseEnabled = osLangs.contains('zh') || osLangs.contains('ch');
          });
        }
      } catch (e) {
        AppLogger.log("Dart: Failed to query OS enabled languages: $e");
      }
    }

    // ซิงค์การตั้งค่าไปยัง AutocorrectEngine
    AutocorrectEngine.isKoreanEnabled = _isKoreanEnabled;
    AutocorrectEngine.isJapaneseEnabled = _isJapaneseEnabled;
    AutocorrectEngine.isChineseEnabled = _isChineseEnabled;
  }

  // ส่งข้อมูล Hotkey ไปยัง Native
  Future<void> _updateNativeHotkey() async {
    try {
      await _platform.invokeMethod('updateHotkey', {
        'modifier': _hotkeyModifier,
        'key': _hotkeyKey,
        'useCustom': _useCustomHotkey,
      });
      AppLogger.log("Dart: updateHotkey sent: $_hotkeyModifier + $_hotkeyKey, useCustom: $_useCustomHotkey");
    } catch (e) {
      AppLogger.log("Dart: Error updating native hotkey: $e");
    }
  }

  // บันทึกการตั้งค่า
  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    }
  }

  // บันทึกประวัติการแก้คำผิด
  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('recentCorrections', jsonEncode(_recentCorrections));
  }

  void _checkAndResetDailyStats() {
    String todayStr = DateTime.now().toIso8601String().substring(0, 10);
    SharedPreferences.getInstance().then((prefs) {
      String savedDate = prefs.getString('statsDate') ?? '';
      if (savedDate != todayStr) {
        setState(() {
          _todayWordsCorrected = 0;
          _todayLayoutFixed = 0;
          _todayAiRequests = 0;
          _todaySavedChars = 0;
          _todayHotkeyCount = 0;
        });
        prefs.setString('statsDate', todayStr);
        prefs.setInt('wordsCorrected_$todayStr', 0);
        prefs.setInt('layoutFixed_$todayStr', 0);
        prefs.setInt('aiRequests_$todayStr', 0);
        prefs.setInt('savedChars_$todayStr', 0);
        prefs.setInt('hotkeyCount_$todayStr', 0);
      }
    });
  }

  void _incrementStat(String baseKey, {int value = 1}) {
    _checkAndResetDailyStats();
    String todayStr = DateTime.now().toIso8601String().substring(0, 10);
    
    setState(() {
      if (baseKey == 'wordsCorrected') {
        _wordsCorrected += value;
        _todayWordsCorrected += value;
      } else if (baseKey == 'layoutFixed') {
        _layoutFixed += value;
        _todayLayoutFixed += value;
      } else if (baseKey == 'aiRequests') {
        _aiRequests += value;
        _todayAiRequests += value;
      } else if (baseKey == 'savedChars') {
        _savedChars += value;
        _todaySavedChars += value;
      } else if (baseKey == 'hotkeyCount') {
        _hotkeyCount += value;
        _todayHotkeyCount += value;
      }
    });

    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('statsDate', todayStr);
      if (baseKey == 'wordsCorrected') {
        prefs.setInt('wordsCorrected', _wordsCorrected);
        prefs.setInt('wordsCorrected_$todayStr', _todayWordsCorrected);
      } else if (baseKey == 'layoutFixed') {
        prefs.setInt('layoutFixed', _layoutFixed);
        prefs.setInt('layoutFixed_$todayStr', _todayLayoutFixed);
      } else if (baseKey == 'aiRequests') {
        prefs.setInt('aiRequests', _aiRequests);
        prefs.setInt('aiRequests_$todayStr', _todayAiRequests);
      } else if (baseKey == 'savedChars') {
        prefs.setInt('savedChars', _savedChars);
        prefs.setInt('savedChars_$todayStr', _todaySavedChars);
      } else if (baseKey == 'hotkeyCount') {
        prefs.setInt('hotkeyCount', _hotkeyCount);
        prefs.setInt('hotkeyCount_$todayStr', _todayHotkeyCount);
      }
    });
  }

  // ตรวจสอบสิทธิ์การเข้าถึง (Accessibility)
  Future<void> _checkAccessibilityPermission() async {
    try {
      final bool hasAccess = await _platform.invokeMethod('checkAccessibility');
      if (_hasAccessibility != hasAccess) {
        setState(() {
          _hasAccessibility = hasAccess;
        });
      }
    } catch (e) {
      AppLogger.log("Error checking accessibility: $e");
    }
  }

  // ขอสิทธิ์ Accessibility
  Future<void> _requestAccessibilityPermission() async {
    try {
      final bool hasAccess = await _platform.invokeMethod('requestAccessibility');
      setState(() {
        _hasAccessibility = hasAccess;
      });
    } catch (e) {
      AppLogger.log("Error requesting accessibility: $e");
    }
  }

  // โหลดโมเดลภาษา local (llama.cpp)
  Future<void> _initLocalLlama(String path) async {
    if (path.isEmpty) return;
    setState(() {
      _isModelLoading = true;
    });
    try {
      await AutocorrectEngine.initAI(path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${AppTranslations.translate('model_prepare_failed', _displayLanguage)}$e")),
      );
    } finally {
      setState(() {
        _isModelLoading = false;
      });
    }
  }

  // เลือกไฟล์โมเดล GGUF
  Future<void> _pickGgufModel() async {
    try {
      fp.FilePickerResult? result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['gguf'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        setState(() {
          _ggufModelPath = path;
          _isAiCorrection = true; // Auto-enable AI correction once model is selected
        });
        _saveSetting('ggufModelPath', path);
        _saveSetting('isAiCorrection', true);
        await _initLocalLlama(path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${AppTranslations.translate('model_pick_failed', _displayLanguage)}$e")),
      );
    }
  }

  // อัปเกรดโมเดลจาก SmolLM2 เป็น Qwen 2.5 1.5B พร้อมลบไฟล์เก่าทิ้งเพื่อคืนพื้นที่
  Future<void> _upgradeToQwenModel() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final modelsDir = Directory('${directory.path}/models');
      
      // ปิดการทำงานของ AI เพื่อคืนทรัพยากรและปลดล็อกไฟล์โมเดลก่อนลบ
      AutocorrectEngine.disposeAI();
      
      // ลบโมเดล SmolLM2 เก่า
      final smolFile = File('${modelsDir.path}/smollm2-360m-instruct-q4_k_m.gguf');
      if (smolFile.existsSync()) {
        try {
          await smolFile.delete();
          AppLogger.log("TinyMind: Old SmolLM2 model deleted successfully.");
        } catch (e) {
          AppLogger.log("TinyMind: Failed to delete old SmolLM2 model: $e");
        }
      }
      
      setState(() {
        _ggufModelPath = '';
      });
      await _saveSetting('ggufModelPath', '');
      
      // เริ่มกระบวนการดาวน์โหลด Qwen
      final path = await _checkAndPrepareModel();
      setState(() {
        _ggufModelPath = path;
        _isAiCorrection = true;
      });
      await _saveSetting('ggufModelPath', path);
      await _saveSetting('isAiCorrection', true);
      
      await _initLocalLlama(path);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("อัปเกรดเป็นโมเดล Qwen 2.5 1.5B เรียบร้อยแล้วค่ะ! 🎉")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${AppTranslations.translate('model_prepare_failed', _displayLanguage)}$e")),
        );
      }
    }
  }

  // เช็คและเตรียมไฟล์โมเดล (คัดลอกในเครื่อง หรือดาวน์โหลดจากคลาวด์)
  Future<String> _checkAndPrepareModel() async {
    final directory = await getApplicationSupportDirectory();
    final modelsDir = Directory('${directory.path}/models');
    if (!modelsDir.existsSync()) {
      modelsDir.createSync(recursive: true);
    }
    
    // ตั้งค่า Qwen เป็นตัวเลือกอันดับแรก
    final qwenFile = File('${modelsDir.path}/qwen2.5-1.5b-instruct-q4_k_m.gguf');
    if (qwenFile.existsSync()) {
      return qwenFile.path;
    }
    final modelFile = File('${modelsDir.path}/smollm2-360m-instruct-q4_k_m.gguf');
    if (modelFile.existsSync()) {
      return modelFile.path;
    }
    
    // ลองคัดลอกไฟล์พัฒนาในเครื่องผู้พัฒนาเพื่อประหยัดเน็ตก่อน
    const qwenDevPath = '/Users/q0022/sites/TinyMind/assets/models/qwen2.5-1.5b-instruct-q4_k_m.gguf';
    const smolDevPath = '/Users/q0022/sites/TinyMind/assets/models/SmolLM2-360M-Instruct-Q4_K_M.gguf';
    final devPath = File(qwenDevPath).existsSync() ? qwenDevPath : smolDevPath;
    
    // หากอยู่ในเครื่องผู้พัฒนาและมีไฟล์ใดไฟล์หนึ่ง ให้เลือกคัดลอกไฟล์นั้น
    final targetFile = File(devPath).existsSync()
        ? (devPath == qwenDevPath ? qwenFile : modelFile)
        : qwenFile;
    
    if (File(devPath).existsSync()) {
      setState(() {
        _isDownloading = true;
        _downloadProgressText = AppTranslations.translate('model_copying_dev', _displayLanguage);
        _downloadProgress = 0.0;
      });
      
      final sourceFile = File(devPath);
      final totalBytes = sourceFile.lengthSync();
      final input = sourceFile.openRead();
      final output = targetFile.openWrite();
      int copiedBytes = 0;
      
      await for (var chunk in input) {
        output.add(chunk);
        copiedBytes += chunk.length;
        setState(() {
          _downloadProgress = copiedBytes / totalBytes;
          final prefix = AppTranslations.translate('model_copying_progress', _displayLanguage);
          _downloadProgressText = '$prefix ${(_downloadProgress * 100).toStringAsFixed(1)}% (${(copiedBytes / (1024 * 1024)).toStringAsFixed(0)} / ${(totalBytes / (1024 * 1024)).toStringAsFixed(0)} MB)';
        });
      }
      await output.close();
      
      setState(() {
        _isDownloading = false;
      });
      return targetFile.path;
    }
    
    // ดาวน์โหลดจริงผ่านลิงก์ HuggingFace CDN ของ Qwen 2.5 1.5B Instruct GGUF
    const qwenUrl = 'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf';
    await _downloadModelFromUrl(qwenFile, qwenUrl);
    return qwenFile.path;
  }

  // ดาวน์โหลดไฟล์จากอินเทอร์เน็ตพร้อมเช็คสถานะ Progress
  Future<void> _downloadModelFromUrl(File targetFile, String urlString) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadProgressText = AppTranslations.translate('model_connecting', _displayLanguage);
    });
    
    final client = http.Client();
    try {
      final request = http.Request(
        'GET',
        Uri.parse(urlString),
      );
      final response = await client.send(request);
      
      if (response.statusCode != 200) {
        throw Exception('ไม่สามารถดาวน์โหลดไฟล์ได้จากเซิร์ฟเวอร์ (รหัสข้อผิดพลาด HTTP ${response.statusCode})');
      }
      
      // ขนาดไฟล์โดยประมาณของ Qwen 2.5 1.5B Instruct Q4_K_M (1.04 GiB)
      final totalBytes = response.contentLength ?? 1116914944;
      int downloadedBytes = 0;
      final sink = targetFile.openWrite();
      
      await for (var chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        setState(() {
          _downloadProgress = downloadedBytes / totalBytes;
          final prefix = AppTranslations.translate('model_downloading_progress', _displayLanguage);
          _downloadProgressText = '$prefix ${(_downloadProgress * 100).toStringAsFixed(1)}% (${(downloadedBytes / (1024 * 1024)).toStringAsFixed(0)} / ${(totalBytes / (1024 * 1024)).toStringAsFixed(0)} MB)';
        });
      }
      await sink.close();
    } catch (e) {
      if (targetFile.existsSync()) {
        targetFile.deleteSync();
      }
      rethrow;
    } finally {
      client.close();
      setState(() {
        _isDownloading = false;
      });
    }
  }

  Future<void> _showWindow() async {
    if (Platform.isMacOS) {
      try {
        await _platform.invokeMethod('showDockIcon');
      } catch (e) {
        AppLogger.log("Failed to show Dock icon: $e");
      }
    }
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _hideWindow() async {
    await windowManager.hide();
    if (Platform.isMacOS) {
      try {
        await _platform.invokeMethod('hideDockIcon');
      } catch (e) {
        AppLogger.log("Failed to hide Dock icon: $e");
      }
    }
  }

  // จัดการเมื่อกดปุ่มปิดหน้าต่าง (ให้ซ่อนลง System Tray แทน)
  @override
  void onWindowClose() async {
    await _hideWindow();
  }

  // ตั้งค่า System Tray
  Future<void> _initSystemTray() async {
    try {
      await _systemTray.initSystemTray(
        title: "",
        iconPath: 'assets/tray_iconTemplate.png',
      );

      await _updateSystemTrayMenu();

      _systemTray.registerSystemTrayEventHandler((eventName) {
        if (eventName == kSystemTrayEventClick) {
          Platform.isMacOS ? _systemTray.popUpContextMenu() : _showWindow();
        } else if (eventName == kSystemTrayEventRightClick) {
          _systemTray.popUpContextMenu();
        }
      });
    } catch (e) {
      AppLogger.log("System Tray Initialization Error: $e");
    }
  }

  Future<void> _updateSystemTrayMenu() async {
    try {
      // อัปเดต ToolTip
      await _systemTray.setToolTip(
        _isEnabled 
            ? "TinyMind: ${AppTranslations.translate('active', _displayLanguage)}"
            : "TinyMind: ${AppTranslations.translate('paused', _displayLanguage)}"
      );

      final Menu newMenu = Menu();
      // สร้าง Menu ใหม่ตามภาษาที่เลือก
      await newMenu.buildFrom([
        MenuItemLabel(
          label: AppTranslations.translate('tray_open', _displayLanguage),
          onClicked: (menuItem) => _showWindow(),
        ),
        MenuItemLabel(
          label: _isEnabled 
              ? AppTranslations.translate('tray_pause', _displayLanguage)
              : AppTranslations.translate('tray_resume', _displayLanguage),
          onClicked: (menuItem) {
            setState(() {
              _isEnabled = !_isEnabled;
              _saveSetting('isEnabled', _isEnabled);
            });
            _updateSystemTrayMenu(); // เรียกอัปเดตเมนูอีกครั้ง
          },
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: AppTranslations.translate('tray_quit', _displayLanguage),
          onClicked: (menuItem) => exit(0),
        ),
      ]);
      
      await _systemTray.setContextMenu(newMenu);
    } catch (e) {
      AppLogger.log("Error updating System Tray Menu: $e");
    }
  }

  // --- Logic หลักการดักปุ่มพิมพ์ ---

  void _handleKeyPress(String char, {String layout = 'en'}) {
    AppLogger.log("Dart: _handleKeyPress received: '$char' (Layout: $layout)");
    ComparisonLogger.recordRawKey(char);
    ComparisonLogger.recordOutputNormal(char);

    // หากยอมรับคำแนะนำสะกดคือก่อนหน้านี้ (ไม่ได้กดสลับกลับ) ให้เอาคำนั้นใส่ Dictionary อัตโนมัติ
    if (_canUndo && _lastReplacement != null) {
      final corrected = _lastReplacement!['corrected']!;
      final trimmed = corrected.trim();
      final pureWord = trimmed.replaceAll(RegExp(r'[.,!?;:\-_()\[\]{}]+$'), '');
      _addWordToIgnoreList(pureWord);
    }

    _canUndo = false; // Invalidate undo on keypress

    // Sync to _slashBuffer
    if (_slashBuffer.isNotEmpty) {
      _slashBuffer += char;
    } else if (char == '/' || char == 'ฝ') {
      _slashBuffer = char;
    }

    // 1. ถ้าพิมพ์ space, enter หรือ tab ถือว่าจบบทคำปัจจุบัน
    if (char == ' ' || char == '\n' || char == '\r' || char == '\t') {
      if (char == '\n' || char == '\r' || char == '\t') {
        // หากกด Enter/Return หรือ Tab ให้เคลียร์บัฟเฟอร์ทันทีและไม่ทำการแก้ไข เพื่อป้องกันปัญหา Autocomplete ใน Terminal/Editor
        _clearBuffers();
        return;
      }
      if (_currentBuffer.isNotEmpty && 
          !_isLayoutDecidedForCurrentWord && 
          !RegExp(r'\s$').hasMatch(_currentBuffer)) {
        if (!_isSlashTriggerOrPrefix(_currentBuffer)) {
          _processWordCorrection(_currentBuffer, char);
        }
      }
      
      // ชะลอการล้างสะสมตัวเคาะวรรค/จบประโยคลงในบัฟเฟอร์ เพื่อให้ปุ่ม Hotkey ทำงานได้ย้อนหลัง 1 คำ
      _currentBuffer += char;
      for (int c = 0; c < char.length; c++) {
        _bufferLayouts.add(layout);
      }
      _syncBufferStatus(); // Sync หลังจากต่อ space
      
      _mirrorCharToSandbox(char);
    } else {
      // For printable characters, mirror FIRST so that the sandbox text is updated before continuous autocorrect check is called
      _mirrorCharToSandbox(char);

      // 2. ถ้าเริ่มพิมพ์ตัวอักษรถัดไป ให้ล้างประวัติคำก่อนหน้าที่เคาะวรรคไปแล้ว
      if (_currentBuffer.isNotEmpty) {
        final lastChar = _currentBuffer.substring(_currentBuffer.length - 1);
        if (lastChar == ' ' || lastChar == '\n' || lastChar == '\r' || lastChar == '\t') {
          _currentBuffer = '';
          _bufferLayouts.clear();
          _isLayoutDecidedForCurrentWord = false;
          _continuousSwitchStopped = false;
          _lastCheckedLen = 0;
        }
      }

      // ตัวอักษรปกติ -> เพิ่มเข้าบัฟเฟอร์
      _currentBuffer += char;
      for (int c = 0; c < char.length; c++) {
        _bufferLayouts.add(layout);
      }
      if (!_isLayoutDecidedForCurrentWord && !_continuousSwitchStopped) {
        if (!_isSlashTriggerOrPrefix(_currentBuffer)) {
          _checkContinuousBufferCorrection();
        }
      }
      _syncBufferStatus(); // Sync
    }
    AppLogger.log("Dart: Buffer state after _handleKeyPress: '$_currentBuffer'");
  }

  void _mirrorCharToSandbox(String char) {
    final String currentText = _sandboxController.text;
    final int selOffset = _sandboxController.selection.baseOffset >= 0 
        ? _sandboxController.selection.baseOffset 
        : currentText.length;
    final String newPrefix = currentText.substring(0, selOffset);
    final String newSuffix = currentText.substring(selOffset);
    setState(() {
      _sandboxController.text = newPrefix + char + newSuffix;
      _sandboxController.selection = TextSelection.fromPosition(
        TextPosition(offset: newPrefix.length + char.length),
      );
    });
  }

  // สลับภาษาอัตโนมัติเมื่อความยาวตัวอักษรถึงเกณฑ์ขั้นต่ำ (ตรวจจับ 3 รอบ และส่งเสียง Beep หากตัดสินไม่ได้)
  void _checkContinuousBufferCorrection() async {
    if (!_isLocalCorrection || !_isAutoSwitchOnLength) return;

    final int len = _currentBuffer.length;
    final int startLen = _autoSwitchLength;

    // หากตัดสินไม่ได้และยาวถึงรอบสุดท้าย + 2 (เช่น >= startLen + 6) ให้ Beep 1 ครั้งและหยุดการตรวจ
    if (len >= startLen + 6 && !_continuousSwitchStopped) {
      _continuousSwitchStopped = true;
      _syncBufferStatus();
      
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (e) {
        // ignore
      }
      
      AppLogger.log("Dart: _checkContinuousBufferCorrection: reached final checkpoint (${startLen + 6}) without layout decision. Beeped and stopped continuous checks.");
      return;
    }

    // ตรวจสอบว่าความยาวเข้าเกณฑ์รอบใดรอบหนึ่ง และรอบนั้นยังไม่เคยถูกตรวจ
    bool shouldCheck = false;
    if (len == startLen && _lastCheckedLen < startLen) {
      shouldCheck = true;
    } else if (len == startLen + 2 && _lastCheckedLen < startLen + 2) {
      shouldCheck = true;
    } else if (len == startLen + 4 && _lastCheckedLen < startLen + 4) {
      shouldCheck = true;
    }

    if (!shouldCheck) return;

    // อัปเดตความยาวที่ทำการตรวจสอบล่าสุดเพื่อไม่ให้เรียกซ้ำ
    _lastCheckedLen = len;

    // แยกเครื่องหมายวรรคตอนท้ายคำออกก่อนประมวลผล (หากมี)
    String trimmedWord = _currentBuffer;
    String trailingPunctuation = '';
    
    final trailingRegExp = RegExp(r'([.,!?;:\-_()\[\]{}]+)$');
    final match = trailingRegExp.firstMatch(_currentBuffer);
    if (match != null) {
      trailingPunctuation = match.group(1)!;
      trimmedWord = _currentBuffer.substring(0, _currentBuffer.length - trailingPunctuation.length);
    }

    if (trimmedWord.isEmpty) return;

    // ข้ามหากคำนั้นพิมพ์ถูกต้องตามผังคีย์บอร์ดปัจจุบันอยู่แล้ว (ป้องกันการสลับกลับเป็นอังกฤษขยะ)
    if (AutocorrectEngine.isLikelyCorrectInCurrentLayout(trimmedWord)) {
      return;
    }

    // ตรวจสอบรายการละเว้น
    if (_ignoredWords.contains(trimmedWord.toLowerCase())) {
      _isLayoutDecidedForCurrentWord = true; 
      _continuousSwitchStopped = true;
      return;
    }

    // 1. ตรวจสอบพจนานุกรม Dict ก่อน (หลักการข้อ 2: หากสลับแล้วตรงกับคำใน Dict ถือว่าสิ้นสุด)
    final CorrectionResult? dictResult = AutocorrectEngine.checkAndCorrectLocalStrict(trimmedWord);
    if (dictResult != null && dictResult.correctedWord != trimmedWord) {
      _applyDictCorrection(trimmedWord, dictResult, trailingPunctuation, 'regex');
      return;
    }

    // 2. ถ้าใน Dict ยังหาไม่พบ ให้ใช้โค้ดแปลงผังแป้นคีย์บอร์ด 2 ภาษาและส่งให้ AI ตัดสินใจ (หลักการข้อ 3)
    if (AutocorrectEngine.isModelLoaded) {
      final String expectedBuffer = _currentBuffer;
      
      final String wordEn = AutocorrectEngine.convertLayout(trimmedWord, languageCode: 'th', toTarget: false);
      final String wordTh = AutocorrectEngine.convertLayout(trimmedWord, languageCode: 'th', toTarget: true);

      AppLogger.log("Dart: AI checking bilingual correct layout: English='$wordEn', Thai='$wordTh'");
      final String? decidedWord = await AutocorrectEngine.identifyCorrectWordAI(wordEn, wordTh);
      final String source = AutocorrectEngine.lastDecisionSource;
      AppLogger.log("Dart: AI decided layout word: '$decidedWord' (Source: $source)");

      // Race Condition Guard & Smart Merge: ตรวจว่าผู้ใช้พิมพ์ตัวอื่นเพิ่มไประหว่างรอ AI หรือไม่
      if (_currentBuffer != expectedBuffer) {
        if (decidedWord != null && decidedWord != trimmedWord && _currentBuffer.startsWith(expectedBuffer)) {
          final String suffix = _currentBuffer.substring(expectedBuffer.length);
          final bool isTh = decidedWord == wordTh;
          final String convertedSuffix = AutocorrectEngine.convertLayout(
            suffix,
            languageCode: isTh ? 'th' : 'en',
            toTarget: isTh,
            context: expectedBuffer,
          );
          
          final String originalWord = expectedBuffer;
          final String replacement = decidedWord + convertedSuffix;
          final int backspaces = _calculateBackspaces(originalWord + suffix, replacement);
          
          AppLogger.log("Dart: AI decided layout word merged with suffix: '$replacement' (Original buffer: '$_currentBuffer', expected: '$expectedBuffer')");
          _replaceText(backspaces, replacement);
          _currentBuffer = replacement;
          _isLayoutDecidedForCurrentWord = true;
          _continuousSwitchStopped = true;
          _syncBufferStatus();
          return;
        }
        AppLogger.log("Dart: AI decided layout word discarded because buffer changed ('$_currentBuffer' != '$expectedBuffer')");
        return;
      }

      if (decidedWord != null) {
        if (decidedWord != trimmedWord) {
          final bool isTh = decidedWord == wordTh;
          final String languageCode = isTh ? 'th' : 'en';
          
          final dummyResult = CorrectionResult(
            correctedWord: decidedWord,
            languageCode: languageCode,
            isToTargetLanguage: isTh,
          );

          _applyDictCorrection(trimmedWord, dummyResult, trailingPunctuation, source);
        } else {
          AppLogger.log("Dart: AI/Heuristics decided layout matches current buffer ('$decidedWord'). Allowing future checkpoints to check again.");
          _syncBufferStatus();
        }
      }
    }
  }

  // ฟังก์ชันแยกสำหรับสลับภาษาระดับคำ (Dict/AI) และล็อกสถานะการตรวจสอบให้จบโดยสมบูรณ์
  void _applyDictCorrection(String trimmedWord, CorrectionResult result, String trailingPunctuation, String source) {
    final String translatedTrailing = AutocorrectEngine.convertLayout(
      trailingPunctuation,
      languageCode: result.languageCode,
      toTarget: result.isToTargetLanguage,
      context: trimmedWord, // Pass the trimmed word as context for trailing punctuation (e.g. '.' -> 'ใ')
    );
    final String replacement = result.correctedWord + translatedTrailing;
    final int backspaces = _calculateBackspaces(_currentBuffer, replacement);

    _replaceText(backspaces, replacement);

    _syncSlashBufferOnReplacement(_currentBuffer, replacement);

    _lastReplacement = {
      'original': _currentBuffer,
      'corrected': replacement,
    };
    _lastReplacementEndingChar = '';
    _canUndo = true;

    final int savedCharsDiff = (result.correctedWord.length - trimmedWord.length).abs();
    _incrementStat('wordsCorrected');
    _incrementStat('layoutFixed');
    if (savedCharsDiff > 0) {
      _incrementStat('savedChars', value: savedCharsDiff);
    }

    AppLogger.log("Dart: [Word Swapped] '$trimmedWord' -> '${result.correctedWord}' (Swapped by ${source.toUpperCase()})");

    final bool alreadyLoggedByAi = _recentCorrections.any((item) => 
      item['original'] == trimmedWord && 
      (item['corrected']!.startsWith('THA') || 
       item['corrected']!.startsWith('ENG') || 
       item['corrected']!.startsWith('NONE'))
    );
    if (!alreadyLoggedByAi) {
      setState(() {
        _recentCorrections.insert(0, {
          'original': trimmedWord,
          'corrected': result.correctedWord,
          'timestamp': DateTime.now().toString().substring(11, 19),
          'type': source == 'ai' ? 'Local AI' : 'Layout (Auto)'
        });
        if (_recentCorrections.length > 5) {
          _recentCorrections.removeLast();
        }
      });
    }

    _currentBuffer = replacement;
    _isLayoutDecidedForCurrentWord = true; 
    _continuousSwitchStopped = true; // สิ้นสุดการตรวจต่อเนื่องคำนี้ทันที
    _syncBufferStatus();

    _saveHistory();
    _addWordToIgnoreList(result.correctedWord);
  }

  int _calculateBackspaces(String textToDelete, String replacementText) {
    // We compute the standard grapheme clusters length as required by workspace rules
    final int baseClusters = textToDelete.characters.length;
    
    // However, if the text contains invalid stacked Thai characters (which occurs during layout typos),
    // macOS/Chromium do not group these invalid parts into grapheme clusters and delete them code point by code point.
    // Thus we compute the precise backspace count to prevent under-deletion.
    final int backspaces = _countPhysicalThaiBackspaces(textToDelete, appMode: _activeAppMode);
    
    AppLogger.log("Dart: [Backspace Breakdown] \"$textToDelete\" = $backspaces Backspaces (base: $baseClusters, appMode: $_activeAppMode)");
    return backspaces;
  }

  int _countPhysicalThaiBackspaces(String text, {String appMode = 'native'}) {
    if (text.isEmpty) return 0;
    
    // สำหรับ Terminal (Zsh/Bash) จะลบอักขระทีละ 1 Code Point เสมอ
    if (appMode == 'terminal') {
      return text.length; 
    }
    
    int backspaces = 0;
    final consonantReg = RegExp(r'[ก-ฮ]');
    final combiningReg = RegExp(r'[ิีึืุูั็่้๊๋์ํฺำ]');
    
    int i = 0;
    while (i < text.length) {
      final char = text[i];
      
      if (consonantReg.hasMatch(char)) {
        int j = i + 1;
        List<String> marks = [];
        while (j < text.length && combiningReg.hasMatch(text[j])) {
          marks.add(text[j]);
          j++;
        }
        
        if (marks.isEmpty) {
          backspaces += 1;
        } else {
          bool isValid = true;
          // Rule 1: No duplicate vowels
          final vowels = marks.where((m) => RegExp(r'[ิีึืุูั็ํำ]').hasMatch(m)).toList();
          if (vowels.length > 1) isValid = false;
          
          // Rule 2: No duplicate tone marks
          final tones = marks.where((m) => RegExp(r'[่้๊๋์]').hasMatch(m)).toList();
          if (tones.length > 1) isValid = false;
          
          // Rule 3: Tone mark must not precede vowel
          if (marks.length >= 2) {
            final firstIsTone = RegExp(r'[่้๊๋์]').hasMatch(marks[0]);
            final secondIsVowel = RegExp(r'[ิีึืุูั็ํำ]').hasMatch(marks[1]);
            if (firstIsTone && secondIsVowel) isValid = false;
          }
          
          if (isValid) {
            backspaces += 1;
            if (appMode == 'flutter' || appMode == 'chromium') {
              // Flutter and Chromium delete character by character, so each mark requires 1 backspace
              backspaces += marks.length;
            } else if (appMode == 'native') {
              // Native deletes the entire valid cluster with 1 backspace (which is the base we already added)
              // SARA AM ('ำ') requires 3 backspaces total in Native (adds 2)
              if (marks.contains('ำ')) {
                backspaces += 2;
              }
            }
          } else {
            backspaces += 1 + marks.length;
            // In an invalid stack, we count character by character.
            // SARA AM ('ำ') occupies 1 char in marks but needs 2 deletes on macOS Native,
            // so we add 1 extra backspace for each SARA AM in marks if running in Native.
            if (appMode == 'native') {
              final saraAmCount = marks.where((m) => m == 'ำ').length;
              backspaces += saraAmCount;
            }
          }
        }
        i = j;
      } else if (combiningReg.hasMatch(char)) {
        backspaces += 1;
        if (char == 'ำ' && appMode == 'native') {
          backspaces += 1; // Isolated SARA AM requires 2 backspaces in Native
        }
        i++;
      } else {
        backspaces += 1;
        i++;
      }
    }
    
    return backspaces;
  }

  void _resetSandbox() {
    setState(() {
      _sandboxController.text = ' ' * 15;
      _sandboxController.selection = TextSelection.fromPosition(
        TextPosition(offset: _sandboxController.text.length),
      );
    });
    _sandboxFocusNode.requestFocus();
  }

  int _countLeadingSpaces(String text) {
    int count = 0;
    for (int i = 0; i < text.length; i++) {
      if (text[i] == ' ') {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  Future<void> _replaceText(int backspaces, String replacement, {int? processedKeystrokes}) async {
    ComparisonLogger.recordOutputAutocorrect(backspaces, replacement);
    _lastSwapTime = DateTime.now();
    _lastSwappedWord = replacement;
    final sandboxBefore = _sandboxController.text;
    AppLogger.log("--- ReplaceText Command Invoked ---");
    AppLogger.log("Dart: Replacing text with backspaces: $backspaces, replacement: '$replacement'");
    AppLogger.log("Dart: Current Buffer before replacement: '$_currentBuffer'");
    AppLogger.log("Dart: Sandbox before replacement: '$sandboxBefore'");

    // Always update the sandbox text field (Global Mirroring Simulation)
    final text = _sandboxController.text;
    final selection = _sandboxController.selection;
    int baseOffset = selection.baseOffset;
    if (baseOffset < 0) baseOffset = text.length;
    
    final String prefix = text.substring(0, baseOffset);
    final String suffix = text.substring(baseOffset);
    
    final String newPrefix = prefix.characters.skipLast(backspaces).toString();
    final String newText = newPrefix + replacement + suffix;
    
    setState(() {
      _sandboxController.text = newText;
      _sandboxController.selection = TextSelection.fromPosition(
        TextPosition(offset: newPrefix.length + replacement.length),
      );
    });
    
    final spacesBefore = _countLeadingSpaces(sandboxBefore);
    final spacesAfter = _countLeadingSpaces(newText);
    AppLogger.log("Dart: Sandbox simulated replacement.");
    AppLogger.log("Dart: Sandbox after replacement: '${_sandboxController.text}'");
    
    if (spacesAfter < spacesBefore) {
      AppLogger.log("Dart: WARNING: Over-deletion detected in sandbox! Spaces reduced from $spacesBefore to $spacesAfter (lost ${spacesBefore - spacesAfter} spaces)");
    } else if (spacesAfter > spacesBefore) {
      AppLogger.log("Dart: WARNING: Sandbox spaces increased from $spacesBefore to $spacesAfter");
    } else {
      AppLogger.log("Dart: Sandbox spacing intact (exactly $spacesBefore spaces). No over-deletion detected.");
    }

    try {
      await _platform.invokeMethod('replaceText', {
        'backspaces': backspaces,
        'text': replacement,
        'processedKeystrokes': processedKeystrokes ?? _lastOsKeystrokeCount,
      });
    } catch (e) {
      AppLogger.log("Dart: Error calling native replaceText: $e");
    }
  }

  SlashCommand? _getSlashCommand(String buffer) {
    if (!_useSlashCommands) return null;
    final trimmed = buffer.trim();
    final sortedCmds = List<SlashCommand>.from(_slashCommands)
      ..sort((a, b) => b.trigger.length.compareTo(a.trigger.length));
    for (final cmd in sortedCmds) {
      if (trimmed == cmd.trigger || trimmed.startsWith(cmd.trigger + ' ')) {
        return cmd;
      }
    }
    return null;
  }

  String _getSlashArgument(String buffer, SlashCommand cmd) {
    final trimmed = buffer.trim();
    String triggerUsed = '';
    if (trimmed == cmd.trigger) {
      triggerUsed = cmd.trigger;
    } else if (trimmed.startsWith(cmd.trigger + ' ')) {
      triggerUsed = cmd.trigger;
    }
    if (triggerUsed.isEmpty) return '';
    var arg = trimmed.substring(triggerUsed.length);
    if (arg.startsWith(' ')) {
      arg = arg.substring(1);
    }
    return arg;
  }

  bool _isSlashTriggerOrPrefix(String text) {
    if (!_useSlashCommands) return false;
    final trimmed = text.trim();
    return trimmed == '/' ||
           trimmed == '/t' ||
           trimmed == '/translate';
  }

  void _syncSlashBufferOnReplacement(String original, String replacement) {
    if (_slashBuffer.isNotEmpty && _slashBuffer.endsWith(original)) {
      _slashBuffer = _slashBuffer.substring(0, _slashBuffer.length - original.length) + replacement;
    }
  }

  bool _isPunctuation(String char) {
    const punctuation = [',', '.', '!', '?', ';', ':', '-', '_', '(', ')'];
    return punctuation.contains(char);
  }

  Future<void> _syncBufferStatus() async {
    if (!_isLocalCorrection) return;
    final bool hasSlash = _getSlashCommand(_slashBuffer) != null;
    final bool needsAutocorrect = (_currentBuffer.isNotEmpty && !_isLayoutDecidedForCurrentWord) || hasSlash;
    AppLogger.log("Dart: _syncBufferStatus: slashBuffer='$_slashBuffer', currentBuffer='$_currentBuffer', hasSlash=$hasSlash, needsAutocorrect=$needsAutocorrect");
    try {
      await _platform.invokeMethod('updateBufferStatus', {'needsAutocorrect': needsAutocorrect});
    } catch (e) {
      // ignore
    }
  }

  Future<void> _handleEnterTriggered() async {
    AppLogger.log("Dart: _handleEnterTriggered called. _slashBuffer='$_slashBuffer', _currentBuffer='$_currentBuffer'");
    
    final cmd = _getSlashCommand(_slashBuffer);
    if (cmd != null) {
      final argument = _getSlashArgument(_slashBuffer, cmd);
      AppLogger.log("Dart: executing slash command ${cmd.trigger} with argument '$argument'");
      
      final result = await cmd.execute(argument);
      AppLogger.log("Dart: slash command result: '$result'");
      
      final int backspaces = _slashBuffer.length;
      
      _replaceText(backspaces, result ?? '');
      
      _clearBuffers();
      await _syncBufferStatus();
      return;
    }

    if (_currentBuffer.isNotEmpty && !_isLayoutDecidedForCurrentWord) {
      // เรียกใช้ autocorrection ด่วนสำหรับคำสุดท้าย (โดยไม่มีตัวอักษรลงท้าย endingChar = '')
      await _processWordCorrection(_currentBuffer, '');
    }
    _clearBuffers();
    
    // อัปเดตสถานะกลับไปเป็น false ทันที
    await _syncBufferStatus();
    
    // ปลดล็อกปุ่ม Enter ฝั่ง Swift
    try {
      await _platform.invokeMethod('releaseEnter');
    } catch (e) {
      AppLogger.log("Failed to release Enter in Swift: $e");
    }
  }

  void _handleBackspace() {
    AppLogger.log("Dart: _handleBackspace received. Buffer before: '$_currentBuffer'");
    ComparisonLogger.recordRawBackspace();
    ComparisonLogger.recordOutputBackspace();
    if (_lastSwapTime != null && _lastSwappedWord != null) {
      final diff = DateTime.now().difference(_lastSwapTime!).inMilliseconds;
      if (diff < 2000) {
        AppLogger.log("⚠️ [WARN: User pressed Backspace immediately after Swap!] Last swap word: '$_lastSwappedWord' was replaced ${diff}ms ago. This might indicate over-deletion, under-deletion, or layout conversion failure.");
      }
    }
    _canUndo = false; // Invalidate undo on backspace
    _isLayoutDecidedForCurrentWord = false; // ปลดล็อกการตรวจภาษาเมื่อกดย้อนกลับ
    _continuousSwitchStopped = false; // ปลดล็อกการหยุดเช็คต่อเนื่อง
    _lastCheckedLen = 0;
    if (_currentBuffer.isNotEmpty) {
      final int lenBefore = _currentBuffer.length;
      _currentBuffer = _currentBuffer.characters.skipLast(1).toString();
      final int lenAfter = _currentBuffer.length;
      final int removedLen = lenBefore - lenAfter;
      if (removedLen > 0 && _bufferLayouts.length >= removedLen) {
        _bufferLayouts.removeRange(_bufferLayouts.length - removedLen, _bufferLayouts.length);
      }
    } else if (_fullSentenceBuffer.isNotEmpty) {
      _fullSentenceBuffer = _fullSentenceBuffer.characters.skipLast(1).toString();
    }
    if (_slashBuffer.isNotEmpty) {
      _slashBuffer = _slashBuffer.characters.skipLast(1).toString();
    }
    _syncBufferStatus(); // Sync
    
    // Global Mirroring for Keyboard Sandbox (Backspace)
    final String currentText = _sandboxController.text;
    final int selOffset = _sandboxController.selection.baseOffset >= 0 
        ? _sandboxController.selection.baseOffset 
        : currentText.length;
    if (selOffset > 0) {
      final String prefix = currentText.substring(0, selOffset);
      final String suffix = currentText.substring(selOffset);
      final String newPrefix = prefix.characters.skipLast(1).toString();
      setState(() {
        _sandboxController.text = newPrefix + suffix;
        _sandboxController.selection = TextSelection.fromPosition(
          TextPosition(offset: newPrefix.length),
        );
      });
    }
    
    AppLogger.log("Dart: Buffer after backspace: '$_currentBuffer'");
  }

  void _clearBuffers() {
    _currentBuffer = '';
    _bufferLayouts.clear();
    _slashBuffer = '';
    _fullSentenceBuffer = '';
    _canUndo = false;
    _isLayoutDecidedForCurrentWord = false;
    _continuousSwitchStopped = false;
    _lastCheckedLen = 0;
    _syncBufferStatus(); // Sync
    ComparisonLogger.flush();
    
    // Reset Sandbox on buffer clear (Global Mirroring)
    setState(() {
      _sandboxController.text = ' ' * 15;
      _sandboxController.selection = TextSelection.fromPosition(
        TextPosition(offset: _sandboxController.text.length),
      );
    });
    
    AppLogger.log("Dart: _clearBuffers invoked. Buffers cleared and Sandbox reset.");
  }
  // ประมวลผลแก้ระดับคำ (Local - Zero Latency)
  void _applyWordCorrection(String originalWord, String endingChar, String corrected, CorrectionResult result, String source, [int? processedKeystrokes]) {
    // แยกเครื่องหมายวรรคตอนท้ายคำออกก่อนประมวลผล (หากมี)
    String trimmedWord = originalWord;
    String trailingPunctuation = '';
    
    final trailingRegExp = RegExp(r'([.,!?;:\-_()\[\]{}]+)$');
    final match = trailingRegExp.firstMatch(originalWord);
    if (match != null) {
      trailingPunctuation = match.group(1)!;
      trimmedWord = originalWord.substring(0, originalWord.length - trailingPunctuation.length);
    }

    // แปลงแป้นพิมพ์ของตัวอักษรจบคำให้สอดคล้องกับภาษาที่ได้รับการตรวจแก้ด้วย
    final String translatedTrailing = AutocorrectEngine.convertLayout(
      trailingPunctuation,
      languageCode: result.languageCode,
      toTarget: result.isToTargetLanguage,
    );
    final String translatedEndingChar = AutocorrectEngine.convertLayout(
      endingChar,
      languageCode: result.languageCode,
      toTarget: result.isToTargetLanguage,
    );
    final String replacement = corrected + translatedTrailing + translatedEndingChar;
    final int backspaces = _calculateBackspaces(originalWord + endingChar, replacement);

    _replaceText(backspaces, replacement, processedKeystrokes: processedKeystrokes);

    _syncSlashBufferOnReplacement(originalWord + endingChar, replacement);

    // เซฟข้อมูลสำหรับการ Undo
    _lastReplacement = {
      'original': originalWord,
      'corrected': corrected + translatedTrailing,
    };
    _lastReplacementEndingChar = endingChar;
    _canUndo = true;

    // แทนที่จะล้างบัฟเฟอร์ ให้เก็บคำที่ได้รับการแทนที่ล่าสุดไว้ เพื่อรองรับการพิมพ์ต่อหรือกด Hotkey แปลงกลับทั้งคำ
    _currentBuffer = replacement;
    _isLayoutDecidedForCurrentWord = true; // ล็อกเพื่อไม่เช็คซ้ำจนกว่าจะเว้นวรรก

    // อัปเดตสถิติ
    final int savedCharsDiff = (corrected.length - trimmedWord.length).abs();
    _incrementStat('wordsCorrected');
    _incrementStat('layoutFixed');
    if (savedCharsDiff > 0) {
      _incrementStat('savedChars', value: savedCharsDiff);
    }

    AppLogger.log("Dart: [Word Swapped] '$trimmedWord' -> '$corrected' (Swapped by ${source.toUpperCase()})");

    final bool alreadyLoggedByAi = _recentCorrections.any((item) => 
      item['original'] == trimmedWord && 
      (item['corrected']!.startsWith('THA') || 
       item['corrected']!.startsWith('ENG') || 
       item['corrected']!.startsWith('NONE'))
    );
    if (!alreadyLoggedByAi) {
      setState(() {
        _recentCorrections.insert(0, {
          'original': trimmedWord,
          'corrected': corrected,
          'timestamp': DateTime.now().toString().substring(11, 19),
          'type': source == 'ai' ? 'Local AI' : (result.isToTargetLanguage ? 'Th Layout' : 'En Layout')
        });
        if (_recentCorrections.length > 5) {
          _recentCorrections.removeLast();
        }
      });
    }

    _saveHistory();
  }

  // ประมวลผลแก้ระดับคำ (Local - Zero Latency + AI Fallback)
  Future<void> _processWordCorrection(String word, String endingChar) async {
    final int capturedKeystrokes = _lastOsKeystrokeCount; // Capture keystrokes AT THIS MOMENT
    
    // 0. ตรวจสอบคีย์ลัดคำย่อ (Text Shortcuts Expansion) ก่อนการแปลงภาษาอื่นๆ
    final shortcutKey = word.trim();
    if (_textShortcuts.containsKey(shortcutKey)) {
      final replacement = _textShortcuts[shortcutKey]! + endingChar;
      final int backspaces = _calculateBackspaces(word + endingChar, replacement);

      _replaceText(backspaces, replacement);

      _syncSlashBufferOnReplacement(word + endingChar, replacement);

      final int savedCharsDiff = (replacement.characters.length - (word + endingChar).characters.length).abs();
      _incrementStat('wordsCorrected');
      if (savedCharsDiff > 0) {
        _incrementStat('savedChars', value: savedCharsDiff);
      }

      setState(() {
        _recentCorrections.insert(0, {
          'original': word,
          'corrected': _textShortcuts[shortcutKey]!,
          'timestamp': DateTime.now().toString().substring(11, 19),
          'type': 'Shortcut'
        });
        if (_recentCorrections.length > 5) {
          _recentCorrections.removeLast();
        }
      });

      // เซฟข้อมูลสำหรับการ Undo
      _lastReplacement = {
        'original': word,
        'corrected': _textShortcuts[shortcutKey]!,
      };
      _lastReplacementEndingChar = endingChar;
      _canUndo = true;

      _currentBuffer = replacement;
      _isLayoutDecidedForCurrentWord = true;
      _saveHistory();
      return;
    }

    if (!_isLocalCorrection) return;

    // แยกเครื่องหมายวรรคตอนท้ายคำออกก่อนประมวลผลแก้คำผิด
    String trimmedWord = word;
    String trailingPunctuation = '';
    
    final trailingRegExp = RegExp(r'([.,!?;:\-_()\[\]{}]+)$');
    final match = trailingRegExp.firstMatch(word);
    if (match != null) {
      trailingPunctuation = match.group(1)!;
      trimmedWord = word.substring(0, word.length - trailingPunctuation.length);
    }

    if (trimmedWord.isEmpty) return;

    // ตรวจสอบว่าคำนี้อยู่ในรายการละเว้นหรือไม่
    if (_ignoredWords.contains(trimmedWord.toLowerCase())) return;

    final CorrectionResult? result = AutocorrectEngine.checkAndCorrectLocal(trimmedWord);
    final String? corrected = result?.correctedWord;
    AppLogger.log("Dart: _processWordCorrection: word='$word', trimmed='$trimmedWord', corrected='$corrected'");
    
    if (corrected != null && corrected != trimmedWord && result != null) {
      // 1. ส่งคำสั่งแก้ไขผ่าน Local Rules (0ms)
      _applyWordCorrection(word, endingChar, corrected, result, 'regex', capturedKeystrokes);
    } else {
      // 2. ถ้า Local ไม่พบคำศัพท์ และเปิดสวิตช์ AI + โหลดโมเดลเสร็จแล้ว -> ส่งให้ AI ช่วยสแกน
      if (_isAiCorrection && AutocorrectEngine.isModelLoaded) {
        if (AutocorrectEngine.isCodeOrSymbol(trimmedWord)) {
          AppLogger.log("Dart: _processWordCorrection: word '$trimmedWord' is code/symbol. Skipping AI fallback.");
          return;
        }
        // กรองคำที่พิมพ์ถูกต้องตามเลย์เอาต์ปัจจุบันอยู่แล้ว เพื่อหลีกเลี่ยงการหน่วงเวลาเรียก AI
        // ในโหมด AI Only เราจะยอมให้ข้ามเฉพาะคำที่ถูกต้อง 100% ในพจนานุกรมหลักหรือ Ignore List เท่านั้น
        // แต่ในโหมดอื่นๆ (เช่น Hybrid) เราจะใช้ Heuristics แบบละเอียดของกฎคัดกรองตามปกติ
        bool shouldSkipAI = false;
        if (AutocorrectEngine.correctionMode == 'ai') {
          shouldSkipAI = AutocorrectEngine.isCommonWord(trimmedWord) || 
                         AutocorrectEngine.isCommonEnglishWord(trimmedWord) ||
                         _ignoredWords.contains(trimmedWord.toLowerCase());
        } else {
          shouldSkipAI = AutocorrectEngine.isLikelyCorrectInCurrentLayout(trimmedWord);
        }
        
        if (shouldSkipAI) {
          AppLogger.log("Dart: _processWordCorrection: word '$trimmedWord' is likely correct/common. Skipping AI fallback.");
          return;
        }

        final String expectedBuffer = _currentBuffer; // บันทึกสถานะบัฟเฟอร์ก่อนเรียก AI
        
        AppLogger.log("Dart: _processWordCorrection: calling AI fallback for word '$trimmedWord'");
        final String? aiCorrected = await AutocorrectEngine.checkAndCorrectAI(trimmedWord);
        AppLogger.log("Dart: _processWordCorrection: AI fallback result for word '$trimmedWord' is '$aiCorrected'");
        
        // Race Condition Guard & Smart Merge (Double Buffer Strategy)
        if (_currentBuffer != expectedBuffer && _currentBuffer != expectedBuffer + endingChar) {
          if (aiCorrected != null && aiCorrected != trimmedWord && _currentBuffer.startsWith(expectedBuffer)) {
            final String suffix = _currentBuffer.substring(expectedBuffer.length);
            final bool isThCorrected = RegExp(r'[ก-์]').hasMatch(aiCorrected);
            
            final String convertedSuffix = AutocorrectEngine.convertLayout(
              suffix,
              languageCode: isThCorrected ? 'th' : 'en',
              toTarget: isThCorrected,
              context: expectedBuffer,
            );
            
            final String originalWord = expectedBuffer;
            final String replacement = aiCorrected + convertedSuffix;
            final int backspaces = _calculateBackspaces(originalWord + suffix, replacement);
            
            AppLogger.log("Dart: AI fallback decided layout word merged with suffix: '$replacement' (Original buffer: '$_currentBuffer', expected: '$expectedBuffer')");
            _replaceText(backspaces, replacement, processedKeystrokes: capturedKeystrokes);
            
            // อัปเดตข้อมูลสำหรับการ Undo (เก็บข้อมูลดั้งเดิมของคำแรกรวมกับ suffix เป็นตัวจบคำ)
            _lastReplacement = {
              'original': trimmedWord,
              'corrected': aiCorrected,
            };
            _lastReplacementEndingChar = suffix;
            _canUndo = true;
            
            _currentBuffer = replacement;
            _isLayoutDecidedForCurrentWord = true;
            _continuousSwitchStopped = true;
            _syncBufferStatus();
            _incrementStat('aiRequests');
            return;
          }
          AppLogger.log("Dart: _processWordCorrection: AI result discarded because buffer changed ('$_currentBuffer' != '$expectedBuffer')");
          return;
        }
        
        if (aiCorrected != null && aiCorrected != trimmedWord) {
          // วิเคราะห์ทิศทางการสลับเลย์เอาต์ (ไทย -> อังกฤษ หรือ อังกฤษ -> ไทย)
          final bool isThCorrected = RegExp(r'[ก-์]').hasMatch(aiCorrected);
          final String languageCode = isThCorrected ? 'th' : 'en';
          
          final dummyResult = CorrectionResult(
            correctedWord: aiCorrected,
            languageCode: languageCode,
            isToTargetLanguage: isThCorrected,
          );
          final String source = AutocorrectEngine.lastDecisionSource;
          _applyWordCorrection(word, endingChar, aiCorrected, dummyResult, source, capturedKeystrokes);
          
          // อัปเดตสถิติจำนวน AI requests
          _incrementStat('aiRequests');
        }
      }
    }
  }

  // จัดการคีย์ลัดสำหรับแปลงภาษากลับ/สลับภาษาเอง (Hotkey Manual Fix & Undo)
  void _handleHotkey() {
    _incrementStat('hotkeyCount');
    AppLogger.log("Dart: _handleHotkey received. _canUndo=$_canUndo, _currentBuffer='$_currentBuffer'. Total hotkey triggers: $_hotkeyCount");
    if (_canUndo && _lastSwappedWord != null) {
      AppLogger.log("⚠️ [WARN: User triggered Hotkey to Undo Swap!] Reverting last swap word: '$_lastSwappedWord'. User might felt the correction was wrong or caused deletion issues.");
    }
    _isLayoutDecidedForCurrentWord = true; // ล็อกสถานะเพื่อประหยัด CPU และลดความขัดแย้ง
    _continuousSwitchStopped = true; // สิ้นสุดการตรวจต่อเนื่องคำนี้ทันที (หลักการข้อ 1)
    // 1. ลองดึงข้อมูลจากการแทนที่ล่าสุดเพื่อทำ Smart Undo (กู้คืนย้อนหลังทั้งคำ)
    // ถึงแม้จะพิมพ์ตัวอักษรเพิ่มไปแล้ว 1-2 ตัวหลังจากโดนแอปแก้ไข หากบัฟเฟอร์ยังขึ้นต้นด้วยคำที่แอปแก้
    // เราจะดึงคีย์ดั้งเดิมทั้งหมดพร้อมแปลงตัวต่อท้ายกลับคืนให้ทั้งยวง
    if (_lastReplacement != null) {
      final original = _lastReplacement!['original']!;
      final corrected = _lastReplacement!['corrected']!;
      
      // กรณีแรก: canUndo ยังเป็น true (กดสลับกลับทันทีที่โปรแกรมแทนที่เสร็จ)
      if (_canUndo && _currentBuffer == corrected) {
        final bool isThaiCorrection = RegExp(r'[ก-์]').hasMatch(original);
        final String originalEndingChar = AutocorrectEngine.convertLayout(
          _lastReplacementEndingChar,
          languageCode: 'th',
          toTarget: isThaiCorrection,
        );
        final String replacement = original + originalEndingChar;
        final int backspaces = _calculateBackspaces(corrected + _lastReplacementEndingChar, replacement);

        _replaceText(backspaces, replacement);

        _syncSlashBufferOnReplacement(corrected + _lastReplacementEndingChar, replacement);

        _currentBuffer = original;
        _canUndo = false;
        
        if (_fullSentenceBuffer.endsWith(corrected + _lastReplacementEndingChar)) {
          _fullSentenceBuffer = _fullSentenceBuffer.substring(0, _fullSentenceBuffer.length - (corrected.length + _lastReplacementEndingChar.length));
        }
        
        _removeWordFromIgnoreList(corrected);
        _addWordToIgnoreList(original);
        return;
      }
      
      // กรณีสอง: พิมพ์ต่อไปบ้างแล้ว แต่ยังไม่เว้นวรรค (บัฟเฟอร์ปัจจุบันขึ้นต้นด้วยคำที่แอปแก้)
      if (_currentBuffer.startsWith(corrected)) {
        final extra = _currentBuffer.substring(corrected.length);
        final bool isThaiCorrection = RegExp(r'[ก-์]').hasMatch(original);
        
        // แปลงส่วนต่อท้ายกลับไปตามภาษาเดิมของคำดั้งเดิม
        final String convertedExtra = AutocorrectEngine.convertLayout(
          extra,
          languageCode: 'th',
          toTarget: isThaiCorrection,
        );
        
        final String replacement = original + convertedExtra;
        final int backspaces = _calculateBackspaces(_currentBuffer, replacement);

        _replaceText(backspaces, replacement);

        _syncSlashBufferOnReplacement(_currentBuffer, replacement);

        _currentBuffer = replacement;
        _lastReplacement = null;
        _canUndo = false;
        
        // ลบคำที่สลับผิดออกจาก Ignore list และบันทึกคำที่ถูกต้องแทน
        _removeWordFromIgnoreList(corrected);
        _addWordToIgnoreList(original);
        _addWordToIgnoreList(replacement);
        return;
      }
    }

    if (_currentBuffer.isNotEmpty) {
      // แปลงคำที่กำลังพิมพ์อยู่
      final bool isThai = RegExp(r'[ก-์]').hasMatch(_currentBuffer);
      String converted = AutocorrectEngine.convertLayout(
        _currentBuffer,
        languageCode: 'th',
        toTarget: !isThai,
      );
      
      // Deduplicate repeated prefix when converting from Thai to English
      if (isThai) {
        for (int len = 1; len <= converted.length ~/ 2; len++) {
          final prefix = converted.substring(0, len);
          final sub = converted.substring(len);
          if (sub.startsWith(prefix)) {
            if (AutocorrectEngine.isCommonEnglishWord(sub) || 
                AutocorrectEngine.isValidEnglishWordPattern(sub)) {
              converted = sub;
              break;
            }
          }
        }
      }
      
      final int backspaces = _calculateBackspaces(_currentBuffer, converted);
      
      _replaceText(backspaces, converted);

      _syncSlashBufferOnReplacement(_currentBuffer, converted);

      _currentBuffer = converted;
      
      // บันทึกคำแปลที่ถูกต้องลง Dictionary/Ignore list
      _addWordToIgnoreList(converted);
      return;
    }

    if (_fullSentenceBuffer.isNotEmpty) {
      // แปลงคำสุดท้ายในประโยคที่พิมพ์ไปแล้ว
      final trimmed = _fullSentenceBuffer.trimRight();
      if (trimmed.isEmpty) return;
      
      final trailing = _fullSentenceBuffer.substring(trimmed.length);
      final words = trimmed.split(RegExp(r'[\s\p{P}]', unicode: true));
      if (words.isEmpty) return;
      
      final lastWord = words.last;
      if (lastWord.isEmpty) return;
      
      final bool isThai = RegExp(r'[ก-์]').hasMatch(lastWord);
      String converted = AutocorrectEngine.convertLayout(
        lastWord,
        languageCode: 'th',
        toTarget: !isThai,
      );
      
      // Deduplicate repeated prefix when converting from Thai to English
      if (isThai) {
        for (int len = 1; len <= converted.length ~/ 2; len++) {
          final prefix = converted.substring(0, len);
          final sub = converted.substring(len);
          if (sub.startsWith(prefix)) {
            if (AutocorrectEngine.isCommonEnglishWord(sub) || 
                AutocorrectEngine.isValidEnglishWordPattern(sub)) {
              converted = sub;
              break;
            }
          }
        }
      }
      
      final String convertedEndingChars = AutocorrectEngine.convertLayout(
        trailing,
        languageCode: 'th',
        toTarget: !isThai,
      );
      final replacement = converted + convertedEndingChars;
      final int totalLengthToDelete = _calculateBackspaces(lastWord + trailing, replacement);
      
      _replaceText(totalLengthToDelete, replacement);

      _syncSlashBufferOnReplacement(lastWord + trailing, replacement);
      
      _fullSentenceBuffer = _fullSentenceBuffer.substring(0, _fullSentenceBuffer.length - (lastWord + trailing).length) + replacement;
      
      // บันทึกคำแปลที่ถูกต้องลง Dictionary/Ignore list
      _addWordToIgnoreList(converted);
    }
  }

  // เพิ่มคำศัพท์ลงรายการละเว้น (Ignore list / dict) โดยอัตโนมัติ
  Future<void> _addWordToIgnoreList(String word) async {
    final lowerWord = word.trim().toLowerCase();
    if (lowerWord.isEmpty || lowerWord.length < 2) return;

    // ถ้าเป็นภาษาอังกฤษ ให้เพิ่มในคลังคำศัพท์ภาษาอังกฤษของผู้ใช้ด้วย เพื่อให้ระบบรู้จักในการตรวจแก้ครั้งถัดไป
    // ต้องตรวจสอบรูปแบบคำภาษาอังกฤษที่ถูกต้องด้วย (ห้ามมีตัวเลขหรือสัญลักษณ์ เพื่อป้องกันคำคีย์บอร์ดขยะเช่น 0yfwx)
    if (RegExp(r'^[a-zA-Z\d]+$').hasMatch(lowerWord) && AutocorrectEngine.isValidEnglishWordPattern(lowerWord)) {
      if (!AutocorrectEngine.userEnWords.contains(lowerWord)) {
        AutocorrectEngine.userEnWords.add(lowerWord);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('userEnWords', AutocorrectEngine.userEnWords.toList());
        AppLogger.log("Dart: Added English word to user dictionary: '$lowerWord'");
      }
    }

    if (!_ignoredWords.contains(lowerWord)) {
      setState(() {
        _ignoredWords.add(lowerWord);
      });
      await _saveSetting('ignoredWords', _ignoredWords);
      AppLogger.log("Dart: Auto-added word to ignore list (dict) via hotkey: '$lowerWord'");
    }
  }

  // ลบคำศัพท์ออกจากรายการละเว้น (เมื่อแอปสลับผิดแล้วผู้ใช้กด undo กลับ)
  Future<void> _removeWordFromIgnoreList(String word) async {
    final lowerWord = word.trim().toLowerCase();
    if (lowerWord.isEmpty) return;

    bool removedEn = false;
    if (AutocorrectEngine.userEnWords.contains(lowerWord)) {
      AutocorrectEngine.userEnWords.remove(lowerWord);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('userEnWords', AutocorrectEngine.userEnWords.toList());
      removedEn = true;
    }

    bool removedIgnore = false;
    if (_ignoredWords.contains(lowerWord)) {
      setState(() {
        _ignoredWords.remove(lowerWord);
      });
      await _saveSetting('ignoredWords', _ignoredWords);
      removedIgnore = true;
    }

    if (removedEn || removedIgnore) {
      AppLogger.log("Dart: Removed wrongly corrected word from dictionary: '$lowerWord'");
    }
  }

  Future<void> _saveShortcuts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('textShortcuts', jsonEncode(_textShortcuts));
  }

  // ประมวลผลแก้ระดับประโยค (Context AI - Ollama API)
  Future<void> _processSentenceCorrection(String sentence) async {
    _incrementStat('aiRequests');

    final String? corrected = await AutocorrectEngine.checkAndCorrectAI(sentence);
    final String source = AutocorrectEngine.lastDecisionSource;
    AppLogger.log("Dart: [Sentence Swapped] '$sentence' -> '$corrected' (Swapped by ${source.toUpperCase()})");

    if (corrected != null && corrected != sentence) {
      // แก้ไขทั้งประโยค
      final int backspaces = _calculateBackspaces(sentence, corrected);
      _replaceText(backspaces, corrected);

      _syncSlashBufferOnReplacement(sentence, corrected);

      final int savedCharsDiff = (corrected.characters.length - sentence.characters.length).abs();
      _incrementStat('wordsCorrected');
      if (savedCharsDiff > 0) {
        _incrementStat('savedChars', value: savedCharsDiff);
      }

      setState(() {
        _recentCorrections.insert(0, {
          'original': sentence,
          'corrected': corrected,
          'timestamp': DateTime.now().toString().substring(11, 19),
          'type': source == 'ai' ? 'Local AI' : 'Layout (Auto)'
        });
        if (_recentCorrections.length > 5) {
          _recentCorrections.removeLast();
        }
      });

      _saveHistory();
      
      // เคลียร์บัฟเฟอร์ประโยคหลังแก้ไขเสร็จ
      _fullSentenceBuffer = '';
    }
  }

  // --- ส่วนการสร้าง UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isDark
                ? [
                    Theme.of(context).colorScheme.background.withOpacity(0.95),
                    const Color(0xFF1E1B4B).withOpacity(0.95), // Deep Indigo-Navy
                  ]
                : [
                    const Color(0xFFF8FAFC).withOpacity(0.95), // Slate 50
                    const Color(0xFFE2E8F0).withOpacity(0.95), // Slate 200
                  ],
          ),
          border: Border.all(
            color: _isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // 1. Custom Title Bar (แถบหัวหน้าต่างลากได้)
            _buildCustomTitleBar(),
            
            // 2. Main Content Layout
            Expanded(
              child: Row(
                children: [
                  // แถบเมนูด้านข้าง (Sidebar)
                  _buildSidebar(),
                  
                  // หน้าจอเนื้อหาหลัก (Tab Views)
                  Expanded(
                    child: Container(
                      color: _isDark ? Colors.black.withOpacity(0.15) : Colors.white.withOpacity(0.4),
                      padding: const EdgeInsets.all(24),
                      child: _buildActiveTabContent(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTitleBar() {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(), // เปิดให้กดลากหน้าต่างได้
      child: Container(
        height: 48,
        padding: EdgeInsets.only(left: Platform.isMacOS ? 80 : 16, right: 16),
        decoration: BoxDecoration(
          color: _isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.5),
          border: Border(
            bottom: BorderSide(
              color: _borderColor,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // โลโก้และชื่อแอป
            Row(
              children: [
                Image.asset('assets/app_icon.png', height: 24, width: 24),
                const SizedBox(width: 8),
                const Text(
                  "TinyMind",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _isEnabled ? const Color(0xFF10B981).withOpacity(0.15) : Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _isEnabled ? const Color(0xFF10B981).withOpacity(0.3) : Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _isEnabled ? AppTranslations.translate('active', _displayLanguage) : AppTranslations.translate('paused', _displayLanguage),
                    style: TextStyle(
                      color: _isEnabled ? const Color(0xFF10B981) : Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            
            // ปุ่มจัดการหน้าต่าง (Window Controls)
            Row(
              children: [
                // ย่อหน้าต่าง (Minimize)
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  onPressed: () => windowManager.minimize(),
                  splashRadius: 16,
                  color: _textColorSecondary,
                ),
                // ปิดหน้าต่าง (Close - ซ่อนไปเมนู Tray)
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => _hideWindow(),
                  splashRadius: 16,
                  color: Colors.redAccent.withOpacity(0.8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: _borderColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildSidebarItem(0, Icons.dashboard_rounded, AppTranslations.translate('dashboard', _displayLanguage)),
          _buildSidebarItem(1, Icons.settings_rounded, AppTranslations.translate('settings', _displayLanguage)),
          _buildSidebarItem(2, Icons.menu_book_rounded, AppTranslations.translate('dictionary', _displayLanguage)),
          
          if (_isUpdateAvailable) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    if (Platform.isMacOS || Platform.isWindows) {
                      try {
                        await autoUpdater.checkForUpdates();
                      } catch (e) {
                        _launchUrl(_latestReleaseUrl);
                      }
                    } else {
                      _launchUrl(_latestReleaseUrl);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.system_update_alt_rounded,
                          color: Color(0xFF6366F1),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.translate('update_available', _displayLanguage),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "v$_latestVersion",
                                style: TextStyle(
                                  fontSize: 9,
                                  color: _isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          
          const Spacer(),
          // สถานะ Accessibility Permission
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _hasAccessibility 
                    ? const Color(0xFF10B981).withOpacity(0.05) 
                    : Colors.amber.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _hasAccessibility 
                      ? const Color(0xFF10B981).withOpacity(0.2) 
                      : Colors.amber.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _hasAccessibility ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                    color: _hasAccessibility ? const Color(0xFF10B981) : Colors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppTranslations.translate('accessibility_status', _displayLanguage),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _hasAccessibility ? AppTranslations.translate('accessibility_granted', _displayLanguage) : AppTranslations.translate('accessibility_needed', _displayLanguage),
                          style: TextStyle(
                            fontSize: 10, 
                            color: _hasAccessibility ? (_isDark ? Colors.white60 : Colors.black54) : Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              "v$currentVersion",
              style: TextStyle(
                fontSize: 10,
                color: _isDark ? Colors.white30 : Colors.black38,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String title) {
    final bool isActive = _activeTab == index;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            _activeTab = index;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? primaryColor.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? primaryColor.withOpacity(0.25) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? primaryColor : (_isDark ? Colors.white60 : Colors.black54),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isActive ? primaryColor : (_isDark ? Colors.white60 : Colors.black54),
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 0:
        return DashboardTab(state: this);
      case 1:
        return SettingsTab(state: this);
      case 2:
        return DictionaryTab(state: this);
      default:
        return DashboardTab(state: this);
    }
  }
}
