import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
    
    var flutterViewController: MyFlutterViewController?
    
    override func awakeFromNib() {
        let flutterViewController = MyFlutterViewController()
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)
        
        RegisterGeneratedPlugins(registry: flutterViewController)
        self.flutterViewController = flutterViewController
        super.awakeFromNib()
    }
}
