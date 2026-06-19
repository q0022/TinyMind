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

    // 3. Test isLikelyCorrectInCurrentLayout
    expect(AutocorrectEngine.isLikelyCorrectInCurrentLayout('สคริปต์'), isTrue);
    expect(AutocorrectEngine.isLikelyCorrectInCurrentLayout('ฟกอฟืแำ'), isFalse); // invalid Thai pattern
    expect(AutocorrectEngine.isLikelyCorrectInCurrentLayout('biodiversity'), isTrue); // valid English pattern
    expect(AutocorrectEngine.isLikelyCorrectInCurrentLayout('mflv[dkirb,rN'), isFalse); // invalid English pattern (contains [ and ,)

    // 4. Test relaxation of consonant limit in strict check
    final longWordResult = AutocorrectEngine.checkAndCorrectLocalStrict('mflv[dkirb,');
    expect(longWordResult, isNotNull);
    expect(longWordResult!.correctedWord, equals('ทดสอบการพิม'));

    // 5. Test Safe Heuristics (RULE 1, 2, 3) in identifyCorrectWordAI (No model loaded tests)
    // RULE 1: English is invalid (has number/punctuation), Thai is valid -> Choose Thai
    AutocorrectEngine.identifyCorrectWordAI('9i;0l', 'ตรวจสอบ').then((res) {
      expect(res, equals('ตรวจสอบ'));
    });
    AutocorrectEngine.identifyCorrectWordAI('mflv[', 'ทดสอบ').then((res) {
      expect(res, equals('ทดสอบ'));
    });

    // RULE 2: Thai is invalid, English is valid & common or short -> Choose English
    AutocorrectEngine.identifyCorrectWordAI('code', 'แเนำ').then((res) {
      expect(res, equals('code'));
    });

    // 6. Test code bypass cases (:wq and =njv:) and Mai Yamok rules
    AutocorrectEngine.identifyCorrectWordAI(':wq', 'ซไๆ').then((res) {
      expect(res, isNull);
    });
    AutocorrectEngine.identifyCorrectWordAI('=njv:', 'ชื่นอซ').then((res) {
      expect(res, isNull);
    });

    expect(AutocorrectEngine.isLikelyCorrectInCurrentLayout('ๆเด็ก'), isFalse);
    expect(AutocorrectEngine.isLikelyCorrectInCurrentLayout('เดๆ็ก'), isFalse);
    expect(AutocorrectEngine.isLikelyCorrectInCurrentLayout('เด็กๆ'), isTrue);
  });
}
