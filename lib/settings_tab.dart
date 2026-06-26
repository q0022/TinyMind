part of 'main.dart';

class SettingsTab extends StatelessWidget {
  final _MainDashboardState state;

  const SettingsTab({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppTranslations.translate('settings_title', state._displayLanguage),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            AppTranslations.translate('settings_subtitle', state._displayLanguage),
            style: TextStyle(fontSize: 12, color: state._textColorSecondary),
          ),
          const SizedBox(height: 24),
          
          // สิทธิ์ Accessibility
          if (!state._hasAccessibility)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        AppTranslations.translate('accessibility_warning_title', state._displayLanguage),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppTranslations.translate('accessibility_warning_desc', state._displayLanguage),
                    style: TextStyle(fontSize: 11, color: state._isDark ? Colors.white70 : Colors.amber.shade900),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: state._requestAccessibilityPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      elevation: 0,
                    ),
                    child: Text(
                      AppTranslations.translate('accessibility_btn', state._displayLanguage),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),

          // บล็อกการตั้งค่าทั่วไป
          _buildSettingsBlock(AppTranslations.translate('general_group', state._displayLanguage), [
            _buildSwitchTile(
              AppTranslations.translate('autocorrect_enable', state._displayLanguage),
              AppTranslations.translate('autocorrect_enable_desc', state._displayLanguage),
              state._isEnabled,
              (val) {
                state.updateState(() {
                  state._isEnabled = val;
                  state._saveSetting('isEnabled', val);
                  state._updateSystemTrayMenu();
                });
              },
            ),
            Divider(color: state._dividerColor),
            _buildSwitchTile(
              AppTranslations.translate('launch_at_login', state._displayLanguage),
              AppTranslations.translate('launch_at_login_desc', state._displayLanguage),
              state._isAutoStart,
              (val) async {
                state.updateState(() {
                  state._isAutoStart = val;
                  state._saveSetting('isAutoStart', val);
                });
                if (val) {
                  await LaunchAtStartup.instance.enable();
                } else {
                  await LaunchAtStartup.instance.disable();
                }
              },
            ),
          ]),
          
          const SizedBox(height: 20),

          _buildSettingsBlock(AppTranslations.translate('keyboard_layouts_group', state._displayLanguage), [
            _buildSwitchTile(
              AppTranslations.translate('auto_detect_os_keyboards', state._displayLanguage),
              AppTranslations.translate('auto_detect_os_keyboards_desc', state._displayLanguage),
              state._useOSKeyboards,
              (val) {
                state.updateState(() {
                  state._useOSKeyboards = val;
                  state._saveSetting('useOSKeyboards', val);
                  state._updateActiveKeyboards();
                });
              },
            ),
            if (state._useOSKeyboards) ...[
              Divider(color: state._dividerColor),
              _buildReadOnlyLayoutTile(
                AppTranslations.translate('korean_layout', state._displayLanguage),
                state._isKoreanEnabled 
                    ? AppTranslations.translate('keyboard_detected', state._displayLanguage)
                    : AppTranslations.translate('keyboard_not_detected', state._displayLanguage),
                state._isKoreanEnabled,
              ),
              Divider(color: state._dividerColor),
              _buildReadOnlyLayoutTile(
                AppTranslations.translate('japanese_layout', state._displayLanguage),
                state._isJapaneseEnabled 
                    ? AppTranslations.translate('keyboard_detected', state._displayLanguage)
                    : AppTranslations.translate('keyboard_not_detected', state._displayLanguage),
                state._isJapaneseEnabled,
              ),
              Divider(color: state._dividerColor),
              _buildReadOnlyLayoutTile(
                AppTranslations.translate('chinese_layout', state._displayLanguage),
                state._isChineseEnabled 
                    ? AppTranslations.translate('keyboard_detected', state._displayLanguage)
                    : AppTranslations.translate('keyboard_not_detected', state._displayLanguage),
                state._isChineseEnabled,
              ),
            ] else ...[
              Divider(color: state._dividerColor),
              _buildSwitchTile(
                AppTranslations.translate('enable_korean', state._displayLanguage),
                AppTranslations.translate('enable_korean_desc', state._displayLanguage),
                state._isKoreanEnabled,
                (val) {
                  state.updateState(() {
                    state._isKoreanEnabled = val;
                    state._saveSetting('isKoreanEnabled', val);
                    AutocorrectEngine.isKoreanEnabled = val;
                  });
                },
              ),
              Divider(color: state._dividerColor),
              _buildSwitchTile(
                AppTranslations.translate('enable_japanese', state._displayLanguage),
                AppTranslations.translate('enable_japanese_desc', state._displayLanguage),
                state._isJapaneseEnabled,
                (val) {
                  state.updateState(() {
                    state._isJapaneseEnabled = val;
                    state._saveSetting('isJapaneseEnabled', val);
                    AutocorrectEngine.isJapaneseEnabled = val;
                  });
                },
              ),
              Divider(color: state._dividerColor),
              _buildSwitchTile(
                AppTranslations.translate('enable_chinese', state._displayLanguage),
                AppTranslations.translate('enable_chinese_desc', state._displayLanguage),
                state._isChineseEnabled,
                (val) {
                  state.updateState(() {
                    state._isChineseEnabled = val;
                    state._saveSetting('isChineseEnabled', val);
                    AutocorrectEngine.isChineseEnabled = val;
                  });
                },
              ),
            ]
          ]),
          
