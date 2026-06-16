import 'language_mapper.dart';

class ThaiMapper implements LanguageMapper {
  @override
  String get languageCode => 'th';

  @override
  String get languageName => 'Thai';

  // ตารางแมปปิ้ง English -> Thai (Kedmanee Layout)
  static const Map<String, String> _enToThMap = {
    'q': 'ๆ', 'w': 'ไ', 'e': 'ำ', 'r': 'พ', 't': 'ะ', 'y': 'ั', 'u': 'ี', 'i': 'ร', 'o': 'น', 'p': 'ย', '[': 'บ', ']': 'ล', '\\': 'ฃ',
    'a': 'ฟ', 's': 'ห', 'd': 'ก', 'f': 'ด', 'g': 'เ', 'h': '้', 'j': '่', 'k': 'า', 'l': 'ส', ';': 'ว', "'": 'ง',
    'z': 'ผ', 'x': 'ป', 'c': 'แ', 'v': 'อ', 'b': 'ิ', 'n': 'ื', 'm': 'ท', ',': 'ม', '.': 'ใ', '/': 'ฝ',
    'Q': '๐', 'W': '"', 'E': 'ฎ', 'R': 'ฑ', 'T': 'ธ', 'Y': 'ํ', 'U': '๊', 'I': 'ณ', 'O': 'ฯ', 'P': 'ญ', '{': 'ฐ', '}': '', '|': 'ฅ',
    'A': 'ฤ', 'S': 'ฆ', 'D': 'ฏ', 'F': 'โ', 'G': 'ฌ', 'H': '็', 'J': '๋', 'K': 'ษ', 'L': 'ศ', ':': 'ซ', '"': 'ศ',
    'Z': '(', 'X': ')', 'C': 'ฉ', 'V': 'ฮ', 'B': 'ฺ', 'N': '์', 'M': '?', '<': 'ฒ', '>': 'ฬ', '?': 'ฦ',
    '1': 'ๅ', '2': '/', '3': '-', '4': 'ภ', '5': 'ถ', '6': 'ุ', '7': 'ึ', '8': 'ค', '9': 'ต', '0': 'จ', '-': 'ข', '=': 'ช',
    '!': '+', '@': '๑', '#': '๒', '\$': '๓', '%': '๔', '^': 'ู', '&': '฿', '*': '๕', '(': '๖', ')': '๗', '_': '๘', '+': '๙',
  };

  static final Map<String, String> _thToEnMap = _enToThMap.map((k, v) => MapEntry(v, k));

  // รายชื่อคำภาษาไทยยอดนิยม
  static const Set<String> _commonThWords = {
    'สวัสดี', 'ครับ', 'ค่ะ', 'และ', 'หรือ', 'แต่', 'เป็น', 'มี', 'ได้', 'ให้', 'การ', 'ความ', 'ที่', 'ใน', 'ของ', 'เพื่อ', 'จะ', 'มา', 'ไป',
    'ทำ', 'เรียน', 'ทำงาน', 'ด้วย', 'จาก', 'นี้', 'นั้น', 'บอก', 'พูด', 'ถาม', 'คิด', 'ดู', 'เห็น', 'อยาก', 'ชอบ', 'รัก', 'คน', 'บ้าน',
    'เมือง', 'วัน', 'เวลา', 'ปี', 'เดือน', 'งาน', 'เงิน', 'น้ำ', 'ไฟ', 'ใจ', 'ตัว', 'อย่าง', 'เช่น', 'เรา', 'เขา', 'เธอ', 'มัน', 'ใคร',
    'อะไร', 'ไหน', 'เมื่อไหร่', 'อย่างไร', 'ทำไม', 'เนื่องจาก', 'เพราะ', 'ดังนั้น', 'จึง', 'ก็', 'ยัง', 'แล้ว', 'อีก', 'กว่า', 'มาก',
    'น้อย', 'ดี', 'ชั่ว', 'สูง', 'ต่ำ', 'ใหญ่', 'เล็ก', 'ใหม่', 'เก่า', 'เร็ว', 'ช้า', 'ก่อน', 'หลัง', 'แรก', 'สุดท้าย', 'จริง', 'เท็จ',
    'ใช่', 'ไม่ใช่', 'เข้าใจ', 'ไม่เข้าใจ', 'ขอบคุณ', 'ขอโทษ', 'ยินดี', 'ตกลง', 'ยกเลิก', 'บันทึก', 'เปิด', 'ปิด', 'สร้าง', 'ลบ',
    'เพิ่ม', 'ลด', 'ค้นหา', 'กรุณา', 'โปรด', 'ช่วย', 'หน่อย', 'นะ', 'คะ', 'ด้วยนะ', 'เขียน', 'โค้ด', 'โปรแกรม', 'คอมพิวเตอร์',
    'จ้า', 'อิอิ', '555', '5555', '55555',
  };

