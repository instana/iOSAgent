//  Created by Nikola Lajic on 12/10/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation
import KSCrash

public class InstanaCrashReportSink: NSObject, KSCrashReportFilter {
    
    private struct ReportKeys {
        static let standard = "standard"
        static let json = "json-encoded"
    }
    
    public func filterReports(_ reports: [Any]!, onCompletion: KSCrashReportFilterCompletion!) {
        guard reports.count > 0 else {
            kscrash_callCompletion(onCompletion, reports, true, nil)
            return
        }
        submit(reports: reports, onCompletion: onCompletion)
    }
    
    @objc public func deafultFilterSet() -> KSCrashReportFilter {
        let json: Any = KSCrashReportFilterPipeline.filter(withFiltersArray: [
            KSCrashReportFilterAppleFmt(reportStyle: KSAppleReportStyleSymbolicatedSideBySide),
            KSCrashReportFilterJSONEncode.filter(withOptions: KSJSONEncodeOptionPretty),
            ])
        let combine: Any = KSCrashReportFilterCombine.init(filtersWithKeys: [
            ReportKeys.standard: KSCrashReportFilterPassthrough.filter(),
            ReportKeys.json: json
            ])
        return KSCrashReportFilterPipeline.filter(withFiltersArray: [combine, self])
    }
}

private extension InstanaCrashReportSink {
    
    func submit(reports: [Any], onCompletion: @escaping KSCrashReportFilterCompletion) {
        guard let dictReports = reports as? [[String: Any]], dictReports.count > 0 else {
            kscrash_callCompletion(onCompletion, reports, true, nil)
            return
        }
        
        let group = DispatchGroup()
        var error: Error?
        
        group.enter()
        dictReports.forEach {
            group.enter()
            Instana.events.submit(event: event(from: $0) { result in
                if case let .failure(resultError) = result {
                    error = resultError
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
    
    func event(from report: [String: Any], completion: @escaping InstanaEventResultNotifiable.CompletionBlock) -> InstanaEvent {
        let standardReport = report[ReportKeys.standard] as? NSDictionary ?? [:]
        let jsonDataReport = report[ReportKeys.json] as? Data
        
        let datetime = standardReport.value(forKeyPath: "report.timestamp") as? String ?? ""
        let date = ISO8601DateFormatter().date(from: datetime) ?? Date()
        let timestamp = date.timeIntervalSince1970
        
        let breadcrumbs = standardReport.value(forKeyPath: "user.breadcrumbs") as? [String]
        
        let sessionId = standardReport.value(forKeyPath: "user.sessionId") as? String ?? "unknown-session"
        let jsonReport = String(data: jsonDataReport ?? Data(), encoding: .utf8) ?? ""
        
        return InstanaCrashEvent(sessionId: sessionId, timestamp: timestamp, report: jsonReport, breadcrumbs: breadcrumbs, completion: completion)
    }
}
