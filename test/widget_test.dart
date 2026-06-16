import 'package:flutter_test/flutter_test.dart';
import 'package:tinymind/autocorrect_engine.dart';

void main() {
  test('AutocorrectEngine local correction checks', () {
    // 1. Version numbers, decimals, and IP addresses should be ignored (return null)
    expect(AutocorrectEngine.checkAndCorrectLocal('v1.0.0'), isNull);
    expect(AutocorrectEngine.checkAndCorrectLocal('1.0'), isNull);
    expect(AutocorrectEngine.checkAndCorrectLocal('3.14'), isNull);
    expect(AutocorrectEngine.checkAndCorrectLocal('192.168.1.1'), isNull);
    expect(AutocorrectEngine.checkAndCorrectLocal('.50'), isNull);
    
    // Strict version checks
    expect(AutocorrectEngine.checkAndCorrectLocalStrict('v1.0.0'), isNull);
    expect(AutocorrectEngine.checkAndCorrectLocalStrict('1.0'), isNull);

    // 2. Typos that map to valid Thai words should be corrected
    // 'fu.0' in English layout maps to 'ดีใจ' (ด - ี - ใ - จ)
    final result = AutocorrectEngine.checkAndCorrectLocal('fu.0');
    expect(result, isNotNull);
    expect(result!.correctedWord, equals('ดีใจ'));
    expect(result.isToTargetLanguage, isTrue);
    expect(result.languageCode, equals('th'));

    // Strict correction for 'fu.0'
    final resultStrict = AutocorrectEngine.checkAndCorrectLocalStrict('fu.0');
    expect(resultStrict, isNotNull);
    expect(resultStrict!.correctedWord, equals('ดีใจ'));

    // 'f7d' in English layout maps to 'ดึก' (ด - ึ - ก)
    final result2 = AutocorrectEngine.checkAndCorrectLocal('f7d');
    expect(result2, isNotNull);
    expect(result2!.correctedWord, equals('ดึก'));
  });
}