          const SizedBox(height: 20),

          _buildSettingsBlock(AppTranslations.translate('appearance_group', state._displayLanguage), [
            _buildSwitchTile(
              AppTranslations.translate('dark_mode', state._displayLanguage),
              AppTranslations.translate('dark_mode_desc', state._displayLanguage),
              state._isDarkMode,
              (val) {
                state._changeThemeMode(val);
              },
            ),
            Divider(color: state._dividerColor),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.translate('primary_color', state._displayLanguage),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildThemeColorDot(const Color(0xFF6366F1), "Indigo"),
                      const SizedBox(width: 12),
                      _buildThemeColorDot(const Color(0xFF06B6D4), "Cyan"),
                      const SizedBox(width: 12),
                      _buildThemeColorDot(const Color(0xFF10B981), "Emerald"),
                      const SizedBox(width: 12),
                      _buildThemeColorDot(const Color(0xFFF97316), "Orange"),
                      const SizedBox(width: 12),
                      _buildThemeColorDot(const Color(0xFFF43F5E), "Rose"),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: state._dividerColor),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.translate('display_language', state._displayLanguage),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: state._displayLanguage,
                    style: TextStyle(fontSize: 13, color: state._textColorPrimary),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    dropdownColor: state._isDark ? const Color(0xFF1E1E2E) : Colors.white,
                    items: [
                      DropdownMenuItem(
                        value: 'th',
                        child: Text('ภาษาไทย (Thai)', style: TextStyle(fontSize: 13, color: state._textColorPrimary)),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Text('English', style: TextStyle(fontSize: 13, color: state._textColorPrimary)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        state.updateState(() {
                          state._displayLanguage = val;
                          state._saveSetting('displayLanguage', val);
                          state._updateSystemTrayMenu();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ]),
          
          const SizedBox(height: 20),

          _buildSettingsBlock(AppTranslations.translate('hotkey_group', state._displayLanguage), [
            _buildSwitchTile(
              AppTranslations.translate('custom_hotkey_enable', state._displayLanguage),
              AppTranslations.translate('custom_hotkey_enable_desc', state._displayLanguage),
              state._useCustomHotkey,
              (val) {
                state.updateState(() {
                  state._useCustomHotkey = val;
                  state._saveSetting('useCustomHotkey', val);
                  state._updateNativeHotkey();
                });
              },
            ),
            if (state._useCustomHotkey) ...[
              Divider(color: state._dividerColor),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslations.translate('modifier_label', state._displayLanguage),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: state._textColorSecondary),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: state._hotkeyModifier,
                            style: TextStyle(fontSize: 13, color: state._textColorPrimary),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            dropdownColor: state._isDark ? const Color(0xFF1E1E2E) : Colors.white,
                            items: [
                              DropdownMenuItem(value: 'Shift', child: Text('Shift', style: TextStyle(fontSize: 13, color: state._textColorPrimary))),
                              DropdownMenuItem(value: 'Option', child: Text('Option / Alt', style: TextStyle(fontSize: 13, color: state._textColorPrimary))),
                              DropdownMenuItem(value: 'Control', child: Text('Control', style: TextStyle(fontSize: 13, color: state._textColorPrimary))),
                              DropdownMenuItem(value: 'Command', child: Text('Command', style: TextStyle(fontSize: 13, color: state._textColorPrimary))),
                              DropdownMenuItem(value: 'None', child: Text(AppTranslations.translate('none_modifier', state._displayLanguage), style: TextStyle(fontSize: 13, color: state._textColorPrimary))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                state.updateState(() {
                                    state._hotkeyModifier = val;
                                    state._saveSetting('hotkeyModifier', val);
                                    state._updateNativeHotkey();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslations.translate('key_label', state._displayLanguage),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: state._textColorSecondary),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: state._hotkeyKey,
                            style: TextStyle(fontSize: 13, color: state._textColorPrimary),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            dropdownColor: state._isDark ? const Color(0xFF1E1E2E) : Colors.white,
                            items: [
                              DropdownMenuItem(value: 'Backspace', child: Text('Backspace', style: TextStyle(fontSize: 13, color: state._textColorPrimary))),
                              DropdownMenuItem(value: 'CapsLock', child: Text('Caps Lock', style: TextStyle(fontSize: 13, color: state._textColorPrimary))),
                              DropdownMenuItem(value: 'Space', child: Text('Spacebar', style: TextStyle(fontSize: 13, color: state._textColorPrimary))),
                              DropdownMenuItem(value: 'GraveAccent', child: Text('Grave Accent (~)', style: TextStyle(fontSize: 13, color: state._textColorPrimary))),
                              DropdownMenuItem(value: 'Esc', child: Text('Escape (Esc)', style: TextStyle(fontSize: 13, color: state._textColorPrimary))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                state.updateState(() {
                                  state._hotkeyKey = val;
                                  state._saveSetting('hotkeyKey', val);
                                  state._updateNativeHotkey();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ]),
          
          const SizedBox(height: 20),

          _buildSettingsBlock(AppTranslations.translate('engine_group', state._displayLanguage), [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.translate('correction_mode_title', state._displayLanguage),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppTranslations.translate('correction_mode_desc', state._displayLanguage),
                    style: TextStyle(fontSize: 11, color: state._textColorSecondary),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: state._correctionMode,
                    style: TextStyle(fontSize: 13, color: state._textColorPrimary),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    dropdownColor: state._isDark ? const Color(0xFF1E1E2E) : Colors.white,
                    items: [
                      DropdownMenuItem(
                        value: 'regex',
                        child: Text(
                          AppTranslations.translate('mode_regex', state._displayLanguage),
                          style: TextStyle(fontSize: 13, color: state._textColorPrimary),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'ai',
                        child: Text(
                          AppTranslations.translate('mode_ai', state._displayLanguage),
                          style: TextStyle(fontSize: 13, color: state._textColorPrimary),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'hybrid',
                        child: Text(
                          AppTranslations.translate('mode_hybrid', state._displayLanguage),
                          style: TextStyle(fontSize: 13, color: state._textColorPrimary),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        state.updateState(() {
                          state._correctionMode = val;
                          state._saveSetting('correctionMode', val);
                          AutocorrectEngine.correctionMode = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            Divider(color: state._dividerColor),
            _buildSwitchTile(
              AppTranslations.translate('fast_local_engine', state._displayLanguage),
              AppTranslations.translate('fast_local_engine_desc', state._displayLanguage),
              state._isLocalCorrection,
              (val) {
                state.updateState(() {
                  state._isLocalCorrection = val;
                  state._saveSetting('isLocalCorrection', val);
                });
              },
            ),
            Divider(color: state._dividerColor),
            _buildSwitchTile(
              AppTranslations.translate('local_ai_engine', state._displayLanguage),
              AppTranslations.translate('local_ai_engine_desc', state._displayLanguage),
              state._isAiCorrection,
              (val) async {
                if (val && state._ggufModelPath.isEmpty) {
                  try {
                    final path = await state._checkAndPrepareModel();
                    state.updateState(() {
                      state._ggufModelPath = path;
                      state._isAiCorrection = true;
                    });
                    state._saveSetting('ggufModelPath', path);
                    state._saveSetting('isAiCorrection', true);
                    await state._initLocalLlama(path);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${AppTranslations.translate('model_prepare_failed', state._displayLanguage)}$e")),
                    );
                  }
                  return;
                }
                state.updateState(() {
                  state._isAiCorrection = val;
                  state._saveSetting('isAiCorrection', val);
                });
                if (val) {
                  await state._initLocalLlama(state._ggufModelPath);
                } else {
                  AutocorrectEngine.disposeAI();
                }
              },
            ),
            Divider(color: state._dividerColor),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppTranslations.translate('gguf_model_label', state._displayLanguage), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            state._ggufModelPath.isEmpty 
                                ? (state._isDownloading ? AppTranslations.translate('gguf_model_downloading', state._displayLanguage) : AppTranslations.translate('gguf_model_loading_auto', state._displayLanguage))
                                : state._ggufModelPath.split('/').last,
                            style: TextStyle(
                              fontSize: 11, 
                              color: state._ggufModelPath.isEmpty && !state._isDownloading 
                                  ? (state._isDark ? Colors.amber : Colors.amber.shade900) 
                                  : state._textColorSecondary
                            ),
                          ),
                          if (state._ggufModelPath.isNotEmpty && state._ggufModelPath.contains('smollm2')) ...[
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: state._isModelLoading || state._isDownloading 
                                  ? null 
                                  : state._upgradeToQwenModel,
                              child: Text(
                                AppTranslations.translate('upgrade_to_qwen_btn', state._displayLanguage),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (!state._isDownloading)
                        OutlinedButton.icon(
                          onPressed: state._isModelLoading ? null : state._pickGgufModel,
                          icon: const Icon(Icons.folder_open_rounded, size: 16),
                          label: Text(
                            AppTranslations.translate('gguf_model_pick_btn', state._displayLanguage),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                    ],
                  ),
                  if (state._isDownloading) ...[
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state._downloadProgressText,
                                style: TextStyle(fontSize: 11, color: state._textColorPrimary, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: state._downloadProgress,
                            color: Theme.of(context).colorScheme.primary,
                            backgroundColor: state._isDark ? Colors.white10 : Colors.black.withOpacity(0.1),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ] else if (state._isModelLoading) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppTranslations.translate('gguf_model_loading_vram', state._displayLanguage),
                          style: TextStyle(fontSize: 11, color: const Color(0xFF10B981).withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ] else if (AutocorrectEngine.isModelLoaded) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          AppTranslations.translate('gguf_model_loaded_success', state._displayLanguage),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
            Divider(color: state._dividerColor),
            _buildSwitchTile(
              AppTranslations.translate('auto_switch_length_title', state._displayLanguage),
              AppTranslations.translate('auto_switch_length_desc', state._displayLanguage),
              state._isAutoSwitchOnLength,
              (val) {
                state.updateState(() {
                  state._isAutoSwitchOnLength = val;
                  state._saveSetting('isAutoSwitchOnLength', val);
                });
              },
            ),
            if (state._isAutoSwitchOnLength) ...[
              Divider(color: state._dividerColor),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppTranslations.translate('auto_switch_threshold', state._displayLanguage),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${state._autoSwitchLength} ${AppTranslations.translate('chars_suffix', state._displayLanguage)}",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: state._autoSwitchLength.toDouble(),
                      min: 5,
                      max: 15,
                      divisions: 10,
                      label: "${state._autoSwitchLength} ${AppTranslations.translate('chars_suffix', state._displayLanguage)}",
                      onChanged: (val) {
                        state.updateState(() {
                          state._autoSwitchLength = val.toInt();
                          state._saveSetting('autoSwitchLength', state._autoSwitchLength);
                        });
                      },
                    ),
                    Text(
                      AppTranslations.translate('auto_switch_hint', state._displayLanguage),
                      style: TextStyle(fontSize: 11, color: state._textColorTertiary),
                    ),
                  ],
                ),
              ),
            ],
            Divider(color: state._dividerColor),
            _buildSwitchTile(
              AppTranslations.translate('enable_slash_commands', state._displayLanguage),
              AppTranslations.translate('enable_slash_commands_desc', state._displayLanguage),
              state._useSlashCommands,
              (val) {
                state.updateState(() {
                  state._useSlashCommands = val;
                  state._saveSetting('useSlashCommands', val);
                });
              },
            ),
            Divider(color: state._dividerColor),
            _buildSwitchTile(
              AppTranslations.translate('settings_code_filter_title', state._displayLanguage),
              AppTranslations.translate('settings_code_filter_desc', state._displayLanguage),
              state._useCodeFilter,
              (val) {
                state.updateState(() {
                  state._useCodeFilter = val;
                  state._saveSetting('useCodeFilter', val);
                  AutocorrectEngine.isCodeFilterEnabled = val;
                });
              },
            ),
          ]),
          
          const SizedBox(height: 20),

          _buildSettingsBlock(AppTranslations.translate('updates_section', state._displayLanguage), [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        AppTranslations.translate('current_version_label', state._displayLanguage),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: state._textColorPrimary),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "v${_MainDashboardState.currentVersion}",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppTranslations.translate('check_updates_desc', state._displayLanguage),
                    style: TextStyle(fontSize: 11, color: state._textColorSecondary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: state._isCheckingForUpdates ? null : state._manualCheckForUpdates,
                        icon: state._isCheckingForUpdates 
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(
                          state._isCheckingForUpdates 
                              ? AppTranslations.translate('checking_updates_status', state._displayLanguage)
                              : AppTranslations.translate('check_updates_btn', state._displayLanguage),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      if (state._updateCheckMessage != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state._updateCheckMessage!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: state._isUpdateAvailable ? Colors.green : state._textColorSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 20),

          _buildSettingsBlock(AppTranslations.translate('diagnostics_section', state._displayLanguage), [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.translate('export_logs_title', state._displayLanguage),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: state._textColorPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppTranslations.translate('export_logs_desc', state._displayLanguage),
                    style: TextStyle(fontSize: 11, color: state._textColorSecondary),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: AppLogger.openLogDirectory,
                    icon: const Icon(Icons.output_rounded, size: 16),
                    label: Text(
                      AppTranslations.translate('export_logs_btn', state._displayLanguage),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsBlock(String blockTitle, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            blockTitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: state._textColorSecondary,
            ),
          ),
        ),
        Material(
          color: state._surfaceColor,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: state._borderColor),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String desc, bool val, ValueChanged<bool> onChange) {
    return SwitchListTile(
      value: val,
      onChanged: onChange,
      title: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: state._textColorPrimary)),
      subtitle: Text(desc, style: TextStyle(fontSize: 11, color: state._textColorSecondary)),
      activeColor: Theme.of(state.context).colorScheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildReadOnlyLayoutTile(String title, String desc, bool isEnabled) {
    return ListTile(
      title: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: state._textColorPrimary)),
      subtitle: Text(desc, style: TextStyle(fontSize: 11, color: isEnabled ? Colors.green : state._textColorSecondary)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.green.withOpacity(0.1) : state._borderColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          isEnabled ? "Active" : "Inactive",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isEnabled ? Colors.green : state._textColorSecondary,
          ),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildThemeColorDot(Color color, String name) {
    final bool isSelected = state._primaryColorValue == color.value;
    return GestureDetector(
      onTap: () => state._changePrimaryColor(color.value),
      child: Tooltip(
        message: name,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected 
                  ? (state._isDark ? Colors.white : Colors.black)
                  : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: isSelected
              ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                )
              : null,
        ),
      ),
    );
  }
}
