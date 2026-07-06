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
    
    // Enter Block Control for AI
    var needsAutocorrect: Bool = false
    var isReplacingText: Bool = false
    var activeAppBundleID: String = ""
    
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
        // Observe active application changes to notify Dart about Chromium vs Native layout
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeAppChanged(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        
        // Notify Dart of initial active application after a short delay to let channel setup complete
        if let activeApp = NSWorkspace.shared.frontmostApplication,
           let bundleID = activeApp.bundleIdentifier {
            self.activeAppBundleID = bundleID
            let appMode = getAppMode(bundleID: bundleID)
            print("AppDelegate: initial active app - bundleID=\(bundleID), appMode=\(appMode)")
            fflush(stdout)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.channel?.invokeMethod("updateActiveApp", arguments: ["appMode": appMode])
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
            } else if call.method == "showDockIcon" {
                DispatchQueue.main.async {
                    NSApp.setActivationPolicy(.regular)
                }
                result(true)
            } else if call.method == "hideDockIcon" {
                DispatchQueue.main.async {
                    NSApp.setActivationPolicy(.accessory)
                }
                result(true)
            } else if call.method == "updateBufferStatus" {
                if let args = call.arguments as? [String: Any],
                   let status = args["needsAutocorrect"] as? Bool {
                    self?.needsAutocorrect = status
                    result(true)
                } else {
                    result(false)
                }
            } else if call.method == "releaseEnter" {
                self?.releaseEnter()
                result(true)
            } else if call.method == "getEnabledLanguages" {
                let langs = self?.getEnabledLanguages() ?? ["en", "th"]
                result(langs)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    // บังคับซ่อน Dock icon ทุกครั้งที่ app กลับมา active (เฉพาะกรณีไม่มีหน้าต่างหลักเปิดอยู่)
    override func applicationDidBecomeActive(_ notification: Notification) {
        super.applicationDidBecomeActive(notification)
        var isAnyWindowVisible = false
        for window in NSApp.windows {
            if window.isVisible && window.className.contains("FlutterWindow") {
                isAnyWindowVisible = true
                break
            }
        }
        if !isAnyWindowVisible {
            if NSApp.activationPolicy() != .accessory {
                NSApp.setActivationPolicy(.accessory)
                print("AppDelegate: applicationDidBecomeActive - forced .accessory policy because no window is visible")
                fflush(stdout)
            }
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
                    
                    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                        if appDelegate.isReplacingText {
                            print("AppDelegate: EventTap disabled by type \(type.rawValue) during replaceText. Keeping it disabled.")
                            fflush(stdout)
                            return Unmanaged.passRetained(event)
                        }
                        if let tap = appDelegate.eventTap {
                            CGEvent.tapEnable(tap: tap, enable: true)
                            print("AppDelegate: EventTap disabled by type \(type.rawValue), re-enabled it successfully.")
                            fflush(stdout)
                        }
                        return Unmanaged.passRetained(event)
                    }
                    
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
            print("AppDelegate: clearBuffer called due to global mouse click")
            fflush(stdout)
            self?.channel?.invokeMethod("clearBuffer", arguments: nil)
        }
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            print("AppDelegate: clearBuffer called due to local mouse click")
            fflush(stdout)
            self?.channel?.invokeMethod("clearBuffer", arguments: nil)
            return event
        }
    }
    
    func releaseEnter() {
        print("AppDelegate: Releasing Enter event to system")
        fflush(stdout)
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        
        let source = CGEventSource(stateID: .privateState)
        let down = CGEvent(keyboardEventSource: source, virtualKey: 0x24, keyDown: true) // 0x24 is Return
        let up = CGEvent(keyboardEventSource: source, virtualKey: 0x24, keyDown: false)
        
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
        
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }
    }
    
    func handleKeyEvent(_ event: CGEvent) -> CGEvent? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        // Skip layout monitoring for ignored launcher apps
        let appMode = getAppMode(bundleID: activeAppBundleID)
        if appMode == "ignored" {
            return event
        }
        
        // 0. ดักจับและบล็อก Enter สำหรับ AI Autocorrection
        if keyCode == 36 || keyCode == 76 { // Return / Enter
            if needsAutocorrect {
                print("AppDelegate: Enter blocked for AI autocorrection")
                fflush(stdout)
                needsAutocorrect = false // เคลียร์ทันทีเพื่อป้องกัน loop
                channel?.invokeMethod("onEnterTriggered", arguments: nil)
                return nil // บล็อกปุ่ม Enter
            }
        }
        
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
            // Do not clear buffer for layout switch shortcuts (like Cmd+Space, Ctrl+Space)
            if keyCode != 49 {
                print("AppDelegate: clearBuffer called due to Cmd/Ctrl shortcut (keyCode: \(keyCode))")
                fflush(stdout)
                channel?.invokeMethod("clearBuffer", arguments: nil)
            } else {
                print("AppDelegate: Cmd/Ctrl shortcut with keyCode 49 (Space) detected. NOT clearing buffer.")
                fflush(stdout)
            }
            return event
        }
        
        // Navigation keys: Tab (48), Esc (53), Left (123), Right (124), Down (125), Up (126), Home (115), PageUp (116), End (119), PageDown (121)
        let navigationKeys: Set<Int64> = [48, 53, 123, 124, 125, 126, 115, 116, 119, 121]
        if navigationKeys.contains(keyCode) {
            print("AppDelegate: clearBuffer called due to navigation key (keyCode: \(keyCode))")
            fflush(stdout)
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
        print("AppDelegate: replaceText command received. backspaces=\(backspaces), text='\(text)'")
        fflush(stdout)
        isReplacingText = true
        // Detect language to switch layout
        var targetLang = "en"
        let hasThai = text.unicodeScalars.contains { $0.value >= 0x0E00 && $0.value <= 0x0E7F }
        let hasKorean = text.unicodeScalars.contains { ($0.value >= 0xAC00 && $0.value <= 0xD7A3) || ($0.value >= 0x1100 && $0.value <= 0x11FF) || ($0.value >= 0x3130 && $0.value <= 0x318F) }
        let hasJapaneseKana = text.unicodeScalars.contains { ($0.value >= 0x3040 && $0.value <= 0x309F) || ($0.value >= 0x30A0 && $0.value <= 0x30FF) }
        let hasChineseHanzi = text.unicodeScalars.contains { $0.value >= 0x4E00 && $0.value <= 0x9FFF }
        
        if hasThai {
            targetLang = "th"
        } else if hasKorean {
            targetLang = "ko"
        } else if hasJapaneseKana {
            targetLang = "ja"
        } else if hasChineseHanzi {
            targetLang = "zh"
        } else {
            let hasEnglish = text.unicodeScalars.contains { ($0.value >= 65 && $0.value <= 90) || ($0.value >= 97 && $0.value <= 122) }
            if hasEnglish {
                targetLang = "en"
            }
        }
        
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            usleep(5000) // Allow OS to complete the event tap transition
        }
        
        var finalBackspaces = backspaces
        let isThai = isCurrentLayoutThai()
        let appMode = getAppMode(bundleID: activeAppBundleID)
        if isThai && (appMode == "native" || appMode == "ignored") && backspaces > 0 {
            print("AppDelegate: replaceText: Thai layout detected in native/launcher app \(activeAppBundleID). Adding 1 extra backspace for IME swallow.")
            finalBackspaces += 1
        }
        
        let source = CGEventSource(stateID: .privateState)
        
        if finalBackspaces > 0 {
            print("AppDelegate: replaceText: Sending \(finalBackspaces) Backspace events...")
            fflush(stdout)
            for _ in 0..<finalBackspaces {
                let down = CGEvent(keyboardEventSource: source, virtualKey: 0x33, keyDown: true)
                let up = CGEvent(keyboardEventSource: source, virtualKey: 0x33, keyDown: false)
                down?.flags = []
                up?.flags = []
                down?.post(tap: .cghidEventTap)
                usleep(1000)
                up?.post(tap: .cghidEventTap)
                usleep(1000)
            }
            usleep(2000) // Allow backspaces to process completely
        }
        
        switchKeyboardLayout(to: targetLang)
        usleep(2000) // Allow layout transition to settle before typing
        
        let utf16Chars = Array(text.utf16)
        print("AppDelegate: replaceText: Typing Unicode string '\(text)' with \(utf16Chars.count) UTF-16 code units...")
        fflush(stdout)
        let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
        let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
        down?.flags = []
        up?.flags = []
        
        down?.keyboardSetUnicodeString(stringLength: utf16Chars.count, unicodeString: utf16Chars)
        up?.keyboardSetUnicodeString(stringLength: utf16Chars.count, unicodeString: utf16Chars)
        
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
        
        if let eventTap = eventTap {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.isReplacingText = false
                if let tap = self?.eventTap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
            }
        } else {
            isReplacingText = false
        }
    }
    
    func switchKeyboardLayout(to targetLanguage: String) {
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
                            print("AppDelegate: switchKeyboardLayout: Successfully switched keyboard layout to \(targetLanguage)")
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
    
    func getEnabledLanguages() -> [String] {
        guard let sources = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            return ["en", "th"]
        }
        var languagesList = Set<String>()
        for source in sources {
            guard let typePtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceType) else { continue }
            let type = Unmanaged<CFString>.fromOpaque(typePtr).takeUnretainedValue() as String
            
            if type == kTISTypeKeyboardLayout as String || 
               type == "TISInputSourceTypeKeyboardLayout" ||
               type.contains("Keyboard") || 
               type.contains("InputMethod") {
                if let langPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages) {
                    let languages = Unmanaged<CFArray>.fromOpaque(langPtr).takeUnretainedValue() as? [String] ?? []
                    for lang in languages {
                        let code = lang.split(separator: "-").first.map(String.init) ?? lang
                        languagesList.insert(code.lowercased())
                    }
                }
            }
        }
        if languagesList.isEmpty {
            return ["en", "th"]
        }
        return Array(languagesList)
    }

    @objc private func activeAppChanged(_ notification: Notification) {
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
           let bundleID = app.bundleIdentifier {
            self.activeAppBundleID = bundleID
            let appMode = getAppMode(bundleID: bundleID)
            print("AppDelegate: activeAppChanged - bundleID=\(bundleID), appMode=\(appMode)")
            fflush(stdout)
            channel?.invokeMethod("updateActiveApp", arguments: ["appMode": appMode])
        }
    }

    private func getAppMode(bundleID: String) -> String {
        let ignoredBundleIDs = [
            "com.runningwithcrayons.alfred",
            "com.raycast.macos",
            "com.apple.spotlight"
        ]
        if ignoredBundleIDs.contains(where: { bundleID.lowercased().contains($0) }) {
            return "ignored"
        }
        
        let chromiumBundleIDs = [
            "com.google.chrome",
            "com.microsoft.vscode",
            "com.tinyspeck.slackmacgap",
            "com.hnc.discord",
            "com.spotify.client",
            "org.chromium.chromium",
            "com.brave.browser",
            "com.operasoftware.opera",
            "com.microsoft.edge",
            "company.thebrowser.browser",
            "electron",
            "notion",
            "obsidian",
            "teams",
            "line",
            "pgadmin",
            "gemini"
        ]
        let flutterBundleIDs = [
            "com.tinymind.tinymind",
            "com.google.antigravity",
            "firefox",
            "mozilla",
            "zen-browser"
        ]
        let terminalBundleIDs = [
            "com.apple.terminal",
            "com.googlecode.iterm2",
            "com.warp.warp",
            "org.alacritty",
            "net.kovidgoyal.kitty",
            "com.mitchellh.ghostty"
        ]
        
        if chromiumBundleIDs.contains(where: { bundleID.lowercased().contains($0) }) {
            return "chromium"
        } else if flutterBundleIDs.contains(where: { bundleID.lowercased().contains($0) }) {
            return "flutter"
        } else if terminalBundleIDs.contains(where: { bundleID.lowercased().contains($0) }) {
            return "terminal"
        } else {
            return "native"
        }
    }
    
    private func isCurrentLayoutThai() -> Bool {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return false
        }
        guard let langPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages) else {
            return false
        }
        let languages = Unmanaged<CFArray>.fromOpaque(langPtr).takeUnretainedValue() as? [String] ?? []
        return languages.contains(where: { $0.hasPrefix("th") })
    }
}

// File-scope helper to redirect all print statements to both console and tinymind.log
fileprivate func print(_ items: Any...) {
    let message = items.map { String(describing: $0) }.joined(separator: " ")
    Swift.print(message)
    fflush(stdout)
    
    let fileManager = FileManager.default
    if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
        let appSupportDir = appSupport.appendingPathComponent("com.tinymind.tinymind")
        let logFile = appSupportDir.appendingPathComponent("tinymind.log")
        
        // Ensure directory exists
        try? fileManager.createDirectory(at: appSupportDir, withIntermediateDirectories: true, attributes: nil)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.string(from: Date())
        let logLine = "[\(timestamp)] [Swift] \(message)\n"
        
        if let data = logLine.data(using: .utf8) {
            if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            } else {
                try? data.write(to: logFile, options: .atomic)
            }
        }
    }
}
