import '../autocorrect_engine.dart';

abstract class SlashCommand {
  String get trigger;
  String get thaiTrigger;
  Future<String?> execute(String argument);
}

class TranslateShortCommand implements SlashCommand {
  @override
  String get trigger => '/t';

  @override
  String get thaiTrigger => 'ฝะ';

  @override
  Future<String?> execute(String argument) async {
    if (argument.isEmpty) return null;
    return await AutocorrectEngine.translateAI(argument);
  }
}

class TranslateCommand implements SlashCommand {
  @override
  String get trigger => '/translate';

  @override
  String get thaiTrigger => 'ฝะพฟืหสฟะำ';

  @override
  Future<String?> execute(String argument) async {
    if (argument.isEmpty) return null;
    return await AutocorrectEngine.translateAI(argument);
  }
}
