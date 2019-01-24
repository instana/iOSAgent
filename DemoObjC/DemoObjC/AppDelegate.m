//  Created by Nikola Lajic on 12/10/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

#import "AppDelegate.h"
@import Instana;

@interface AppDelegate ()
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Instana setup];
    return YES;
}

@end
