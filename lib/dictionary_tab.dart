part of 'main.dart';

class DictionaryTab extends StatelessWidget {
  final _MainDashboardState state;

  const DictionaryTab({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.translate('dict_title', state._displayLanguage),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          AppTranslations.translate('dict_subtitle', state._displayLanguage),
          style: TextStyle(fontSize: 12, color: state._textColorSecondary),
        ),
        const SizedBox(height: 20),

        // Segmented Tab Selector
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: state._isDark ? const Color(0xFF1E1E2E) : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    state.updateState(() {
                      state._dictionarySubTab = 0;
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: state._dictionarySubTab == 0
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      AppTranslations.translate('dict_tab_ignore', state._displayLanguage),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: state._dictionarySubTab == 0
                            ? Colors.white
                            : state._textColorSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    state.updateState(() {
                      state._dictionarySubTab = 1;
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: state._dictionarySubTab == 1
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      AppTranslations.translate('dict_tab_shortcuts', state._displayLanguage),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: state._dictionarySubTab == 1
                            ? Colors.white
                            : state._textColorSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        if (state._dictionarySubTab == 0) ...[
          // ช่องพิมพ์เพิ่มคำศัพท์ละเว้น
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: state._ignoreWordController,
                  decoration: InputDecoration(
                    hintText: AppTranslations.translate('dict_input_hint', state._displayLanguage),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: state._surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: state._borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: state._borderColor),
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: (_) => _addIgnoreWord(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _addIgnoreWord,
                icon: const Icon(Icons.add, size: 18),
                label: Text(AppTranslations.translate('dict_add_btn', state._displayLanguage), style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // รายชื่อคำละเว้น
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: state._surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: state._borderColor),
              ),
              child: state._ignoredWords.isEmpty
                  ? Center(
                      child: Text(
                        AppTranslations.translate('dict_empty', state._displayLanguage),
                        style: TextStyle(color: state._textColorTertiary, fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: state._ignoredWords.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final word = state._ignoredWords[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: state._isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                word,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                onPressed: () => _removeIgnoreWord(word),
                                splashRadius: 16,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ] else ...[
          // ช่องพิมพ์เพิ่มคีย์ลัดคำย่อ
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: state._shortcutKeyController,
                  decoration: InputDecoration(
                    hintText: AppTranslations.translate('shortcut_key_hint', state._displayLanguage),
                    labelText: AppTranslations.translate('shortcut_key_label', state._displayLanguage),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: state._surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: state._borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: state._borderColor),
                    ),
                    labelStyle: TextStyle(fontSize: 11, color: state._textColorSecondary),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: state._shortcutValueController,
                  decoration: InputDecoration(
                    hintText: AppTranslations.translate('shortcut_val_hint', state._displayLanguage),
                    labelText: AppTranslations.translate('shortcut_val_label', state._displayLanguage),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: state._surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: state._borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: state._borderColor),
                    ),
                    labelStyle: TextStyle(fontSize: 11, color: state._textColorSecondary),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: (_) => _addShortcut(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _addShortcut,
                icon: const Icon(Icons.add, size: 16),
                label: Text(AppTranslations.translate('shortcut_add_btn', state._displayLanguage), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // รายชื่อคีย์ลัดคำย่อ
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: state._surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: state._borderColor),
              ),
              child: state._textShortcuts.isEmpty
                  ? Center(
                      child: Text(
                        AppTranslations.translate('shortcut_empty', state._displayLanguage),
                        style: TextStyle(color: state._textColorTertiary, fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: state._textShortcuts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final key = state._textShortcuts.keys.elementAt(index);
                        final val = state._textShortcuts[key]!;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: state._isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(fontSize: 13, color: state._textColorPrimary),
                                    children: [
                                      TextSpan(text: "$key ", style: const TextStyle(fontWeight: FontWeight.bold)),
                                      TextSpan(text: "➔ ", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                                      TextSpan(text: val, style: TextStyle(color: state._textColorSecondary)),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                onPressed: () => _removeShortcut(key),
                                splashRadius: 16,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ],
    );
  }

  void _addIgnoreWord() {
    final text = state._ignoreWordController.text.trim().toLowerCase();
    if (text.isNotEmpty && !state._ignoredWords.contains(text)) {
      state.updateState(() {
        state._ignoredWords.add(text);
        state._ignoreWordController.clear();
      });
      state._saveSetting('ignoredWords', state._ignoredWords);
    }
  }

  void _removeIgnoreWord(String word) {
    state.updateState(() {
      state._ignoredWords.remove(word);
      final lowerWord = word.trim().toLowerCase();
      if (AutocorrectEngine.userEnWords.contains(lowerWord)) {
        AutocorrectEngine.userEnWords.remove(lowerWord);
        SharedPreferences.getInstance().then((prefs) {
          prefs.setStringList('userEnWords', AutocorrectEngine.userEnWords.toList());
        });
      }
    });
    state._saveSetting('ignoredWords', state._ignoredWords);
  }

  void _addShortcut() {
    final key = state._shortcutKeyController.text.trim();
    final val = state._shortcutValueController.text.trim();
    if (key.isNotEmpty && val.isNotEmpty) {
      state.updateState(() {
        state._textShortcuts[key] = val;
        state._shortcutKeyController.clear();
        state._shortcutValueController.clear();
      });
      state._saveShortcuts();
    }
  }

  void _removeShortcut(String key) {
    state.updateState(() {
      state._textShortcuts.remove(key);
    });
    state._saveShortcuts();
  }
}
