//
//  DragContainer.swift
//  Runner
//
//  Created by wangwenjian on 2023/12/5.
//

import Foundation
import Cocoa

protocol DragContainerDelegate {
    func draggingEntered();
    func draggingExit();
    func draggingFileAccept(_ files:Array<FileInfo>);
}

class DragContainer: NSView {
    var delegate : DragContainerDelegate?
    
    let acceptTypes = ["svga"]
    let NSFilenamesPboardType = NSPasteboard.PasteboardType("NSFilenamesPboardType")
    
    let normalAlpha: CGFloat = 0
    let highlightAlpha: CGFloat = 0.2
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.registerForDraggedTypes([
            NSPasteboard.PasteboardType.backwardsCompatibleFileURL,
            NSPasteboard.PasteboardType(rawValue: kUTTypeItem as String)
            ]);
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.registerForDraggedTypes([
            NSPasteboard.PasteboardType.backwardsCompatibleFileURL,
            NSPasteboard.PasteboardType(rawValue: kUTTypeItem as String)
            ]);
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        self.layer?.backgroundColor = NSColor(white: 1, alpha: highlightAlpha).cgColor;
        if let delegate = self.delegate {
            delegate.draggingEntered();
        }
        return NSDragOperation.generic
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        self.layer?.backgroundColor = NSColor(white: 1, alpha: normalAlpha).cgColor;
        if let delegate = self.delegate {
            delegate.draggingExit();
        }
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        self.layer?.backgroundColor = NSColor(white: 1, alpha: normalAlpha).cgColor;
        return true
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        var files = Array<FileInfo>()
        if let board = sender.draggingPasteboard.propertyList(forType: NSFilenamesPboardType) as? NSArray {
            for path in board {
                files.append(contentsOf: collectFiles(path as! String))
            }
        }
        
        if self.delegate != nil {
            self.delegate?.draggingFileAccept(files);
        }
        
        return true
    }
    
    func collectFiles(_ filePath: String) -> Array<FileInfo> {
        var files = Array<FileInfo>()
        let isDirectory = IOHeler.isDirectory(filePath)
        if isDirectory {
            let fileManager = FileManager.default
            let enumerator = fileManager.enumerator(atPath: filePath)
            while let relativePath = enumerator?.nextObject() as? String {
                let fullFilePath = filePath.appending("/\(relativePath)")
                if (fileIsAcceptable(fullFilePath)) {
                    let parent = URL(fileURLWithPath: filePath).lastPathComponent
                    files.append(FileInfo(URL(fileURLWithPath: fullFilePath), relativePath:"\(parent)/\(relativePath)"))
                }
            }
        } else if (fileIsAcceptable(filePath)) {
            let url = URL(fileURLWithPath: filePath)
            files.append(FileInfo(url, relativePath:url.lastPathComponent))
        }
        return files
    }
    
    func fileIsAcceptable(_ path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        let fileExtension = url.pathExtension.lowercased()
        return acceptTypes.contains(fileExtension)
    }
}

class FileInfo {
    var filePath: URL
    var relativePath: String
    
    init(_ filePath: URL, relativePath: String) {
        self.filePath = filePath
        self.relativePath = relativePath
    }
}

class IOHeler {
    static let sOutPutFolderName = "tinypng_output"
    
    static var sOutputPath = ""
    
    static func getOutputPath() -> URL {
        let fileManager = FileManager.default
        var path: URL!
        if sOutputPath == "" {
            let directoryURL = fileManager.urls(for: .desktopDirectory, in: .userDomainMask)[0]
            path = directoryURL.appendingPathComponent(sOutPutFolderName, isDirectory: true)
        } else {
            path = URL(fileURLWithPath: sOutputPath)
        }
        if !fileManager.fileExists(atPath: path!.path) {
            try! fileManager.createDirectory(at: path!, withIntermediateDirectories: true, attributes: nil)
        }
        return path!
    }
    
    static func getDefaultOutputPath() -> URL {
        let fileManager = FileManager.default
        let directoryURL = fileManager.urls(for: .desktopDirectory, in: .userDomainMask)[0]
        let path = directoryURL.appendingPathComponent(sOutPutFolderName, isDirectory: true)
        return path
    }
    
    static func deleteOnExists(_ file: URL) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: file.path) {
            try! fileManager.removeItem(at: file)
        }
    }
    
    static func isDirectory(_ path: String) -> Bool {
        let fileManager = FileManager.default
        var isDirectory = ObjCBool(false)
        let fileExists = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        return fileExists && isDirectory.boolValue
    }
}

extension NSPasteboard.PasteboardType {
    static let backwardsCompatibleFileURL: NSPasteboard.PasteboardType = {
        if #available(OSX 10.13, *) {
            return NSPasteboard.PasteboardType.fileURL
        } else {
            return NSPasteboard.PasteboardType(kUTTypeFileURL as String)
        }
    } ()
}
