//
//  MachOEncryptionInfo.swift
//  Created on 10/5/19
//

import Foundation

struct MachOEncryptionInfo {
    private let value: ArchitectureValue<MachO.encryption_info_command_32, MachO.encryption_info_command_64>

    let view: DataView

    init(dataView view: inout DataView) throws {
        self.view = view
        var copy = view
        let cmd: UInt32 = try copy.read()
        if cmd == MachO.LoadCommands.encryptionInfo32.rawValue {
            value = try .arch32(data: MachO.encryption_info_command_32(dataView: &view))
        } else if cmd == MachO.LoadCommands.encryptionInfo64.rawValue {
            value = try .arch64(data: MachO.encryption_info_command_64(dataView: &view))
        } else {
            throw MachOError.message("Invalid encryption command value: \(cmd)")
        }
    }

    var cryptoff: UInt32 {
        switch value {
        case let .arch32(data):
            return data.cryptoff
        case let.arch64(data):
            return data.cryptoff
        }
    }

    var cryptsize: UInt32 {
        switch value {
        case let .arch32(data):
            return data.cryptsize
        case let.arch64(data):
            return data.cryptsize
        }
    }

    var cryptid: UInt32 {
        switch value {
        case let .arch32(data):
            return data.cryptid
        case let.arch64(data):
            return data.cryptid
        }
    }

    var pad: UInt32 {
        switch value {
        case .arch32:
            return 0
        case let.arch64(data):
            return data.pad
        }
    }

    var cryptIdOffset: Int {
        return view.offset + MemoryLayout<UInt32>.size * 4
    }
}
