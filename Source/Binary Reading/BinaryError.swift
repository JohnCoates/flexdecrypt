//
//  BinaryError.swift
//  Created on 6/12/20
//

import Foundation

enum BinaryError: Error {
    case notEnoughData
    case tooMuchData
    case invalidString(bytes: [UInt8])
    case message(_ message: String)
}
