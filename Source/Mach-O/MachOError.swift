//
//  MachOError.swift
//  Created on 6/30/20
//

import Foundation

enum MachOError: Error {
    case noHostArchitecture
    case noSlices
    case notEncrypted
    case noEncryptionLoadCommand
    case openFailed(error: String)
    case vmAllocateFailed(error: String)
    case munmapFailed(segment: String, error: String)
    case mmapFailed(segment: String, error: String)
    case missingSegmentAtFileOffsetZero
    case mremap_encryptedFailed(segment: String, error: String)
    case mappingAddressToPointerFailed(address: UInt)
    case decryptionDifferenceBelowMinimum(difference: Int)
    case failedToAllowInvalidCodesignedMemory
    case noSectionForAddress(address: UInt64)
    case codesignDirectivesNotSupportedForDecryption
    case notAnApplication
    case initialMmapFailed
    case message(_ info: String)
}
