//
//  MachOBinary.swift
//  Created on 10/5/19
//

import Foundation

struct MachOBinary {
    let data: Data
    var mutableData: Data

    init(fileUrl: URL) {
        guard let data = try? Data.init(contentsOf: fileUrl) else {
            fatalError("Failed to read \(fileUrl.path)")
        }
        self.data = data
        mutableData = data
    }

    var slices: [MachOSlice] {
        var view = DataView(data: data)
        do {
            let magic: UInt32 = try view.read()
            if magic == MachO.Magic.arch32.rawValue || magic == MachO.Magic.arch64.rawValue {
                return try [MachOSlice(data: data)]
            } else if magic == MachO.Magic.fat.rawValue {
                var slices = [MachOSlice]()
                view = view.with(offset: 0)

                let fatHeader = try MachO.fat_header(dataView: &view)
                for _ in 0..<fatHeader.nfat_arch {
                    let arch = try MachO.fat_arch(dataView: &view)
                    let offset = Int(arch.offset)
                    let size = Int(arch.size)

                    let range: Range<Int> = offset..<offset+size
                    let archData = Data(data[range])
                    let slice = try MachOSlice(data: archData, fileRange: range)
                    slices.append(slice)
                }

                return slices

            } else {
                fatalError("Invalid Mach-O magic: \(magic)")
            }
        } catch let error {
            fatalError("Mach-O Parsing error: \(error)")
        }

    }
}
