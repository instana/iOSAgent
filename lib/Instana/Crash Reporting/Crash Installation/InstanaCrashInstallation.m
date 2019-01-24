//  Created by Nikola Lajic on 1/21/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

#import "InstanaCrashInstallation.h"
#import "Instana/Instana-Swift.h"

@interface InstanaCrashInstallation ()
@property (nonatomic, strong) InstanaCrashReportSink *crashReportSink;
@end

@implementation InstanaCrashInstallation

const char *_sessionId;

static void onCrash(const KSCrashReportWriter *writer) {
    writer->addStringElement(writer, "sessionId", _sessionId);
}

- (instancetype)init
{
    self = [super initWithRequiredProperties:@[]];
    if (self) {
        _sessionId = [Instana.sessionId UTF8String];
        self.crashReportSink = [InstanaCrashReportSink new];
        self.onCrash = onCrash;
        [self install];
        [self sendAllReportsWithCompletion:^(NSArray *filteredReports, BOOL completed, NSError *error) {}];
    }
    return self;
}

- (id<KSCrashReportFilter>)sink
{
    return [self.crashReportSink deafultFilterSet];
}

@end
