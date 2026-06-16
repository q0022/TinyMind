class AppTranslations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'th': {
      'app_title': 'TinyMind',
      'dashboard': 'Dashboard',
      'settings': 'การตั้งค่า',
      'dictionary': 'คำละเว้น',
      
      // Sidebar
      'accessibility_status': 'Accessibility',
      'accessibility_granted': 'อนุญาตแล้ว',
      'accessibility_needed': 'ต้องการสิทธิ์',
      
      // Dashboard Tab
      'performance_title': 'ประสิทธิภาพการทํางาน',
      'performance_subtitle': 'สถิติและประวัติการแก้คำผิดแบบเรียลไทม์',
      'stat_words_corrected': 'แก้ไขคำผิดแล้ว',
      'stat_layout_fixed': 'สลับภาษา Layout',
      'stat_ai_requests': 'เรียกประมวลผล AI',
      'stat_saved_chars': 'ประหยัดตัวอักษรพิมพ์',
      'recent_activity': 'ประวัติการทำงานล่าสุด (Recent Activity)',
      'empty_history': 'ยังไม่มีประวัติการแก้ไขคำผิดในรอบนี้ค่ะ พิมพ์เพื่อทดสอบได้เลยนะ!',
      
      // Settings Tab
      'settings_title': 'การตั้งค่าระบบ',
      'settings_subtitle': 'ปรับแต่งพฤติกรรมและการทำงานของ TinyMind',
      'accessibility_warning_title': 'ต้องขอสิทธิ์ Accessibility สำหรับดักจับปุ่มกดภายนอกค่ะ',
      'accessibility_warning_desc': 'การปิดแอปพลิเคชันอื่นและเขียนข้อความใหม่จำเป็นต้องใช้สิทธิ์นี้ รันสิทธิ์ในระบบแล้วเปิดการอนุญาตให้แอป TinyMind ด้วยนะจ๊ะ',
      'accessibility_btn': 'เปิดหน้าการอนุญาตของระบบ',
      
      'general_group': 'การทํางานทั่วไป',
      'autocorrect_enable': 'เปิดใช้งานระบบ Autocorrection',
      'autocorrect_enable_desc': 'เปิดเพื่อตรวจจับปุ่มพิมพ์ผิดและสลับภาษาอัตโนมัติในแอปอื่นๆ',
      'launch_at_login': 'เปิดพร้อมกับการบูตระบบ (Launch at Login)',
      'launch_at_login_desc': 'เปิดแอปพลิเคชันและรันเบื้องหลังทันทีที่เปิดเครื่องคอมพิวเตอร์',
      
      'appearance_group': 'ปรับแต่งหน้าตา (Appearance)',
      'dark_mode': 'โหมดกลางคืน (Dark Mode)',
      'dark_mode_desc': 'เปิดการใช้งานโหมดมืด (ปิดหากต้องการใช้ธีมสว่างสดใส)',
      'primary_color': 'โทนสีหลักของแอป (Primary Color)',
      'display_language': 'ภาษาที่ใช้แสดง (Display Language)',
      
      'hotkey_group': 'ปุ่มลัดสลับภาษา (Hotkey Settings)',
      'custom_hotkey_enable': 'กำหนดปุ่มลัดด้วยตัวเอง (Use Custom Hotkey)',
      'custom_hotkey_enable_desc': 'เปิดเพื่อเลือกปุ่มลัดสลับภาษาเอง (หากปิด จะใช้ปุ่มร่วมเดิมทั้ง 3 แบบ)',
      'modifier_label': 'ปุ่มร่วม (Modifier)',
      'key_label': 'ปุ่มหลัก (Key)',
      'none_modifier': 'None (ไม่ใช้ปุ่มร่วม)',
      
      'engine_group': 'เครื่องมือประมวลผลคำแปล (Correction Engine)',
      'fast_local_engine': 'ระบบแก้คำและ Layout สลับภาษาในตัว (Fast Local Engine)',
      'fast_local_engine_desc': 'วิเคราะห์ Layout ผิดพลาด (ไทย <-> อังกฤษ) ทันทีหลังกด Spacebar/Enter ด้วยความเร็วระดับมิลลิวินาที',
      'local_ai_engine': 'ระบบวิเคราะห์บริบทด้วย Local AI (Embedded Llama.cpp)',
      'local_ai_engine_desc': 'รันโมเดลภาษาขนาดเล็ก (GGUF) ภายในเครื่องเพื่อตรวจแก้ข้อความตามบริบทด้วย llama.cpp',
      'gguf_model_label': 'ไฟล์โมเดล GGUF ในเครื่อง',
      'gguf_model_loading_auto': 'ยังไม่ได้เลือกโมเดล (กรุณาเปิดใช้งานเพื่อโหลดอัตโนมัติ)',
      'gguf_model_downloading': 'กำลังคัดลอก/ดาวน์โหลดโมเดล...',
      'gguf_model_pick_btn': 'เลือกไฟล์ GGUF',
      'gguf_model_loading_vram': 'กำลังโหลดโมเดลเข้า VRAM/RAM... (โปรดรอสักครู่)',
      'gguf_model_loaded_success': 'โมเดลโหลดเข้า VRAM เรียบร้อยแล้ว พร้อมทำงาน!',
      'auto_switch_length_title': 'สลับเลย์เอาต์ภาษาอัตโนมัติตามความยาวตัวอักษร',
      'auto_switch_length_desc': 'สลับคีย์บอร์ดและแปลงคำทันทีเมื่อพิมพ์คำศัพท์ในเลย์เอาต์อังกฤษแต่น่าจะเป็นภาษาไทยถึงเกณฑ์ โดยไม่ต้องรอเว้นวรรค',
      'auto_switch_threshold': 'เกณฑ์ความยาวตัวอักษรสำหรับสลับอัตโนมัติ',
      'chars_suffix': 'ตัวอักษร',
      'auto_switch_hint': 'ช่วงที่แนะนำคือ 8 ตัวอักษร (หากสั้นเกินไปอาจทำให้สลับผิดพลาดสำหรับคำศัพท์ภาษาอังกฤษทั่วไป)',
      
      // Dictionary Tab
      'dict_title': 'คลังคำละเว้น (Ignore List)',
      'dict_subtitle': 'ใส่คำศัพท์ที่คุณไม่ต้องการให้ TinyMind เข้าไปดัดแปลงหรือแก้ไข (เช่น ชื่อเฉพาะ รหัส โค้ด)',
      'dict_input_hint': 'พิมพ์คำละเว้น เช่น api, admin, db, เจน, boy',
      'dict_add_btn': 'เพิ่มคำศัพท์',
      'dict_empty': 'ยังไม่มีคำศัพท์ละเว้นในขณะนี้ค่ะ',
      
      // Dialogs
      'model_prepare_failed': 'เตรียมโมเดลล้มเหลว: ',
      'model_pick_failed': 'เกิดข้อผิดพลาดในการเลือกไฟล์: ',
      'model_connecting': 'กำลังเชื่อมต่อเซิร์ฟเวอร์เพื่อดาวน์โหลดโมเดล AI (398 MB)...',
      'model_copying_dev': 'ตรวจพบไฟล์โมเดลในโปรเจกต์ กำลังคัดลอกไฟล์เข้าเครื่อง...',
      'model_copying_progress': 'กำลังคัดลอกโมเดล...',
      'model_downloading_progress': 'กำลังดาวน์โหลดโมเดลภาษา...',
      'Layout (Auto)': 'สลับภาษาอัตโนมัติ',
      'Layout': 'สลับภาษา',
      'Local AI': 'วิเคราะห์ด้วย AI',
      
      // App Updates
      'update_available': 'มีอัปเดตเวอร์ชันใหม่!',
      'update_download_btn': 'ดาวน์โหลดตัวอัปเดต',

      // Diagnostics
      'diagnostics_section': 'การวินิจฉัยและบันทึกประวัติ',
      'export_logs_title': 'ส่งออกไฟล์ประวัติการทำงาน (Logs)',
      'export_logs_desc': 'เปิดโฟลเดอร์เก็บข้อมูลประวัติของแอป สำหรับส่งให้นักพัฒนานำไปวิเคราะห์แก้ไขปัญหา',
      'export_logs_btn': 'เปิดโฟลเดอร์ Log',

      // Tray Menu
      'tray_open': 'เปิดหน้าต่างหลัก',
      'tray_pause': 'ปิดการทำงานชั่วคราว',
      'tray_resume': 'เปิดการทำงาน',
      'tray_quit': 'ออกจากแอป',
    },
    'en': {
      'app_title': 'TinyMind',
      'dashboard': 'Dashboard',
      'settings': 'Settings',
      'dictionary': 'Ignore List',
      
      // Sidebar
      'accessibility_status': 'Accessibility',
      'accessibility_granted': 'Granted',
      'accessibility_needed': 'Requires Permission',
      
      // Dashboard Tab
      'performance_title': 'Work Efficiency',
      'performance_subtitle': 'Real-time statistics and correction history',
      'stat_words_corrected': 'Words Corrected',
      'stat_layout_fixed': 'Layouts Switched',
      'stat_ai_requests': 'AI Inferences',
      'stat_saved_chars': 'Saved Keystrokes',
      'recent_activity': 'Recent Activity',
      'empty_history': 'No correction history yet. Type something to test!',
      
      // Settings Tab
      'settings_title': 'System Settings',
      'settings_subtitle': 'Adjust behavior and settings of TinyMind',
      'accessibility_warning_title': 'Accessibility permission required to hook global keystrokes',
      'accessibility_warning_desc': 'Closing other applications and typing replacements requires this permission. Please enable TinyMind in System Settings.',
      'accessibility_btn': 'Open System Preferences',
      
      'general_group': 'General Settings',
      'autocorrect_enable': 'Enable Autocorrection',
      'autocorrect_enable_desc': 'Detect keyboard layout errors and automatically switch language in other apps',
      'launch_at_login': 'Launch at Login',
      'launch_at_login_desc': 'Open application and run in background on startup',
      
      'appearance_group': 'Appearance Settings',
      'dark_mode': 'Dark Mode',
      'dark_mode_desc': 'Enable dark theme (disable for vibrant light theme)',
      'primary_color': 'Primary Theme Color',
      'display_language': 'Display Language',
      
      'hotkey_group': 'Hotkey Settings',
      'custom_hotkey_enable': 'Use Custom Hotkey',
      'custom_hotkey_enable_desc': 'Enable to select custom hotkeys; if disabled, default hotkeys are used',
      'modifier_label': 'Modifier Key',
      'key_label': 'Main Key',
      'none_modifier': 'None (No Modifier)',
      
      'engine_group': 'Correction Engine',
      'fast_local_engine': 'Fast Local Layout Switcher',
      'fast_local_engine_desc': 'Correct layout typos (Thai <-> English) instantly after Spacebar/Enter in milliseconds',
      'local_ai_engine': 'Contextual Local AI Correction',
      'local_ai_engine_desc': 'Run local small language model (GGUF) to correct contextually via llama.cpp',
      'gguf_model_label': 'Local GGUF Model Path',
      'gguf_model_loading_auto': 'Model not selected; enable AI to download automatically',
      'gguf_model_downloading': 'Copying/downloading model file...',
      'gguf_model_pick_btn': 'Select GGUF File',
      'gguf_model_loading_vram': 'Loading model into VRAM/RAM... (Please wait)',
      'gguf_model_loaded_success': 'Model successfully loaded into VRAM. Ready!',
      'auto_switch_length_title': 'Auto Switch Layout by Word Length',
      'auto_switch_length_desc': 'Switch layout immediately when typed characters reach threshold before pressing Space',
      'auto_switch_threshold': 'Length Threshold for Auto Switch',
      'chars_suffix': 'characters',
      'auto_switch_hint': '8 characters is recommended to prevent false switches on English words',
      
      // Dictionary Tab
      'dict_title': 'Ignore List',
      'dict_subtitle': 'Words you want to exclude from autocorrection (e.g., proper nouns, codes, IDs)',
      'dict_input_hint': 'Type ignored word (e.g. api, admin, db, boy)',
      'dict_add_btn': 'Add Word',
      'dict_empty': 'No ignored words yet.',
      
      // Dialogs
      'model_prepare_failed': 'Model preparation failed: ',
      'model_pick_failed': 'Error selecting file: ',
      'model_connecting': 'Connecting to server to download AI model (398 MB)...',
      'model_copying_dev': 'Dev model file detected. Copying file to application support directory...',
      'model_copying_progress': 'Copying model...',
      'model_downloading_progress': 'Downloading language model...',
      'Layout (Auto)': 'Layout (Auto)',
      'Layout': 'Layout',
      'Local AI': 'Local AI',
      
      // App Updates
      'update_available': 'New version available!',
      'update_download_btn': 'Download update',

      // Diagnostics
      'diagnostics_section': 'Diagnostics & Logs',
      'export_logs_title': 'Export Application Logs',
      'export_logs_desc': 'Open the folder containing application logs to send to the developer for debugging',
      'export_logs_btn': 'Open Logs Folder',

      // Tray Menu
      'tray_open': 'Open Window',
      'tray_pause': 'Pause',
      'tray_resume': 'Resume',
      'tray_quit': 'Quit',
    }
  };

  static String translate(String key, String locale) {
    final Map<String, String>? translations = _localizedValues[locale];
    if (translations == null) return key;
    return translations[key] ?? key;
  }
}
