//
//  Logger.swift
//  Runner
//
//  Created by wangwenjian on 2023/12/6.
//

import Cocoa

class Logger {
    private let logFileName = "AppLog.txt"
    static let logger = Logger()
    
    class func write(_ log: String) {
        logger.writeLog(log)
    }
    
    init() {
        setupLogFile()
    }

    private func setupLogFile() {
        // 获取应用程序文档目录路径
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access documents directory.")
        }

        // 拼接日志文件的完整路径
        let logFileURL = documentsDirectory.appendingPathComponent(logFileName)

        // 创建日志文件（如果文件不存在）
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
        }
    }

    func writeLog(_ logMessage: String) {
        // 获取应用程序文档目录路径
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access documents directory.")
        }

        // 拼接日志文件的完整路径
        let logFileURL = documentsDirectory.appendingPathComponent(logFileName)

        // 打开文件句柄以进行写入
        if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
            // 将文件句柄移动到文件末尾
            fileHandle.seekToEndOfFile()

            // 将日志消息转换为 Data，并写入文件
            if let data = "\(Date().timeIntervalSince1970)".appending(":").appending(logMessage) .appending("\n").data(using: .utf8) {
                fileHandle.write(data)
            }

            // 关闭文件句柄
            fileHandle.closeFile()
        }
    }
}

