import AVFoundation
import Cocoa
import FlutterMacOS
import Foundation

struct MotionDocumentDescriptor {
    let id: String
    let url: URL
    let source: String
    let accessAvailable: Bool

    var dictionary: [String: Any] {
        [
            "id": id,
            "path": url.path,
            "displayName": url.lastPathComponent,
            "extension": url.pathExtension.lowercased(),
            "source": source,
            "accessAvailable": accessAvailable,
        ]
    }
}

final class DocumentAccessManager {
    static let shared = DocumentAccessManager()

    static let supportedExtensions: Set<String> = [
        "svga", "json", "gif", "webp", "apng", "png", "jpg", "jpeg",
        "bmp", "heic", "svg", "mp4", "mov", "m4v", "webm",
    ]

    private struct BookmarkRecord: Codable {
        let id: String
        let path: String
        let bookmark: String
    }

    private struct ActiveAccess {
        let url: URL
        var retainCount: Int
        let securityScoped: Bool
    }

    private let defaultsKey = "motion_preview.security_bookmarks.v1"
    private var records: [String: BookmarkRecord] = [:]
    private var activeAccess: [String: ActiveAccess] = [:]

    private init() {
        loadRecords()
    }

    func register(urls: [URL], source: String) -> [[String: Any]] {
        collectSupportedFiles(urls).map { register(url: $0, source: source).dictionary }
    }

    func register(url: URL, source: String, preferredId: String? = nil) -> MotionDocumentDescriptor {
        let standardizedURL = url.standardizedFileURL
        let existingId = records.values.first(where: { $0.path == standardizedURL.path })?.id
        let id = preferredId ?? existingId ?? UUID().uuidString

        var bookmarkText = ""
        do {
            let bookmark = try standardizedURL.bookmarkData(
                options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            bookmarkText = bookmark.base64EncodedString()
        } catch {
            Logger.write("Bookmark creation failed: \(standardizedURL.path)")
        }

        records[id] = BookmarkRecord(id: id, path: standardizedURL.path, bookmark: bookmarkText)
        saveRecords()
        let available = FileManager.default.fileExists(atPath: standardizedURL.path)
        if available { retain(id: id, url: standardizedURL) }
        return MotionDocumentDescriptor(
            id: id,
            url: standardizedURL,
            source: source,
            accessAvailable: available
        )
    }

    func resolve(savedDocuments: [[String: Any]]) -> [[String: Any]] {
        savedDocuments.map { saved in
            let id = saved["id"] as? String ?? UUID().uuidString
            let savedPath = saved["path"] as? String ?? ""
            var resolvedURL = URL(fileURLWithPath: savedPath)
            var available = false

            if let record = records[id],
               let data = Data(base64Encoded: record.bookmark),
               !data.isEmpty
            {
                do {
                    var stale = false
                    resolvedURL = try URL(
                        resolvingBookmarkData: data,
                        options: [.withSecurityScope, .withoutUI],
                        relativeTo: nil,
                        bookmarkDataIsStale: &stale
                    )
                    available = FileManager.default.fileExists(atPath: resolvedURL.path)
                    if available {
                        retain(id: id, url: resolvedURL)
                        if stale {
                            _ = register(url: resolvedURL, source: "restore", preferredId: id)
                            release(ids: [id])
                        }
                    }
                } catch {
                    available = false
                }
            } else {
                available = FileManager.default.fileExists(atPath: resolvedURL.path)
                if available { retain(id: id, url: resolvedURL) }
            }

            return MotionDocumentDescriptor(
                id: id,
                url: resolvedURL,
                source: "restore",
                accessAvailable: available
            ).dictionary
        }
    }

    func release(ids: [String]) {
        for id in ids {
            guard var access = activeAccess[id] else { continue }
            access.retainCount -= 1
            if access.retainCount <= 0 {
                if access.securityScoped { access.url.stopAccessingSecurityScopedResource() }
                activeAccess.removeValue(forKey: id)
            } else {
                activeAccess[id] = access
            }
        }
    }

    private func retain(id: String, url: URL) {
        if var existing = activeAccess[id] {
            existing.retainCount += 1
            activeAccess[id] = existing
            return
        }
        let scoped = url.startAccessingSecurityScopedResource()
        activeAccess[id] = ActiveAccess(url: url, retainCount: 1, securityScoped: scoped)
    }

    private func collectSupportedFiles(_ urls: [URL]) -> [URL] {
        var result: [URL] = []
        for url in urls {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
                continue
            }
            if isDirectory.boolValue {
                guard let enumerator = FileManager.default.enumerator(
                    at: url,
                    includingPropertiesForKeys: [.isRegularFileKey],
                    options: [.skipsHiddenFiles]
                ) else { continue }
                for case let child as URL in enumerator where Self.supportedExtensions.contains(child.pathExtension.lowercased()) {
                    result.append(child)
                }
            } else if Self.supportedExtensions.contains(url.pathExtension.lowercased()) {
                result.append(url)
            }
        }
        return result
    }

