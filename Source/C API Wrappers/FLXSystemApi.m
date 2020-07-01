//
//  FLXSystemApi.m
//  Created on 10/4/19
//

#import "FLXSystemApi.h"
#import <sys/mman.h>
#import <mach/mach.h>
#import <mach/mach_vm_private.h>

@implementation FLXSystemApi

+ (int)openPath:(NSString *)path flag:(int)flag mode:(int)mode NS_SWIFT_NAME(open(path:flag:mode:)) {
    return open(path.UTF8String, flag, mode);
}

+ (NSUInteger)mmap:(NSUInteger)address
              length:(size_t)length
          protection:(int)protection
               flags:(int)flags
      fileDescriptor:(int)fileDescriptor
              offset:(NSUInteger)offset NS_SWIFT_NAME(mmap(address:length:protection:flags:fileDescriptor:offset:)) {
    return (NSUInteger)mmap((void *)address, length, protection, flags, fileDescriptor, offset);
}

+ (int)munmap:(NSUInteger)address length:(size_t)length
NS_SWIFT_NAME(munmap(address:length:)) {
    return munmap((void *)address, length);
}

+ (NSString *)stringFromError:(int)errorCode
NS_SWIFT_NAME(string(fromError:)) {
    return @(strerror(errorCode));
}

// MARK: - VM Allocations

/*
 kern_return_t vm_allocate
 (
 vm_map_t target_task,
 vm_address_t *address,
 vm_size_t size,
 int flags
 );
 */
+ (kern_return_t)vm_allocate:(NSUInteger *)address size:(NSUInteger)size flags:(int)flags {
    //    kern_return_t r = vm_alloc(&addr, size, VM_FLAGS_ANYWHERE | VM_MAKE_TAG(VM_MEMORY_DYLIB));
    //    vm_allocate(mach_task_self(), addr, size, flags);
    
    vm_address_t addressOut;
    kern_return_t result = vm_allocate(mach_task_self(), &addressOut, size, flags);
    if (result == KERN_SUCCESS) {
        *address = (NSUInteger)addressOut;
    }

    return result;
}

// kern_return_t vm_protect (vm_task_t target_task, vm_address_t address, vm_size_t size, boolean_t set_maximum, vm_prot_t new_protection)
+ (kern_return_t)vm_protect:(NSUInteger)address size:(NSUInteger)size setMaximum:(BOOL)maximum newProtection:(vm_prot_t)newProtection {
    return vm_protect(mach_task_self(), (vm_address_t)address, (vm_size_t)size, maximum, newProtection);
}

/*
 kern_return_t vm_deallocate
 (
 vm_map_t target_task,
 vm_address_t address,
 vm_size_t size
 );
 */
+ (kern_return_t)vm_deallocate:(NSUInteger)address size:(NSUInteger)size {
    return vm_deallocate(mach_task_self(), (vm_address_t)address, (vm_size_t)size);
}

extern char **environ;
+ (int)posix_spawnWithPidOut:(pid_t *)pid path:(NSString *)path
                 fileActions:(const posix_spawn_file_actions_t _Nullable * _Nullable)fileActions
                  attributes:(const posix_spawnattr_t _Nullable * _Nullable)attributes {
    char *argv[] = {
        (char *)path.UTF8String,
        NULL
    };
    return posix_spawn(pid, path.UTF8String, fileActions, attributes, argv, environ);
}


+ (uintptr_t)executableAddressFromSuspendedTask:(mach_port_name_t)task {
    thread_act_array_t threads;
    mach_msg_type_number_t threadCount = 0;
    kern_return_t result = task_threads(task, &threads, &threadCount);

    if (result != 0) {
        NSLog(@"task_threads error: 0x%x %s", result, mach_error_string(result));
        return 0;
    }

    mach_port_t targetThread = threads[0];

    mach_msg_type_number_t stateCount;
    thread_state_flavor_t stateFlavor;

    #if defined(__arm__) && !defined(__aarch64__)
        stateFlavor = ARM_THREAD_STATE32;
        stateCount = ARM_THREAD_STATE32_COUNT;
        arm_thread_state_t state;
    #elif defined(__aarch64__)
        stateFlavor = ARM_THREAD_STATE64;
        stateCount = ARM_THREAD_STATE64_COUNT;
        arm_thread_state64_t state;
    #elif defined(__x86_64__)
        stateFlavor = x86_THREAD_STATE;
        stateCount = x86_THREAD_STATE_COUNT;
        struct __darwin_x86_thread_state64 state;
    #else
        #error "Unsupported architecture"
    #endif

    result = thread_get_state(targetThread, stateFlavor, (thread_state_t)&state, &stateCount);

    if (result != 0) {
        NSLog(@"thread_get_state error: 0x%x %s", result, mach_error_string(result));
        return 0;
    }

    #if defined(__arm__) || defined(__aarch64__)
        uintptr_t stackPointer = state.__sp;
    #else
        uintptr_t stackPointer = state.__rsp;
    #endif

    uintptr_t executableAddress = 0;
    mach_vm_size_t bytesWritten = 0;
    result = mach_vm_read_overwrite(task, stackPointer, sizeof(uintptr_t),
                                    (mach_vm_address_t)&executableAddress, &bytesWritten);
    if (result != 0 || bytesWritten != sizeof(uintptr_t)) {
        NSLog(@"mach_vm_read_overwrite error: 0x%x %s", result, mach_error_string(result));
        return 0;
    }

    for (int index = 1; index < threadCount; index += 1) {
        mach_port_deallocate(mach_task_self_, threads[index]);
    }

    vm_deallocate(mach_task_self_, (vm_address_t) threads, threadCount * sizeof (thread_t));

    return executableAddress;
}

+ (NSData *)readTask:(mach_port_name_t)task address:(uintptr_t)address length:(size_t)length {
    NSMutableData *data = [NSMutableData dataWithLength:length];
    mach_vm_size_t bytesWritten = 0;
    kern_return_t result = mach_vm_read_overwrite(task, address, length,
                                                  (mach_vm_address_t)data.mutableBytes, &bytesWritten);
    if (result != 0 || bytesWritten != length) {
        NSLog(@"mach_vm_read_overwrite error: 0x%x %s", result, mach_error_string(result));
        return nil;
    }

    return data;
}

@end
