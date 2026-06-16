#include "flutter_window.h"

#include <optional>
#include <windows.h>
#include <winuser.h>
#include <string>
#include <vector>

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include "flutter/generated_plugin_registrant.h"

// Global static variables for Windows Hooks
static HHOOK hKeyboardHook = NULL;
static HHOOK hMouseHook = NULL;
static flutter::MethodChannel<flutter::EncodableValue>* g_channel = nullptr;
static bool g_isTyping = false;

// WideCharToMultiByte UTF-8 conversion helper
static std::string WideToUtf8(const std::wstring& wstr) {
    if (wstr.empty()) return std::string();
    int size_needed = WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), NULL, 0, NULL, NULL);
    std::string strTo(size_needed, 0);
    WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), &strTo[0], size_needed, NULL, NULL);
    return strTo;
}

// MultiByteToWideChar conversion helper
static std::wstring Utf8ToWide(const std::string& str) {
    if (str.empty()) return std::wstring();
    int size_needed = MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), NULL, 0);
    std::wstring wstrTo(size_needed, 0);
    MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), &wstrTo[0], size_needed);
    return wstrTo;
}

// Simulated Backspaces
static void SendBackspaces(int count) {
    std::vector<INPUT> inputs;
    for (int i = 0; i < count; ++i) {
        INPUT input_down = {};
        input_down.type = INPUT_KEYBOARD;
        input_down.ki.wVk = VK_BACK;
        input_down.ki.dwFlags = 0;
        
        INPUT input_up = {};
        input_up.type = INPUT_KEYBOARD;
        input_up.ki.wVk = VK_BACK;
        input_up.ki.dwFlags = KEYEVENTF_KEYUP;
        
        inputs.push_back(input_down);
        inputs.push_back(input_up);
    }
    SendInput(static_cast<UINT>(inputs.size()), inputs.data(), sizeof(INPUT));
}

// Simulated Unicode string input
static void TypeUnicodeString(const std::string& utf8_str) {
    std::wstring wstr = Utf8ToWide(utf8_str);
    std::vector<INPUT> inputs;
    for (wchar_t wch : wstr) {
        INPUT input_down = {};
        input_down.type = INPUT_KEYBOARD;
        input_down.ki.wScan = wch;
        input_down.ki.dwFlags = KEYEVENTF_UNICODE;
        
        INPUT input_up = {};
        input_up.type = INPUT_KEYBOARD;
        input_up.ki.wScan = wch;
        input_up.ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;
        
        inputs.push_back(input_down);
        inputs.push_back(input_up);
    }
    SendInput(static_cast<UINT>(inputs.size()), inputs.data(), sizeof(INPUT));
}

// Text Replacement Logic
static void ReplaceText(int backspaces, const std::string& text) {
    g_isTyping = true;
    SendBackspaces(backspaces);
    TypeUnicodeString(text);
    Sleep(50); // Tiny delay to let the OS process keyboard messages
    g_isTyping = false;
}

