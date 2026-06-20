import 'language_mapper.dart';

class ChineseMapper implements LanguageMapper {
  @override
  String get languageCode => 'zh';

  @override
  String get languageName => 'Chinese';

  // Chinese Pinyin uses standard QWERTY layout, so no layout mapping is needed.
  @override
  String convertToTarget(String input) => input;

  @override
  String convertFromTarget(String input) => input;

  // Common Chinese words for pattern verification fallback
  static const Set<String> _commonZhWords = {
    '你好', '谢谢', '对不起', '没关系', '不客气', '再见', '是', '不是', '有', '没有',
    '我们', '你们', '他们', '这个', '那个', '什么', '哪里', '什么时候', '为什么', '怎么',
    '今天', '明天', '昨天', '现在', '时间', '人', '朋友', '家', '学校', '工作',
    '程序', '代码', '计算机', '电脑', '服务器', '网站', '软件', '应用', '数据',
  };

  @override
  bool isValidPattern(String text) {
    if (text.isEmpty) return false;
    for (final word in _commonZhWords) {
      if (text.contains(word)) return true;
    }
    // Check if it contains Hanzi (Chinese characters)
    return RegExp(r'[\u4e00-\u9fa5]').hasMatch(text);
  }

  @override
  bool isValidPatternStrict(String text, String originalEnText) {
    if (text.isEmpty) return false;
    // Must be fully Chinese characters (Hanzi, digits, spaces, punctuation)
    return RegExp(r'^[\u4e00-\u9fa5\d\s\p{P}]+$', unicode: true).hasMatch(text);
  }

  @override
  bool isCommonWord(String text) {
    return _commonZhWords.contains(text);
  }
}
