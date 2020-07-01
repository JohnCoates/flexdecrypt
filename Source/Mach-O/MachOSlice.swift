//
//  MachOSlice.swift
//  Created on 10/5/19
//

import Foundation

struct MachOSlice {
    enum Error: Swift.Error {
        case missingSymbolTable
    }

    let data: Data
    var mutableData: Data
    let fileRange: Range<Int>
    let header: MachOHeader

    init(data: Data, fileRange: Range<Int>? = nil) throws {
        self.data = data
        if let range = fileRange {
            self.fileRange = range
        } else {
            self.fileRange = 0..<data.count
        }
        mutableData = data

        var view = DataView(data: data)
        header = try MachOHeader(view: &view)

        var commands = [MachOLoadCommand]()
        for _ in 0..<header.ncmds {
            guard let command = try MachOLoadCommand(view: &view) else { continue }
            commands.append(command)
        }

        loadCommands = commands
    }

    let loadCommands: [MachOLoadCommand]
}

// MARK: - Encryption

extension MachOSlice {
    var isEncrypted: Bool {
        for command in loadCommands {
            switch command.type {
            case let .encryptionInfo(value):
                if value.cryptid == 0 {
                    return false
                } else {
                    return true
                }
            default:
                break
            }
        }

        return false
    }

    var hasCodesignDirectives: Bool {
        for command in loadCommands {
            switch command.cmd {
            case .codesignDirectives:
                return true
            default:
                break
            }
        }

        return false
    }
}

// MARK: - Segments

extension MachOSlice {
    func segments() throws -> [MachOSegment] {
        var segments: [MachOSegment] = []

        for command in loadCommands {
            switch command.type {
            case let .segment(segment):
                segments.append(segment)
            default:
                break
            }
        }
        return segments
    }
}
