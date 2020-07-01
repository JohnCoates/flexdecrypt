//
//  FLXPrivateApi.m
//  Created on 10/4/19
//

#import "FLXPrivateApi.h"
#import <sys/syscall.h>
#define    PT_TRACE_ME    0    /* child declares it's being traced */
#define    PT_ATTACH    10    /* trace some running process */
#define    PT_DETACH    11    /* stop tracing a process */
#define PT_ATTACHEXC    14    /* attach to running process with signal exception */

#define CS_OPS_STATUS       0   /* return status */
/* process is currently or has previously been debugged and allowed to run with invalid pages */
#define CS_DEBUGGED         0x10000000

#define FORK_IS_CHILD 0
#define FORK_FAILURE -1

// External
extern "C" {
int csops(pid_t pid, unsigned int  ops, void * useraddr, size_t usersize);
extern int mremap_encrypted(caddr_t addr, size_t len,
                            uint32_t cryptid, uint32_t cputype,
                            uint32_t cpusubtype);
};

@implementation FLXPrivateApi

static BOOL allowsInvalidCodesignedMemoryEnabled = FALSE;

+ (BOOL)allowInvalidCodesignedMemoryEnabled {
    if (allowsInvalidCodesignedMemoryEnabled) {
        return TRUE;
    }

    uint32_t flags;
    csops(getpid(), CS_OPS_STATUS, &flags, 0);
    if (flags & CS_DEBUGGED){
        return TRUE;
    } else {
        return FALSE;
    }
}

+ (BOOL)allowInvalidCodesignedMemory {
    pid_t pid = fork();

    if (pid == FORK_IS_CHILD) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        syscall(SYS_ptrace, PT_TRACE_ME, 0, 0, 0);
        #pragma clang diagnostic pop
        exit(0);
    } else if (pid == FORK_FAILURE) {
        int error = errno;
        const char *errorMessage = strerror(error);
        NSLog(@"fork failed: %d - %s", error, errorMessage);
        return FALSE;
    }

    allowsInvalidCodesignedMemoryEnabled = TRUE;
    return TRUE;
}

+ (int)mremap_encrypted:(NSUInteger)address
                 length:(size_t)length
                cryptId:(uint32_t)cryptId
                cpuType:(uint32_t)cpuType
             cpuSubType:(uint32_t)cpuSubType {
    return mremap_encrypted((caddr_t)address, length,
                            cryptId, cpuType, cpuSubType);
}

@end
