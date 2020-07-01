//
//  MachOHeader.swift
//  Created on 10/5/19
//

import Foundation

struct MachOHeader {
    private let value: ArchitectureValue<MachO.mach_header, MachO.mach_header_64>
    init(view: inout DataView) throws {
        var copy = view
        let magic: UInt32 = try copy.read()
        if magic == MachO.Magic.arch32.rawValue {
            value = try .arch32(data: MachO.mach_header(dataView: &view))
        } else if magic == MachO.Magic.arch64.rawValue {
            value = try .arch64(data: MachO.mach_header_64(dataView: &view))
        } else {
            throw MachOError.message("Invalid slice magic: \(magic) @ offset \(view.offset)")
        }
    }

    var magic: UInt32 {
        switch value {
        case let .arch32(data):
            return data.magic
        case let.arch64(data):
            return data.magic
        }
    }

    var cputype: cpu_type_t {
        switch value {
        case let .arch32(data):
            return data.cputype
        case let.arch64(data):
            return data.cputype
        }
    }

    var cpusubtype: cpu_subtype_t {
        switch value {
        case let .arch32(data):
            return data.cpusubtype
        case let.arch64(data):
            return data.cpusubtype
        }
    }

    var filetype: UInt32 {
        switch value {
        case let .arch32(data):
            return data.filetype
        case let.arch64(data):
            return data.filetype
        }
    }

    var ncmds: UInt32 {
        switch value {
        case let .arch32(data):
            return data.ncmds
        case let.arch64(data):
            return data.ncmds
        }
    }

    var sizeofcmds: UInt32 {
        switch value {
        case let .arch32(data):
            return data.sizeofcmds
        case let.arch64(data):
            return data.sizeofcmds
        }
    }

    var flags: UInt32 {
        switch value {
        case let .arch32(data):
            return data.flags
        case let.arch64(data):
            return data.flags
        }
    }

    var reserved: UInt32 {
        switch value {
        case .arch32:
            return 0
        case let.arch64(data):
            return data.reserved
        }
    }

    var size: Int {
        return value.size
    }
}
