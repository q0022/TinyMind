import 'language_mapper.dart';

class KoreanMapper implements LanguageMapper {
  @override
  String get languageCode => 'ko';

  @override
  String get languageName => 'Korean';

  static const Map<String, String> _enToKoMap = {
    'q': 'ㅂ', 'w': 'ㅈ', 'e': 'ㄷ', 'r': 'ㄱ', 't': 'ㅅ', 'y': 'ㅛ', 'u': 'ㅕ', 'i': 'ㅑ', 'o': 'ㅐ', 'p': 'ㅔ',
    'a': 'ㅁ', 's': 'ㄴ', 'd': 'ㅇ', 'f': 'ㄹ', 'g': 'ㅎ', 'h': 'ㅗ', 'j': 'ㅓ', 'k': 'ㅏ', 'l': 'ㅣ',
    'z': 'ㅋ', 'x': 'ㅌ', 'c': 'ㅊ', 'v': 'ㅍ', 'b': 'ㅠ', 'n': 'ㅜ', 'm': 'ㅡ',
    'Q': 'ㅃ', 'W': 'ㅉ', 'E': 'ㄸ', 'R': 'ㄲ', 'T': 'ㅆ', 'O': 'ㅒ', 'P': 'ㅖ',
    'A': 'ㅁ', 'S': 'ㄴ', 'D': 'ㅇ', 'F': 'ㄹ', 'G': 'ㅎ', 'H': 'ㅗ', 'J': 'ㅓ', 'K': 'ㅏ', 'L': 'ㅣ',
    'Z': 'ㅋ', 'X': 'ㅌ', 'C': 'ㅊ', 'V': 'ㅍ', 'B': 'ㅠ', 'N': 'ㅜ', 'M': 'ㅡ',
  };

  static final Map<String, String> _koToEnMap = _enToKoMap.map((k, v) => MapEntry(v, k));

  // Common Korean words in raw Jamo for pattern verification fallback
  static const Set<String> _commonKoWords = {
    'ㅇㅏㄴㄴㅕㅇㅎㅏㅅㅔㅇㅛ', 'ㄱㅏㅁㅅㅏㅎㅏㅂㄴㅣㄷㅏ', 'ㄱㅗㅁㅏㅂㅅㅡㅂㄴㅣㄷㅏ', 'ㅈㅗㅣㅅㅗㅇㅎㅏㅂㄴㅣㄷㅏ', 'ㅁㅣㅇㅏㄴㅎㅏㅂㄴㅣㄷㅏ', 'ㄴㅔ', 'ㅇㅏㄴㅣㅇㅛ', 'ㅈㅓㄱㅣㅇㅛ',
    'ㅅㅏㄹㅏㅁ', 'ㅇㅜㄹㅣ', 'ㄴㅏㄹㅏ', 'ㅊㅣㄴㄱㅜ', 'ㅅㅏㄹㅏㅇ', 'ㅅㅐㅇㄱㅏㄱ', 'ㅇㅗㄴㅡㄹ', 'ㄴㅐㅇㅣㄹ', 'ㅇㅓㅈㅔ', 'ㅈㅣㄱㅡㅁ', 'ㅅㅣㄱㅏㄴ',
    'ㅎㅏㄱㅗ', 'ㄱㅡㄹㅣㄱㅗ', 'ㅎㅏㅈㅣㅁㅏㄴ', 'ㄱㅡㄹㅐㅅㅓ', 'ㅈㅣㄴㅉㅏ', 'ㅈㅓㅇㅁㅏㄹ', 'ㅁㅐㅇㅜ', 'ㅇㅏㅈㅜ', 'ㅈㅗㄱㅡㅁ', 'ㅁㅏㄴㅎㅇㅣ',
    'ㅍㅡㄹㅗㄱㅡㄹㅐㅁ', 'ㅋㅗㄷㅡ', 'ㅋㅓㅁㅍㅠㅌㅓ', 'ㅇㅜㅔㅂㅅㅏㅇㅣㅌㅡ', 'ㅇㅐㅍㅡㄹㄹㅣㅋㅔㅇㅣㅅㅕㄴ', 'ㄷㅔㅇㅣㅌㅓ', 'ㅅㅓㅂㅓ', 'ㅋㅡㄹㄹㅏㅇㅣㅇㅓㄴㅌㅡ',
    'ㅇㅏㄴㄴㅕㅇ'
  };

  @override
  String convertToTarget(String input) {
    final sb = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      sb.write(_enToKoMap[char] ?? char);
    }
    return sb.toString();
  }

  @override
  String convertFromTarget(String input) {
    final sb = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      sb.write(_koToEnMap[char] ?? char);
    }
    return sb.toString();
  }

  @override
  bool isValidPattern(String text) {
    if (text.isEmpty) return false;
    
    // If it contains combined Hangul syllables, check if it's fully Hangul
    if (RegExp(r'[\uac00-\ud7af]').hasMatch(text)) {
      return RegExp(r'^[ㄱ-ㅎㅏ-ㅣ\uac00-\ud7af]+$').hasMatch(text);
    }
    
    for (final word in _commonKoWords) {
      if (text.contains(word)) return true;
    }
    
    // Allow common repeating slang/emoticons
    if (RegExp(r'^(ㅋ{2,}|ㅎ{2,}|ㅠ{2,}|ㅜ{2,}|ㅇ{2,}|ㄴ{2,}|ㅂ{2,}|ㅃ{2,}|ㄷ{2,}|ㅈ{2,}|ㅅ{2,}|ㅊ{2,})$').hasMatch(text)) {
      return true;
    }
    
    // For raw Jamo, enforce valid syllable structure: (C+ V{1,2} C{0,2})+
    return RegExp(r'^([ㄱ-ㅎ]+[ㅏ-ㅣ]{1,2}[ㄱ-ㅎ]{0,2})+$').hasMatch(text);
  }

  @override
  bool isValidPatternStrict(String text, String originalEnText) {
    return isValidPattern(text);
  }

  @override
  bool isCommonWord(String text) {
    return _commonKoWords.contains(text);
  }
}
