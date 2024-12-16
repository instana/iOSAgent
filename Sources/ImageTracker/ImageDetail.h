//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>

@interface ImageDetail: NSObject

@property(nonatomic, assign) uintptr_t baseAddress;
@property(nonatomic, assign) UInt64 size;
@property(nonatomic, assign) int32_t cputype;
@property(nonatomic, assign) int32_t cpusubtype;

@property(nonatomic, assign) bool inMemory;
@property(nonatomic, strong, nullable) NSString *path;

- (NSString* _Nullable) getArchitecture;
@end


@interface ImageTracker : NSObject

@property(class, atomic, readwrite) bool pauseTracking;
@property(class, nonatomic, strong, nullable) NSMutableDictionary* binaryImagesDict;

+ (CFAbsoluteTime)retrieveObjCLoadTime;
+ (bool)startTrackingDyldImages;

@end
