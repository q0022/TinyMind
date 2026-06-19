part of 'main.dart';

class DashboardTab extends StatelessWidget {
  final _MainDashboardState state;

  const DashboardTab({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.translate('performance_title', state._displayLanguage),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  AppTranslations.translate('performance_subtitle', state._displayLanguage),
                  style: TextStyle(fontSize: 12, color: state._textColorSecondary),
                ),
              ],
            ),
            _buildViewToggle(),
          ],
        ),
        const SizedBox(height: 20),
        
        // Grid สถิติ
        Row(
          children: [
            _buildStatCard(
              AppTranslations.translate('stat_words_corrected', state._displayLanguage),
              "${state._showTodayStatsOnly ? state._todayWordsCorrected : state._wordsCorrected}",
              Icons.spellcheck,
              Colors.indigoAccent,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              AppTranslations.translate('stat_layout_fixed', state._displayLanguage),
              "${state._showTodayStatsOnly ? state._todayLayoutFixed : state._layoutFixed}",
              Icons.keyboard_alt_outlined,
              Colors.cyan,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              AppTranslations.translate('stat_ai_requests', state._displayLanguage),
              "${state._showTodayStatsOnly ? state._todayAiRequests : state._aiRequests}",
              Icons.psychology,
              Colors.purpleAccent,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              AppTranslations.translate('stat_saved_chars', state._displayLanguage),
              "${state._showTodayStatsOnly ? state._todaySavedChars : state._savedChars}",
              Icons.electric_bolt,
              Colors.amber,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              AppTranslations.translate('stat_hotkey_used', state._displayLanguage),
              "${state._showTodayStatsOnly ? state._todayHotkeyCount : state._hotkeyCount}",
              Icons.keyboard_command_key,
              Colors.deepOrangeAccent,
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        Text(
          AppTranslations.translate('recent_activity', state._displayLanguage),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // ตารางประวัติ
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: state._surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: state._borderColor),
            ),
            child: state._recentCorrections.isEmpty
                ? Center(
                    child: Text(
                      AppTranslations.translate('empty_history', state._displayLanguage),
                      style: TextStyle(color: state._textColorTertiary, fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: state._recentCorrections.length,
                    separatorBuilder: (_, __) => Divider(color: state._dividerColor),
                    itemBuilder: (context, index) {
                      final item = state._recentCorrections[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      item['original'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        decoration: TextDecoration.lineThrough,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.arrow_forward_rounded, color: state._textColorTertiary, size: 16),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      item['corrected'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF10B981),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: state._isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    AppTranslations.translate(item['type'] ?? 'Layout', state._displayLanguage),
                                    style: TextStyle(fontSize: 10, color: state._textColorSecondary),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  item['timestamp'] ?? '',
                                  style: TextStyle(fontSize: 11, color: state._textColorTertiary),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
        )
      ],
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: state._surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: state._borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 4),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              val,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -1, color: state._textColorPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: state._textColorSecondary),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    final isDark = state._isDark;
    final displayLanguage = state._displayLanguage;
    
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            label: AppTranslations.translate('today', displayLanguage),
            isSelected: state._showTodayStatsOnly,
            onTap: () {
              state.setState(() {
                state._showTodayStatsOnly = true;
              });
            },
          ),
          _buildToggleButton(
            label: AppTranslations.translate('lifetime', displayLanguage),
            isSelected: !state._showTodayStatsOnly,
            onTap: () {
              state.setState(() {
                state._showTodayStatsOnly = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = state._isDark;
    final primaryColor = Color(state._primaryColorValue);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }
}
