//
//  FLXLog.swift
//  Created on 6/30/20
//

import Foundation

struct FLXLog {
    static func `internal`(_ message: String) {
        guard printInternalMessages else { return }
        print(message)
    }

    static var printInternalMessages = false
}
