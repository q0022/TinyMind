import 'language_mapper.dart';

class JapaneseMapper implements LanguageMapper {
  @override
  String get languageCode => 'ja';

  @override
  String get languageName => 'Japanese';

  static const Map<String, String> _enToJaMap = {
    'q': 'た', 'w': 'て', 'e': 'い', 'r': 'す', 't': 'か', 'y': 'ん', 'u': 'な', 'i': 'に', 'o': 'ら', 'p': 'せ',
    'a': 'ち', 's': 'と', 'd': 'し', 'f': 'は', 'g': 'き', 'h': 'く', 'j': 'ま', 'k': 'の', 'l': 'り',
    'z': 'つ', 'x': 'さ', 'c': 'そ', 'v': 'ひ', 'b': 'こ', 'n': 'み', 'm': 'も',
    'Q': 'た', 'W': 'て', 'E': 'ぃ', 'R': 'す', 'T': 'か', 'Y': 'ん', 'U': 'な', 'I': 'に', 'O': 'ら', 'P': 'せ',
    'A': 'ち', 'S': 'と', 'D': 'し', 'F': 'は', 'G': 'き', 'H': 'く', 'J': 'ま', 'K': 'の', 'L': 'り',
    'Z': 'っ', 'X': 'さ', 'C': 'そ', 'V': 'ひ', 'B': 'こ', 'N': 'み', 'M': 'も',
  };

  static final Map<String, String> _jaToEnMap = _enToJaMap.map((k, v) => MapEntry(v, k));

  // Common Japanese words for pattern verification fallback
  static const Set<String> _commonJaWords = {
    'こんにちは', 'ありがとう', 'すみません', 'はい', 'いいえ', 'これ', 'それ', 'あれ',
    'わたし', 'あなた', 'ともだち', 'にほんご', 'えいご', 'きょう', 'あした', 'きのう',
    'です', 'ます', 'ください', 'します', 'ある', 'いる', 'ない', 'いい', 'わるい',
    'プログラム', 'コード', 'コンピュータ', 'サーバー', 'ウェブサイト', 'アプリ',
  };

  @override
  String convertToTarget(String input) {
    final sb = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      sb.write(_enToJaMap[char] ?? char);
    }
    return sb.toString();
  }

  @override
  String convertFromTarget(String input) {
    final sb = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      sb.write(_jaToEnMap[char] ?? char);
    }
    return sb.toString();
  }

  @override
  bool isValidPattern(String text) {
    if (text.isEmpty) return false;
    for (final word in _commonJaWords) {
      if (text.contains(word)) return true;
    }
    // Must be fully Japanese characters (Hiragana, Katakana, Kanji, long vowel mark)
    return RegExp(r'^[ぁ-んァ-ン一-龠ー]+$').hasMatch(text);
  }

  @override
  bool isValidPatternStrict(String text, String originalEnText) {
    if (text.isEmpty) return false;
    // Must be fully Japanese characters (Hiragana, Katakana, Kanji, long vowel mark)
    return RegExp(r'^[ぁ-んァ-ン一-龠ー]+$').hasMatch(text);
  }

  @override
  bool isCommonWord(String text) {
    return _commonJaWords.contains(text);
  }
}
