import Cocoa
import FlutterMacOS
import window_manager

class MainFlutterWindow: NSWindow {
    
    var flutterViewController: MyFlutterViewController?
    
    override func awakeFromNib() {
        let flutterViewController = MyFlutterViewController(project: nil)
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        self.backgroundColor = NSColor.windowBackgroundColor
        self.isOpaque = true
        self.setFrame(windowFrame, display: true)
        
        self.flutterViewController = flutterViewController
        super.awakeFromNib()
    }
    
    override func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
        super.order(place, relativeTo: otherWin)
    }
    
}
