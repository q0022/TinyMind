import 'package:flutter_test/flutter_test.dart';
import 'package:tinymind/autocorrect_engine.dart';
import 'package:tinymind/thai_mapper.dart';

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
    final thMapper = ThaiMapper();
    expect(thMapper.isValidPatternStrict('ทดสอบการพิม', 'mflv[dkirb,'), isTrue);

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
    expect(AutocorrectEngine.convertLayout('5hk.=', languageCode: 'th', toTarget: true), equals('ถ้าใช'));
    expect(AutocorrectEngine.convertLayout('5hk.=h', languageCode: 'th', toTarget: true), equals('ถ้าใช้'));
    expect(AutocorrectEngine.convertLayout('.=', languageCode: 'th', toTarget: true), equals('ใช'));
    expect(AutocorrectEngine.convertLayout('.=h', languageCode: 'th', toTarget: true), equals('ใช้'));
    expect(AutocorrectEngine.convertLayout(',.8.', languageCode: 'th', toTarget: true), equals('ม.ค.'));

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

    // 14. Test English words with apostrophes/hyphens/dots bypass Thai conversion
    expect(AutocorrectEngine.checkAndCorrectLocal("photo'"), isNull);
    expect(AutocorrectEngine.checkAndCorrectLocalStrict("photo'"), isNull);
    expect(AutocorrectEngine.checkAndCorrectLocal("don't"), isNull);
    expect(AutocorrectEngine.checkAndCorrectLocalStrict("don't"), isNull);
    expect(AutocorrectEngine.checkAndCorrectLocal("cs.ID"), isNull);
    expect(AutocorrectEngine.checkAndCorrectLocalStrict("cs.ID"), isNull);
    expect(AutocorrectEngine.checkAndCorrectLocal("google.com"), isNull);
    expect(AutocorrectEngine.checkAndCorrectLocalStrict("google.com"), isNull);
    expect(AutocorrectEngine.isLikelyCorrectInCurrentLayout("แห.ณฏ"), isFalse);

    // 15. Test isLikelyCorrectInCurrentLayout invalid Thai patterns (e.g. wrong layout English words)
    expect(AutocorrectEngine.isLikelyCorrectInCurrentLayout('ย้นะนห้นย'), isFalse); // photoshop
    expect(AutocorrectEngine.isLikelyCorrectInCurrentLayout('ทนะ้ำพ'), isFalse); // mother
    expect(AutocorrectEngine.isLikelyCorrectInCurrentLayout('ใหะ้ชน'), isFalse); // github
    expect(AutocorrectEngine.isLikelyCorrectInCurrentLayout('ค่ะ'), isTrue);
    expect(AutocorrectEngine.isLikelyCorrectInCurrentLayout('จ้ะ'), isTrue);
    expect(AutocorrectEngine.isLikelyCorrectInCurrentLayout('น่ะ'), isTrue);

    // 16. Test double-letter mixed layout correction (e.g., ่json -> json)
    final jsonResult = AutocorrectEngine.checkAndCorrectLocal('่json');
    expect(jsonResult, isNotNull);
    expect(jsonResult!.correctedWord, equals('json'));

    // 17. Test meaningless English word that converts to invalid Thai spelling (e.g., mbk -> ทิา) is not corrected
    final mbkRes = AutocorrectEngine.checkAndCorrectLocal('mbk');
    if (mbkRes != null) {
      print('DEBUG MBK: correctedWord=${mbkRes.correctedWord}, lang=${mbkRes.languageCode}');
    }
    expect(mbkRes, isNull);

    // 18. Test AI mode bypasses heuristics (RULE 3 & Rule 4)
    AutocorrectEngine.correctionMode = 'ai';
    AutocorrectEngine.identifyCorrectWordAI('9i;0l', 'แเนำ').then((res) {
      expect(res, isNull);
    });
    AutocorrectEngine.correctionMode = 'hybrid'; // Reset

    // 19. Test checkAndCorrectAI does not bypass English layout for Thai words converting to non-dictionary English patterns (e.g., นิดหน่อย -> obfsojvp)
    AutocorrectEngine.checkAndCorrectAI('นิดหน่อย').then((res) {
      expect(res, isNull);
    });
    // 20. Test isValidEnglishWordPattern correctly rejects words with digits (like 0yfwx) and accepts clean English words
    expect(AutocorrectEngine.isValidEnglishWordPattern('0yfwx'), isFalse);
    expect(AutocorrectEngine.isValidEnglishWordPattern('hello'), isTrue);
    expect(AutocorrectEngine.isValidEnglishWordPattern('don\'t'), isTrue);
    expect(AutocorrectEngine.isValidEnglishWordPattern('first-class'), isTrue);

    // Test SARA AM version typo local dictionary match
    final vResult = AutocorrectEngine.checkAndCorrectLocalStrict('อำพหรนื');
    expect(vResult, isNotNull, reason: 'Expected local dict match for version typo');
    expect(vResult!.correctedWord, equals('version'));
    expect(vResult.isToTargetLanguage, isFalse);

    // 21. Test Thai backspace counting logic for 3 app modes (Chromium, Flutter, Native)
    int countPhysicalThaiBackspaces(String text, {String appMode = 'native'}) {
      if (text.isEmpty) return 0;
      
      int backspaces = 0;
      final consonantReg = RegExp(r'[ก-ฮ]');
      final combiningReg = RegExp(r'[ิีึืุูั็่้๊๋์ํฺำ]');
      
      int i = 0;
      while (i < text.length) {
        final char = text[i];
        
        if (consonantReg.hasMatch(char)) {
          int j = i + 1;
          List<String> marks = [];
          while (j < text.length && combiningReg.hasMatch(text[j])) {
            marks.add(text[j]);
            j++;
          }
          
          if (marks.isEmpty) {
            backspaces += 1;
          } else {
            bool isValid = true;
            final vowels = marks.where((m) => RegExp(r'[ิีึืุูั็ํำ]').hasMatch(m)).toList();
            if (vowels.length > 1) isValid = false;
            
            final tones = marks.where((m) => RegExp(r'[่้๊๋์]').hasMatch(m)).toList();
            if (tones.length > 1) isValid = false;
            
            if (marks.length >= 2) {
              final firstIsTone = RegExp(r'[่้๊๋์]').hasMatch(marks[0]);
              final secondIsVowel = RegExp(r'[ิีึืุูั็ํำ]').hasMatch(marks[1]);
              if (firstIsTone && secondIsVowel) isValid = false;
            }
            
            if (isValid) {
              backspaces += 1;
              final hasVowel = marks.any((m) => RegExp(r'[ิีึืุูั็ํ]').hasMatch(m));
              final hasTone = marks.any((m) => RegExp(r'[่้๊๋์]').hasMatch(m));
              if (hasVowel && !hasTone && (appMode == 'chromium' || appMode == 'flutter')) {
                backspaces += 1;
              }
              if (marks.contains('ำ')) {
                backspaces += (appMode == 'chromium') ? 2 : 1;
              }
            } else {
              backspaces += 1 + marks.length;
              if (appMode == 'chromium') {
                final saraAmCount = marks.where((m) => m == 'ำ').length;
                backspaces += saraAmCount;
              }
            }
          }
          i = j;
        } else if (combiningReg.hasMatch(char)) {
          backspaces += 1;
          if (char == 'ำ' && appMode == 'chromium') {
            backspaces += 1;
          }
          i++;
        } else {
          backspaces += 1;
          i++;
        }
      }
      return backspaces;
    }

    // Chromium Deletion Mode Tests
    expect(countPhysicalThaiBackspaces('อำ', appMode: 'chromium'), equals(3));
    expect(countPhysicalThaiBackspaces('ทำ', appMode: 'chromium'), equals(3));
    expect(countPhysicalThaiBackspaces('ย่ำ', appMode: 'chromium'), equals(4));
    expect(countPhysicalThaiBackspaces('อำพหณนย', appMode: 'chromium'), equals(8));
    expect(countPhysicalThaiBackspaces('รืหะพีแะ', appMode: 'chromium'), equals(8));

    // Flutter Deletion Mode Tests
    expect(countPhysicalThaiBackspaces('อำ', appMode: 'flutter'), equals(2));
    expect(countPhysicalThaiBackspaces('ทำ', appMode: 'flutter'), equals(2));
    expect(countPhysicalThaiBackspaces('ย่ำ', appMode: 'flutter'), equals(3));
    expect(countPhysicalThaiBackspaces('อำพหณนย', appMode: 'flutter'), equals(7)); // ดสีะะำพ (flutter) typo mapping
    expect(countPhysicalThaiBackspaces('รืหะพีแะ', appMode: 'flutter'), equals(8)); // single vowel 'รื' & 'พี' takes 2 backspaces each in Flutter

    // Native macOS Deletion Mode Tests
    expect(countPhysicalThaiBackspaces('อำ', appMode: 'native'), equals(2));
    expect(countPhysicalThaiBackspaces('ทำ', appMode: 'native'), equals(2));
    expect(countPhysicalThaiBackspaces('ย่ำ', appMode: 'native'), equals(3));
    expect(countPhysicalThaiBackspaces('อำพหณนย', appMode: 'native'), equals(7));
    expect(countPhysicalThaiBackspaces('รืหะพีแะ', appMode: 'native'), equals(6));
  });
}


