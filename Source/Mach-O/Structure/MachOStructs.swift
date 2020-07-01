//
//  MachOStructs.swift
//  Created on 5/24/19
//
// swiftlint:disable large_tuple

import Foundation
import MachO

struct MachO {
    enum Magic: UInt32 {
        case arch32 = 0xfeedface
        case arch64 = 0xfeedfacf
        case fat = 0xbebafeca
    }

    enum Filetype: UInt32 {
        case execute = 0x2
        case dylib = 0x6
    }
    
    struct mach_header {
        var magic: UInt32 /* mach magic number identifier */
        var cputype: cpu_type_t /* cpu specifier */
        var cpusubtype: cpu_subtype_t /* machine specifier */
        var filetype: UInt32 /* type of file */
        var ncmds: UInt32 /* number of load commands */
        var sizeofcmds: UInt32 /* the size of all the load commands */
        var flags: UInt32 /* flags */
    }
    
    struct mach_header_64 {
        var magic: UInt32 /* mach magic number identifier */
        var cputype: cpu_type_t /* cpu specifier */
        var cpusubtype: cpu_subtype_t /* machine specifier */
        var filetype: UInt32 /* type of file */
        var ncmds: UInt32 /* number of load commands */
        var sizeofcmds: UInt32 /* the size of all the load commands */
        var flags: UInt32 /* flags */
        var reserved: UInt32 /* reserved */
    }
    
    public struct fat_header {
        public var magic: UInt32 /* FAT_MAGIC or FAT_MAGIC_64 */
        public var nfat_arch: UInt32 /* number of structs that follow */
    }
    
    public struct fat_arch {
        public var cputype: cpu_type_t /* cpu specifier (int) */
        public var cpusubtype: cpu_subtype_t /* machine specifier (int) */
        public var offset: UInt32 /* file offset to this object file */
        public var size: UInt32 /* size of this object file */
        public var align: UInt32 /* alignment as a power of 2 */
    }
    
    struct load_command {
        var cmd: UInt32
        var cmdsize: UInt32
    }
    
    enum LoadCommands: UInt32 {
        case segment32 = 0x1
        case segment64 = 0x19
        case encryptionInfo32 = 0x21
        case encryptionInfo64 = 0x2C
        case codesignDirectives = 0x2B
    }
    
    struct symtab_command {
        var cmd: UInt32 /* LC_SYMTAB */
        var cmdsize: UInt32 /* sizeof(struct symtab_command) */
        var symoff: UInt32 /* symbol table offset */
        var nsyms: UInt32 /* number of symbol table entries */
        var stroff: UInt32 /* string table offset */
        var strsize: UInt32 /* string table size in bytes */
    }
    
    public struct segment_command {
        public var cmd: UInt32 /* for 32-bit architectures */ /* LC_SEGMENT */
        public var cmdsize: UInt32 /* includes sizeof section structs */
        public var segname: (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8) /* segment name */
        public var vmaddr: UInt32 /* memory address of this segment */
        public var vmsize: UInt32 /* memory size of this segment */
        public var fileoff: UInt32 /* file offset of this segment */
        public var filesize: UInt32 /* amount to map from the file */
        public var maxprot: vm_prot_t /* maximum VM protection */
        public var initprot: vm_prot_t /* initial VM protection */
        public var nsects: UInt32 /* number of sections in segment */
        public var flags: UInt32 /* flags */
    }
    
    public struct segment_command_64 {
        public var cmd: UInt32 /* for 64-bit architectures */ /* LC_SEGMENT_64 */
        public var cmdsize: UInt32 /* includes sizeof section_64 structs */
        public var segname: (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8) /* segment name */
        public var vmaddr: UInt64 /* memory address of this segment */
        public var vmsize: UInt64 /* memory size of this segment */
        public var fileoff: UInt64 /* file offset of this segment */
        public var filesize: UInt64 /* amount to map from the file */
        public var maxprot: vm_prot_t /* maximum VM protection */
        public var initprot: vm_prot_t /* initial VM protection */
        public var nsects: UInt32 /* number of sections in segment */
        public var flags: UInt32 /* flags */
    }

    struct encryption_info_command_32 {
        var cmd: UInt32 /* LC_ENCRYPTION_INFO */
        var cmdsize: UInt32  /* sizeof(struct encryption_info_command_64) */
        var cryptoff: UInt32 /* file offset of encrypted range */
        var cryptsize: UInt32 /* file size of encrypted range */
        var cryptid: UInt32 /* which enryption system, 0 means not-encrypted yet */
    }

    // LC_ENCRYPTION_INFO_64
    struct encryption_info_command_64 {
        var cmd: UInt32 /* LC_ENCRYPTION_INFO */
        var cmdsize: UInt32  /* sizeof(struct encryption_info_command) */
        var cryptoff: UInt32 /* file offset of encrypted range */
        var cryptsize: UInt32 /* file size of encrypted range */
        var cryptid: UInt32 /* which enryption system, 0 means not-encrypted yet */
        var pad: UInt32 /* padding to make this struct's size a multiple of 8 bytes */
    }
}