// Low-level Keyboard Hook Callback
LRESULT CALLBACK LowLevelKeyboardProc(int nCode, WPARAM wParam, LPARAM lParam) {
    if (nCode >= 0 && !g_isTyping) {
        KBDLLHOOKSTRUCT* pKeyBoard = (KBDLLHOOKSTRUCT*)lParam;
        
        if (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN) {
            bool ctrlPressed = (GetKeyState(VK_CONTROL) & 0x8000) != 0;
            bool winPressed = (GetKeyState(VK_LWIN) & 0x8000) != 0 || (GetKeyState(VK_RWIN) & 0x8000) != 0;
            
            if (ctrlPressed || winPressed) {
                if (g_channel) {
                    g_channel->InvokeMethod("clearBuffer", nullptr);
                }
            } else {
                DWORD vkCode = pKeyBoard->vkCode;
                
                if (vkCode == VK_ESCAPE || vkCode == VK_LEFT || vkCode == VK_RIGHT ||
                    vkCode == VK_UP || vkCode == VK_DOWN || vkCode == VK_HOME ||
                    vkCode == VK_END || vkCode == VK_PRIOR || vkCode == VK_NEXT) {
                    if (g_channel) {
                        g_channel->InvokeMethod("clearBuffer", nullptr);
                    }
                } else if (vkCode == VK_BACK) {
                    if (g_channel) {
                        g_channel->InvokeMethod("onBackspace", nullptr);
                    }
                } else {
                    BYTE keyboardState[256];
                    GetKeyboardState(keyboardState);
                    
                    keyboardState[VK_SHIFT] = GetKeyState(VK_SHIFT) & 0x8000 ? 0x80 : 0;
                    keyboardState[VK_CAPITAL] = GetKeyState(VK_CAPITAL) & 0x01 ? 0x01 : 0;
                    keyboardState[VK_CONTROL] = 0;
                    keyboardState[VK_MENU] = 0;
                    
                    wchar_t buffer[5];
                    HWND activeHWnd = GetForegroundWindow();
                    DWORD activeThreadId = GetWindowThreadProcessId(activeHWnd, NULL);
                    HKL layout = GetKeyboardLayout(activeThreadId);
                    
                    int result = ToUnicodeEx(vkCode, pKeyBoard->scanCode, keyboardState, buffer, 4, 0, layout);
                    if (result > 0) {
                        std::wstring chars(buffer, result);
                        std::string utf8_chars = WideToUtf8(chars);
                        if (!utf8_chars.empty() && g_channel) {
                            flutter::EncodableMap args = {
                                {flutter::EncodableValue("char"), flutter::EncodableValue(utf8_chars)},
                                {flutter::EncodableValue("keyCode"), flutter::EncodableValue((int)vkCode)}
                            };
                            g_channel->InvokeMethod("onKey", std::make_unique<flutter::EncodableValue>(args));
                        }
                    }
                }
            }
        }
    }
    return CallNextHookEx(hKeyboardHook, nCode, wParam, lParam);
}

// Low-level Mouse Hook Callback
LRESULT CALLBACK LowLevelMouseProc(int nCode, WPARAM wParam, LPARAM lParam) {
    if (nCode >= 0 && !g_isTyping) {
        if (wParam == WM_LBUTTONDOWN || wParam == WM_RBUTTONDOWN) {
            if (g_channel) {
                g_channel->InvokeMethod("clearBuffer", nullptr);
            }
        }
    }
    return CallNextHookEx(hMouseHook, nCode, wParam, lParam);
}

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
      
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Setup Windows Keyboard Method Channel
  flutter::BinaryMessenger* messenger = flutter_controller_->engine()->messenger();
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "com.tinymind.app/keyboard",
      &flutter::standard_method_codec::GetInstance()
  );
  
  g_channel = channel.release();
  
  g_channel->SetMethodCallHandler([](const flutter::MethodCall<flutter::EncodableValue>& call,
                                     std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
      if (call.method() == "checkAccessibility") {
          result->Success(flutter::EncodableValue(true)); // Always true on Windows
      } else if (call.method() == "requestAccessibility") {
          result->Success(flutter::EncodableValue(true));
      } else if (call.method() == "replaceText") {
          const auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());
          if (arguments) {
              auto backspaces_it = arguments->find(flutter::EncodableValue("backspaces"));
              auto text_it = arguments->find(flutter::EncodableValue("text"));
              if (backspaces_it != arguments->end() && text_it != arguments->end()) {
                  int backspaces = std::get<int>(backspaces_it->second);
                  std::string text = std::get<std::string>(text_it->second);
                  ReplaceText(backspaces, text);
                  result->Success(flutter::EncodableValue(true));
                  return;
              }
          }
          result->Error("INVALID_ARGUMENTS", "Missing backspaces or text");
      } else {
          result->NotImplemented();
      }
  });

  // Start Windows Low-Level Hooks
  hKeyboardHook = SetWindowsHookEx(WH_KEYBOARD_LL, LowLevelKeyboardProc, GetModuleHandle(NULL), 0);
  hMouseHook = SetWindowsHookEx(WH_MOUSE_LL, LowLevelMouseProc, GetModuleHandle(NULL), 0);

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (hKeyboardHook) {
    UnhookWindowsHookEx(hKeyboardHook);
    hKeyboardHook = NULL;
  }
  
  if (hMouseHook) {
    UnhookWindowsHookEx(hMouseHook);
    hMouseHook = NULL;
  }

  if (g_channel) {
    delete g_channel;
    g_channel = nullptr;
  }

  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
