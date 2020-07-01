//
//  MachOLoadCommand.swift
//  Created on 10/5/19
//

import Foundation

struct MachOLoadCommand {
    enum CommandType {
        case segment(value: MachOSegment)
//        case id(value: MachODylibCommand)
//        case symbolTable(value: MachOSymbolTable)
        case encryptionInfo(value: MachOEncryptionInfo)
//        case codeSignature(value: MachOLinkeditDataCommand)
        case noAssociatedValue

        init(command: MachO.LoadCommands, view: inout DataView) throws {
            switch command {
//            case .symbolTable:
//                self = try .symbolTable(value: MachOSymbolTable(dataView: &view))
            case .segment32, .segment64:
                self = try .segment(value: MachOSegment(view: &view))
//            case .id, .loadDylib,
//                 .loadWeakDylib:
//                self = try .id(value: MachODylibCommand(dataView: &view))
            case .encryptionInfo32, .encryptionInfo64:
                self = try .encryptionInfo(value: MachOEncryptionInfo(dataView: &view))
//            case .codeSignature:
//                self = try .codeSignature(value: MachOLinkeditDataCommand(dataView: &view))
            case .codesignDirectives:
                self = .noAssociatedValue
            }
        }
    }

    private let value: MachO.load_command
    init?(view: inout DataView) throws {
        var copy = view
        let value = try MachO.load_command(dataView: &copy)
        defer {
            view.offset += Int(value.cmdsize)
        }
        guard let command = MachO.LoadCommands(rawValue: value.cmd) else {
            return nil
        }
        copy = view
        type = try CommandType(command: command, view: &copy)
        self.cmd = command
        self.value = value
    }

    let cmd: MachO.LoadCommands
    var type: CommandType

    var cmdsize: UInt32 {
        return value.cmdsize
    }
}

extension MachOLoadCommand: CustomStringConvertible {
    var description: String {
        return "MachOLoadCommand: \(type)"
    }
}