    private func loadRecords() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([String: BookmarkRecord].self, from: data)
        else { return }
        records = decoded
    }

    private func saveRecords() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}

final class MyFlutterViewController: FlutterViewController {
    private var pendingDocuments: [[String: Any]]
    private var ownedDocumentIds: Set<String> = []
    private let restoreSession: Bool
    private var eventSink: FlutterEventSink?

    init(
        engine: FlutterEngine,
        pendingDocuments: [[String: Any]] = [],
        restoreSession: Bool = false
    ) {
        self.pendingDocuments = pendingDocuments
        self.restoreSession = restoreSession
        super.init(engine: engine, nibName: nil, bundle: nil)
        _ = claim(pendingDocuments)
    }

    override init(project: FlutterDartProject?) {
        pendingDocuments = []
        restoreSession = false
        super.init(project: project)
    }

    required init(coder: NSCoder) {
        pendingDocuments = []
        restoreSession = true
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        _ = container

        RegisterGeneratedPlugins(registry: self)
        let messenger = engine.binaryMessenger
        let eventChannel = FlutterEventChannel(
            name: "com.motionpreview.documents",
            binaryMessenger: messenger
        )
        eventChannel.setStreamHandler(self)

        let methodChannel = FlutterMethodChannel(
            name: "com.motionpreview.workspace",
            binaryMessenger: messenger
        )
        methodChannel.setMethodCallHandler { [weak self] call, result in
            guard let self else {
                result(nil)
                return
            }
            handle(call: call, result: result)
        }
    }

    lazy var container: DragContainer = {
        let container = DragContainer()
        container.delegate = self
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        return container
    }()

    func receiveDocuments(_ documents: [[String: Any]]) {
        guard !documents.isEmpty else { return }
        let newDocuments = claim(documents)
        guard !newDocuments.isEmpty else { return }
        if let eventSink {
            eventSink(["documents": newDocuments])
        } else {
            pendingDocuments.append(contentsOf: newDocuments)
        }
    }

    func releaseOwnedDocuments() {
        DocumentAccessManager.shared.release(ids: Array(ownedDocumentIds))
        ownedDocumentIds.removeAll()
    }

    func toggleInspectorFromTitleBar() {
        let channel = FlutterMethodChannel(
            name: "com.motionpreview.workspace",
            binaryMessenger: engine.binaryMessenger
        )
        channel.invokeMethod("toggleInspector", arguments: nil)
    }

