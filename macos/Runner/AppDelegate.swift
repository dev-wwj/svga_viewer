import Cocoa
import AVFoundation
import FlutterMacOS

final class InspectorTitlebarAccessory: NSTitlebarAccessoryViewController {
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
        super.init(nibName: nil, bundle: nil)
        layoutAttribute = .right
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 34, height: 28))
        let image: NSImage
        if #available(macOS 11.0, *),
           let symbol = NSImage(
               systemSymbolName: "sidebar.right",
               accessibilityDescription: "Show or hide inspector"
           ) {
            image = symbol
        } else if let sidebar = NSImage(named: NSImage.Name("NSImageNameSidebar")) {
            image = sidebar
        } else {
            image = NSImage(size: NSSize(width: 18, height: 18))
        }
        let button = NSButton(
            image: image,
            target: self,
            action: #selector(toggleInspector)
        )
        button.isBordered = false
        button.bezelStyle = .texturedRounded
        button.toolTip = "Show or hide inspector"
        button.setAccessibilityLabel("Show or hide inspector")
        button.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 24),
            button.heightAnchor.constraint(equalToConstant: 24),
        ])
        view = container
    }

    @objc private func toggleInspector() {
        action()
    }
}

@main
class AppDelegate: FlutterAppDelegate {
    private var extraWindows: [NSWindow] = []
    private var engines: [ObjectIdentifier: FlutterEngine] = [:]
    private var titlebarAccessories: [ObjectIdentifier: InspectorTitlebarAccessory] = [:]
    private var documentIDsByWindow: [ObjectIdentifier: Set<String>] = [:]
    private var activeDocumentIDs: Set<String> = []
    private var pendingLaunchDocuments: [[String: Any]] = []
    private var pendingMainReveal: DispatchWorkItem?
    private var resourceOpenInProgress = false

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    override func applicationDidFinishLaunching(_ notification: Notification) {
        super.applicationDidFinishLaunching(notification)
        // Flutter asks window_manager to show the main window during startup.
        // Hold it briefly so a cold-start Finder open can be routed directly
        // to a resource window without flashing the workspace first.
        mainFlutterWindow?.orderOut(nil)
        let reveal = DispatchWorkItem { [weak self] in
            guard let self, extraWindows.isEmpty, !resourceOpenInProgress else { return }
            mainFlutterWindow?.makeKeyAndOrderFront(nil)
            pendingMainReveal = nil
        }
        pendingMainReveal = reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: reveal)
        DispatchQueue.main.async { [weak self] in
            guard let self, !pendingLaunchDocuments.isEmpty else { return }
            pendingMainReveal?.cancel()
            pendingMainReveal = nil
            mainFlutterWindow?.orderOut(nil)
            openDocumentWindows(pendingLaunchDocuments)
            pendingLaunchDocuments.removeAll()
        }
    }

    override func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        if !flag {
            if resourceOpenInProgress || !extraWindows.isEmpty {
                return true
            }
            pendingMainReveal?.cancel()
            pendingMainReveal = nil
            if let mainFlutterWindow {
                mainFlutterWindow.makeKeyAndOrderFront(nil)
            } else {
                createWorkspaceWindow()
            }
        }
        return true
    }

    override func application(_ application: NSApplication, open urls: [URL]) {
        openFiles(urls, source: "finder")
    }

    @IBAction func open(_ sender: Any) {
        openPanelInSeparateWindows()
    }

    func selectDocuments() -> [[String: Any]] {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.showsHiddenFiles = false
        panel.allowedFileTypes = Array(DocumentAccessManager.supportedExtensions).sorted()
        guard panel.runModal() == .OK else { return [] }
        let documents = DocumentAccessManager.shared.register(
            urls: panel.urls,
            source: "openPanel"
        )
        return documents
    }

    func openPanelInSeparateWindows() {
        let documents = selectDocuments()
        if !documents.isEmpty {
            resourceOpenInProgress = true
            pendingMainReveal?.cancel()
            pendingMainReveal = nil
            mainFlutterWindow?.orderOut(nil)
        }
        openDocumentWindows(documents)
    }

    func openFiles(
        _ files: [URL],
        source: String
    ) {
        let documents = DocumentAccessManager.shared.register(urls: files, source: source)
        guard !documents.isEmpty else {
            showOpenFailedAlert()
            return
        }
        resourceOpenInProgress = true
        pendingMainReveal?.cancel()
        pendingMainReveal = nil
        if source == "finder" || source == "drag" {
            mainFlutterWindow?.orderOut(nil)
        }
        openDocumentWindows(documents)
    }

    private func openDocumentWindows(_ documents: [[String: Any]]) {
        for document in documents {
            guard let id = document["id"] as? String, !id.isEmpty else { continue }
            guard !activeDocumentIDs.contains(id) else {
                // register(url:) retains access for every registration. Balance
                // a duplicate open event that does not create a new window.
                DocumentAccessManager.shared.release(ids: [id])
                continue
            }
            activeDocumentIDs.insert(id)
            let window = createWorkspaceWindow(pendingDocuments: [document])
            documentIDsByWindow[ObjectIdentifier(window)] = [id]
        }
    }

    @discardableResult
    func createWorkspaceWindow(
        pendingDocuments: [[String: Any]] = []
    ) -> NSWindow {
        let engine = FlutterEngine(
            name: "motion-preview-window-\(UUID().uuidString)",
            project: nil
        )
        _ = engine.run(withEntrypoint: nil)

        let flutterViewController = MyFlutterViewController(
            engine: engine,
            pendingDocuments: pendingDocuments,
            restoreSession: false
        )
        let windowSize = preferredWindowSize(for: pendingDocuments.first)
        let window = MainFlutterWindow(
            contentRect: NSRect(origin: .zero, size: windowSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Motion Preview"
        window.backgroundColor = NSColor.windowBackgroundColor
        window.isOpaque = true
        window.minSize = pendingDocuments.isEmpty
            ? NSSize(width: 760, height: 520)
            : minimumWindowSize(for: pendingDocuments.first)
        window.isReleasedWhenClosed = false
        window.contentViewController = flutterViewController
        window.flutterViewController = flutterViewController
        // Force the Flutter view to attach before showing the resource window.
        _ = flutterViewController.view
        window.delegate = self
        if !pendingDocuments.isEmpty {
            let accessory = InspectorTitlebarAccessory { [weak flutterViewController] in
                flutterViewController?.toggleInspectorFromTitleBar()
            }
            window.addTitlebarAccessoryViewController(accessory)
            titlebarAccessories[ObjectIdentifier(window)] = accessory
        }
        window.center()
        // Keep resource windows visible while Flutter loads their first frame.
        // The preview renders its own loading state, so startup cannot end
        // with an invisible window if a decoder callback is delayed.
        window.makeKeyAndOrderFront(nil)

        extraWindows.append(window)
        engines[ObjectIdentifier(window)] = engine
        return window
    }

    func showResourceWindow(for controller: MyFlutterViewController) -> Bool {
        guard let window = extraWindows.first(where: {
            $0.contentViewController === controller
        }) else {
            return false
        }
        if !window.isVisible {
            window.center()
            NSApp.activate(ignoringOtherApps: true)
            window.orderFrontRegardless()
            window.makeKey()
        }
        return true
    }

    private func preferredWindowSize(for document: [String: Any]?) -> NSSize {
        let fallback = NSSize(width: 900, height: 640)
        guard let path = document?["path"] as? String else { return fallback }
        let url = URL(fileURLWithPath: path)
        let resourceSize: CGSize?
        if let image = NSImage(contentsOf: url), image.size.width > 0,
           image.size.height > 0 {
            resourceSize = image.size
        } else if ["mp4", "mov", "m4v", "webm"].contains(url.pathExtension.lowercased()) {
            let asset = AVURLAsset(url: url)
            if let track = asset.tracks(withMediaType: .video).first {
                let size = track.naturalSize.applying(track.preferredTransform)
                resourceSize = CGSize(width: abs(size.width), height: abs(size.height))
            } else {
                resourceSize = nil
            }
        } else {
            resourceSize = nil
        }
        guard let resourceSize, resourceSize.width > 0, resourceSize.height > 0 else {
            return fallback
        }

        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let chromeHeight: CGFloat = 76
        let maxSize = CGSize(
            width: min(1400, screenFrame.width * 0.86),
            height: min(1000, screenFrame.height * 0.82) - chromeHeight
        )
        let scale = min(maxSize.width / resourceSize.width, maxSize.height / resourceSize.height, 1.0)
        var width = resourceSize.width * scale
        var height = resourceSize.height * scale
        let minimum = minimumWindowSize(for: document)
        let minimumScale = max(minimum.width / width, minimum.height / height, 1.0)
        width *= minimumScale
        height *= minimumScale
        return NSSize(
            width: min(width, maxSize.width),
            height: min(height, maxSize.height) + chromeHeight
        )
    }

    private func minimumWindowSize(for document: [String: Any]?) -> NSSize {
        let extensionName = (document?["extension"] as? String ?? "").lowercased()
        let usesTransport = ["svga", "json", "gif", "webp", "apng", "mp4", "mov", "m4v", "webm"]
            .contains(extensionName)
        return usesTransport
            ? NSSize(width: 800, height: 520)
            : NSSize(width: 640, height: 420)
    }

    private func showOpenFailedAlert() {
        guard let window = NSApplication.shared.keyWindow ?? mainFlutterWindow else { return }
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "No supported resources found"
        alert.informativeText = "Choose a supported animation, image, SVG, or video file."
        alert.beginSheetModal(for: window)
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        (window.contentViewController as? MyFlutterViewController)?.releaseOwnedDocuments()

        guard let index = extraWindows.firstIndex(where: { $0 === window }) else { return }
        extraWindows.remove(at: index)
        let identifier = ObjectIdentifier(window)
        titlebarAccessories.removeValue(forKey: identifier)
        if let documentIDs = documentIDsByWindow.removeValue(forKey: identifier) {
            activeDocumentIDs.subtract(documentIDs)
        }
        if extraWindows.isEmpty {
            resourceOpenInProgress = false
        }
        engines.removeValue(forKey: identifier)?.shutDownEngine()
    }
}
