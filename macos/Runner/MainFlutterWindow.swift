import Cocoa
import FlutterMacOS
import LaunchAtLogin

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    // ซ่อน Dock icon ก่อน Flutter init
    NSApp.setActivationPolicy(.accessory)
    
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // ลงทะเบียนช่องทางควบคุมการเปิดแอปตอนเปิดเครื่อง (launch_at_startup MethodChannel)
    FlutterMethodChannel(
      name: "launch_at_startup",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    ).setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "launchAtStartupIsEnabled":
        result(LaunchAtLogin.isEnabled)
      case "launchAtStartupSetEnabled":
        if let arguments = call.arguments as? [String: Any],
           let setEnabledValue = arguments["setEnabledValue"] as? Bool {
          LaunchAtLogin.isEnabled = setEnabledValue
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
    
    // ซ่อนอีกครั้งหลัง super
    NSApp.setActivationPolicy(.accessory)
  }
}
