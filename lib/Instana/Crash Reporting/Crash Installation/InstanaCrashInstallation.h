//  Created by Nikola Lajic on 1/21/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

@import KSCrash;

@interface InstanaCrashInstallation : KSCrashInstallation
- (void)addBreadcrumb:(nonnull NSString *)breadcrumb;
@end
