//
//  FLXPrivateApi.h
//  Created on 10/4/19
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLXPrivateApi : NSObject

@property (class, readonly) BOOL allowInvalidCodesignedMemoryEnabled;
+ (BOOL)allowInvalidCodesignedMemory;

/// int mremap_encrypted(caddr_t addr, size_t len,
/// uint32_t cryptid, uint32_t cputype,
/// uint32_t cpusubtype);
+ (int)mremap_encrypted:(NSUInteger)address
                 length:(size_t)length
                cryptId:(uint32_t)cryptId
                cpuType:(uint32_t)cpuType
             cpuSubType:(uint32_t)cpuSubType
NS_SWIFT_NAME(mremap_encrypted(address:length:cryptId:cpuType:cpuSubType:));

@end

NS_ASSUME_NONNULL_END
