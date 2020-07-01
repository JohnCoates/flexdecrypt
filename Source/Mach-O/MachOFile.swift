//
//  MachOFile.swift
//  Created on 6/30/20
//

import Foundation
import Darwin.sys
import Darwin.Mach
import MachO

class MachOFile {
    var data: Data
    let fileUrl: URL

    init(url: URL) throws {
        self.fileUrl = url
        let data = try Data.init(contentsOf: fileUrl)
        self.data = data
    }

    func sliceDataForHostArchitecture(decryptIfEncrypted: Bool = true) throws -> Data {
        FLXLog.internal("Identifying best slice for \(fileUrl.path)")
        let slice = try sliceForHostArchitecture()
        if decryptIfEncrypted && slice.isEncrypted {
            FLXLog.internal("Decrypting slice")
            return try decrypt(slice: slice)
        } else {
            FLXLog.internal("Not encrypted")
            return slice.data
        }
    }

    private func sliceForHostArchitecture() throws -> MachOSlice {
        let binary = MachOBinary(fileUrl: self.fileUrl)
        let slices = binary.slices

        guard let localArch = NXGetLocalArchInfo()?.pointee else {
            throw MachOError.noHostArchitecture
        }

        var bestSlice: MachOSlice?

        for slice in slices {
            if bestSlice == nil {
                bestSlice = slice
                continue
            }

            if slice.header.cputype == localArch.cputype {
                FLXLog.internal("found slice for cputype")
                bestSlice = slice
                if slice.header.cpusubtype == localArch.cpusubtype {
                    FLXLog.internal("found slice for cpusubtype")
                    break
                }
            }
        }

        guard let slice = bestSlice else {
            throw MachOError.noSlices
        }

        return slice
    }

    func bytesDifference(original: Data, decrypted: Data, maximum: Int) -> Int {
        var difference = 0
        for index in 0..<original.count {
            let originalByte = original[index]
            let decryptedByte = decrypted[index]
            if originalByte != decryptedByte {
                difference += 1
            }
            if difference >= maximum {
                break
            }
        }

        return difference
    }

    var name: String {
        return fileUrl.deletingPathExtension().lastPathComponent
    }

    func popError() -> String {
        let error = errno
        let errorString = FLXSystemApi.string(fromError: error)
        return "#\(error): \(errorString)"
    }

    func machError(code: kern_return_t) -> String {
        let errorString = mach_error_string(code)
        return "#\(code): \(errorString.debugDescription)"
    }
}
