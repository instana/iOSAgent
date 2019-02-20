//  Created by Nikola Lajic on 12/10/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

#import "ViewController.h"
@import Instana;

@interface ViewController ()
@property (strong) InstanaRemoteCallMarker *marker;
@end

@interface ViewController (URLSession) <NSURLSessionTaskDelegate, NSURLSessionDelegate>
@end

#pragma mark -

@implementation ViewController

- (IBAction)onTapCrash:(id)sender {
    [Instana.crashReporting leaveBreadcrumb:@"intentiaonally crashing"];
    @throw NSInternalInconsistencyException;
//    int* p = 0;
//    *p = 0;
}

#pragma optimize("", off)
- (IBAction)onHighIntensityWorkload:(id)sender {
    [Instana.crashReporting leaveBreadcrumb:@"high intensity workload"];
    for (int i = 0; i < 100000000; i++) {
        float a = arc4random_uniform(1000000000);
        float b = arc4random_uniform(1000000000);
        __unused float c = a / b / a / b;
    }
}
#pragma optimize("", on)

- (IBAction)onDropFrames:(id)sender {
    [Instana.crashReporting leaveBreadcrumb:@"dropping frames"];
    [self sleep:100];
}

- (void)sleep:(int)count {
    if (count <= 0) return;
    [NSThread sleepForTimeInterval:0.065];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.016 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self sleep:count - 1];
    });
}

- (IBAction)onTapCustomEvent:(id)sender {
    [Instana.crashReporting leaveBreadcrumb:@"sending custom event"];
    [Instana.events submitEvent:[[InstanaCustomEvent alloc] initWithName:@"manual evenet" timestamp:[[NSDate new] timeIntervalSince1970] duration:1.5]];
}

- (IBAction)onTapUrlRequest:(id)sender {
    [Instana.crashReporting leaveBreadcrumb:@"sending url requests"];
    // shared session
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"https://www.apple.com"] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"[DemoObjC] Finished shared session task (apple)");
    }] resume];
    
    
    // custom session
    NSURLSessionConfiguration *customConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    [Instana.remoteCallInstrumentation installIn:customConfig];
    customConfig.allowsCellularAccess = false;
    [[[NSURLSession sessionWithConfiguration:customConfig] dataTaskWithURL:[NSURL URLWithString:@"http://www.google.com/"] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"[DemoObjC] Finished custom session task (google)");
    }] resume];

    // manual tracking
    NSURLSessionConfiguration *ephemeralConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURL *url = [NSURL URLWithString:@"https://www.microsoft.com"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    self.marker = [Instana.remoteCallInstrumentation markCallTo:url.absoluteString method:@"GET"];
    [self.marker addTrackingHeadersTo:request];
    [[[NSURLSession sessionWithConfiguration:ephemeralConfig delegate:self delegateQueue:nil] dataTaskWithRequest:request] resume];

    // cancelled request
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"https://www.yahoo.com"] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"[DemoObjC] Finished cancelled task (yahoo)");
    }];
    [task resume];
    [task cancel];
}

@end

#pragma mark -

@implementation ViewController (URLSession)

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error) [self.marker endedWithError:error responseSize:task.countOfBytesReceived];
    else [self.marker endedWithResponseCode:200 responseSize:task.countOfBytesReceived];
    NSLog(@"[DemoObjC] Finished manually tracked delegated task (microsoft)");
}

@end
