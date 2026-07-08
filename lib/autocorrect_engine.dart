import 'dart:convert';
import 'dart:io';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'language_mapper.dart';
import 'thai_mapper.dart';
import 'korean_mapper.dart';
import 'japanese_mapper.dart';
import 'chinese_mapper.dart';
import 'logger.dart';

class AutocorrectEngine {
  // ทะเบียนของภาษาที่เปิดใช้งานในระบบสลับคีย์บอร์ด
  static final List<LanguageMapper> _mappers = [
    ThaiMapper(),
    KoreanMapper(),
    JapaneseMapper(),
    ChineseMapper(),
  ];

  // รายชื่อคำภาษาอังกฤษยอดนิยม (เพื่อป้องกันไม่ให้แอปไปแปลงคำภาษาอังกฤษที่ถูกต้อง)
  static const Set<String> _commonEnWords = {
    'a', 'about', 'above', 'add', 'admin', 'after', 'again', 'against', 'ai', 'align', 'all', 'almost', 'along', 'already', 'also',
    'although', 'always', 'am', 'amd', 'among', 'an', 'ancestor', 'and', 'android', 'another', 'any', 'anyone', 'anything', 'anywhere', 'api',
    'app', 'apple', 'application', 'apr', 'april', 'are', 'area', 'around', 'art', 'as', 'ask', 'asset', 'assets', 'at', 'audio', 'aug', 'august', 'away', 'back', 'backspace', 'bad', 'bar', 'base', 'bash', 'be', 'because', 'become', 'bed', 'before', 'began', 'begin', 'behind', 'being', 'below', 'between', 'bin', 'blog', 'both', 'book', 'boy', 'buy',
    'bring', 'brought', 'build', 'built', 'busy', 'but', 'button', 'by', 'call', 'called', 'came', 'can', 'cancel', 'cannot', 'capslock',
    'card', 'cards', 'car', 'cat', 'case', 'cause', 'center', 'certain', 'change', 'chat', 'check', 'child', 'children', 'class', 'clear', 'client', 'cli', 'cmd', 'col', 'choe', 'close',
    'code', 'color', 'column', 'come', 'commit', 'cool', 'cute', 'compile', 'config', 'configuration', 'console', 'const', 'could', 'count', 'cpu', 'course', 'cpp', 'cron', 'csv', 'create', 'csharp',
    'css', 'cut', 'dart', 'data', 'database', 'day', 'db', 'debug', 'dec', 'december', 'deepmind', 'delete', 'deploy', 'descendant', 'design', 'detail', 'details', 'dev', 'div', 'dns', 'doc', 'dock', 'dog', 'dom', 'door',
    'developer', 'development', 'device', 'did', 'differ', 'different', 'directory', 'do', 'does', 'done', 'double', 'down', 'draw', 'during', 'each',
    'ear', 'early', 'earth', 'ease', 'east', 'easy', 'eat', 'either', 'else', 'end', 'enough', 'env', 'environment', 'error', 'etc', 'even', 'evenly',
    'ever', 'every', 'everyone', 'everything', 'eye', 'example', 'export', 'face', 'facebook', 'fact', 'failure', 'fall', 'far', 'fast', 'feb', 'february', 'feel', 'few', 'feed',
    'field', 'file', 'filter', 'final', 'find', 'fine', 'fire', 'fish', 'first', 'five', 'flat', 'flex', 'flutter', 'fly', 'folder', 'follow', 'font', 'food', 'foot', 'for', 'ftp', 'free',
    'force', 'form', 'forward', 'found', 'four', 'framework', 'friend', 'from', 'front', 'full', 'function', 'game', 'gave', 'gate', 'get', 'git', 'gif',
    'github', 'gitlab', 'give', 'given', 'girl', 'glad', 'go', 'goal', 'god', 'golang', 'gold', 'good', 'google', 'got', 'gpu', 'graphql', 'great', 'green', 'grid', 'ground',
    'group', 'grow', 'grpc', 'guest', 'had', 'half', 'hand', 'happen', 'hard', 'has', 'have', 'he', 'head', 'hear', 'heard', 'hair',
    'height', 'held', 'hello', 'help', 'her', 'here', 'high', 'him', 'himself', 'his', 'hold', 'home', 'hot',
    'hour', 'house', 'how', 'however', 'html', 'http', 'https', 'href', 'hundred', 'i', 'icon', 'id', 'idea', 'if', 'ig', 'ii', 'iii', 'image', 'img', 'import',
    'important', 'in', 'inches', 'ind', 'index', 'info', 'init', 'instagram', 'install', 'integer', 'intel', 'internet', 'into', 'ios', 'io', 'ip', 'is', 'iv', 'ix',
    'it', 'item', 'items', 'its', 'itself', 'issue', 'java', 'javascript', 'json', 'job', 'jpg', 'js', 'jan', 'january', 'jul', 'july', 'jun', 'june', 'just', 'justify', 'keep', 'kept', 'key', 'keys', 'kind',
    'knew', 'know', 'known', 'kotlin', 'land', 'large', 'last', 'late', 'later', 'laugh', 'lay', 'layout', 'lead', 'learn', 'least',
    'leave', 'left', 'length', 'less', 'let', 'letter', 'lib', 'library', 'life', 'light', 'like', 'line', 'linux', 'list', 'listen', 'lists',
    'little', 'live', 'lived', 'load', 'loading', 'local', 'login', 'logout', 'log', 'logo', 'long', 'look', 'love', 'low', 'mac', 'macos', 'made',
    'main', 'make', 'many', 'map', 'maps', 'mar', 'march', 'margin', 'mark', 'match', 'may', 'me', 'mean', 'measure', 'media', 'member', 'men',
    'method', 'microsoft', 'might', 'min', 'mind', 'miss', 'model', 'module', 'more', 'morning', 'most', 'mother', 'mountain', 'move', 'ms', 'much', 'multi',
    'must', 'my', 'myself', 'name', 'nav', 'near', 'need', 'network', 'never', 'new', 'next', 'night', 'nil', 'no', 'north', 'not', 'note',
    'nothing', 'notice', 'nov', 'november', 'now', 'null', 'number', 'object', 'objectivec', 'oct', 'october', 'of', 'off', 'often', 'oh', 'ok', 'okay', 'old', 'on', 'once',
    'one', 'only', 'open', 'option', 'options', 'or', 'order', 'os', 'other', 'our', 'out', 'outside', 'over', 'own', 'page', 'paper', 'pdf',
    'parent', 'part', 'party', 'pass', 'password', 'past', 'path', 'pattern', 'pause', 'people', 'perhaps', 'person', 'picture',
    'place', 'plan', 'play', 'please', 'png', 'point', 'port', 'pose', 'position', 'possible', 'post', 'power', 'present', 'press', 'prev', 'private', 'problem',
    'process', 'prod', 'product', 'production', 'profile', 'program', 'project', 'provide', 'public', 'publish', 'pull', 'push', 'put', 'python', 'query', 'question',
    'quick', 'quite', 'rain', 'ran', 'ram', 'rom', 'reach', 'read', 'ready', 'real', 'receive', 'record', 'red', 'release', 'remember', 'remove', 'represent',
    'reset', 'resource', 'resources', 'rest', 'result', 'return', 'right', 'rise', 'road', 'rock', 'room', 'row', 'ruby', 'run', 'rust',
    'sad', 'said', 'same', 'sand', 'sat', 'save', 'saw', 'say', 'school', 'science', 'screen', 'scroll', 'sdk', 'sea', 'sec', 'search',
    'second', 'see', 'seem', 'seen', 'self', 'send', 'sent', 'sentence', 'serve', 'server', 'service', 'sep', 'september', 'set', 'sets', 'setting', 'settings',
    'setup', 'several', 'shall', 'shape', 'she', 'shell', 'shift', 'ship', 'shoe', 'short', 'should', 'show', 'shown', 'shut', 'sibling', 'side', 'soca', 'soda',
    'sight', 'sign', 'silent', 'simple', 'since', 'sing', 'single', 'sir', 'sister', 'sit', 'site', 'six', 'size', 'skin', 'sky',
    'sleep', 'slip', 'slow', 'slug', 'small', 'smell', 'smile', 'snow', 'so', 'software', 'some', 'someone', 'something', 'sometime', 'somewhere', 'song',
    'soon', 'sorry', 'sort', 'sound', 'south', 'space', 'speak', 'special', 'spell', 'spend', 'spoke', 'spot', 'spread', 'spring', 'sql', 'src', 'ssh', 'ssl', 'stack',
    'staging', 'start', 'static', 'status', 'stop', 'stretch', 'string', 'strong', 'student', 'study', 'subject', 'submit', 'substance',
    'success', 'such', 'sudden', 'suffice', 'sugar', 'suit', 'summer', 'sun', 'supply', 'support', 'sure', 'surface', 'surprise',
    'sweet', 'swift', 'swim', 'system', 'table', 'tail', 'take', 'taken', 'talk', 'tall', 'tag', 'tap', 'tape', 'task', 'taste', 'teach',
    'team', 'teeth', 'tell', 'ten', 'temp', 'tmp', 'term', 'terminal', 'test', 'than', 'thank', 'thanks', 'that', 'the', 'their', 'them',
    'theme', 'themselves', 'then', 'there', 'these', 'they', 'thick', 'thin', 'thing', 'think', 'third', 'this', 'those',
    'though', 'thought', 'thousand', 'three', 'threw', 'through', 'throw', 'thus', 'tie', 'tight', 'tiktok', 'time',
    'tiny', 'tinymind', 'tire', 'to', 'today', 'together', 'told', 'tomorrow', 'too', 'took', 'top', 'total', 'touch',
    'toward', 'town', 'toy', 'trace', 'track', 'trade', 'train', 'travel', 'tree', 'trial', 'triangle', 'trip', 'trouble',
    'true', 'trunk', 'try', 'tube', 'turn', 'twenty', 'two', 'type', 'typescript', 'under', 'understand', 'unit',
    'ui', 'until', 'up', 'update', 'upon', 'uri', 'url', 'us', 'use', 'user', 'usual', 'ux', 'v', 'validate', 'valley',
    'var', 'value', 'values', 'various', 'verb', 'version', 'very', 'view', 'void', 'vi', 'vii', 'viii', 'visit', 'voice', 'vowel', 'wagon', 'wait',
    'walk', 'wall', 'want', 'war', 'warm', 'warn', 'warning', 'was', 'wash', 'watch', 'water',
    'wave', 'way', 'we', 'weak', 'wear', 'weather', 'week', 'weight', 'well', 'went', 'were',
    'west', 'wfh', 'what', 'wheel', 'when', 'where', 'whether', 'which', 'while', 'white',
    'who', 'whole', 'whom', 'whose', 'why', 'wide', 'widget', 'width', 'wife', 'wifi',
    'wild', 'will', 'win', 'wind', 'window', 'windows', 'wing', 'winter', 'wire', 'wise',
    'wish', 'with', 'within', 'without', 'woman', 'wonder', 'wood', 'word', 'work',
    'worker', 'world', 'worry', 'worse', 'worth', 'would', 'wrap', 'write', 'written',
    'wrong', 'wrote', 'x', 'xml', 'yaml', 'yard', 'year', 'yellow', 'yes', 'yesterday',
    'yet', 'you', 'young', 'your', 'yours', 'yourself', 'yourselves', 'youth', 'youtube',
    'zero', 'zone', 'zsh',
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

  static bool _hasTargetCharacters(LanguageMapper mapper, String text) {
    if (mapper.languageCode == 'th') {
      return RegExp(r'[ก-์]').hasMatch(text);
    } else if (mapper.languageCode == 'ko') {
      return RegExp(r'[\uac00-\ud7af\u1100-\u11ff\u3130-\u318f]').hasMatch(text);
    } else if (mapper.languageCode == 'ja') {
      return RegExp(r'[\u3040-\u309f\u30a0-\u30ff\u4e00-\u9faf]').hasMatch(text);
    } else if (mapper.languageCode == 'zh') {
      return RegExp(r'[\u4e00-\u9fa5]').hasMatch(text);
    }
    return false;
  }

  static bool isKoreanEnabled = false;
  static bool isJapaneseEnabled = false;
  static bool isChineseEnabled = false;
  static String correctionMode = 'hybrid';
  static String lastDecisionSource = 'regex';
  static bool isCodeFilterEnabled = true;
  static void Function(String original, String decision, String type)? onAiDecision;

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
          ..nCtx = 1024
          ..nBatch = 1024
          ..nPredict = 120,
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
  static String convertLayout(String input, {required String languageCode, required bool toTarget, String? context}) {
    for (var mapper in _mappers) {
      if (mapper.languageCode == languageCode) {
        if (toTarget) {
          if (_hasTargetCharacters(mapper, input)) {
            return input;
          }
          if (context != null && context.isNotEmpty) {
            final combined = mapper.convertToTarget(context + input);
            return combined.substring(combined.length - input.length);
          }
          return mapper.convertToTarget(input);
        } else {
          if (!_hasTargetCharacters(mapper, input)) {
            return input;
          }
          if (context != null && context.isNotEmpty) {
            final combined = mapper.convertFromTarget(context + input);
            return combined.substring(combined.length - input.length);
          }
          return mapper.convertFromTarget(input);
        }
      }
    }
    return input;
  }

  // ฟังก์ชันวิเคราะห์การแก้ไขคำผิดระดับคำเดี่ยว (Local - Fast)
  static CorrectionResult? checkAndCorrectLocal(String word) {
    lastDecisionSource = 'regex';
    if (word.isEmpty || word.length < 2) return null;

    // ป้องกันการแปลงหากคำเป็นตัวเลขทศนิยม เวอร์ชัน หรือ IP address (เช่น 1.0, 3.14, .50, v1.0.0)
    if (RegExp(r'^v?\d*\.\d+(\.\d+)*$').hasMatch(word)) {
      return null;
    }

    // ป้องกันการแปลงหากคำเป็นโค้ด พาธ อีเมล หรือสัญลักษณ์ระบบ
    if (isCodeOrSymbol(word)) {
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
      if (mapper is KoreanMapper && !isKoreanEnabled) continue;
      if (mapper is JapaneseMapper && !isJapaneseEnabled) continue;
      if (mapper is ChineseMapper && !isChineseEnabled) continue;
      final enConverted = mapper.convertFromTarget(word);
      if (enConverted != word) {
        if (_isThaiBypassWord(word)) {
          continue;
        }
        final enFixed = _getCommonTypoCorrection(enConverted) ?? enConverted;
        
        String finalEn = enFixed;
        for (int len = 1; len <= enFixed.length ~/ 2; len++) {
          final prefix = enFixed.substring(0, len);
          final sub = enFixed.substring(len);
          if (sub.startsWith(prefix)) {
            if (_commonEnWords.contains(sub.toLowerCase()) || 
                userEnWords.contains(sub.toLowerCase()) ||
                isValidEnglishWordPattern(sub)) {
              finalEn = sub;
              break;
            }
          }
        }

        if (_commonEnWords.contains(finalEn.toLowerCase()) || 
            userEnWords.contains(finalEn.toLowerCase())) {
          return CorrectionResult(
            correctedWord: finalEn,
            languageCode: mapper.languageCode,
            isToTargetLanguage: false,
          );
        }
      }
    }

    // 2. ลองแปลงเป็นภาษาไทยดู
    for (var mapper in _mappers) {
      if (mapper is KoreanMapper && !isKoreanEnabled) continue;
      if (mapper is JapaneseMapper && !isJapaneseEnabled) continue;
      if (mapper is ChineseMapper && !isChineseEnabled) continue;
      if (_hasTargetCharacters(mapper, word)) continue;
      final thConverted = mapper.convertToTarget(word);
      if (thConverted != word) {
        final thFixed = _getCommonTypoCorrection(thConverted) ?? thConverted;
        if (mapper.isCommonWord(thFixed) || (mapper.languageCode != 'th' && mapper.isValidPattern(thFixed))) {
          // ป้องกันการแปลงคำอังกฤษล้วนที่มีความหมายหรือมีรูปแบบปกติอยู่แล้ว
          if (RegExp(r"^[a-zA-Z\d'-]+$").hasMatch(word)) {
            if (_commonEnWords.contains(word.toLowerCase()) || userEnWords.contains(word.toLowerCase())) {
              continue;
            }
            if (!mapper.isCommonWord(thFixed) && word.length >= 4) {
              // ผ่อนปรนหากคำภาษาไทยค่อนข้างยาว (เช่น >= 8 ตัวอักษร) และอินพุตอังกฤษไม่ใช่คำอังกฤษยอดนิยม
              final bool isLongThaiSentence = thFixed.length >= 8 && !isCommonEnglishWord(word);
              if (!isLongThaiSentence) {
                continue; // ไม่แปลงคำอังกฤษสั้นๆ ที่ไม่ใช่คำไทยยอดนิยม เพื่อป้องกัน False Positive
              }
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

  static bool isCommonWord(String word) {
    for (final mapper in _mappers) {
      if (mapper.isCommonWord(word)) {
        return true;
      }
    }
    return false;
  }

  static bool isValidEnglishWordPattern(String word) {
    if (word.isEmpty) return false;
    
    // English words must start with a letter, and can be followed by letters, numbers, apostrophe, and hyphen
    if (!RegExp(r"^[a-zA-Z][a-zA-Z0-9'-]*$").hasMatch(word)) {
      return false;
    }
    
    // Check casing: should be all lowercase, all uppercase, or title case
    final isAllLower = word == word.toLowerCase();
    final isAllUpper = word == word.toUpperCase();
    final isTitleCase = RegExp(r'^[A-Z][a-z]+$').hasMatch(word);
    
    if (!isAllLower && !isAllUpper && !isTitleCase) {
      return false; // Rejects mixed casing like 'gHoKkwm'
    }
    
    return true;
  }

  // ฟังก์ชันวิเคราะห์การแก้ไขคำผิดระดับคำเดี่ยวแบบเข้มงวดเป็นพิเศษ (สำหรับ Continuous Switch)
  static CorrectionResult? checkAndCorrectLocalStrict(String word) {
    lastDecisionSource = 'regex';
    if (word.isEmpty || word.length < 2) return null;

    // ป้องกันการแปลงหากคำเป็นตัวเลขทศนิยม เวอร์ชัน หรือ IP address (เช่น 1.0, 3.14, .50, v1.0.0)
    if (RegExp(r'^v?\d*\.\d+(\.\d+)*$').hasMatch(word)) {
      return null;
    }

    // ป้องกันการแปลงหากคำเป็นโค้ด พาธ อีเมล หรือสัญลักษณ์ระบบ
    if (isCodeOrSymbol(word)) {
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
      if (mapper is KoreanMapper && !isKoreanEnabled) continue;
      if (mapper is JapaneseMapper && !isJapaneseEnabled) continue;
      if (mapper is ChineseMapper && !isChineseEnabled) continue;
      final enConverted = mapper.convertFromTarget(word);
      if (enConverted != word) {
        if (_isThaiBypassWord(word)) {
          continue;
        }
        final enFixed = _getCommonTypoCorrection(enConverted) ?? enConverted;
        
        String finalEn = enFixed;
        if (enFixed.length >= 3 && enFixed[0].toLowerCase() == enFixed[1].toLowerCase()) {
          final sub = enFixed.substring(1);
          if (_commonEnWords.contains(sub.toLowerCase()) || 
              userEnWords.contains(sub.toLowerCase())) {
            finalEn = sub;
          }
        }

        if (_commonEnWords.contains(finalEn.toLowerCase()) || 
            userEnWords.contains(finalEn.toLowerCase())) {
          return CorrectionResult(
            correctedWord: finalEn,
            languageCode: mapper.languageCode,
            isToTargetLanguage: false,
          );
        }
      }
    }

    // 2. ลองแปลงเป็นภาษาไทย
    for (var mapper in _mappers) {
      if (mapper is KoreanMapper && !isKoreanEnabled) continue;
      if (mapper is JapaneseMapper && !isJapaneseEnabled) continue;
      if (mapper is ChineseMapper && !isChineseEnabled) continue;
      if (_hasTargetCharacters(mapper, word)) continue;
      final thConverted = mapper.convertToTarget(word);
      if (thConverted != word) {
        final thFixed = _getCommonTypoCorrection(thConverted) ?? thConverted;
        if (mapper.isCommonWord(thFixed) || (mapper.languageCode != 'th' && mapper.isValidPatternStrict(thFixed, word))) {
          // ป้องกันการแปลงคำอังกฤษล้วนที่มีความหมายอยู่แล้ว
          if (RegExp(r"^[a-zA-Z\d'-]+$").hasMatch(word)) {
            if (_commonEnWords.contains(word.toLowerCase()) || userEnWords.contains(word.toLowerCase())) {
              continue;
            }
            if (!mapper.isCommonWord(thFixed) && word.length >= 4) {
              // ผ่อนปรนหากคำภาษาไทยค่อนข้างยาว (เช่น >= 8 ตัวอักษร) และอินพุตอังกฤษไม่ใช่คำอังกฤษยอดนิยม
              final bool isLongThaiSentence = thFixed.length >= 8 && !isCommonEnglishWord(word);
              if (!isLongThaiSentence) {
                continue;
              }
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

  static bool isCodeOrSymbol(String word) {
    if (!isCodeFilterEnabled) return false;
    if (word.isEmpty) return false;

    // 0. Bypass URLs, Domains, and Emails immediately
    // e.g., google.com, www.google.com, tinymind.app, boy@tinymind.com
    final emailRegExp = RegExp(r'^[a-zA-Z\d._%+-]+@[a-zA-Z\d.-]+\.[a-zA-Z]{2,}$', caseSensitive: false);
    const tldPattern = r'(com|net|org|io|co|th|edu|gov|mil|app|me|ai|xyz|info|biz|cc|tv|so|fm|dev|link|online|site|tech|web|us|uk|jp|cn|tw|sg|hk)';
    final domainRegExp = RegExp('^(www\\.)?([a-zA-Z\\d-]+\\.)+$tldPattern(/\\S*)?\$', caseSensitive: false);
    if (emailRegExp.hasMatch(word) || domainRegExp.hasMatch(word)) {
      return true;
    }

    bool matchesBypass = false;

    // 1. ถ้ามีสัญลักษณ์โปรแกรมมิ่ง/ระบบ/พาธ/ลิงก์ (ยกเว้น . , - และเครื่องหมายวรรคตอนทั่วไป)
    // สัญลักษณ์ที่จะข้าม: / \ @ ~ _ = + * ^ % $ # & | < > [ ] { } ` :
    final codeSymbolRegExp = RegExp(r'[/\@~_=\+\*\^%\$#&|<>\\[\]{}`:]');
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
        if (mapper is KoreanMapper && !isKoreanEnabled) continue;
        if (mapper is JapaneseMapper && !isJapaneseEnabled) continue;
        if (mapper is ChineseMapper && !isChineseEnabled) continue;
        if (_hasTargetCharacters(mapper, word)) continue;
        final thConverted = mapper.convertToTarget(word);
        if (thConverted != word) {
          final thFixed = _getCommonTypoCorrection(thConverted) ?? thConverted;
          final bool useStrict = word.contains('.');
          final bool isValidTh = useStrict ? mapper.isValidPatternStrict(thFixed, word) : mapper.isValidPattern(thFixed);
          if (mapper.isCommonWord(thFixed) || (RegExp(r'^[ก-์\d.]+$').hasMatch(thFixed) && isValidTh)) {
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

  // เช็คว่าคำนั้นพิมพ์ถูกต้องตามเลย์เอาต์แป้นพิมพ์ปัจจุบันอยู่แล้วหรือไม่ เพื่อหลีกเลี่ยงการเรียก AI ฟุ่มเฟือย
  static bool isLikelyCorrectInCurrentLayout(String word) {
    if (word.isEmpty) return true;

    // 1. ถ้าคำนั้นมีภาษาไทยผสมอยู่
    if (RegExp(r'[ก-์]').hasMatch(word)) {
      final thMapper = _mappers.firstWhere((m) => m.languageCode == 'th');
      return thMapper.isValidPatternStrict(word, '');
    }

    // 2. ถ้าเป็นคำภาษาอังกฤษ (ASCII เท่านั้น)
    final lowerWord = word.toLowerCase();
    if (_commonEnWords.contains(lowerWord) || userEnWords.contains(lowerWord)) {
      return true;
    }

    // ตรวจสอบว่ามีเฉพาะตัวอักษร, apostrophe (') และ hyphen (-) เท่านั้น
    if (!RegExp(r"^[a-zA-Z'-]+$").hasMatch(word)) {
      return false;
    }

    // ตรวจสอบว่ามีสระภาษาอังกฤษอย่างน้อยหนึ่งตัวหรือไม่ (รวมตัว y)
    final hasVowel = RegExp(r'[aeiouyAEIOUY]').hasMatch(word);
    if (!hasVowel) return false;

    return true;
  }

  static String _sanitizeAIResult(String rawResult) {
    var trimmed = rawResult.trim();
    trimmed = trimmed.split('<|im_end|>')[0].trim();
    trimmed = trimmed.split('<|im_start|>')[0].trim();
    
    if (trimmed.contains('->')) {
      trimmed = trimmed.split('->').last.trim();
    } else if (trimmed.contains('➔')) {
      trimmed = trimmed.split('➔').last.trim();
    }
    
    final bool hasThai = RegExp(r'[ก-์]').hasMatch(trimmed);
    if (hasThai) {
      trimmed = trimmed.replaceAll('"', '').replaceAll("'", '').replaceAll('`', '');
    } else {
      trimmed = trimmed.replaceAll('"', '').replaceAll('`', '');
      trimmed = trimmed.replaceAll(RegExp(r"^'|'$"), '');
    }
    
    return trimmed.trim();
  }

  // แปลข้อความสลับภาษา (อังกฤษ/เกาหลี/ญี่ปุ่น/จีน <-> ไทย) ด้วยโมเดล AI
  static Future<String?> translateAI(String text) async {
    if (_llama == null) {
      AppLogger.log("TinyMind AI: Model is not loaded yet.");
      return null;
    }
    try {
      _llama!.clear();

      final bool hasKorean = RegExp(r'[\uac00-\ud7af\u1100-\u11ff\u3130-\u318f]').hasMatch(text);
      final bool hasJapanese = RegExp(r'[\u3040-\u309f\u30a0-\u30ff\u4e00-\u9faf]').hasMatch(text);
      final bool hasChinese = !hasJapanese && RegExp(r'[\u4e00-\u9fa5]').hasMatch(text);
      final bool hasThai = RegExp(r'[ก-์]').hasMatch(text);

      String sourceLang = "ภาษาอังกฤษ";
      String targetLang = "ภาษาไทย";
      String exampleSource = "Beautiful";
      String exampleTarget = "สวยงาม";

      if (hasKorean) {
        sourceLang = "ภาษาเกาหลี";
        targetLang = "ภาษาอังกฤษ";
        exampleSource = "안녕하세요";
        exampleTarget = "Hello";
      } else if (hasJapanese) {
        sourceLang = "ภาษาญี่ปุ่น";
        targetLang = "ภาษาอังกฤษ";
        exampleSource = "こんにちは";
        exampleTarget = "Hello";
      } else if (hasChinese) {
        sourceLang = "ภาษาจีน";
        targetLang = "ภาษาอังกฤษ";
        exampleSource = "你好";
        exampleTarget = "Hello";
      } else if (hasThai) {
        sourceLang = "ภาษาไทย";
        targetLang = "ภาษาอังกฤษ";
        exampleSource = "สวัสดี";
        exampleTarget = "Hello";
      }

      final prompt = """<|im_start|>system
คุณคือระบบแปลภาษาที่แม่นยำสูง (Multilingual Translator)
แปลข้อความที่อยู่ในแท็ก <text>...</text> จาก$sourceLangเป็น$targetLang
ให้ส่งคืนเฉพาะข้อความที่แปลเสร็จแล้วเท่านั้น ห้ามอธิบาย ห้ามใส่เครื่องหมายคำพูด หรือข้อความอื่นใดเพิ่มเติม
<|im_end|>
<|im_start|>user
<text>$exampleSource</text><|im_end|>
<|im_start|>assistant
$exampleTarget<|im_end|>
<|im_start|>user
<text>$text</text><|im_end|>
<|im_start|>assistant
""";

      _llama!.setPrompt(prompt);
      final correctedText = await _llama!.generateCompleteText(maxTokens: 100);
      final trimmed = _sanitizeAIResult(correctedText);
      return trimmed.isNotEmpty ? trimmed : null;
    } catch (e) {
      AppLogger.log("TinyMind AI Translation Error: $e");
      return null;
    }
  }

  // ฟังก์ชันวิเคราะห์คำและบริบทแป้นพิมพ์โดยการสลับเลย์เอาต์ทางกายภาพ 100% สำหรับอังกฤษ และใช้ Local AI ซ่อมเฉพาะภาษาไทย
  static Future<String?> checkAndCorrectAI(String sentence) async {
    lastDecisionSource = 'regex';
    if (correctionMode == 'regex') return null; // Regex mode disables AI completely
    if (isCodeOrSymbol(sentence)) {
      return null;
    }
    try {
      // 1. แปลง Layout ด้วยวิธี Programmatic ของเราก่อนเพื่อความแม่นยำ 100% ด้านตำแหน่งแป้น
      final bool isThaiInput = RegExp(r'[ก-์]').hasMatch(sentence);
      final String converted = convertLayout(
        sentence, 
        languageCode: 'th', 
        toTarget: !isThaiInput,
      );

      // 2. หากคำที่ได้แปลงเป็นภาษาอังกฤษ (จากอินพุตภาษาไทย)
      if (isThaiInput) {
        String finalEn = converted;
        for (int len = 1; len <= converted.length ~/ 2; len++) {
          final prefix = converted.substring(0, len);
          final sub = converted.substring(len);
          if (sub.startsWith(prefix)) {
            if (isCommonEnglishWord(sub) || isValidEnglishWordPattern(sub)) {
              finalEn = sub;
              break;
            }
          }
        }

        // ตรวจสอบโครงสร้างคำภาษาอังกฤษเบื้องต้น
        final hasVowel = RegExp(r'[aeiouyAEIOUY]').hasMatch(finalEn);
        final hasInvalidEnChar = RegExp(r'[\[\];,/\\]').hasMatch(finalEn);
        final hasDot = finalEn.contains('.');
        
        if (hasVowel && !hasInvalidEnChar && !hasDot) {
          // ต้องเป็นคำภาษาอังกฤษที่ใช้กันทั่วไป
          if (isCommonEnglishWord(finalEn)) {
            AppLogger.log("TinyMind Heuristic (Regex): English layout conversion bypass AI for '$finalEn'.");
            lastDecisionSource = 'regex';
            return finalEn;
          }
          
          // ถ้าเป็นรูปแบบคำภาษาอังกฤษแต่ไม่ใช่คำใน Dic -> ส่งไปถาม AI
          if (isValidEnglishWordPattern(finalEn)) {
            final String? finalChoice = await identifyCorrectWordAI(finalEn, sentence);
            if (finalChoice == finalEn) {
              lastDecisionSource = 'ai';
              AppLogger.log("TinyMind AI Model (Alibaba Qwen): Confirmed English selection '$finalEn' over Thai '$sentence'");
              return finalEn;
            }
          }
        }
        
        // หากไม่ใช่คำอังกฤษที่ถูกต้อง ถือว่าแปลงเป็นคำอังกฤษไม่สำเร็จ
        return null;
      }

      // 3. หากคำที่ได้แปลงเป็นภาษาไทย (จากอินพุตอังกฤษ)
      final thMapper = _mappers.firstWhere((m) => m.languageCode == 'th');
      if (thMapper.isCommonWord(converted)) {
        AppLogger.log("TinyMind Heuristic (Regex): Thai layout conversion bypass AI for common word '$converted'.");
        lastDecisionSource = 'regex';
        return converted;
      }

      // 4. ถ้าโครงสร้างคำไทยยังก้ำกึ่ง ส่งไปเปรียบเทียบใน identifyCorrectWordAI (เป็น Layout Classifier 3 ตัวเลือก)
      final String? finalChoice = await identifyCorrectWordAI(sentence, converted);
      if (finalChoice == converted) {
        lastDecisionSource = 'ai';
        AppLogger.log("TinyMind AI Model (Alibaba Qwen): Confirmed Thai selection '$converted' over English '$sentence'");
        return converted;
      } else {
        AppLogger.log("TinyMind AI Model (Alibaba Qwen): Rejected Thai spelling '$converted' in favor of English '$sentence'");
        return null;
      }
    } catch (e) {
      AppLogger.log("TinyMind Local AI Inference Error: $e");
    }
    return null;
  }

  // วิเคราะห์คำที่สลับแป้นทั้ง 2 ภาษา และให้ AI ระบุว่าคำไหนถูกต้องตามพจนานุกรม
  static Future<String?> identifyCorrectWordAI(String wordEn, String wordTh) async {
    lastDecisionSource = 'regex';
    if (correctionMode == 'regex') return null; // Regex mode disables AI completely
    // 0. ป้องกันการแปลงหากคำใดคำหนึ่งเป็นโค้ด พาธ อีเมล หรือสัญลักษณ์ระบบ
    if (isCodeOrSymbol(wordEn) || isCodeOrSymbol(wordTh)) {
      return null;
    }

    final String lowerEn = wordEn.toLowerCase();
    
    // 1. ตรวจสอบความถูกต้องของคำอังกฤษ (Heuristics)
    bool isEnValid = true;
    if (lowerEn.isEmpty) {
      isEnValid = false;
    } else {
      // 1.1 ห้ามมีตัวเลขปะปนในคำอังกฤษ (ยกเว้นตัวเลขล้วน)
      if (RegExp(r'\d').hasMatch(lowerEn) && !RegExp(r'^\d+$').hasMatch(lowerEn)) {
        isEnValid = false;
      }
      // 1.2 ห้ามมีเครื่องหมายวรรคตอนหรือสัญลักษณ์ปนในคำอังกฤษ (เช่น ; , . - _ @ :)
      if (RegExp(r'[;,\.\-\_@#\$%\^&\*\(\)\[\]\{\}<>\\/|`~+=:]').hasMatch(lowerEn)) {
        isEnValid = false;
      }
      // 1.3 ถ้าคำยาวตั้งแต่ 3 ตัวอักษรขึ้นไป ต้องมีสระภาษาอังกฤษอย่างน้อย 1 ตัว
      if (lowerEn.length >= 3) {
        final hasVowel = RegExp(r'[aeiouy]').hasMatch(lowerEn);
        if (!hasVowel) {
          isEnValid = false;
        }
      }
      // 1.4 ถ้าไม่ใช่คำอังกฤษยอดนิยมที่สะกดในพจนานุกรม จะต้องมีโครงสร้าง casing ที่เป็นธรรมชาติด้วย
      // เพื่อป้องกันคำคีย์บอร์ดขยะที่กด Shift (เช่น oujxyPs ที่มี P พิมพ์ใหญ่ปนมากลางคำ)
      final bool isCommonEn = _commonEnWords.contains(lowerEn) || userEnWords.contains(lowerEn);
      if (isEnValid && !isCommonEn) {
        if (!isValidEnglishWordPattern(wordEn)) {
          isEnValid = false;
        }
      }
    }

    // 2. ตรวจสอบความถูกต้องของคำไทย (ใช้เกณฑ์เข้มงวดเพื่อความปลอดภัยสูงสุดในการคัดกรอง)
    bool isThValid = false;
    final thMapper = _mappers.firstWhere((m) => m.languageCode == 'th');
    if (wordTh.isNotEmpty) {
      isThValid = thMapper.isValidPatternStrict(wordTh, wordEn);
    }

    // 3. กรองด้วยระบบ Heuristics 3 ชั้น เพื่อความรวดเร็วและปลอดภัยก่อนเรียก AI
    final bool isCommonEn = _commonEnWords.contains(lowerEn) || userEnWords.contains(lowerEn);
    final bool isCommonTh = thMapper.isCommonWord(wordTh);

    // [RULE 1] ป้องกันคำขยะฝั่งอังกฤษ (เช่น 9i;0l หรือ mflv[) และยืนยันคำไทยที่สะกดถูกต้อง
    // ในโหมด AI (correctionMode == 'ai') เราจะไม่ตัดสิทธิ์คำอังกฤษเพื่อให้ AI เป็นผู้พิจารณาโดยตรง
    if (correctionMode != 'ai' && !isEnValid && isThValid && isCommonTh) {
      AppLogger.log("TinyMind Heuristic [RULE 1] (Regex): English '$wordEn' is invalid, selecting Thai '$wordTh' directly.");
      lastDecisionSource = 'regex';
      onAiDecision?.call(wordEn, 'THA ($wordTh)', 'Regex');
      return wordTh;
    }

    // [RULE 2] การสลับเป็นอังกฤษทันทีเมื่อคำไทยสะกดผิดโครงสร้างธรรมชาติอย่างชัดเจน
    // ในโหมด AI (correctionMode == 'ai') เราจะไม่ตัดสิทธิ์คำไทยที่สะกดไม่สมบูรณ์ เพื่อปล่อยให้ AI ได้ตัดสินใจคำสะกดค้าง
    if (correctionMode != 'ai' && isEnValid && !isThValid) {
      AppLogger.log("TinyMind Heuristic [RULE 2 - Invalid Thai] (Regex): Selecting English '$wordEn' directly.");
      lastDecisionSource = 'regex';
      onAiDecision?.call(wordEn, 'ENG ($wordEn)', 'Regex');
      return wordEn;
    }

    if (correctionMode != 'ai' && isEnValid && !thMapper.isValidPatternStrict(wordTh, '')) {
      if (isCommonEn || lowerEn.length < 6) {
        AppLogger.log("TinyMind Heuristic [RULE 2 - Strict Thai Failure] (Regex): Selecting English '$wordEn' directly.");
        lastDecisionSource = 'regex';
        onAiDecision?.call(wordEn, 'ENG ($wordEn)', 'Regex');
        return wordEn;
      }
    }

    // [RULE 3] ยึดภาษาไทยหากคู่คำภาษาอังกฤษไม่ใช่คำจริงในพจนานุกรม
    // ในโหมด AI (correctionMode == 'ai') เราจะไม่ใช้กฎนี้ในการตัดสิทธิ์
    if (correctionMode != 'ai' && isEnValid && isThValid) {
      if (!isCommonEn && isCommonTh) {
        AppLogger.log("TinyMind Heuristic [RULE 3a] (Regex): English '$wordEn' is not in Dict, but Thai '$wordTh' is common. Choosing Thai.");
        lastDecisionSource = 'regex';
        onAiDecision?.call(wordEn, 'THA ($wordTh)', 'Regex');
        return wordTh;
      }
    }

    // 4. ถ้าไม่ถูกต้องทั้งคู่ -> คืนค่า null ทันทีโดยไม่ต้องเรียก AI
    // ในโหมด AI (correctionMode == 'ai') เราจะไม่ตัดสิทธิ์ เพื่อปล่อยให้ AI ได้ตัดสินใจ 100%
    if (correctionMode != 'ai' && !isEnValid && !isThValid) {
      AppLogger.log("TinyMind Heuristic: Both words are invalid (En='$wordEn', Th='$wordTh'). Wait for more input.");
      onAiDecision?.call(wordEn, 'NONE', 'Regex');
      return null;
    }

    // 5. ถ้าไม่ใช่คำทั่วไปทั้งคู่ และความยาวคำสะสมสั้น (< 6 ตัวอักษร) -> คืน null ทันทีเพื่อรอพิมพ์คำให้เสร็จ
    // แต่ถ้าเป็นโหมด AI เราสามารถส่งให้ AI วิเคราะห์ล่วงหน้าได้
    if (correctionMode != 'ai' && !isCommonEn && !isCommonTh && wordEn.length < 6) {
      AppLogger.log("TinyMind Heuristic: Neither word in Dict and length < 6. Wait for more input.");
      onAiDecision?.call(wordEn, 'NONE', 'Regex');
      return null;
    }

    // 6. ถ้าผ่าน Heuristics 3 ชั้นมาได้ ค่อยส่งให้ AI ตัดสินใจ (Qwen 1.5B/1.7B)
    if (_llama == null) {
      AppLogger.log("TinyMind AI: Model is not loaded yet.");
      return null;
    }

    try {
      _llama!.clear();

      final prompt = """<|im_start|>system
You are a strict keyboard layout classifier.
Look at the input and identify which side is a REAL, MEANINGFUL word.

CRITICAL RULES:
1. Meaningful English word (e.g., "code", "hello") -> ENG
2. Meaningful Thai word (e.g., "คอมพิวเตอร์", "ออกมา") -> THA
3. Gibberish / Random keys on both sides (e.g., "vvd,k", "qwxzcv", "ๆไผปแฮ") -> NONE

Response strictly with only one word: ENG, THA, or NONE. No explanation.
<|im_end|>
<|im_start|>user
Candidates -> English: "$wordEn", Thai: "$wordTh"<|im_end|>
<|im_start|>assistant
""";

      _llama!.setPrompt(prompt);
      
      final output = await _llama!.generateCompleteText(maxTokens: 5);
      final fullOutput = output.trim();
      
      // Parse last line
      final lines = fullOutput.split('\n');
      String lastLine = '';
      for (int i = lines.length - 1; i >= 0; i--) {
        if (lines[i].trim().isNotEmpty) {
          lastLine = lines[i].trim().toUpperCase();
          break;
        }
      }
      
      bool isThaiChosen = lastLine.contains("THA") || lastLine.contains("RESULT: THA");
      bool isEnglishChosen = lastLine.contains("ENG") || lastLine.contains("RESULT: ENG");
      
      if (!isThaiChosen && !isEnglishChosen) {
        final words = lastLine.split(RegExp(r'[^A-Z]'));
        isThaiChosen = words.contains("THA") || words.contains("TH");
        isEnglishChosen = words.contains("ENG") || words.contains("EN");
      }

      if (isThaiChosen) {
        if (!isThValid) {
          AppLogger.log("TinyMind AI Safe Guard: Rejected Thai selection '$wordTh' because Thai spelling is invalid.");
          onAiDecision?.call(wordEn, 'NONE (Invalid Thai Safeguard)', 'Local AI');
          return null;
        }
        lastDecisionSource = 'ai';
        AppLogger.log("TinyMind AI Model (Alibaba Qwen): Selected Thai '$wordTh' (AI response: $lastLine)");
        onAiDecision?.call(wordEn, 'THA ($wordTh)', 'Local AI');
        return wordTh;
      } else if (isEnglishChosen) {
        lastDecisionSource = 'ai';
        AppLogger.log("TinyMind AI Model (Alibaba Qwen): Selected English '$wordEn' (AI response: $lastLine)");
        onAiDecision?.call(wordEn, 'ENG ($wordEn)', 'Local AI');
        return wordEn;
      } else {
        AppLogger.log("TinyMind AI Model (Alibaba Qwen): Selected NONE or invalid response (AI response: $lastLine)");
        onAiDecision?.call(wordEn, 'NONE ($lastLine)', 'Local AI');
      }
    } catch (e) {
      AppLogger.log("TinyMind AI identifyCorrectWordAI Error: $e");
    }
    onAiDecision?.call(wordEn, 'NONE', 'Local AI');
    return null;
  }
}
