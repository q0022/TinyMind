import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    // ซ่อน Dock icon ก่อน Flutter init
    NSApp.setActivationPolicy(.accessory)
    
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
    
    // ซ่อนอีกครั้งหลัง super
    NSApp.setActivationPolicy(.accessory)
    
    // ตั้ง Timer บังคับซ่อนซ้ำอีก 3 ครั้งใน 3 วินาทีแรก
    // เพื่อชนะ Flutter internal setup ที่อาจรีเซ็ตกลับ
    var count = 0
    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
      NSApp.setActivationPolicy(.accessory)
      count += 1
      if count >= 3 {
        timer.invalidate()
      }
    }
  }
}
