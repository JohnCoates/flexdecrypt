//
//  FLXSystemApi.h
//  Created on 10/4/19
//

#import <Foundation/Foundation.h>
#import <spawn.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLXSystemApi : NSObject

/// int open(const char *path, int oflag, ...);
+ (int)openPath:(NSString *)path flag:(int)flag mode:(int)mode NS_SWIFT_NAME(open(path:flag:mode:));

/// void * mmap(void *addr, size_t len, int prot, int flags, int fd, off_t offset);
+ (NSUInteger)mmap:(NSUInteger)address
              length:(size_t)length
          protection:(int)protection
               flags:(int)flags
      fileDescriptor:(int)fileDescriptor
              offset:(NSUInteger)offset NS_SWIFT_NAME(mmap(address:length:protection:flags:fileDescriptor:offset:));

// int munmap(void *addr, size_t len);
+ (int)munmap:(NSUInteger)address length:(size_t)length
NS_SWIFT_NAME(munmap(address:length:));

/// char *strerror(int errnum);
+ (NSString *)stringFromError:(int)errorCode
NS_SWIFT_NAME(string(fromError:));

// kern_return_t vm_allocate(mach_task_self(), vm_address_t *address, vm_size_t size, int flags);
+ (kern_return_t)vm_allocate:(NSUInteger *)address size:(NSUInteger)size flags:(int)flags;

// kern_return_t vm_protect (vm_task_t target_task, vm_address_t address, vm_size_t size, boolean_t set_maximum, vm_prot_t new_protection);
+ (kern_return_t)vm_protect:(NSUInteger)address size:(NSUInteger)size setMaximum:(BOOL)maximum newProtection:(int)newProtection;

// kern_return_t vm_deallocate(mach_task_self(), vm_address_t address, vm_size_t size);
+ (kern_return_t)vm_deallocate:(NSUInteger)address size:(NSUInteger)size;

// int posix_spawn(pid_t *restrict pid, const char *restrict path, const posix_spawn_file_actions_t *file_actions,
// const posix_spawnattr_t *restrict attrp, char *const argv[restrict], char *const envp[restrict]);
//   result = posix_spawn (&pid, path, &file_actions, &attributes, argv, envp);
+ (int)posix_spawnWithPidOut:(pid_t *)pid path:(NSString *)path
                 fileActions:(const posix_spawn_file_actions_t _Nullable * _Nullable)fileActions
                  attributes:(const posix_spawnattr_t _Nullable * _Nullable)attributes;

+ (uintptr_t)executableAddressFromSuspendedTask:(mach_port_name_t)task;

+ (nullable NSData *)readTask:(mach_port_name_t)task address:(uintptr_t)address length:(size_t)length;

@end

NS_ASSUME_NONNULL_END
