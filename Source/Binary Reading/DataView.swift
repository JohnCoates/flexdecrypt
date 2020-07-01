//
//  DataView.swift
//  Created on 6/12/20
//

import Foundation

struct DataView {
    let data: Data
    var offset: Int
    var pointer: UnsafeMutableRawPointer?
    var startAddress: UInt?
    var endAddress: UInt?
    var slide: Int?

    init(data: Data, offset: Int = 0, pointer: UnsafeMutableRawPointer? = nil, slide: Int? = nil) {
        self.data = data
        self.offset = offset
        self.pointer = pointer
        if let slide = slide {
            self.slide = slide
        }
        if let pointer = pointer {
            let start = UInt(bitPattern: pointer)
            let end = start + UInt(data.count)
            startAddress = start
            endAddress = end
        }
    }

    mutating func read<T: DataConvertible>(endian: Endian = .little) throws -> T {
        let size = MemoryLayout<T>.size
        let range: Range<Data.Index> = offset..<offset + size
        let sliceData = data.subdata(in: range)

        var value: T
        value = try T(data: sliceData, endian: endian)
        offset += size

        return value
    }

    mutating func readString() throws -> String? {
        var bytes = [UInt8]()
        while bytes.last != 0 {
            try bytes.append(read())
        }

        return String(bytes: bytes.dropLast(), encoding: .utf8)
    }

    func immutableReadString() throws -> String {
        var copy = self
        var bytes = [UInt8]()

        while bytes.last != 0 {
            try bytes.append(copy.read())
        }
        bytes = bytes.dropLast()

        guard let string = String(bytes: bytes, encoding: .utf8) else {
            throw BinaryError.invalidString(bytes: bytes)
        }

        return string
    }

    func with(offset: Int) -> DataView {
        var copy = self
        copy.offset = offset
        return copy
    }

    /// Use address if this data view has address information.
    /// Otherwise fallback to offset.
    func with(offset: Int?, address: UInt, slid: Bool) throws -> DataView {
        if let offset = offset, slide == nil {
            return with(offset: offset)
        }

        return try with(address: address, slid: slid)
    }

    func with(address: UInt, slid: Bool) throws -> DataView {
        let (target, start, end) = try self.info(forAddress: address, slid: slid)

        guard target >= start, target < end else {
            throw Error.addressOutOfBounds(address: target)
        }

        var copy = self
        copy.offset = Int(target - start)
        return copy
    }

    func withCString(offset: Int?, address: UInt, slid: Bool) throws -> DataView {
        if let offset = offset, slide == nil {
            return with(offset: offset)
        }

        let target = try self.info(forAddress: address, slid: slid).target

        guard let pointer = UnsafePointer<UInt8>(bitPattern: target) else {
            throw Error.invalidAddress(address: target)
        }

        var position = pointer
        while position.pointee != 0 {
            position = position.advanced(by: 1)
        }

        let bytes = pointer.distance(to: position) + 1
        return try with(offset: nil, address: address, slid: slid, bytes: bytes)
    }

    func with<T>(offset: Int?, address: UInt, slid: Bool, targetType: T.Type) throws -> DataView {
        let bytes = MemoryLayout<T>.size
        return try with(offset: offset, address: address, slid: slid, bytes: bytes)
    }

    func with(offset: Int?, address: UInt, slid: Bool, bytes: Int) throws -> DataView {
        if let offset = offset, slide == nil {
            return with(offset: offset)
        }

        let (target, start, end) = try self.info(forAddress: address, slid: slid)
        if target >= start, target < end {
            var copy = self
            copy.offset = Int(target - start)
            return copy
        }

        guard let pointer = UnsafeMutableRawPointer(bitPattern: target) else {
            throw Error.invalidAddress(address: target)
        }
        let data = Data(bytesNoCopy: pointer, count: bytes, deallocator: .none)
        return DataView(data: data, offset: 0, pointer: pointer, slide: 0)
    }

    // Utilities

    private func info(forAddress address: UInt, slid: Bool) throws -> (target: UInt, start: UInt, end: UInt) {
        guard let slide = slide, let start = startAddress, let end = endAddress else {
            throw Error.missingAddressInformation
        }
        let target: UInt
        if slid {
            target = address
        } else {
            target = UInt(Int(address) + slide)
        }
        return (target: target, start: start, end: end)
    }

    enum Error: Swift.Error {
        case missingAddressInformation
        case addressOutOfBounds(address: UInt)
        case invalidAddress(address: UInt)
    }
}
