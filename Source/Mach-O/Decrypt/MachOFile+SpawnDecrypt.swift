//
//  MachOFile+SpawnDecrypt.swift
//  Created on 9/13/19
//

import Foundation

extension MachOFile {
    func decryptApplication(slice: MachOSlice, encryptionInfo: MachOEncryptionInfo) throws -> Data {
        let isApplication = slice.header.filetype == MachO.Filetype.execute.rawValue
        guard isApplication else {
            throw MachOError.notAnApplication
        }

        var pid: pid_t = 0
        var fileActions: posix_spawn_file_actions_t?
        var attributes: posix_spawnattr_t?
        posix_spawn_file_actions_init(&fileActions)
        posix_spawnattr_init(&attributes)

        var signalMaskSet: sigset_t = 0
        sigemptyset(&signalMaskSet)
        posix_spawnattr_setsigmask(&attributes, &signalMaskSet)

        var flags: Int16 = 0
        flags |= Int16(POSIX_SPAWN_SETPGROUP)
        flags |= Int16(POSIX_SPAWN_SETSIGMASK)
        flags |= Int16(POSIX_SPAWN_START_SUSPENDED)
        posix_spawnattr_setflags(&attributes, flags)

        FLXLog.internal("Spawning \(fileUrl.path)")
        let result = FLXSystemApi.posix_spawn(withPidOut: &pid, path: fileUrl.path,
                                              fileActions: &fileActions,
                                              attributes: &attributes)

        let error = popError()
        posix_spawnattr_destroy(&attributes)
        posix_spawn_file_actions_destroy(&fileActions)

        if result != 0 {
            throw MachOError.message("Spawn failed with result #\(result): \(error)")
        }

        var task: mach_port_t = 0

        let taskResult = task_for_pid(mach_task_self_, pid, &task)
        if taskResult != 0 {
            throw MachOError.message("Failed to find get task, error: \(machError(code: taskResult))")
        }

        let executableAddress = FLXSystemApi.executableAddress(fromSuspendedTask: task)
        if executableAddress == 0 {
            throw MachOError.message("Failed to find executable address")
        }

        let segments = try slice.segments()
            .filter { $0.filesize > 0 }
            .sorted(by: { $0.vmaddr < $1.vmaddr })

        let capacity = segments.map({$0.filesize}).reduce(0, +)
        var decryptedData = Data(capacity: Int(capacity))
        let preferredLoadAddress = segments[0].vmaddr
        let slide = Int(executableAddress) - Int(preferredLoadAddress)
        for segment in segments {
            let address = Int(segment.vmaddr) + slide
            guard let data = FLXSystemApi.readTask(task, address: UInt(address), length: Int(segment.filesize)) else {
                throw MachOError.message("Failed to read segment \(segment.segmentName)")
            }
            decryptedData.append(data)
        }

        FLXLog.internal("Terminating process")
        kill(pid, SIGKILL)
        waitpid(pid, nil, 0)

        // Modify encryption flag
        let cryptIdStart = decryptedData.startIndex.advanced(by: encryptionInfo.cryptIdOffset)
        let cryptIdEnd = cryptIdStart.advanced(by: MemoryLayout<UInt32>.size)
        decryptedData.replaceSubrange(cryptIdStart..<cryptIdEnd,
                                      with: Data(count: MemoryLayout<UInt32>.size))

        return decryptedData
    }
}
