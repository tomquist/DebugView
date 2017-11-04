import Foundation
import AppKit

extension String {
    @discardableResult
    func run(with arguments: String...) throws -> String? {
        let process = Process()
        process.launchPath = self
        process.arguments = arguments
        let out = Pipe()
        process.standardOutput = out
        process.launch()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }
    
    public var dotImage: NSImage? {
        do {
            let inFile = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer {
                try? FileManager.default.removeItem(at: inFile)
            }
            try write(to: inFile, atomically: true, encoding: .utf8)
            let outFile = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try "/usr/local/bin/dot".run(with: "-Tpng", "-o\(outFile.path)", inFile.path)
            defer {
                try? FileManager.default.removeItem(at: outFile)
            }
            return NSImage(contentsOf: outFile)
        } catch {
            return nil
        }
        
    }
}
