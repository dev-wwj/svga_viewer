//
//  MyFlutterViewController.swift
//  Runner
//
//  Created by wangwenjian on 2023/12/5.
//

import Foundation
import FlutterMacOS

struct FileItem: Codable {
    let name: String
    let data: Data
    
    init(name: String, data: Data) {
        self.name = name
        self.data = data
    }
    
    enum CodingKeys: CodingKey {
        case name
        case data
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.data = try container.decode(Data.self, forKey: .data)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(String(data: data.base64EncodedData(),
                                    encoding: .ascii),
                             forKey: .data)
    }
}

class MyFlutterViewController: FlutterViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _ = container
        
        RegisterGeneratedPlugins(registry: self)
        let messager = self.engine.binaryMessenger
        let channel = FlutterEventChannel(name: "com.push.data",
                                          binaryMessenger: messager)
        channel.setStreamHandler(self)
    }
    
    lazy var container: DragContainer = {
        let container = DragContainer()
        container.delegate = self
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        // 创建约束：子视图的四个边与父视图的四个边相等，以确保填充到父视图
        let leadingConstraint = NSLayoutConstraint(item: container, attribute: .leading, relatedBy: .equal,toItem: view, attribute: .leading, multiplier: 1.0, constant: 0)
        let trailingConstraint = NSLayoutConstraint(item: container, attribute: .trailing, relatedBy: .equal,toItem: view, attribute: .trailing, multiplier: 1.0, constant: 0)
        let topConstraint = NSLayoutConstraint(item: container, attribute: .top, relatedBy: .equal,toItem: view, attribute: .top, multiplier: 1.0, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: container, attribute: .bottom, relatedBy: .equal,toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0)
        view.addConstraints([leadingConstraint, trailingConstraint, topConstraint, bottomConstraint])
        return container
    }()
    
    var eventSink:FlutterEventSink? = nil

    var file: Any? = nil
    
    func sendToFlutter(file: FileItem) {
        
        let fileBase64 = file.data.base64EncodedString()
        let message = ["name": file.name, "data": fileBase64]
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(file)
            let dataBits = [UInt8](data)
            if let eventSink {
                eventSink(message)
            } else {
                self.file = message
            }
        } catch {
        }
        
    }
    
    func openFiles(_ files: [URL]) {
        for file in files {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: file.path, isDirectory: &isDirectory) else {
                continue
            }
            do {
                let data = try Data(contentsOf: file)
                let name = file.relativePath
                let item = FileItem(name: name, data: data)
                self.sendToFlutter(file: item)
            } catch {
            }
        }
    }
}

extension MyFlutterViewController: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        //openFiles在前, onListen在后, 在onListen 建立成功后将 data 传输给flutter
        if let file {
            events(file)
        }
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }
}

extension MyFlutterViewController: DragContainerDelegate{
    func draggingEntered() {
        
    }
    
    func draggingExit() {
        
    }
    
    func draggingFileAccept(_ files: Array<FileInfo>) {
        let urls = files.map { $0.filePath }
        openFiles(urls)
    }
    
    
}
