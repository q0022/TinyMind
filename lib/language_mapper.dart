abstract class LanguageMapper {
  /// รหัสภาษา เช่น 'th', 'ko', 'ru'
  String get languageCode;

  /// ชื่อภาษา เช่น 'Thai', 'Korean', 'Russian'
  String get languageName;

  /// แปลงเลย์เอาต์แป้นพิมพ์จากภาษาต้นทาง (อังกฤษ) ไปยังภาษาเป้าหมาย
  String convertToTarget(String input);

  /// แปลงเลย์เอาต์แป้นพิมพ์จากภาษาเป้าหมายกลับมาเป็นอังกฤษ
  String convertFromTarget(String input);

  /// ตรวจสอบรูปแบบคำทั่วไปในภาษานี้
  bool isValidPattern(String text);

  /// ตรวจสอบรูปแบบคำในภาษานี้แบบเข้มงวดเป็นพิเศษ
  bool isValidPatternStrict(String text, String originalEnText);

  /// ตรวจสอบว่าเป็นคำที่พบบ่อยในภาษานี้หรือไม่
  bool isCommonWord(String text);
}

class CorrectionResult {
  /// คำที่ได้รับการแก้ไขเสร็จแล้ว
  final String correctedWord;

  /// รหัสภาษาที่ได้รับการแก้ไข
  final String languageCode;

  /// เป็นการแปลงไปยังภาษาเป้าหมาย (true) หรือสลับกลับมาภาษาอังกฤษ (false)
  final bool isToTargetLanguage;

  CorrectionResult({
    required this.correctedWord,
    required this.languageCode,
    required this.isToTargetLanguage,
  });
}
