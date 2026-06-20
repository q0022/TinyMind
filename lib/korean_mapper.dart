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

  // Common Korean words for pattern verification fallback
  static const Set<String> _commonKoWords = {
    '안녕하세요', '감사합니다', '고맙습니다', '죄송합니다', '미안합니다', '네', '아니요', '저기요',
    '사람', '우리', '나라', '친구', '사랑', '생각', '오늘', '내일', '어제', '지금', '시간',
    '하고', '그리고', '하지만', '그래서', '진짜', '정말', '매우', '아주', '조금', '많이',
    '프로그램', '코드', '컴퓨터', '웹사이트', '애플리케이션', '데이터', '서버', '클라이언트',
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
    // Check if it contains Hangul letters or syllables
    for (final word in _commonKoWords) {
      if (text.contains(word)) return true;
    }
    return RegExp(r'[ㄱ-ㅎㅏ-ㅣ가-힣]').hasMatch(text);
  }

  @override
  bool isValidPatternStrict(String text, String originalEnText) {
    if (text.isEmpty) return false;
    // Must be fully Hangul characters
    return RegExp(r'^[ㄱ-ㅎㅏ-ㅣ가-힣\d\s\p{P}]+$', unicode: true).hasMatch(text);
  }

  @override
  bool isCommonWord(String text) {
    return _commonKoWords.contains(text);
  }
}
