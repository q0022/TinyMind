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
    // 7. Test CJK layouts disabled by default
    AutocorrectEngine.isKoreanEnabled = false;
    AutocorrectEngine.isJapaneseEnabled = false;
    AutocorrectEngine.isChineseEnabled = false;
    expect(AutocorrectEngine.checkAndCorrectLocal('v2/in'), isNull);
    expect(AutocorrectEngine.checkAndCorrectLocalStrict('v2/in'), isNull);

    // Test CJK layouts enabled
    AutocorrectEngine.isKoreanEnabled = true;
    // Even if enabled, v2/in has 2 and / which should be rejected by stricter Korean validation
    expect(AutocorrectEngine.checkAndCorrectLocal('v2/in'), isNull);
    expect(AutocorrectEngine.checkAndCorrectLocalStrict('v2/in'), isNull);

    // Typing a valid Korean mapped word like 'dkssud' (which maps to Korean 'ㅇㅏㄴㄴㅕㅇ')
    final koResult = AutocorrectEngine.checkAndCorrectLocal('dkssud');
    expect(koResult, isNotNull);
    expect(koResult!.correctedWord, equals('ㅇㅏㄴㄴㅕㅇ'));
    expect(koResult.languageCode, equals('ko'));

    // 8. Test code/symbol bypass for checkAndCorrectAI
    expect(AutocorrectEngine.isCodeOrSymbol('49/1'), isTrue);
    AutocorrectEngine.checkAndCorrectAI('49/1').then((res) {
      expect(res, isNull);
    });

    // 9. Test Thai abbreviation with periods bypass
    expect(AutocorrectEngine.checkAndCorrectLocal('อ.พาน'), isNull);
    expect(AutocorrectEngine.checkAndCorrectLocalStrict('อ.พาน'), isNull);
    expect(AutocorrectEngine.checkAndCorrectLocal('ม.1'), isNull);
    expect(AutocorrectEngine.checkAndCorrectLocalStrict('ม.1'), isNull);
    expect(AutocorrectEngine.isCodeOrSymbol('อ.พาน'), isFalse);
    expect(AutocorrectEngine.isCodeOrSymbol('ม.1'), isFalse);

    // 10. Test Mai Muan constraints & period layout conversion for abbreviations
    expect(AutocorrectEngine.convertLayout('v.rko', languageCode: 'th', toTarget: true), equals('อ.พาน'));
    expect(AutocorrectEngine.convertLayout(',.1', languageCode: 'th', toTarget: true), equals('ม.1'));
    expect(AutocorrectEngine.convertLayout('9.sov\'dt-t', languageCode: 'th', toTarget: true), equals('ต.หนองกะขะ'));
    expect(AutocorrectEngine.convertLayout('fu.0', languageCode: 'th', toTarget: true), equals('ดีใจ'));
    expect(AutocorrectEngine.convertLayout('lt.4h', languageCode: 'th', toTarget: true), equals('สะใภ้'));

    // 11. Test checkAndCorrectAI does not bypass English layout with periods
    AutocorrectEngine.checkAndCorrectAI('อ.พาน').then((res) {
      expect(res, isNull);
    });

    // 12. Test identifyCorrectWordAI chooses abbreviation over invalid English
    AutocorrectEngine.identifyCorrectWordAI('v.rko', 'อ.พาน').then((res) {
      expect(res, equals('อ.พาน'));
    });

    // 13. Test English layout conversion bypass validation rules
    AutocorrectEngine.checkAndCorrectAI('เ็นภาษาไทย').then((res) {
      expect(res, isNull);
    });
    AutocorrectEngine.checkAndCorrectAI('เหี้๊๊๊๊้').then((res) {
      expect(res, isNull);
    });

    // 14. Test English words with apostrophes/hyphens bypass Thai conversion
    expect(AutocorrectEngine.checkAndCorrectLocal("photo'"), isNull);
    expect(AutocorrectEngine.checkAndCorrectLocalStrict("photo'"), isNull);
    expect(AutocorrectEngine.checkAndCorrectLocal("don't"), isNull);
    expect(AutocorrectEngine.checkAndCorrectLocalStrict("don't"), isNull);

    // 15. Test isLikelyCorrectInCurrentLayout invalid Thai patterns (e.g. wrong layout English words)
    expect(AutocorrectEngine.isLikelyCorrectInCurrentLayout('ย้นะนห้นย'), isFalse); // photoshop
    expect(AutocorrectEngine.isLikelyCorrectInCurrentLayout('ทนะ้ำพ'), isFalse); // mother
    expect(AutocorrectEngine.isLikelyCorrectInCurrentLayout('ใหะ้ชน'), isFalse); // github
    expect(AutocorrectEngine.isLikelyCorrectInCurrentLayout('ค่ะ'), isTrue);
    expect(AutocorrectEngine.isLikelyCorrectInCurrentLayout('จ้ะ'), isTrue);
    expect(AutocorrectEngine.isLikelyCorrectInCurrentLayout('น่ะ'), isTrue);
  });
}
