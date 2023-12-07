//
//  MyFlutterViewController.swift
//  Runner
//
//  Created by wangwenjian on 2023/12/5.
//

import Foundation
import FlutterMacOS

class MyFlutterViewController: FlutterViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _ = container
        
        RegisterGeneratedPlugins(registry: self)
        if let messager = self.engine.binaryMessenger as? FlutterBinaryMessenger {
            let channel = FlutterEventChannel(name: "com.push.data", binaryMessenger: messager)
            channel.setStreamHandler(self)
        }
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

    var dataBits: [UInt8]? = nil
    
    func load(data: Data) {
        dataBits = [UInt8](data)
        self.eventSink?(self.dataBits!)
    }
    
    func openFiles(_ files: [URL]) {
        for file in files {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: file.path, isDirectory: &isDirectory) else {
                continue
            }
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                do {
                    let data = try Data(contentsOf: file)
                    self?.load(data: data)
                } catch {
                    
                }
            }
        }
    }
}

extension MyFlutterViewController: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        events(self.dataBits)  //openFiles在前, onListen在后, 在onListen 建立成功后将 data 传输给flutter
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
