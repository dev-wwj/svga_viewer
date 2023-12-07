import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
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
        dialog.allowedFileTypes = ["svga"]
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
}
