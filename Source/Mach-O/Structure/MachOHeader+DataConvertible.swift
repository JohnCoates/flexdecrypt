//
//  MachOHeader+DataConvertible.swift
//  Created on 5/22/19
//

import Foundation

protocol DataConvertibleStruct {
    init(data: Data, endian: Endian) throws
    init(dataView view: inout DataView, endian: Endian) throws
}

extension MachO.mach_header: DataConvertible, DataConvertibleStruct {
    init(dataView view: inout DataView, endian: Endian = .little) throws {
        magic = try view.read(endian: endian)
        cputype = try view.read(endian: endian)
        cpusubtype = try view.read(endian: endian)
        filetype = try view.read(endian: endian)
        ncmds = try view.read(endian: endian)
        sizeofcmds = try view.read(endian: endian)
        flags = try view.read(endian: endian)
    }
}

extension MachO.mach_header_64: DataConvertible {
    init(data: Data, endian: Endian = .little) throws {
        let size = MemoryLayout<MachO.mach_header_64>.size
        guard data.count == size else {
            if data.count < size {
                throw BinaryError.notEnoughData
            } else {
                throw BinaryError.tooMuchData
            }
        }
        
        var view = DataView(data: data)
        try self.init(dataView: &view, endian: endian)
    }
    
    init(dataView view: inout DataView, endian: Endian = .little) throws {
        magic = try view.read(endian: endian)
        cputype = try view.read(endian: endian)
        cpusubtype = try view.read(endian: endian)
        filetype = try view.read(endian: endian)
        ncmds = try view.read(endian: endian)
        sizeofcmds = try view.read(endian: endian)
        flags = try view.read(endian: endian)
        reserved = try view.read(endian: endian)
    }
}

extension MachO.fat_header: DataConvertible {
    init(data: Data, endian: Endian = .little) throws {
        let size = MemoryLayout<MachO.fat_header>.size
        guard data.count == size else {
            if data.count < size {
                throw BinaryError.notEnoughData
            } else {
                throw BinaryError.tooMuchData
            }
        }
        
        var view = DataView(data: data)
        try self.init(dataView: &view, endian: endian)
    }
    
    init(dataView view: inout DataView, endian: Endian = .little) throws {
        magic = try view.read(endian: endian)
        nfat_arch = try view.read(endian: .big)
    }
}

extension DataConvertibleStruct {
    init(data: Data, endian: Endian = .little) throws {
        let size = MemoryLayout<Self>.size
        guard data.count == size else {
            if data.count < size {
                throw BinaryError.notEnoughData
            } else {
                throw BinaryError.tooMuchData
            }
        }
        
        var view = DataView(data: data)
        try self.init(dataView: &view, endian: endian)
    }
}

extension MachO.fat_arch: DataConvertible, DataConvertibleStruct {
    init(dataView view: inout DataView, endian: Endian = .little) throws {
        cputype = try view.read(endian: .big)
        cpusubtype = try view.read(endian: .big)
        offset = try view.read(endian: .big)
        size = try view.read(endian: .big)
        align = try view.read(endian: .big)
    }
}

// MARK: - Load Commands

extension MachO.load_command: DataConvertible, DataConvertibleStruct {
    init(dataView view: inout DataView, endian: Endian = .little) throws {
        let offset = view.offset
        cmd = try view.read(endian: endian)
        cmdsize = try view.read(endian: endian)
        view.offset = offset + Int(cmdsize)
    }
}

extension MachO.segment_command: DataConvertible, DataConvertibleStruct {
    init(dataView view: inout DataView, endian: Endian = .little) throws {
        cmd = try view.read(endian: endian)
        cmdsize = try view.read(endian: endian)
        segname.0 = try view.read()
        segname.1 = try view.read()
        segname.2 = try view.read()
        segname.3 = try view.read()
        segname.4 = try view.read()
        segname.5 = try view.read()
        segname.6 = try view.read()
        segname.7 = try view.read()
        segname.8 = try view.read()
        segname.9 = try view.read()
        segname.10 = try view.read()
        segname.11 = try view.read()
        segname.12 = try view.read()
        segname.13 = try view.read()
        segname.14 = try view.read()
        segname.15 = try view.read()
        vmaddr = try view.read(endian: endian)
        vmsize = try view.read(endian: endian)
        fileoff = try view.read(endian: endian)
        filesize = try view.read(endian: endian)
        maxprot = try view.read(endian: endian)
        initprot = try view.read(endian: endian)
        nsects = try view.read(endian: endian)
        flags = try view.read(endian: endian)
    }
    
    var segmentName: String {
        let mirror = Mirror(reflecting: segname)
        let bytes: [UInt8] = mirror.children.map({ UInt8($0.value as! Int8) })
        let string = String(cString: bytes)
        return string
    }
}

extension MachO.segment_command_64: DataConvertible, DataConvertibleStruct {
    init(dataView view: inout DataView, endian: Endian = .little) throws {
        cmd = try view.read(endian: endian)
        cmdsize = try view.read(endian: endian)
        segname.0 = try view.read()
        segname.1 = try view.read()
        segname.2 = try view.read()
        segname.3 = try view.read()
        segname.4 = try view.read()
        segname.5 = try view.read()
        segname.6 = try view.read()
        segname.7 = try view.read()
        segname.8 = try view.read()
        segname.9 = try view.read()
        segname.10 = try view.read()
        segname.11 = try view.read()
        segname.12 = try view.read()
        segname.13 = try view.read()
        segname.14 = try view.read()
        segname.15 = try view.read()
        vmaddr = try view.read(endian: endian)
        vmsize = try view.read(endian: endian)
        fileoff = try view.read(endian: endian)
        filesize = try view.read(endian: endian)
        maxprot = try view.read(endian: endian)
        initprot = try view.read(endian: endian)
        nsects = try view.read(endian: endian)
        flags = try view.read(endian: endian)
    }
    
    var segmentName: String {
        let mirror = Mirror(reflecting: segname)
        let bytes: [UInt8] = mirror.children.map({ UInt8($0.value as! Int8) })
        let string = String(cString: bytes)
        return string
    }
}

extension MachO.encryption_info_command_32: DataConvertible, DataConvertibleStruct {
    init(dataView view: inout DataView, endian: Endian = .little) throws {
        cmd = try view.read(endian: endian)
        cmdsize = try view.read(endian: endian)
        cryptoff = try view.read(endian: endian)
        cryptsize = try view.read(endian: endian)
        cryptid = try view.read(endian: endian)
    }
}

extension MachO.encryption_info_command_64: DataConvertible, DataConvertibleStruct {
    init(dataView view: inout DataView, endian: Endian = .little) throws {
        cmd = try view.read(endian: endian)
        cmdsize = try view.read(endian: endian)
        cryptoff = try view.read(endian: endian)
        cryptsize = try view.read(endian: endian)
        cryptid = try view.read(endian: endian)
        pad = try view.read(endian: endian)
    }
}
