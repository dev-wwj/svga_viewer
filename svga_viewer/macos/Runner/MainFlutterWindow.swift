import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
        let flutterViewController = FlutterViewController.init()
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)
        
        RegisterGeneratedPlugins(registry: flutterViewController)
        if let messager = flutterViewController.engine.binaryMessenger as? FlutterBinaryMessenger {
            let channel = FlutterEventChannel(name: "com.push.data", binaryMessenger: messager)
            channel.setStreamHandler(self)
        }
        super.awakeFromNib()
    }
    
    var eventSink:FlutterEventSink? = nil

    var dataBits: [UInt8]? = nil
    func load(data: Data) {
        dataBits = [UInt8](data)
        self.eventSink?(self.dataBits!)
    }
}

extension MainFlutterWindow: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        events(self.dataBits)
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }
}

