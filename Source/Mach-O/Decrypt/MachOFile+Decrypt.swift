//
//  MachOFile+Decrypt.swift
//  Created on 6/30/20
//

import Foundation

extension MachOFile {
    func decrypt(slice: MachOSlice) throws -> Data {
        for command in slice.loadCommands {
            switch command.type {
            case let .encryptionInfo(value):
                if value.cryptid == 0 {
                    throw MachOError.notEncrypted
                }
                FLXLog.internal("Found encryption info")
                return try decrypt(slice: slice, encryptionInfo: value)
            default:
                break
            }
        }

        throw MachOError.noEncryptionLoadCommand
    }

    func decrypt(slice: MachOSlice, encryptionInfo: MachOEncryptionInfo) throws -> Data {
        let isApplication = slice.header.filetype == MachO.Filetype.execute.rawValue
        if isApplication {
            let pageSize = UInt(getpagesize())
            let pageRemainder = UInt(encryptionInfo.cryptoff) % pageSize
            // Can't remap to decrypted unless crypt offset is on a page
            // Application needs to be launched so kernel juggles this.
            if pageRemainder != 0 || slice.hasCodesignDirectives {
                return try decryptApplication(slice: slice, encryptionInfo: encryptionInfo)
            }
        }

        if slice.hasCodesignDirectives {
            throw MachOError.codesignDirectivesNotSupportedForDecryption
        }

        // TODO: Support fat Mach-O
        FLXLog.internal("Opening file descriptor")
        let fileDescriptor = FLXSystemApi.open(path: fileUrl.path, flag: O_RDONLY, mode: 0)

        if fileDescriptor == -1 {
            throw MachOError.openFailed(error: popError())
        }

        var segmentIndexAtFileOffsetZeroMaybe: Int?
        var segmentIndex = 0
        let allSegments = try slice.segments()
        let validSegments = allSegments.filter { $0.filesize > 0 }
        let sortedSegments = validSegments.sorted(by: { $0.vmaddr < $1.vmaddr })

        guard let firstSegment = sortedSegments.first else {
            throw MachOError.message("Failed to find a segment with a valid vm address")
        }

        let vmStart = UInt(firstSegment.vmaddr)
        let vmEnd = try slice.segments().reduce(UInt(0), { (sum, segment) in
            let isPageZero = isApplication && segment.vmaddr == 0
            if isPageZero { return sum }

            let isRestrict = segment.segmentName == "__RESTRICT"
            if isRestrict { return sum }

            let end = segment.vmaddr + segment.filesize
            if end > sum {
                return UInt(end)
            } else {
                return sum
            }
        })
        FLXLog.internal("VM start: \(vmStart.hex)")

        var allocatedAddress: UInt = 0
        let allocateSize = vmEnd - vmStart

        FLXLog.internal("Allocating \(allocateSize.hex) bytes")

        var allocateResult: kern_return_t = KERN_SUCCESS
        allocateResult = FLXSystemApi.vm_allocate(&allocatedAddress,
                                                  size: allocateSize,
                                                  flags: VM_FLAGS_ANYWHERE | (VM_MEMORY_DYLIB << 24 ))

        guard allocateResult == KERN_SUCCESS else {
            throw MachOError.vmAllocateFailed(error: "Failed to allocate \(allocateSize.hex) bytes, result: \(allocateResult)")
        }

        let didMap = FLXSystemApi.mmap(address: allocatedAddress,
                                       length: Int(allocateSize),
                                       protection: VM_PROT_READ,
                                       flags: MAP_PRIVATE | MAP_FIXED | MAP_ANONYMOUS,
                                       fileDescriptor: 0, offset: 0)

        if didMap == UInt.max || didMap != allocatedAddress {
            throw MachOError.initialMmapFailed
        }

        let allocationEnd = allocatedAddress + allocateSize

        FLXLog.internal("Mapped \(allocatedAddress.hex) - \((allocatedAddress + allocateSize).hex)")

        let restrictAllocation: (() throws -> Void) = {
            let result = FLXSystemApi.vm_protect(allocatedAddress, size: allocateSize, setMaximum: true, newProtection: 0)
            guard result == KERN_SUCCESS else {
                throw MachOError.vmAllocateFailed(error: "Failed to restrict \(allocateSize.hex) bytes, result: \(result)")
            }

            FLXLog.internal("Restricted allocation to prevent memory mappings.")
        }

        let deallocAllocation: (() throws -> Void) = {
            let deallocateResult = FLXSystemApi.vm_deallocate(allocatedAddress, size: allocateSize)
            guard deallocateResult == KERN_SUCCESS else {
                throw MachOError.vmAllocateFailed(error: "Failed to de-allocate \(allocateSize.hex) bytes, result: \(deallocateResult)")
            }
            FLXLog.internal("Deallocating \(allocateSize.hex) at \(allocatedAddress.hex)")
        }

        var deallocateMemoryCallback: (() throws -> Void)? = {
            try restrictAllocation()
            try deallocAllocation()
            FLXLog.internal("Restricted allocation to prevent memory mappings.")
            FLXLog.internal("Unmapped segments")
        }

        defer {
            if let deallocateMemoryCallback = deallocateMemoryCallback {
                try? deallocateMemoryCallback()
            }
        }

        let slide: Int

        if allocatedAddress > vmStart {
            slide = Int(allocatedAddress) - Int(vmStart)
        } else {
            slide = Int(vmStart) - Int(allocatedAddress)
        }

        var segments: [MachOSegment] = []
        var mappedSegments: [UInt] = []

        let unmapMappedSegments: (() throws -> Void) = {
            try mappedSegments.enumerated().forEach { (offset, address) in
                let segment = segments[offset]
                let result = FLXSystemApi.munmap(address: address, length: Int(segment.filesize))

                if result != 0 {
                    FLXLog.internal("Unmapping failed for \(segment.segmentName) at \(address.hex)")
                    throw MachOError.munmapFailed(segment: segment.segmentName, error: self.popError())
                }
            }
        }

        deallocateMemoryCallback = {
            try unmapMappedSegments()
            try deallocAllocation()
            FLXLog.internal("Restricted allocation to prevent memory mappings.")
            //            FLXLog.internal("Unmapped segments")
        }

        for segment in allSegments {
            let isPageZero = segment.vmaddr == 0 && isApplication
            if isPageZero { continue }

            let isRestrict = segment.segmentName == "__RESTRICT"
            if isRestrict { continue }

            if segment.fileoff == 0 && segment.filesize > 0 {
                segmentIndexAtFileOffsetZeroMaybe = segmentIndex
            }

            let mapAddress = UInt(Int(segment.vmaddr) + slide)
            let length = Int(segment.filesize)
            let endAddress: UInt = mapAddress + UInt(length)
            let mapped: UInt

            guard mapAddress >= allocatedAddress && endAddress <= allocationEnd else {
                if mapAddress < allocatedAddress {
                    throw MachOError.message("Map address for \(segment.segmentName): \(mapAddress.hex) < \(allocatedAddress.hex)")
                } else {
                    throw MachOError.message("End address for \(segment.segmentName): \(endAddress.hex) > \(allocationEnd.hex)")
                }
            }

            mapped = FLXSystemApi.mmap(address: mapAddress,
                                       length: length,
                                       protection: Int32(segment.initprot),
                                       flags: MAP_PRIVATE | MAP_FIXED,
                                       fileDescriptor: fileDescriptor,
                                       offset: UInt(segment.fileoff))

            if mapped == UInt.max || mapped != mapAddress {
                throw MachOError.mmapFailed(segment: segment.segmentName, error: popError())
            }

            FLXLog.internal("Mapped \(mapAddress.hex) - \(endAddress.hex)")

            mappedSegments.append(mapped)
            segments.append(segment)
            segmentIndex += 1
        }

        FLXLog.internal("Segments mapped, resuming verbosity.")
        FLXLog.internal("Allocation address: \(allocatedAddress.hex)")
        FLXLog.internal("Slide: \(slide.hex)")
        mappedSegments.enumerated().forEach { (index, mappedSegment) in
            let segment = segments[index]
            FLXLog.internal("Mapped \(segment.segmentName) to \(mappedSegment.hex) - bytes: \(segment.filesize.hex)")
        }

        guard let segmentIndexAtFileOffsetZero = segmentIndexAtFileOffsetZeroMaybe else {
            throw MachOError.missingSegmentAtFileOffsetZero
        }

        let segment = segments[segmentIndexAtFileOffsetZero]
        let mappedSegment = mappedSegments[segmentIndexAtFileOffsetZero]

        let offset = encryptionInfo.cryptoff
        let size = encryptionInfo.cryptsize
        let cpuType = UInt32(slice.header.cputype)
        let cpuSubType = UInt32(slice.header.cpusubtype)

        if FLXPrivateApi.allowInvalidCodesignedMemoryEnabled == false {
            FLXLog.internal("Allowing invalid codesigned memory")
            if FLXPrivateApi.allowInvalidCodesignedMemory() == false {
                throw MachOError.failedToAllowInvalidCodesignedMemory
            }
        }

        FLXLog.internal("Remapping \(segment.segmentName) to encrypted backing")
        let result = FLXPrivateApi.mremap_encrypted(address: mappedSegment + UInt(offset),
                                                    length: Int(size),
                                                    cryptId: encryptionInfo.cryptid,
                                                    cpuType: cpuType,
                                                    cpuSubType: cpuSubType)
        if result == -1 {
            throw MachOError.mremap_encryptedFailed(segment: segment.segmentName, error: popError())
        }

        FLXLog.internal("Reading decrypted file")
        let capacity = segments.reduce(0, { $0 + $1.filesize })
        FLXLog.internal("Bytes: \(capacity.hex)")
        var originalData = Data(capacity: Int(capacity))
        var decryptedData = Data(capacity: Int(capacity))

        try mappedSegments.enumerated().forEach { (index, address) in
            let segment = segments[index]
            guard let pointer = UnsafePointer<UInt8>.init(bitPattern: Int(address)) else {
                throw MachOError.mappingAddressToPointerFailed(address: address)
            }

            let fileSize = Int(segment.filesize)
            FLXLog.internal("Reading \(fileSize.hex) bytes at \(address.hex)")
            decryptedData.append(pointer, count: fileSize)
            originalData.append(slice.data[Int(segment.fileoff)..<Int(segment.fileoff) + Int(segment.filesize)])
        }

        FLXLog.internal("Comparing encrypted file to decrypted file")
        let minimumDifference: Int = 0x1
        let difference = bytesDifference(original: originalData, decrypted: decryptedData, maximum: minimumDifference)

        if difference < minimumDifference {
            throw MachOError.decryptionDifferenceBelowMinimum(difference: difference)
        }

        if let deallocateMemoryCallback = deallocateMemoryCallback {
            try deallocateMemoryCallback()
        }
        deallocateMemoryCallback = nil

        // Modify encryption flag
        let cryptIdStart = decryptedData.startIndex.advanced(by: encryptionInfo.cryptIdOffset)
        let cryptIdEnd = cryptIdStart.advanced(by: MemoryLayout<UInt32>.size)
        decryptedData.replaceSubrange(cryptIdStart..<cryptIdEnd,
                                      with: Data.init(count: MemoryLayout<UInt32>.size))

        return decryptedData
    }
}

