//
//  MachOSegment.swift
//  Created on 10/5/19
//

import Foundation

struct MachOSegment {
    private let value: ArchitectureValue<MachO.segment_command, MachO.segment_command_64>
    let architecture: Architecture
    private let view: DataView

    init(view: inout DataView) throws {
        var copy = view
        let cmd: UInt32 = try copy.read()

        if cmd == MachO.LoadCommands.segment32.rawValue {
            architecture = .arch32
            value = try .arch32(data: MachO.segment_command(dataView: &view))
        } else if cmd == MachO.LoadCommands.segment64.rawValue {
            architecture = .arch64
            value = try .arch64(data: MachO.segment_command_64(dataView: &view))
        } else {
            throw MachOError.message("Invalid segment command value: \(cmd)")
        }

        self.view = view
    }

    var segmentName: String {
        switch value {
        case let .arch32(data):
            return data.segmentName
        case let.arch64(data):
            return data.segmentName
        }
    }

    var vmaddr: UInt64 {
        switch value {
        case let .arch32(data):
            return UInt64(data.vmaddr)
        case let.arch64(data):
            return data.vmaddr
        }
    }

    var vmsize: UInt64 {
        switch value {
        case let .arch32(data):
            return UInt64(data.vmsize)
        case let.arch64(data):
            return data.vmsize
        }
    }

    var fileoff: UInt64 {
        switch value {
        case let .arch32(data):
            return UInt64(data.fileoff)
        case let.arch64(data):
            return data.fileoff
        }
    }

    var filesize: UInt64 {
        switch value {
        case let .arch32(data):
            return UInt64(data.filesize)
        case let.arch64(data):
            return data.filesize
        }
    }

    var maxprot: vm_prot_t {
        switch value {
        case let .arch32(data):
            return data.maxprot
        case let.arch64(data):
            return data.maxprot
        }
    }

    var initprot: vm_prot_t {
        switch value {
        case let .arch32(data):
            return data.initprot
        case let.arch64(data):
            return data.initprot
        }
    }

    var nsects: UInt32 {
        switch value {
        case let .arch32(data):
            return data.nsects
        case let.arch64(data):
            return data.nsects
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
}
