//  Created by Nikola Lajic on 1/16/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

#import "KSCrash+Swift.h"

@implementation KSCrashReportFilterPipeline (Swift)

+ (KSCrashReportFilterPipeline *)filterWithFiltersArray:(nullable NSArray *)filters {
    // KSCrash doesn't init the filters array if initialized directly, so appending filters won't work
    KSCrashReportFilterPipeline *pipeline = [[KSCrashReportFilterPipeline alloc] initWithFilters:nil];

    // we have to reverse filters since "addFilter:" inserts ay index 0
    for (id filter in [filters reverseObjectEnumerator]) {
        [pipeline addFilter:filter];
    }
    
    return pipeline;
}

@end

// TODO: fork KSCrash
@interface KSCrashReportFilterCombine (ExposePrivate)
- (id) initWithFilters:(NSArray *)filters keys:(NSArray *)keys;
@end

@implementation KSCrashReportFilterCombine (Swift)

+ (KSCrashReportFilterCombine *)combineFiltersWithKeys:(nullable NSDictionary<NSString*, id> *)filters
{
    return [[KSCrashReportFilterCombine alloc] initWithFilters:[filters allValues] keys:[filters allKeys]];
}

@end
