import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    
    @IBOutlet weak var showProperty: NSMenuItem!
    
    override func applicationDidBecomeActive(_ notification: Notification) {
        super.applicationDidBecomeActive(notification)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showProperty.state = .off
        }
    }
    
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    override func application(_ application: NSApplication, open urls: [URL]) {
        openFiles(urls)
        super.application(application, open: urls)
    }
    
    override func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        return super.application(sender, openFile: filename)
    }
    
    override func application(_ sender: NSApplication, openFiles filenames: [String]) {
        super.application(sender, openFiles: filenames)
        Logger.write("openFiles: \(filenames.first ?? "")")
    }
    
    @IBAction func open(_ sender: Any) {
        let dialog = NSOpenPanel()
        dialog.allowsMultipleSelection = false
        dialog.canChooseFiles = true
        dialog.showsHiddenFiles = true
        dialog.canCreateDirectories = true
        dialog.canChooseDirectories = true
        dialog.allowedFileTypes = ["svga","json"]
        guard
            dialog.runModal() == .OK,
            let result = dialog.url
        else { return }
        openFiles([result])
    }
    
    func openFiles(_ files: [URL]){
        Logger.write(files.first?.absoluteString ?? "")
        if let window = self.mainFlutterWindow as? MainFlutterWindow {
            window.flutterViewController?.openFiles(files)
        }
    }
    
    @IBAction func showProperty(_ sender: Any) {
        print("/////---showProperty-----")
        UserDefaults.standard.setValue(true, forKey:"Property Hide")
    }
    
}
