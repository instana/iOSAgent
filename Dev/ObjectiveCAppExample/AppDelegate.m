//
//  AppDelegate.m
//  ObjectiveCAppExample
//
//  Created by Helen Jiang on 1/2/24.
//

#import "AppDelegate.h"
@import InstanaAgent;

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    (void)[Instana setupWithKey: @"INSTANA_REPORTING_KEY"
             reportingURL: [NSURL URLWithString: @"INSTANA_REPORTING_URL"]
                  options: nil];

//    NSArray<NSString *> *viewControllerClasses = @[@"ViewController"];
//    //note: explicitly get user permission before setting enableCrashReporting to true
//    InstanaSetupOptions* options = [[InstanaSetupOptions alloc] initWithHttpCaptureConfig: 0
//                                                                  collectionEnabled: true
//                                                               enableCrashReporting: true
//                                                             suspendReportingOnLowBattery: true
//                                                               suspendReportingOnCellular: false
//                                                                   slowSendInterval: 0.0
//                                                              usiRefreshTimeIntervalInHrs: -1
//                                                                autoCaptureScreenNames: 2
//                                                            autoViewCaptureAllowedClasses: viewControllerClasses];
//    (void)[Instana setupWithKey: @"INSTANA_REPORTING_KEY"
//             reportingURL: [NSURL URLWithString: @"INSTANA_REPORTING_URL"]
//                  options: options];

    NSURL* url = [NSURL URLWithString: @"https://www.ibm.com/jp-ja"];
    NSURLRequest* request = [NSURLRequest requestWithURL: url];
    [[[NSURLSession sharedSession] dataTaskWithRequest: request] resume];

    [Instana reportEventWithName: @"testCustomEventName"
                       timestamp: NSNotFound
                        duration: NSNotFound
                backendTracingID: nil
                           error: nil
                            meta: nil
                        viewName: nil
                    customMetric: NAN]; //"0x7fc00000"

    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
