import 'dart:convert';
import 'dart:io';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'language_mapper.dart';
import 'thai_mapper.dart';
import 'logger.dart';

class AutocorrectEngine {
  // ทะเบียนของภาษาที่เปิดใช้งานในระบบสลับคีย์บอร์ด (เริ่มต้นเป็นภาษาไทย)
  static final List<LanguageMapper> _mappers = [ThaiMapper()];

  // รายชื่อคำภาษาอังกฤษยอดนิยม (เพื่อป้องกันไม่ให้แอปไปแปลงคำภาษาอังกฤษที่ถูกต้อง)
  static const Set<String> _commonEnWords = {
    'a', 'about', 'above', 'add', 'admin', 'after', 'again', 'against', 'ai', 'align', 'all', 'almost', 'along', 'already', 'also',
    'although', 'always', 'am', 'amd', 'among', 'an', 'ancestor', 'and', 'android', 'another', 'any', 'anyone', 'anything', 'anywhere', 'api',
    'app', 'apple', 'application', 'are', 'area', 'around', 'as', 'ask', 'asset', 'assets', 'at', 'audio', 'away', 'back', 'backspace',
    'base', 'bash', 'be', 'because', 'become', 'before', 'began', 'begin', 'behind', 'being', 'below', 'between', 'both',
    'bring', 'brought', 'build', 'built', 'busy', 'but', 'button', 'by', 'call', 'called', 'came', 'can', 'cancel', 'cannot', 'capslock',
    'card', 'cards', 'case', 'cause', 'center', 'certain', 'change', 'chat', 'check', 'child', 'children', 'class', 'clear', 'client', 'close',
    'code', 'color', 'column', 'come', 'compile', 'config', 'configuration', 'console', 'const', 'could', 'count', 'course', 'cpp', 'create', 'csharp',
    'css', 'cut', 'dart', 'data', 'database', 'day', 'db', 'debug', 'deepmind', 'delete', 'deploy', 'descendant', 'design', 'detail', 'details', 'dev',
    'developer', 'development', 'device', 'did', 'differ', 'different', 'directory', 'do', 'does', 'done', 'double', 'down', 'draw', 'during', 'each',
    'early', 'earth', 'ease', 'east', 'easy', 'eat', 'either', 'else', 'end', 'enough', 'env', 'environment', 'error', 'even', 'evenly',
    'ever', 'every', 'everyone', 'everything', 'example', 'export', 'face', 'facebook', 'fact', 'failure', 'fall', 'far', 'fast', 'feel', 'few',
    'field', 'file', 'filter', 'final', 'find', 'first', 'five', 'flex', 'flutter', 'fly', 'folder', 'follow', 'font', 'food', 'for',
    'force', 'form', 'forward', 'found', 'four', 'framework', 'friend', 'from', 'front', 'full', 'function', 'game', 'gave', 'get', 'git',
    'github', 'gitlab', 'give', 'given', 'go', 'golang', 'gold', 'good', 'google', 'got', 'graphql', 'great', 'green', 'grid', 'ground',
    'group', 'grow', 'grpc', 'guest', 'had', 'half', 'hand', 'happen', 'hard', 'has', 'have', 'he', 'head', 'hear', 'heard',
    'height', 'held', 'hello', 'help', 'her', 'here', 'high', 'him', 'himself', 'his', 'hold', 'home', 'hot',
    'hour', 'house', 'how', 'however', 'html', 'http', 'https', 'hundred', 'i', 'icon', 'id', 'idea', 'if', 'ig', 'ii', 'iii', 'image', 'import',
    'important', 'in', 'inches', 'ind', 'index', 'info', 'init', 'instagram', 'install', 'integer', 'intel', 'internet', 'into', 'ios', 'ip', 'is', 'iv', 'ix',
    'it', 'item', 'items', 'its', 'itself', 'java', 'javascript', 'json', 'just', 'justify', 'keep', 'kept', 'key', 'keys', 'kind',
    'knew', 'know', 'known', 'kotlin', 'land', 'large', 'last', 'late', 'later', 'laugh', 'lay', 'layout', 'lead', 'learn', 'least',
    'leave', 'left', 'length', 'less', 'let', 'letter', 'library', 'life', 'light', 'like', 'line', 'linux', 'list', 'listen', 'lists',
    'little', 'live', 'lived', 'load', 'loading', 'local', 'login', 'logout', 'long', 'look', 'love', 'low', 'mac', 'macos', 'made',
    'main', 'make', 'many', 'map', 'maps', 'margin', 'mark', 'match', 'may', 'me', 'mean', 'measure', 'media', 'member', 'men',
    'method', 'microsoft', 'might', 'mind', 'miss', 'model', 'module', 'more', 'morning', 'most', 'mother', 'mountain', 'move', 'much', 'multi',
    'must', 'my', 'myself', 'name', 'near', 'need', 'network', 'never', 'new', 'next', 'night', 'no', 'north', 'not', 'note',
    'nothing', 'notice', 'now', 'number', 'object', 'objectivec', 'of', 'off', 'often', 'oh', 'ok', 'okay', 'old', 'on', 'once',
    'one', 'only', 'open', 'option', 'options', 'or', 'order', 'os', 'other', 'our', 'out', 'outside', 'over', 'own', 'page', 'paper',
    'parent', 'part', 'party', 'pass', 'password', 'past', 'path', 'pattern', 'pause', 'people', 'perhaps', 'person', 'picture',
    'place', 'plan', 'play', 'please', 'point', 'port', 'pose', 'position', 'possible', 'power', 'present', 'press', 'prev', 'private', 'problem',
    'process', 'prod', 'product', 'production', 'profile', 'program', 'project', 'provide', 'public', 'publish', 'pull', 'put', 'python', 'query', 'question',
    'quick', 'quite', 'rain', 'ran', 'reach', 'read', 'ready', 'real', 'receive', 'record', 'red', 'release', 'remember', 'remove', 'represent',
    'reset', 'resource', 'resources', 'rest', 'result', 'return', 'right', 'rise', 'road', 'rock', 'room', 'row', 'ruby', 'run', 'rust',
    'sad', 'said', 'same', 'sand', 'sat', 'save', 'saw', 'say', 'school', 'science', 'screen', 'scroll', 'sdk', 'sea', 'search',
    'second', 'see', 'seem', 'seen', 'self', 'send', 'sent', 'sentence', 'serve', 'server', 'service', 'set', 'sets', 'setting', 'settings',
    'setup', 'several', 'shall', 'shape', 'she', 'shell', 'shift', 'ship', 'short', 'should', 'show', 'shown', 'shut', 'sibling', 'side',
    'sight', 'sign', 'silent', 'simple', 'since', 'sing', 'single', 'sir', 'sister', 'sit', 'site', 'six', 'size', 'skin', 'sky',
    'sleep', 'slip', 'slow', 'small', 'smell', 'smile', 'snow', 'so', 'software', 'some', 'someone', 'something', 'sometime', 'somewhere', 'song',
    'soon', 'sorry', 'sort', 'sound', 'south', 'space', 'speak', 'special', 'spell', 'spend', 'spoke', 'spot', 'spread', 'spring', 'sql', 'stack',
    'staging', 'start', 'static', 'status', 'stop', 'stretch', 'string', 'strong', 'student', 'study', 'subject', 'submit', 'substance',
    'success', 'such', 'sudden', 'suffice', 'sugar', 'suit', 'summer', 'sun', 'supply', 'support', 'sure', 'surface', 'surprise',
    'sweet', 'swift', 'swim', 'system', 'table', 'tail', 'take', 'taken', 'talk', 'tall', 'tape', 'task', 'taste', 'teach',
    'team', 'teeth', 'tell', 'ten', 'term', 'terminal', 'test', 'than', 'thank', 'thanks', 'that', 'the', 'their', 'them',
    'theme', 'themselves', 'then', 'there', 'these', 'they', 'thick', 'thin', 'thing', 'think', 'third', 'this', 'those',
    'though', 'thought', 'thousand', 'three', 'threw', 'through', 'throw', 'thus', 'tie', 'tight', 'tiktok', 'time',
    'tiny', 'tinymind', 'tire', 'to', 'today', 'together', 'told', 'tomorrow', 'too', 'took', 'top', 'total', 'touch',
    'toward', 'town', 'toy', 'trace', 'track', 'trade', 'train', 'travel', 'tree', 'trial', 'triangle', 'trip', 'trouble',
    'true', 'trunk', 'try', 'tube', 'turn', 'twenty', 'two', 'type', 'typescript', 'under', 'understand', 'unit',
    'ui', 'until', 'up', 'update', 'upon', 'uri', 'url', 'us', 'use', 'user', 'usual', 'ux', 'v', 'validate', 'valley',
    'value', 'values', 'various', 'verb', 'very', 'view', 'vi', 'vii', 'viii', 'visit', 'voice', 'vowel', 'wagon', 'wait',
    'walk', 'wall', 'want', 'war', 'warm', 'warn', 'warning', 'was', 'wash', 'watch', 'water',
    'wave', 'way', 'we', 'weak', 'wear', 'weather', 'week', 'weight', 'well', 'went', 'were',
    'west', 'wfh', 'what', 'wheel', 'when', 'where', 'whether', 'which', 'while', 'white',
    'who', 'whole', 'whom', 'whose', 'why', 'wide', 'widget', 'width', 'wife', 'wifi',
    'wild', 'will', 'win', 'wind', 'window', 'windows', 'wing', 'winter', 'wire', 'wise',
    'wish', 'with', 'within', 'without', 'woman', 'wonder', 'wood', 'word', 'work',
    'worker', 'world', 'worry', 'worse', 'worth', 'would', 'wrap', 'write', 'written',
    'wrong', 'wrote', 'x', 'xml', 'yaml', 'yard', 'year', 'yellow', 'yes', 'yesterday',
    'yet', 'you', 'young', 'your', 'yours', 'yourself', 'yourselves', 'youth', 'youtube',
    'zero', 'zone',
  };

