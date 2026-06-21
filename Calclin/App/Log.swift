//
//  Log.swift
//  Calc26
//
//  Created by sumpo/azukid on 2025/07/07.
//

import Foundation
import FirebaseCrashlytics


enum LogLevel: Int, Comparable {
    case info = 0
    case debug = 1
    case warning = 2
    case error = 3
    case fatal = 4
    
    var prefix: String {
        switch self {
            case .info:    return "(i)"
            case .debug:   return "(d)"
            case .warning: return "(W)"
            case .error:   return "[ERROR]"
            case .fatal:   return "[FATAL]"
        }
    }
    
    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var analyticsName: String {
        switch self {
        case .info:    return "info"
        case .debug:   return "debug"
        case .warning: return "warning"
        case .error:   return "error"
        case .fatal:   return "fatal"
        }
    }
}

#if DEBUG
let currentLogLevel: LogLevel = .info
#else
let currentLogLevel: LogLevel = .error
#endif

func log(_ level: LogLevel,
         _ message: String,
         file: String = #file,
         line: Int = #line,
         function: String = #function)
{
    guard currentLogLevel <= level else { return }
    
    let fileName = (file as NSString).lastPathComponent
    let printOut = "\(fileName)(\(line)) \(function) \(level.prefix) \(message)"
    print(printOut)

    switch level {
        case .error, .fatal:
            AppAnalytics.logAppError(level: level,
                                     fileName: fileName,
                                     function: function,
                                     line: line)
            // 計算内容やメモを含めないため、Crashlyticsにも発生箇所だけを記録する
            let error = NSError(domain: "Calclin.\(fileName).\(function)",
                                code: line,
                                userInfo: [
                                    "level": level.analyticsName,
                                    "file": fileName
                                ])
            Crashlytics.crashlytics().record(error: error)
        default:
            break
    }
}
