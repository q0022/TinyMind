import 'dart:convert';
import 'dart:io';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'language_mapper.dart';
import 'thai_mapper.dart';

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
    'css', 'cut', 'dart', 'data', 'database', 'day', 'debug', 'deepmind', 'delete', 'deploy', 'descendant', 'design', 'detail', 'details', 'dev',
    'developer', 'development', 'device', 'did', 'differ', 'different', 'directory', 'do', 'does', 'done', 'double', 'down', 'draw', 'during', 'each',
    'early', 'earth', 'ease', 'east', 'easy', 'eat', 'either', 'else', 'end', 'enough', 'env', 'environment', 'error', 'even', 'evenly',
    'ever', 'every', 'everyone', 'everything', 'example', 'export', 'face', 'facebook', 'fact', 'failure', 'fall', 'far', 'fast', 'feel', 'few',
    'field', 'file', 'filter', 'final', 'find', 'first', 'five', 'flex', 'flutter', 'fly', 'folder', 'follow', 'font', 'food', 'for',
    'force', 'form', 'forward', 'found', 'four', 'framework', 'friend', 'from', 'front', 'full', 'function', 'game', 'gave', 'get', 'git',
    'github', 'gitlab', 'give', 'given', 'go', 'golang', 'gold', 'good', 'google', 'got', 'graphql', 'great', 'green', 'grid', 'ground',
    'group', 'grow', 'grpc', 'guest', 'had', 'half', 'hand', 'happen', 'hard', 'has', 'have', 'he', 'head', 'hear', 'heard',
    'height', 'held', 'hello', 'help', 'her', 'here', 'high', 'him', 'himself', 'his', 'hold', 'home', 'hot',
    'hour', 'house', 'how', 'however', 'html', 'http', 'https', 'hundred', 'i', 'icon', 'idea', 'if', 'ig', 'image', 'import',
    'important', 'in', 'inches', 'ind', 'index', 'info', 'init', 'instagram', 'install', 'integer', 'intel', 'internet', 'into', 'ios', 'is',
    'it', 'item', 'items', 'its', 'itself', 'java', 'javascript', 'json', 'just', 'justify', 'keep', 'kept', 'key', 'keys', 'kind',
    'knew', 'know', 'known', 'kotlin', 'land', 'large', 'last', 'late', 'later', 'laugh', 'lay', 'layout', 'lead', 'learn', 'least',
    'leave', 'left', 'length', 'less', 'let', 'letter', 'library', 'life', 'light', 'like', 'line', 'linux', 'list', 'listen', 'lists',
    'little', 'live', 'lived', 'load', 'loading', 'local', 'login', 'logout', 'long', 'look', 'love', 'low', 'mac', 'macos', 'made',
    'main', 'make', 'many', 'map', 'maps', 'margin', 'mark', 'match', 'may', 'me', 'mean', 'measure', 'media', 'member', 'men',
    'method', 'microsoft', 'might', 'mind', 'miss', 'model', 'module', 'more', 'morning', 'most', 'mother', 'mountain', 'move', 'much', 'multi',
    'must', 'my', 'myself', 'name', 'near', 'need', 'network', 'never', 'new', 'next', 'night', 'no', 'north', 'not', 'note',
    'nothing', 'notice', 'now', 'number', 'object', 'objectivec', 'of', 'off', 'often', 'oh', 'ok', 'okay', 'old', 'on', 'once',
    'one', 'only', 'open', 'option', 'options', 'or', 'order', 'other', 'our', 'out', 'outside', 'over', 'own', 'page', 'paper',
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
    'soon', 'sorry', 'sort', 'sound', 'south', 'space', 'speak', 'special', 'spell', 'spend', 'spoke', 'spot', 'spread', 'spring', 'stack',
    'staging', 'start', 'static', 'status', 'stop', 'stretch', 'string', 'strong', 'student', 'study', 'subject', 'submit', 'substance',
    'success', 'such', 'sudden', 'suffice', 'sugar', 'suit', 'summer', 'sun', 'supply', 'support', 'sure', 'surface', 'surprise',
    'sweet', 'swift', 'swim', 'system', 'table', 'tail', 'take', 'taken', 'talk', 'tall', 'tape', 'task', 'taste', 'teach',
    'team', 'teeth', 'tell', 'ten', 'term', 'terminal', 'test', 'than', 'thank', 'thanks', 'that', 'the', 'their', 'them',
    'theme', 'themselves', 'then', 'there', 'these', 'they', 'thick', 'thin', 'thing', 'think', 'third', 'this', 'those',
    'though', 'thought', 'thousand', 'three', 'threw', 'through', 'throw', 'thus', 'tie', 'tight', 'tiktok', 'time',
    'tiny', 'tinymind', 'tire', 'to', 'today', 'together', 'told', 'tomorrow', 'too', 'took', 'top', 'total', 'touch',
    'toward', 'town', 'toy', 'trace', 'track', 'trade', 'train', 'travel', 'tree', 'trial', 'triangle', 'trip', 'trouble',
    'true', 'trunk', 'try', 'tube', 'turn', 'twenty', 'two', 'type', 'typescript', 'under', 'understand', 'unit',
    'until', 'up', 'update', 'upon', 'uri', 'url', 'us', 'use', 'user', 'usual', 'validate', 'valley',
    'value', 'values', 'various', 'verb', 'very', 'view', 'visit', 'voice', 'vowel', 'wagon', 'wait',
    'walk', 'wall', 'want', 'war', 'warm', 'warn', 'warning', 'was', 'wash', 'watch', 'water',
    'wave', 'way', 'we', 'weak', 'wear', 'weather', 'week', 'weight', 'well', 'went', 'were',
    'west', 'wfh', 'what', 'wheel', 'when', 'where', 'whether', 'which', 'while', 'white',
    'who', 'whole', 'whom', 'whose', 'why', 'wide', 'widget', 'width', 'wife', 'wifi',
    'wild', 'will', 'win', 'wind', 'window', 'windows', 'wing', 'winter', 'wire', 'wise',
    'wish', 'with', 'within', 'without', 'woman', 'wonder', 'wood', 'word', 'work',
    'worker', 'world', 'worry', 'worse', 'worth', 'would', 'wrap', 'write', 'written',
    'wrong', 'wrote', 'xml', 'yaml', 'yard', 'year', 'yellow', 'yes', 'yesterday',
    'yet', 'you', 'young', 'your', 'yours', 'yourself', 'yourselves', 'youth', 'youtube',
    'zero', 'zone',
  };

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
        Llama.libraryPath = "/Users/q0022/.pub-cache/hosted/pub.dev/llama_cpp_dart-0.2.2/dist/Llama.xcframework/macos-arm64/Llama.framework/Llama";
      }

      print("TinyMind: Loading local GGUF model: $modelPath");
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
      print("TinyMind: Local GGUF model loaded successfully!");
    } catch (e) {
      print("TinyMind: Failed to load local Llama model: $e");
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
        print("TinyMind: Disposed local GGUF model");
      } catch (e) {
        print("TinyMind: Error disposing Llama: $e");
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

    // 1. ตรวจสอบกรณีพิมพ์อังกฤษแต่ลืมเปลี่ยนภาษา (เช่น "l;lfu" -> "สวัสดี" หรือ "wfh" -> "ทำงาน")
    if (RegExp(r"^[a-zA-Z\d;\[\]\\,.//=?`~\-_=+!@#\$%^&*()']+$").hasMatch(word)) {
      if (_commonEnWords.contains(word.toLowerCase())) {
        return null;
      }

      for (var mapper in _mappers) {
        final converted = mapper.convertToTarget(word);
        if (mapper.isCommonWord(converted) || mapper.isValidPattern(converted)) {
          return CorrectionResult(
            correctedWord: converted,
            languageCode: mapper.languageCode,
            isToTargetLanguage: true,
          );
        }
      }
    } 
    // 2. ตรวจสอบกรณีพิมพ์ภาษาอื่นแต่ลืมเปลี่ยนภาษา (เช่น "ไพำ" -> "wfh")
    else {
      for (var mapper in _mappers) {
        // ภาษาไทยจะใช้ regex ก-์ ของมัน ภาษาอื่นจะกำหนดต่างกัน
        final pattern = mapper.languageCode == 'th' ? r'^[ก-์\d]+$' : '';
        if (pattern.isNotEmpty && RegExp(pattern).hasMatch(word)) {
          if (mapper.isCommonWord(word)) {
            continue; // เป็นคำที่ถูกต้องของภาษานั้นแล้ว ไม่ต้องแปลงกลับเป็น Eng
          }

          final enConverted = mapper.convertFromTarget(word);
          if (_commonEnWords.contains(enConverted.toLowerCase()) || _isValidEnglishAbbreviation(enConverted)) {
            return CorrectionResult(
              correctedWord: enConverted,
              languageCode: mapper.languageCode,
              isToTargetLanguage: false,
            );
          }
        }
      }
    }

    return null;
  }

  static bool isCommonEnglishWord(String word) {
    if (word.isEmpty) return false;
    return _commonEnWords.contains(word.toLowerCase());
  }

  // ฟังก์ชันวิเคราะห์การแก้ไขคำผิดระดับคำเดี่ยวแบบเข้มงวดเป็นพิเศษ (สำหรับ Continuous Switch)
  static CorrectionResult? checkAndCorrectLocalStrict(String word) {
    if (word.isEmpty || word.length < 2) return null;

    // ตรวจสอบกรณีพิมพ์อังกฤษแต่ลืมเปลี่ยนภาษา
    if (RegExp(r"^[a-zA-Z\d;\[\]\\,.//=?`~\-_=+!@#\$%^&*()']+$").hasMatch(word)) {
      if (_commonEnWords.contains(word.toLowerCase())) {
        return null;
      }

      for (var mapper in _mappers) {
        final converted = mapper.convertToTarget(word);
        if (mapper.isCommonWord(converted) || mapper.isValidPatternStrict(converted, word)) {
          return CorrectionResult(
            correctedWord: converted,
            languageCode: mapper.languageCode,
            isToTargetLanguage: true,
          );
        }
      }
    }

    return null;
  }

  static bool _isValidEnglishAbbreviation(String text) {
    if (text.isEmpty) return false;
    if (text.length >= 2 && text.length <= 4) {
      return RegExp(r'^[a-zA-Z]+$').hasMatch(text);
    }
    return false;
  }

  // ฟังก์ชันวิเคราะห์ประโยคและบริบทโดยใช้ Local llama.cpp (Embedded AI)
  static Future<String?> checkAndCorrectAI(String sentence) async {
    if (_llama == null) {
      print("TinyMind AI: Model is not loaded yet.");
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
      print("TinyMind Local AI Inference Error: $e");
    }
    return null;
  }
}