  // คลังคำศัพท์ภาษาอังกฤษเพิ่มเติมของผู้ใช้ (เรียนรู้จากการกู้คืนด้วย Hotkey)
  static final Set<String> userEnWords = {};

  // พจนานุกรมคำสะกดผิดทั่วไป (ไทย-อังกฤษ)
  static const Map<String, String> _commonTypos = {
    // คำผิดภาษาไทยยอดนิยม
    'สังเกตุ': 'สังเกต',
    'เว็ปไซต์': 'เว็บไซต์',
    'กระเพรา': 'กะเพรา',
    'กฏ': 'กฎ',
    'ระชาชน': 'ประชาชน',
    'กิตติกรรมประกาศ': 'กิตติประกาศ',
    
    // คำผิดภาษาอังกฤษยอดนิยม
    'recieve': 'receive',
    'definately': 'definitely',
    'teh': 'the',
    'wont': 'won\'t',
    'cant': 'can\'t',
    'dont': 'don\'t',
    'seperate': 'separate',
    'occured': 'occurred',
    'unil': 'until',
  };

  static String? _getCommonTypoCorrection(String word) {
    final lower = word.toLowerCase();
    if (_commonTypos.containsKey(lower)) {
      final corrected = _commonTypos[lower]!;
      // Match casing of original word
      if (word.isNotEmpty && word[0] == word[0].toUpperCase()) {
        return corrected[0].toUpperCase() + corrected.substring(1);
      }
      return corrected;
    }
    return null;
  }

