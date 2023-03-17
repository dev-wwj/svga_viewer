import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    override func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return true
    }
    
    override func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return true
    }
    
    override func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let fileURLs = filenames.compactMap { URL(fileURLWithPath: $0) }
        self.openFiles(fileURLs)
        sender.reply(toOpenOrPrint: .success)
        
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
    
    @IBAction func openFile(_ sender: Any) {
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
    
    func openFiles(_ files: [URL]) {
        //        let alert = NSAlert()
        //        alert.informativeText = "openFile\(String(describing: files.first?.absoluteString))"
        //        alert.alertStyle = .warning
        //        alert.beginSheetModal(for: self.mainFlutterWindow)
        //        _ = self.mainFlutterWindow
        for file in files {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: file.path, isDirectory: &isDirectory) else {
                continue
            }
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let data = try? Data(contentsOf: file)
                DispatchQueue.main.async {
                    self?.windowShow(data: data!)
                }
            }
        }
    }
    
    func windowShow(data: Data) {
        if let window = self.mainFlutterWindow as? MainFlutterWindow {
            window.load(data: data)
        }
    }
}
