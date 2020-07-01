//
//  ArchitectureValue.swift
//  Created on 10/5/19
//

import Foundation

enum ArchitectureValue<Architecture32, Architecture64> {
    case arch32(data: Architecture32)
    case arch64(data: Architecture64)

    var size: Int {
        switch self {
        case .arch32:
            return MemoryLayout<Architecture32>.size
        case .arch64:
            return MemoryLayout<Architecture64>.size
        }
    }
}

enum Architecture {
    case arch32
    case arch64
}
