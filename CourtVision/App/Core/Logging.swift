import Foundation

enum LogLevel: String {
    case debug
    case info
    case warning
    case error
}

enum Logging {
    /// Lightweight logging helper to keep debug prints consistent.
    static func log(_ message: String, level: LogLevel = .debug, file: String = #fileID, line: Int = #line) {
        #if DEBUG
        print("[\(level.rawValue.uppercased())] \(file):\(line) - \(message)")
        #endif
    }
}
