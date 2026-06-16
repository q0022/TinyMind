import Cocoa
import FlutterMacOS
import Carbon

@main
class AppDelegate: FlutterAppDelegate {
    var channel: FlutterMethodChannel?
    var eventTap: CFMachPort?
    var runLoopSource: CFRunLoopSource?
    
    // Custom Hotkey Configurations
    var hotkeyModifier: String = "Shift"
    var hotkeyKey: String = "Backspace"
    var useCustomHotkey: Bool = false
    
    override func applicationDidFinishLaunching(_ notification: Notification) {
        print("AppDelegate: applicationDidFinishLaunching starting...")
        fflush(stdout)
        
        // Let's try to get FlutterViewController before calling super
        if let window = mainFlutterWindow {
            print("AppDelegate: found mainFlutterWindow before super: \(window)")
            fflush(stdout)
            if let controller = window.contentViewController as? FlutterViewController {
                print("AppDelegate: found FlutterViewController: \(controller)")
                fflush(stdout)
                channel = FlutterMethodChannel(name: "com.tinymind.app/keyboard", binaryMessenger: controller.engine.binaryMessenger)
                setupMethodChannelHandler()
            } else {
                print("AppDelegate: contentViewController is not FlutterViewController: \(String(describing: window.contentViewController))")
                fflush(stdout)
            }
        } else {
            print("AppDelegate: mainFlutterWindow is nil before super")
            fflush(stdout)
            // Try to find it in NSApplication windows
            for window in NSApplication.shared.windows {
                print("AppDelegate: NSApplication window: \(window)")
                fflush(stdout)
                if let mainWin = window as? MainFlutterWindow, let controller = mainWin.contentViewController as? FlutterViewController {
                    print("AppDelegate: found FlutterViewController in NSApplication windows: \(controller)")
                    fflush(stdout)
                    channel = FlutterMethodChannel(name: "com.tinymind.app/keyboard", binaryMessenger: controller.engine.binaryMessenger)
                    setupMethodChannelHandler()
                    break
                }
            }
        }
        
        // Start listening (Call before super just in case super blocks)
        startMonitoringKeyboard()
        startMonitoringMouse()
        
        // ตั้งค่าก่อนเรียก super เพื่อพยายามซ่อนตั้งแต่แรก
        NSApp.setActivationPolicy(.accessory)
        
        super.applicationDidFinishLaunching(notification)
        print("AppDelegate: super.applicationDidFinishLaunching returned.")
        fflush(stdout)
        
        // ซ่อนไอคอนออกจาก Dock — บังคับหลัง super ทันที
        NSApp.setActivationPolicy(.accessory)
        
        // และบังคับอีกครั้งหลัง delay เพื่อให้ชนะ Flutter internal setup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApp.setActivationPolicy(.accessory)
            print("AppDelegate: Set activation policy to .accessory (delayed 0.5s)")
            fflush(stdout)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            NSApp.setActivationPolicy(.accessory)
            print("AppDelegate: Set activation policy to .accessory (delayed 2.0s)")
            fflush(stdout)
        }
    }
    
    private func setupMethodChannelHandler() {
        print("AppDelegate: Setting up MethodChannel handler...")
        channel?.setMethodCallHandler { [weak self] (call, result) in
            print("AppDelegate: MethodChannel call received: \(call.method)")
            if call.method == "checkAccessibility" {
                let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
                let isTrusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
                if isTrusted && self?.eventTap == nil {
                    print("AppDelegate: checkAccessibility: Process is trusted but eventTap is nil. Attempting to start...")
                    fflush(stdout)
                    self?.startMonitoringKeyboard()
                }
                let hasEventTap = self?.eventTap != nil
                result(isTrusted && hasEventTap)
            } else if call.method == "requestAccessibility" {
                let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
                let isTrusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
                if isTrusted && self?.eventTap == nil {
                    print("AppDelegate: requestAccessibility: Process is trusted but eventTap is nil. Attempting to start...")
                    fflush(stdout)
                    self?.startMonitoringKeyboard()
                }
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    if !NSWorkspace.shared.open(url) {
                        if let fallbackUrl = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
                            NSWorkspace.shared.open(fallbackUrl)
                        }
                    }
                }
                let hasEventTap = self?.eventTap != nil
                result(isTrusted && hasEventTap)
            } else if call.method == "replaceText" {
                if let args = call.arguments as? [String: Any],
                   let backspaces = args["backspaces"] as? Int,
                   let text = args["text"] as? String {
                     self?.replaceText(backspaces: backspaces, text: text)
                     result(true)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing backspaces or text", details: nil))
                }
            } else if call.method == "updateHotkey" {
                if let args = call.arguments as? [String: Any],
                   let modifier = args["modifier"] as? String,
                   let key = args["key"] as? String,
                   let useCustom = args["useCustom"] as? Bool {
                    self?.hotkeyModifier = modifier
                    self?.hotkeyKey = key
                    self?.useCustomHotkey = useCustom
                    print("AppDelegate: hotkey configuration updated: modifier=\(modifier), key=\(key), useCustom=\(useCustom)")
                    fflush(stdout)
                    result(true)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing modifier, key, or useCustom", details: nil))
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    // บังคับซ่อน Dock icon ทุกครั้งที่ app กลับมา active
    override func applicationDidBecomeActive(_ notification: Notification) {
        super.applicationDidBecomeActive(notification)
        if NSApp.activationPolicy() != .accessory {
            NSApp.setActivationPolicy(.accessory)
            print("AppDelegate: applicationDidBecomeActive - forced .accessory policy")
            fflush(stdout)
        }
    }
    
    func startMonitoringKeyboard() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                if let refcon = refcon {
                    let appDelegate = Unmanaged<AppDelegate>.fromOpaque(refcon).takeUnretainedValue()
                    if let resultEvent = appDelegate.handleKeyEvent(event) {
                        return Unmanaged.passRetained(resultEvent)
                    } else {
                        return nil // Block event
                    }
                }
                return Unmanaged.passRetained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )
        
        if let eventTap = eventTap {
            print("AppDelegate: startMonitoringKeyboard: Keyboard EventTap created successfully!")
            fflush(stdout)
            runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        } else {
            print("AppDelegate: startMonitoringKeyboard: FAILED to create Keyboard EventTap (Missing accessibility permission)")
            fflush(stdout)
        }
    }
    
    func startMonitoringMouse() {
        // ...
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.channel?.invokeMethod("clearBuffer", arguments: nil)
        }
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.channel?.invokeMethod("clearBuffer", arguments: nil)
            return event
        }
    }
    
    func handleKeyEvent(_ event: CGEvent) -> CGEvent? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        // Check hotkey matches
        if useCustomHotkey {
            let isShift = flags.contains(.maskShift)
            let isOption = flags.contains(.maskAlternate)
            let isControl = flags.contains(.maskControl)
            let isCommand = flags.contains(.maskCommand)
            
            var modifierMatched = false
            switch hotkeyModifier {
            case "Shift":
                modifierMatched = isShift && !isOption && !isControl && !isCommand
            case "Option":
                modifierMatched = isOption && !isShift && !isControl && !isCommand
            case "Control":
                modifierMatched = isControl && !isShift && !isOption && !isCommand
            case "Command":
                modifierMatched = isCommand && !isShift && !isOption && !isControl
            case "None":
                modifierMatched = !isShift && !isOption && !isControl && !isCommand
            default:
                modifierMatched = false
            }
            
            var keyMatched = false
            switch hotkeyKey {
            case "Backspace":
                keyMatched = (keyCode == 51)
            case "CapsLock":
                keyMatched = (keyCode == 57)
            case "Space":
                keyMatched = (keyCode == 49)
            case "GraveAccent":
                keyMatched = (keyCode == 50)
            case "Esc":
                keyMatched = (keyCode == 53)
            default:
                keyMatched = false
            }
            
            if modifierMatched && keyMatched {
                print("AppDelegate: Custom Hotkey (\(hotkeyModifier) + \(hotkeyKey)) detected!")
                fflush(stdout)
                channel?.invokeMethod("onHotkey", arguments: nil)
                return nil // Block
            }
        } else {
            let isShift = flags.contains(.maskShift)
            let isOption = flags.contains(.maskAlternate)
            
            // 1. Shift + Backspace (keyCode 51)
            if keyCode == 51 && isShift {
                print("AppDelegate: Hotkey Shift + Backspace detected!")
                fflush(stdout)
                channel?.invokeMethod("onHotkey", arguments: nil)
                return nil // Block
            }
            
            // 2. Shift + Caps Lock (keyCode 57)
            if keyCode == 57 && isShift {
                print("AppDelegate: Hotkey Shift + Caps Lock detected!")
                fflush(stdout)
                channel?.invokeMethod("onHotkey", arguments: nil)
                return nil // Block
            }
            
            // 3. Option + Space (keyCode 49)
            if keyCode == 49 && isOption {
                print("AppDelegate: Hotkey Option + Space detected!")
                fflush(stdout)
                channel?.invokeMethod("onHotkey", arguments: nil)
                return nil // Block
            }
        }

        if flags.contains(.maskCommand) || flags.contains(.maskControl) {
            channel?.invokeMethod("clearBuffer", arguments: nil)
            return event
        }
        
        // Navigation keys: Esc (53), Left (123), Right (124), Down (125), Up (126), Home (115), PageUp (116), End (119), PageDown (121)
        let navigationKeys: Set<Int64> = [53, 123, 124, 125, 126, 115, 116, 119, 121]
        if navigationKeys.contains(keyCode) {
            channel?.invokeMethod("clearBuffer", arguments: nil)
            return event
        }
        
        if keyCode == 51 { // Backspace
            channel?.invokeMethod("onBackspace", arguments: nil)
            return event
        }
        
        if let nsEvent = NSEvent(cgEvent: event) {
            let chars = nsEvent.characters ?? ""
            if !chars.isEmpty {
                print("AppDelegate: handleKeyEvent: invoking onKey for '\(chars)'")
                fflush(stdout)
                channel?.invokeMethod("onKey", arguments: ["char": chars, "keyCode": keyCode])
            }
        }
        return event
    }
    
    func replaceText(backspaces: Int, text: String) {
        // Detect language to switch layout
        let hasThai = text.unicodeScalars.contains { $0.value >= 0x0E00 && $0.value <= 0x0E7F }
        let hasEnglish = text.unicodeScalars.contains { ($0.value >= 65 && $0.value <= 90) || ($0.value >= 97 && $0.value <= 122) }
        
        if hasThai {
            switchKeyboardLayout(toThai: true)
        } else if hasEnglish {
            switchKeyboardLayout(toThai: false)
        }

        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        
        let source = CGEventSource(stateID: .combinedSessionState)
        
        for _ in 0..<backspaces {
            let down = CGEvent(keyboardEventSource: source, virtualKey: 0x33, keyDown: true)
            let up = CGEvent(keyboardEventSource: source, virtualKey: 0x33, keyDown: false)
            down?.post(tap: .cghidEventTap)
            up?.post(tap: .cghidEventTap)
            usleep(1000)
        }
        
        let utf16Chars = Array(text.utf16)
        let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
        let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
        
        down?.keyboardSetUnicodeString(stringLength: utf16Chars.count, unicodeString: utf16Chars)
        up?.keyboardSetUnicodeString(stringLength: utf16Chars.count, unicodeString: utf16Chars)
        
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
        
        if let eventTap = eventTap {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
        }
    }
    
    func switchKeyboardLayout(toThai: Bool) {
        let targetLanguage = toThai ? "th" : "en"
        print("AppDelegate: switchKeyboardLayout: requested switch to \(targetLanguage)")
        fflush(stdout)
        
        // Get the list of all active input sources
        guard let sources = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            print("AppDelegate: switchKeyboardLayout: Failed to create input source list")
            fflush(stdout)
            return
        }
        
        for source in sources {
            guard let typePtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceType) else { continue }
            let type = Unmanaged<CFString>.fromOpaque(typePtr).takeUnretainedValue() as String
            
            if type == kTISTypeKeyboardLayout as String || type == "TISInputSourceTypeKeyboardLayout" {
                if let langPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages) {
                    let languages = Unmanaged<CFArray>.fromOpaque(langPtr).takeUnretainedValue() as? [String] ?? []
                    
                    if languages.contains(where: { $0.hasPrefix(targetLanguage) }) {
                        let status = TISSelectInputSource(source)
                        if status == noErr {
                            print("AppDelegate: switchKeyboardLayout: Successfully switched keyboard layout to \(toThai ? "Thai" : "English")")
                            fflush(stdout)
                            return
                        } else {
                            print("AppDelegate: switchKeyboardLayout: Failed to select input source: \(status)")
                            fflush(stdout)
                        }
                    }
                }
            }
        }
    }
}