    private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "workspaceContext":
            result(["restoreSession": restoreSession])
        case "takePendingDocuments":
            let documents = pendingDocuments
            pendingDocuments.removeAll()
            result(["documents": documents])
        case "showOpenPanel":
            guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else {
                result(false)
                return
            }
            appDelegate.openPanelInSeparateWindows()
            result(true)
        case "createWorkspaceWindow":
            guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else {
                result(false)
                return
            }
            appDelegate.createWorkspaceWindow()
            result(true)
        case "showResourceWindow":
            guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else {
                result(false)
                return
            }
            result(appDelegate.showResourceWindow(for: self))
        case "openDocument":
            guard let appDelegate = NSApplication.shared.delegate as? AppDelegate,
                  let arguments = call.arguments as? [String: Any],
                  let path = arguments["path"] as? String
            else {
                result(false)
                return
            }
            appDelegate.openFiles([URL(fileURLWithPath: path)], source: "restore")
            result(true)
        case "resolveBookmarks":
            let arguments = call.arguments as? [String: Any]
            let saved = arguments?["documents"] as? [[String: Any]] ?? []
            let documents = DocumentAccessManager.shared.resolve(savedDocuments: saved)
            result(["documents": claim(documents)])
        case "releaseDocuments":
            let arguments = call.arguments as? [String: Any]
            let ids = arguments?["ids"] as? [String] ?? []
            ownedDocumentIds.subtract(ids)
            DocumentAccessManager.shared.release(ids: ids)
            result(nil)
        case "locateMissingDocument":
            let arguments = call.arguments as? [String: Any]
            let id = arguments?["id"] as? String ?? UUID().uuidString
            result(["documents": locateDocument(id: id)])
        case "mediaMetadata":
            let arguments = call.arguments as? [String: Any]
            let path = arguments?["path"] as? String ?? ""
            result(mediaMetadata(path: path))
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func claim(_ documents: [[String: Any]]) -> [[String: Any]] {
        documents.filter { document in
            guard let id = document["id"] as? String else { return false }
            if ownedDocumentIds.contains(id) {
                DocumentAccessManager.shared.release(ids: [id])
                return false
            }
            ownedDocumentIds.insert(id)
            return true
        }
    }

    private func locateDocument(id: String) -> [[String: Any]] {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedFileTypes = Array(DocumentAccessManager.supportedExtensions).sorted()
        guard panel.runModal() == .OK, let url = panel.url else { return [] }
        let descriptor = DocumentAccessManager.shared.register(
            url: url,
            source: "openPanel",
            preferredId: id
        ).dictionary
        ownedDocumentIds.insert(id)
        return [descriptor]
    }

    private func mediaMetadata(path: String) -> [String: Any] {
        let asset = AVURLAsset(url: URL(fileURLWithPath: path))
        guard let track = asset.tracks(withMediaType: .video).first else { return [:] }
        let transformedSize = track.naturalSize.applying(track.preferredTransform)
        var metadata: [String: Any] = [
            "width": abs(transformedSize.width),
            "height": abs(transformedSize.height),
            "frameRate": track.nominalFrameRate,
            "durationMs": CMTimeGetSeconds(asset.duration) * 1000,
        ]
        if let description = track.formatDescriptions.first {
            let subtype = CMFormatDescriptionGetMediaSubType(description as! CMFormatDescription)
            let characters = [
                Character(UnicodeScalar((subtype >> 24) & 0xff)!),
                Character(UnicodeScalar((subtype >> 16) & 0xff)!),
                Character(UnicodeScalar((subtype >> 8) & 0xff)!),
                Character(UnicodeScalar(subtype & 0xff)!),
            ]
            metadata["codec"] = String(characters)
        }
        return metadata
    }
}

extension MyFlutterViewController: FlutterStreamHandler {
    func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        eventSink = events
        if !pendingDocuments.isEmpty {
            events(["documents": pendingDocuments])
            pendingDocuments.removeAll()
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}

extension MyFlutterViewController: DragContainerDelegate {
    func draggingEntered() {}
    func draggingExit() {}

    func draggingFileAccept(_ files: [FileInfo]) {
        let urls = files.map(\.filePath)
        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.openFiles(urls, source: "drag")
    }
}
