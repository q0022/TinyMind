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
        
        // ช่องพิมพ์เพิ่มคำศัพท์
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
        
        // รายชื่อคำที่เก็บไว้
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
    });
    state._saveSetting('ignoredWords', state._ignoredWords);
  }
}