  // ตัวแปรเก็บ Llama Instance
  static Llama? _llama;
  static String? _loadedModelPath;
  static bool _isLoading = false;

  static bool get isModelLoaded => _llama != null;
  static bool get isLoading => _isLoading;
  static String? get loadedModelPath => _loadedModelPath;

  // โหลด Local AI Model (llama.cpp)
  static Future<void> initAI(String modelPath) async {
    if (_llama != null && _loadedModelPath == modelPath) {
      return; // โหลดไว้แล้ว
    }

    _isLoading = true;
    disposeAI();

    try {
      if (Platform.isWindows) {
        Llama.libraryPath = "llama_cpp_dart_plugin.dll";
      } else if (Platform.isMacOS) {
        // ค้นหาตำแหน่ง Llama library ภายใน app bundle's Frameworks ก่อน (โหมดใช้งานจริงที่ผ่านการลงลายเซ็น)
        final executableDir = File(Platform.resolvedExecutable).parent.path;
        final localFrameworkPath = "$executableDir/../Frameworks/Llama.framework/Llama";
        if (File(localFrameworkPath).existsSync()) {
          Llama.libraryPath = localFrameworkPath;
          AppLogger.log("TinyMind: Using local bundle Llama library at $localFrameworkPath");
        } else {
          // ใช้ไฟล์จาก pub cache สำหรับกรณีรัน debug ในโหมดพัฒนา
          Llama.libraryPath = "/Users/q0022/.pub-cache/hosted/pub.dev/llama_cpp_dart-0.2.2/dist/Llama.xcframework/macos-arm64/Llama.framework/Llama";
          AppLogger.log("TinyMind: Falling back to pub cache Llama library");
        }
      }

      AppLogger.log("TinyMind: Loading local GGUF model: $modelPath");
      // โหลด Model โดยตั้งค่า Context ขนาดเล็กเพื่อ Latency ที่เร็วที่สุด
      _llama = Llama(
        modelPath,
        contextParams: ContextParams()
          ..nCtx = 512
          ..nPredict = 64,
        samplerParams: SamplerParams()
          ..greedy = true, // ใช้ greedy เพื่อความรวดเร็วและตรงประเด็นที่สุดในการแก้คำผิด
        verbose: true,
      );
      _loadedModelPath = modelPath;
      AppLogger.log("TinyMind: Local GGUF model loaded successfully!");
    } catch (e) {
      AppLogger.log("TinyMind: Failed to load local Llama model: $e");
      _llama = null;
      _loadedModelPath = null;
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  // เคลียร์ VRAM และปิดการเชื่อมต่อโมเดล
  static void disposeAI() {
    if (_llama != null) {
      try {
        _llama!.dispose();
        AppLogger.log("TinyMind: Disposed local GGUF model");
      } catch (e) {
        AppLogger.log("TinyMind: Error disposing Llama: $e");
      }
      _llama = null;
      _loadedModelPath = null;
    }
  }

  // แปลงเลย์เอาต์แป้นพิมพ์สำหรับภาษาที่ระบุ
  static String convertLayout(String input, {required String languageCode, required bool toTarget}) {
    for (var mapper in _mappers) {
      if (mapper.languageCode == languageCode) {
        return toTarget ? mapper.convertToTarget(input) : mapper.convertFromTarget(input);
      }
    }
    return input;
  }

  // ฟังก์ชันวิเคราะห์การแก้ไขคำผิดระดับคำเดี่ยว (Local - Fast)
  static CorrectionResult? checkAndCorrectLocal(String word) {
    if (word.isEmpty || word.length < 2) return null;

    // ป้องกันการแปลงหากคำเป็นตัวเลขทศนิยม เวอร์ชัน หรือ IP address (เช่น 1.0, 3.14, .50, v1.0.0)
    if (RegExp(r'^v?\d*\.\d+(\.\d+)*$').hasMatch(word)) {
      return null;
    }

    // ป้องกันการแปลงหากคำเป็นโค้ด พาธ อีเมล หรือสัญลักษณ์ระบบ
    if (_isCodeOrSymbol(word)) {
      return null;
    }

    // 0. ตรวจสอบคำสะกดผิดสะสมโดยตรง (Spelling correction)
    final directTypo = _getCommonTypoCorrection(word);
    if (directTypo != null) {
      final isThai = RegExp(r'[ก-์]').hasMatch(directTypo);
      return CorrectionResult(
        correctedWord: directTypo,
        languageCode: isThai ? 'th' : 'en',
        isToTargetLanguage: isThai,
      );
    }

    // 1. ตรวจสอบกรณีพิมพ์ไทยผสมอังกฤษ (สลับเลย์เอาต์กลางคำ) หรือลืมเปลี่ยนภาษาแบบผสม
    // ลองแปลงเป็นภาษาอังกฤษดู
    for (var mapper in _mappers) {
      final enConverted = mapper.convertFromTarget(word);
      if (enConverted != word) {
        if (_isThaiBypassWord(word)) {
          continue;
        }
        final enFixed = _getCommonTypoCorrection(enConverted) ?? enConverted;
        if (_commonEnWords.contains(enFixed.toLowerCase()) || 
            userEnWords.contains(enFixed.toLowerCase())) {
          return CorrectionResult(
            correctedWord: enFixed,
            languageCode: mapper.languageCode,
            isToTargetLanguage: false,
          );
        }
      }
    }

    // 2. ลองแปลงเป็นภาษาไทยดู
    for (var mapper in _mappers) {
      final thConverted = mapper.convertToTarget(word);
      if (thConverted != word) {
        final thFixed = _getCommonTypoCorrection(thConverted) ?? thConverted;
        if (mapper.isCommonWord(thFixed) || mapper.isValidPattern(thFixed)) {
          // ป้องกันการแปลงคำอังกฤษล้วนที่มีความหมายหรือมีรูปแบบปกติอยู่แล้ว
          if (RegExp(r'^[a-zA-Z\d]+$').hasMatch(word)) {
            if (_commonEnWords.contains(word.toLowerCase()) || userEnWords.contains(word.toLowerCase())) {
              continue;
            }
            if (!mapper.isCommonWord(thFixed) && word.length >= 4) {
              continue; // ไม่แปลงคำอังกฤษยาวๆ ที่ไม่ใช่คำไทยยอดนิยม เพื่อป้องกัน False Positive
            }
          }

          return CorrectionResult(
            correctedWord: thFixed,
            languageCode: mapper.languageCode,
            isToTargetLanguage: true,
          );
        }
      }
    }

    return null;
  }

  static bool isCommonEnglishWord(String word) {
    if (word.isEmpty) return false;
    return _commonEnWords.contains(word.toLowerCase()) || userEnWords.contains(word.toLowerCase());
  }

  // ฟังก์ชันวิเคราะห์การแก้ไขคำผิดระดับคำเดี่ยวแบบเข้มงวดเป็นพิเศษ (สำหรับ Continuous Switch)
  static CorrectionResult? checkAndCorrectLocalStrict(String word) {
    if (word.isEmpty || word.length < 2) return null;

    // ป้องกันการแปลงหากคำเป็นตัวเลขทศนิยม เวอร์ชัน หรือ IP address (เช่น 1.0, 3.14, .50, v1.0.0)
    if (RegExp(r'^v?\d*\.\d+(\.\d+)*$').hasMatch(word)) {
      return null;
    }

    // ป้องกันการแปลงหากคำเป็นโค้ด พาธ อีเมล หรือสัญลักษณ์ระบบ
    if (_isCodeOrSymbol(word)) {
      return null;
    }

    // 0. ตรวจสอบคำสะกดผิดสะสมโดยตรง (Spelling correction)
    final directTypo = _getCommonTypoCorrection(word);
    if (directTypo != null) {
      final isThai = RegExp(r'[ก-์]').hasMatch(directTypo);
      return CorrectionResult(
        correctedWord: directTypo,
        languageCode: isThai ? 'th' : 'en',
        isToTargetLanguage: isThai,
      );
    }

    // 1. ลองแปลงเป็นภาษาอังกฤษก่อน
    for (var mapper in _mappers) {
      final enConverted = mapper.convertFromTarget(word);
      if (enConverted != word) {
        if (_isThaiBypassWord(word)) {
          continue;
        }
        final enFixed = _getCommonTypoCorrection(enConverted) ?? enConverted;
        if (_commonEnWords.contains(enFixed.toLowerCase()) || userEnWords.contains(enFixed.toLowerCase())) {
          return CorrectionResult(
            correctedWord: enFixed,
            languageCode: mapper.languageCode,
            isToTargetLanguage: false,
          );
        }
      }
    }

    // 2. ลองแปลงเป็นภาษาไทย
    for (var mapper in _mappers) {
      final thConverted = mapper.convertToTarget(word);
      if (thConverted != word) {
        final thFixed = _getCommonTypoCorrection(thConverted) ?? thConverted;
        if (mapper.isCommonWord(thFixed) || mapper.isValidPatternStrict(thFixed, word)) {
          // ป้องกันการแปลงคำอังกฤษล้วนที่มีความหมายอยู่แล้ว
          if (RegExp(r'^[a-zA-Z\d]+$').hasMatch(word)) {
            if (_commonEnWords.contains(word.toLowerCase()) || userEnWords.contains(word.toLowerCase())) {
              continue;
            }
            if (!mapper.isCommonWord(thFixed) && word.length >= 4) {
              continue;
            }
          }

          return CorrectionResult(
            correctedWord: thFixed,
            languageCode: mapper.languageCode,
            isToTargetLanguage: true,
          );
        }
      }
    }

    return null;
  }

  static bool _isThaiBypassWord(String word) {
    final lower = word.toLowerCase();
    const bypassWords = {'รร', 'รอ', 'อร', 'รด', 'รก', 'ทำ', 'นา', 'นพ', 'เป', 'ระ'};
    return bypassWords.contains(lower);
  }

  static bool _isCodeOrSymbol(String word) {
    if (word.isEmpty) return false;

    bool matchesBypass = false;

    // 1. ถ้ามีสัญลักษณ์โปรแกรมมิ่ง/ระบบ/พาธ/ลิงก์ (ยกเว้น . , - และเครื่องหมายวรรคตอนทั่วไป)
    // สัญลักษณ์ที่จะข้าม: / \ @ ~ _ = + * ^ % $ # & | < > [ ] { } `
    final codeSymbolRegExp = RegExp(r'[/\@~_=\+\*\^%\$#&|<>\\[\]{}`]');
    if (codeSymbolRegExp.hasMatch(word)) {
      matchesBypass = true;
    }

    // 2. ถ้าขึ้นต้นหรือลงท้ายด้วยเครื่องหมายคำพูด (เช่น "hello", 'world')
    if (!matchesBypass && ((word.startsWith('"') && word.endsWith('"')) ||
        (word.startsWith("'") && word.endsWith("'")))) {
      matchesBypass = true;
    }

    // 3. ถ้าขึ้นต้นด้วยเครื่องหมายลบ (เช่น -i, --help, -rf)
    if (!matchesBypass && word.startsWith('-')) {
      matchesBypass = true;
    }

    // 4. ถ้ามีจุด (.) และตามด้วยนามสกุลไฟล์หรือ TLD (เช่น index.js, google.com, main.dart)
    if (!matchesBypass && word.contains('.')) {
      final parts = word.split('.');
      if (parts.length >= 2) {
        final lastPart = parts.last.toLowerCase();
        const commonExtensions = {
          'com', 'net', 'org', 'io', 'co', 'th', 'edu', 'gov', 'mil',
          'js', 'ts', 'py', 'dart', 'swift', 'java', 'cpp', 'h', 'c',
          'html', 'css', 'json', 'yaml', 'yml', 'md', 'sh', 'bat', 'exe',
          'dll', 'so', 'dylib', 'bin', 'txt', 'pdf', 'png', 'jpg', 'jpeg',
          'gif', 'svg', 'zip', 'tar', 'gz', 'dmg', 'app', 'config', 'log'
        };
        if (commonExtensions.contains(lastPart)) {
          matchesBypass = true;
        }
      }
    }

    // 5. ถ้ามีจุด (.) หรือเครื่องหมายขีด (-) อยู่กึ่งกลางคำ (ขนาบข้างด้วยตัวอักษร/ตัวเลข)
    // เช่น index.js, google.com, sisa-ai, my-key, svn.s
    if (!matchesBypass && RegExp(r'[a-zA-Z\d]+[\.-][a-zA-Z\d]+').hasMatch(word)) {
      matchesBypass = true;
    }

    // ถ้าตรวจพบว่าตรงกับเงื่อนไขการ Bypass โค้ด/สัญลักษณ์
    // ให้ตรวจสอบก่อนว่าคำนั้นเป็นคำในภาษาไทยที่ถูกต้องหรือไม่ (เพื่อกันการบล็อกปุ่ม บ, ล, ฝ, ช, ู, ข, ใ ฯลฯ)
    if (matchesBypass) {
      bool isThaiWord = false;
      for (var mapper in _mappers) {
        final thConverted = mapper.convertToTarget(word);
        if (thConverted != word) {
          final thFixed = _getCommonTypoCorrection(thConverted) ?? thConverted;
          if (mapper.isCommonWord(thFixed) || mapper.isValidPatternStrict(thFixed, word)) {
            // ดักจับพิเศษ: หากคำดั้งเดิมเริ่มต้นด้วยเครื่องหมายลบ (เช่น -rf, -la)
            // แต่ไม่มีสระหรือวรรณยุกต์ไทยเลย และไม่ใช่คำไทยยอดนิยม เราจะไม่นับเป็นคำไทย (เพื่อป้องกันการสลับคำสั่ง option ใน command line)
            if (word.startsWith('-') && 
                !RegExp(r'[เแโใไิีึืั็ํุูะาำ่้๊๋์]').hasMatch(thFixed) && 
                !mapper.isCommonWord(thFixed)) {
              continue;
            }
            isThaiWord = true;
            break;
          }
        }
      }
      if (!isThaiWord) {
        return true;
      }
    }

    return false;
  }

  // ฟังก์ชันวิเคราะห์ประโยคและบริบทโดยใช้ Local llama.cpp (Embedded AI)
  static Future<String?> checkAndCorrectAI(String sentence) async {
    if (_llama == null) {
      AppLogger.log("TinyMind AI: Model is not loaded yet.");
      return null;
    }

    try {
      _llama!.clear();
      
      final prompt = """
You are an advanced real-time autocorrection tool.
Fix any spelling mistakes, typos, or keyboard layout errors (e.g. typing Thai words using English keyboard layout or vice versa) in the provided text.
Preserve the original meaning, punctuation, and casing as much as possible.
Output ONLY the corrected text. Do NOT explain your changes. Do NOT wrap in quotes.

Text to correct: "$sentence"
Corrected Text:""";

      _llama!.setPrompt(prompt);
      
      // สั่ง Generate ข้อความแบบสมบูรณ์
      final correctedText = await _llama!.generateCompleteText(maxTokens: 50);
      final trimmed = correctedText.trim().replaceAll(RegExp(r'^"|"$'), '');
      
      if (trimmed.isNotEmpty && trimmed != sentence) {
        return trimmed;
      }
    } catch (e) {
      AppLogger.log("TinyMind Local AI Inference Error: $e");
    }
    return null;
  }
}
