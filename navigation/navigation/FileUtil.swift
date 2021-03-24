//
//  FileUtil.swift
//  navigation
//
//  Created by 郑旭 on 2021/1/31.
//

import Foundation

class FileUtils {

    static func urlFile(_ name:String) ->URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH_mm_ss"
        let dateString = formatter.string(from: Date()) + name
        let fileName = "\(dateString).txt"
        return documentsDirectory.appendingPathComponent(fileName)
    }

    static func fileWrite(_ toFile: URL, _ message: String) {
        /*let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
         */
        guard let data = (message + "\n").data(using: String.Encoding.utf8) else { return }

        if FileManager.default.fileExists(atPath: toFile.path) {
            if let fileHandle = try? FileHandle(forWritingTo: toFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } else {
            try? data.write(to: toFile, options: .atomicWrite)
        }
    }
    
    static func writeStrings(_ toFile: URL,_ data: [String]){
        for str in data {
            fileWrite(toFile, str)
        }
    }
}
