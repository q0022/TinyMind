import '../autocorrect_engine.dart';

abstract class SlashCommand {
  String get trigger;
  Future<String?> execute(String argument);
}

class TranslateShortCommand implements SlashCommand {
  @override
  String get trigger => '/t';

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
  Future<String?> execute(String argument) async {
    if (argument.isEmpty) return null;
    return await AutocorrectEngine.translateAI(argument);
  }
}
