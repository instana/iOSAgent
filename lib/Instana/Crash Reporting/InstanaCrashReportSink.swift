//  Created by Nikola Lajic on 12/10/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation
import KSCrash

/// This class is for internal use, it's public only becasuse of Obj-C compatibility.
public class InstanaCrashReportSink: NSObject, KSCrashReportFilter {
    
    private struct ReportKeys {
        static let standard = "standard"
        static let json = "json-encoded"
    }
    
    var submitEvent: InstanaEvents.Submitter = Instana.events.submit(event:)
    var deleteReport: (NSNumber) -> () = KSCrash.sharedInstance().deleteReport(withID:)
    
    public func filterReports(_ reports: [Any]!, onCompletion: KSCrashReportFilterCompletion!) {
        guard reports.count > 0 else {
            kscrash_callCompletion(onCompletion, reports, true, nil)
            return
        }
        submit(reports: reports, onCompletion: onCompletion)
    }
    
    @objc public func deafultFilterSet() -> KSCrashReportFilter {
        let json: Any = KSCrashReportFilterPipeline(filtersArray: [
            KSCrashReportFilterAppleFmt(reportStyle: KSAppleReportStyleSymbolicatedSideBySide),
            KSCrashReportFilterJSONEncode.filter(withOptions: KSJSONEncodeOptionPretty),
            ])
        let combine: Any = KSCrashReportFilterCombine(filters: [
            KSCrashReportFilterPassthrough.filter(), json
            ], keys: [
                ReportKeys.standard, ReportKeys.json
            ])
        return KSCrashReportFilterPipeline(filtersArray: [combine, self])
    }
}

private extension InstanaCrashReportSink {
    
    func submit(reports: [Any], onCompletion: @escaping KSCrashReportFilterCompletion) {
        guard let dictReports = reports as? [[String: Any]], dictReports.count > 0 else {
            KSCrash.sharedInstance().deleteBehaviorAfterSendAll = KSCDeleteOnSucess
            kscrash_callCompletion(onCompletion, reports, true, nil)
            return
        }
        
        let group = DispatchGroup()
        var error: Error?
        
        group.enter()
        dictReports.forEach {
            group.enter()
            submitEvent(eventReport(from: $0) { localReportId, result in
                if case let .failure(resultError) = result {
                    error = resultError
                }
                else if let localReportId = localReportId {
                    self.deleteReport(localReportId)
                }
                group.leave()
            })
        }
        group.leave()

        group.notify(queue: .main) {
            if let error = error {
                Instana.log.add("Failed to send crash reports: \(error.localizedDescription)")
                kscrash_callCompletion(onCompletion, reports, false, error)
            }
            else {
                Instana.log.add("Crash reports sent")
                kscrash_callCompletion(onCompletion, reports, true, nil)
            }
        }
    }
    
    func eventReport(from report: [String: Any], completion: @escaping (_ localReportId: NSNumber?, _ result: InstanaEventResult) -> Void) -> InstanaEvent {
        let standardReport = report[ReportKeys.standard] as? NSDictionary ?? [:]
        let jsonDataReport = report[ReportKeys.json] as? Data
        
        let datetime = standardReport.value(forKeyPath: "report.timestamp") as? String ?? ""
        let date = ISO8601DateFormatter().date(from: datetime) ?? Date()
        let timestamp = date.timeIntervalSince1970
        
        let breadcrumbs = standardReport.value(forKeyPath: "user.breadcrumbs") as? [String]
        
        let sessionId = standardReport.value(forKeyPath: "user.sessionId") as? String ?? "unknown-session"
        let jsonReport = String(data: jsonDataReport ?? Data(), encoding: .utf8) ?? ""
        
        let localReportId = standardReport["reportId"] as? NSNumber
        // revert to default deletion method if it's not possible to find report id
        if localReportId == nil {
            KSCrash.sharedInstance().deleteBehaviorAfterSendAll = KSCDeleteOnSucess
        }
        
        return InstanaCrashEvent(sessionId: sessionId, timestamp: timestamp, report: jsonReport, breadcrumbs: breadcrumbs) { result in
            completion(localReportId, result)
        }
    }
}