  @override
  String convertToTarget(String input) {
    final sb = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      sb.write(_enToThMap[char] ?? char);
    }
    return sb.toString();
  }

  @override
  String convertFromTarget(String input) {
    final sb = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      sb.write(_thToEnMap[char] ?? char);
    }
    return sb.toString();
  }

  @override
  bool isValidPattern(String text) {
    if (text.isEmpty) return false;
    if (RegExp(r'[ิีึืั็ํุู][ิีึืั็ํุู]').hasMatch(text)) return false;
    if (RegExp(r'[่้๊๋์][่้๊๋์]').hasMatch(text)) return false;
    
    final firstChar = text[0];
    if (RegExp(r'[ิีึืั็ํุู่้๊๋์]').hasMatch(firstChar)) return false;

    // ตัวลากข้าง (ๅ) ต้องตามหลัง ฤ หรือ ฦ เท่านั้น
    if (text.contains('ๅ')) {
      for (int i = 0; i < text.length; i++) {
        if (text[i] == 'ๅ') {
          if (i == 0 || !(text[i - 1] == 'ฤ' || text[i - 1] == 'ฦ')) {
            return false;
          }
        }
      }
    }

    for (var thWord in _commonThWords) {
      if (text.contains(thWord) && text.length - thWord.length <= 2) {
        return true;
      }
    }

    return RegExp(r'[ก-ฮ]+[ะ-์]*').hasMatch(text);
  }

  @override
  bool isValidPatternStrict(String thText, String originalEnText) {
    if (thText.isEmpty || thText.length < 3) return false;

    // ต้องมีเฉพาะตัวอักษรไทย/วรรณยุกต์
    if (!RegExp(r'^[ก-์\d]+$').hasMatch(thText)) return false;

    // ตัวลากข้าง (ๅ) ต้องตามหลัง ฤ หรือ ฦ เท่านั้น
    if (thText.contains('ๅ')) {
      for (int i = 0; i < thText.length; i++) {
        if (thText[i] == 'ๅ') {
          if (i == 0 || !(thText[i - 1] == 'ฤ' || thText[i - 1] == 'ฦ')) {
            return false;
          }
        }
      }
    }

    // ตัวแรกต้องเป็นพยัญชนะต้น หรือสระหน้าเท่านั้น
    final firstChar = thText[0];
    if (!RegExp(r'^[ก-ฮเแโใไ]').hasMatch(firstChar)) return false;

    // ห้ามลงท้ายด้วยสระบน/ล่างบางตัว หรือตัวการันต์/พินทุเดี่ยวๆ
    if (RegExp(r'[ั็ฺ]$').hasMatch(thText)) return false;

    // ห้ามสระบน/ล่าง หรือวรรณยุกต์ ซ้อนกันเอง
    if (RegExp(r'[ิีึืั็ํุู][ิีึืั็ํุู]').hasMatch(thText)) return false;
    if (RegExp(r'[่้๊๋์][่้๊๋์]').hasMatch(thText)) return false;
    if (RegExp(r'[่้๊๋์][ิีึืั็ํุู]').hasMatch(thText)) return false; // วรรณยุกต์มาก่อนสระไม่ได้

    // สระบน/ล่างและสระท้ายคำห้ามติดกัน
    if (RegExp(r'[ิีึืั็ํุู][ะาำ]|[ะาำ][ิีึืั็ํุู]').hasMatch(thText)) return false;

    // สระท้ายคำซ้อนกันเองไม่ได้
    if (RegExp(r'[ะาำ][ะาำ]').hasMatch(thText)) return false;

    // สระหน้า (เแโใไ) ต้องมีพยัญชนะตามหลัง (ยกเว้นตัวสุดท้ายของประโยคระหว่างพิมพ์)
    for (int i = 0; i < thText.length - 1; i++) {
      if (['เ', 'แ', 'โ', 'ใ', 'ไ'].contains(thText[i])) {
        if (!RegExp(r'[ก-ฮ]').hasMatch(thText[i + 1])) {
          return false;
        }
      }
    }

    // ตัวการันต์ต้องอยู่หลังพยัญชนะ
    if (thText.endsWith('์')) {
      if (thText.length < 2 || !RegExp(r'[ก-ฮ]').hasMatch(thText[thText.length - 2])) {
        return false;
      }
    }

    // ตรวจสอบลำดับพยัญชนะติดต่อกัน (Consonant sequence)
    final matches = RegExp(r'[ก-ฮๆฯ]{4,}').allMatches(thText);
    for (final match in matches) {
      final seq = match.group(0)!;
      if (seq.length >= 5) return false; // พยัญชนะซ้อนกัน 5 ตัวขึ้นไปไม่มีในภาษาไทยปกติ
      if (seq.length == 4) {
        // พยัญชนะซ้อนกัน 4 ตัว ต้องมี รร (รหัน), ว, อ หรือเป็นคำว่า พรหม
        if (!seq.contains('รร') &&
            !seq.contains('ว') &&
            !seq.contains('อ') &&
            seq != 'พรหม') {
          return false;
        }
      }
    }

    // คำที่ยาวตั้งแต่ 5 ตัวอักษรขึ้นไป ต้องมีสระหรือวรรณยุกต์อย่างน้อย 1 ตัว
    if (thText.length >= 5 && !RegExp(r'[เแโใไิีึืั็ํุูะาำ่้๊๋์]').hasMatch(thText)) {
      return false;
    }

    return true;
  }

  @override
  bool isCommonWord(String text) {
    return _commonThWords.contains(text);
  }
}
