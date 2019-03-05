//  Created by Nikola Lajic on 1/21/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

#import "InstanaCrashInstallation.h"
#import "Instana/Instana-Swift.h"

@interface InstanaCrashInstallation ()
@property (nonatomic, strong) InstanaCrashReportSink *crashReportSink;
@end

@implementation InstanaCrashInstallation

const int MAX_BREADCRUMBS = 100;
const int MAX_BREADCRUMB_LENGTH = 141; // +1, for zero termination
const char *_sessionId;
char _breadcrumbs[MAX_BREADCRUMBS][MAX_BREADCRUMB_LENGTH];
int _breadcrumbIndex = 0;

static void onCrash(const KSCrashReportWriter *writer) {
    writer->addStringElement(writer, "sessionId", _sessionId);
    writer->beginArray(writer, "breadcrumbs");
    for (int i = 0; i < MAX_BREADCRUMBS; i++) {
        int n = (i + _breadcrumbIndex) % MAX_BREADCRUMBS;
        if (strlen(_breadcrumbs[n]) > 0) writer->addStringElement(writer, nil, _breadcrumbs[n]);
    }
}

- (instancetype)init
{
    self = [super initWithRequiredProperties:@[]];
    if (self) {
        _sessionId = [Instana.sessionId UTF8String];
        [KSCrash sharedInstance].deleteBehaviorAfterSendAll = KSCDeleteNever;
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

- (void)addBreadcrumb:(NSString *)breadcrumb
{
    @synchronized (self) {
        NSString *truncated = [breadcrumb safelyTruncatedTo:MAX_BREADCRUMB_LENGTH - 1];;
        strlcpy(_breadcrumbs[_breadcrumbIndex], [truncated UTF8String], MAX_BREADCRUMB_LENGTH);
        _breadcrumbIndex = (_breadcrumbIndex + 1 >= MAX_BREADCRUMBS) ? 0 : _breadcrumbIndex + 1;
    }
}

@end
