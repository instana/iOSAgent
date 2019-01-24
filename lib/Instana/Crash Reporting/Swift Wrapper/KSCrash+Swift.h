//  Created by Nikola Lajic on 1/16/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

@import Foundation;
@import KSCrash;

@interface KSCrashReportFilterPipeline (Swift)
/**
 ObjC VA functions are not exposed to Swift so we need this.
 */
+ (KSCrashReportFilterPipeline *)filterWithFiltersArray:(nullable NSArray *)filters;
@end

@interface KSCrashReportFilterCombine (Swift)
/**
 ObjC VA functions are not exposed to Swift so we need this.
 */
+ (KSCrashReportFilterCombine *)combineFiltersWithKeys:(nullable NSDictionary<NSString*, id> *)filters;
@end
