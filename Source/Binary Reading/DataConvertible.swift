//
//  DataConvertible.swift
//  Created on 6/12/20
//

import Foundation

enum Endian {
    case big
    case little
}

protocol DataConvertible {
    init(data: Data, endian: Endian) throws
}

extension DataConvertible where Self: FixedWidthInteger {
    init(data: Data, endian: Endian = .little) throws {
        var value: Self = 0
        let valueSize = MemoryLayout.size(ofValue: value)
        guard data.count == valueSize else {
            if data.count < valueSize {
                throw BinaryError.notEnoughData
            } else {
                throw BinaryError.tooMuchData
            }
        }

        _ = withUnsafeMutablePointer(to: &value, {
            data.copyBytes(to: UnsafeMutableBufferPointer(start: $0, count: 1))
        })

        self = value
        if case .big = endian {
            self = self.bigEndian
        }
    }
}

extension UInt8: DataConvertible {}
extension Int8: DataConvertible {}
extension UInt16: DataConvertible {}
extension Int16: DataConvertible {}
extension UInt32: DataConvertible {}
extension Int32: DataConvertible {}
extension UInt64: DataConvertible {}
extension Int64: DataConvertible {}
extension UInt: DataConvertible {}
extension Int: DataConvertible {}
