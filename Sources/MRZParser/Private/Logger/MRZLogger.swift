
import os
import Foundation

enum LogLevel {
    case debug, info, error
}

final class MRZLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.MRZParser.app"
    
    #if DEBUG
    private static let isEnabled = true
    #else
    private static let isEnabled = false
    #endif

    private static func getLogger(for category: String) -> Logger {
        return Logger(subsystem: subsystem, category: category)
    }

    private static func log(_ message: String,
                            level: LogLevel,
                            tag: String) {
        guard isEnabled else { return }

        let logger = getLogger(for: tag)
        let fullMessage = "\(message)"

        switch level {
        case .debug:
            logger.debug("\(fullMessage, privacy: .public)")
        case .info:
            logger.info("\(fullMessage, privacy: .public)")
        case .error:
            logger.error("\(fullMessage, privacy: .public)")
        }
    }

    static func debug(_ message: String,
                      extraTag: String? = nil,
                      file: String = #file) {
        let className = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
        let tag = extraTag != nil ? "\(className).\(extraTag!)" : className
        log(message, level: .debug, tag: tag)
    }

    static func info(_ message: String,
                     extraTag: String? = nil,
                     file: String = #file) {
        let className = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
        let tag = extraTag != nil ? "\(className).\(extraTag!)" : className
        log(message, level: .info, tag: tag)
    }

    static func error(_ message: String,
                      extraTag: String? = nil,
                      file: String = #file) {
        let className = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
        let tag = extraTag != nil ? "\(className).\(extraTag!)" : className
        log(message, level: .error, tag: tag)
    }
}
