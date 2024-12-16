//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

#include "ImageDetail.h"
#import <dlfcn.h>
#import <mach-o/loader.h>
#import <mach-o/dyld.h>
#import <mach-o/arch.h>

@implementation ImageDetail

@synthesize baseAddress = _baseAddress;
@synthesize size = _size;
@synthesize cputype = _cputype;
@synthesize cpusubtype = _cpusubtype;
@synthesize inMemory = _inMemory;
@synthesize path = _path;

- (NSString*) getArchitecture {
    if (_cputype == CPU_TYPE_ARM && _cpusubtype == CPU_SUBTYPE_ARM_V7S) {
        return @"armv7s";
    }

    if (_cputype == (CPU_TYPE_ARM | CPU_ARCH_ABI64)) {
        if (_cpusubtype == CPU_SUBTYPE_ARM64E) {
            return @"arm64e";
        } else if (_cpusubtype == CPU_SUBTYPE_ARM64_ALL) {
            return @"arm64";
        }
    }

    if (_cputype == (CPU_TYPE_ARM) && _cpusubtype == CPU_SUBTYPE_ARM_V7K) {
        return @"armv7k";
    }

    const NXArchInfo* archInfo;
    archInfo = NXGetArchInfoFromCpuType(_cputype, _cpusubtype);
    if (archInfo != NULL) {
        return [NSString stringWithUTF8String: archInfo->name];
    }

    return nil;
}
@end


@implementation ImageTracker

@dynamic binaryImagesDict;

static CFAbsoluteTime objCLoadTime = 0;
static bool pauseTracking = false;
static NSMutableDictionary* binaryImagesDict = nil;

+ (void)load {
    objCLoadTime = CFAbsoluteTimeGetCurrent();
}

+ (CFAbsoluteTime)retrieveObjCLoadTime {
    return objCLoadTime;
}

+ (bool) pauseTracking {
    return pauseTracking;
}

+ (void) setPauseTracking: (bool) newValue {
    if (newValue != pauseTracking) {
        pauseTracking = newValue;
    }
}

+ (NSMutableDictionary*) binaryImagesDict {
    return binaryImagesDict;
}

+ (bool)startTrackingDyldImages {
    if (binaryImagesDict == nil) {
        binaryImagesDict = [[NSMutableDictionary alloc] init];
        _dyld_register_func_for_add_image(&imageAdded);
        _dyld_register_func_for_remove_image(&imageRemoved);
        return true;
    }
    return false;
}

static void imageAdded(const struct mach_header *mh, intptr_t vmaddr_slide) {
    if (ImageTracker.pauseTracking) return;
    binaryImageUpdated(mh, vmaddr_slide, true);
}

static void imageRemoved(const struct mach_header *mh, intptr_t vmaddr_slide) {
    if (ImageTracker.pauseTracking) return;
    binaryImageUpdated(mh, vmaddr_slide, false);
}

static void binaryImageUpdated(const struct mach_header *mh, intptr_t vmaddr_slide, bool added) {
    Dl_info imageInfo;
    int result = dladdr(mh, &imageInfo);

    if (result == 0) {
        return;
    }

    uint64_t textSegmentSize;
    const uuid_t *uuidBytes = getUUID_TextSegmentSize(mh, &textSegmentSize);
    if (uuidBytes == nil) {
        return;
    }

    char imageUUID[38];
    uuid_unparse(*uuidBytes, imageUUID);
    NSString* uuidStr = [NSString stringWithUTF8String: imageUUID];

    ImageDetail* imageDetail;
    if (added) {
        imageDetail = [[ImageDetail alloc] init];
        imageDetail.baseAddress = (intptr_t)imageInfo.dli_fbase;
        imageDetail.size = textSegmentSize;
        imageDetail.cputype = mh->cputype;
        imageDetail.cpusubtype = mh->cpusubtype;
        imageDetail.inMemory = true;
        imageDetail.path = NULL;
        [ImageTracker.binaryImagesDict setObject: imageDetail forKey: uuidStr];

    } else {
        imageDetail = ImageTracker.binaryImagesDict[uuidStr];
        if (imageDetail != NULL) {
            imageDetail.inMemory = false;
            imageDetail.path = [NSString stringWithUTF8String: imageInfo.dli_fname];
        }
    }
//#if DEBUG
//    printf("%s 0x%02lx (0x%02llx) %s <%s> cputype=%d cpusubtype=%d\n", (added ? "+" : "-"),
//           imageDetail.baseAddress, imageDetail.size, imageInfo.dli_fname, imageUUID, mh->cputype, mh->cpusubtype);
//#endif
}


#pragma mark - MachO header

static uint32_t getHeaderSize(const struct mach_header *mh) {
    bool is_header_64_bit = (mh->magic == MH_MAGIC_64 || mh->magic == MH_CIGAM_64);
    return (is_header_64_bit ? sizeof(struct mach_header_64) : sizeof(struct mach_header));
}

static void IterateLoadCommands(const struct mach_header *mh, void (^block)(struct load_command *lc, bool *stop)) {
    uintptr_t lcCursor = (uintptr_t)mh + getHeaderSize(mh);

    for (uint32_t idx = 0; idx < mh->ncmds; idx++) {
        struct load_command *lcmd = (struct load_command *)lcCursor;

        bool stop = false;
        block(lcmd, &stop);

        if (stop) {
            return;
        }

        lcCursor += lcmd->cmdsize;
    }
}

static const uuid_t *getUUID_TextSegmentSize(const struct mach_header *mh, uint64_t* pTextSegmentSize) {
    static const char *textSegmentName = "__TEXT";

    __block const struct uuid_command *uuidCmd = NULL;
    __block uint64_t textSize = 0;

    __block bool foundUUID = false;
    __block bool foundSegmentSize = false;

    IterateLoadCommands(mh, ^ (struct load_command *lcmd, bool *stop) {
        if (lcmd->cmdsize == 0) {
            return;
        }
        if (lcmd->cmd == LC_UUID) {
            uuidCmd = (const struct uuid_command *)lcmd;
            foundUUID = true;
            if (foundSegmentSize) {
                *stop = true;
            }
            return;
        }
        if (lcmd->cmd == LC_SEGMENT) {
            struct segment_command *segCmd = (struct segment_command *)lcmd;
            if (strcmp(segCmd->segname, textSegmentName) == 0) {
                textSize = segCmd->vmsize;
                foundSegmentSize = true;
                if (foundUUID) {
                    *stop = true;
                }
                return;
            }
        }
        if (lcmd->cmd == LC_SEGMENT_64) {
            struct segment_command_64 *segCmd = (struct segment_command_64 *)lcmd;
            if (strcmp(segCmd->segname, textSegmentName) == 0) {
                textSize = segCmd->vmsize;
                foundSegmentSize = true;
                if (foundUUID) {
                    *stop = true;
                }
                return;
            }
        }
    });

    *pTextSegmentSize = textSize;

    if (uuidCmd == NULL) {
        return NULL;
    }

    return &uuidCmd->uuid;
}

@end
