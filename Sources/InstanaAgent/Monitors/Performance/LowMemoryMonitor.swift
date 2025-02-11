//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
#if os(tvOS) || os(watchOS) || os(iOS)
    import UIKit
#endif
import MachO

class LowMemoryMonitor {
    let reporter: Reporter

    init(reporter: Reporter) {
        self.reporter = reporter
        #if os(tvOS) || os(watchOS) || os(iOS)
            NotificationCenter.default.addObserver(self, selector: #selector(onLowMemoryWarning(notification:)),
                                                   name: UIApplication.didReceiveMemoryWarningNotification,
                                                   object: nil)
        #endif
    }

    @objc func onLowMemoryWarning(notification: Notification) {
        let unit = UInt64(1024 * 1024)
        let usedMemory = getUsedMemory()
        let freeMemory = getFreeMemory()
        let maxMemory: UInt64 = ProcessInfo.processInfo.physicalMemory
        // in mega bytes
        reporter.submit(PerfLowMemoryBeacon(usedMemory: usedMemory != nil ? usedMemory! / unit : nil,
                                            availableMemory: freeMemory != nil ? freeMemory! / unit : nil,
                                            maximumMemory: maxMemory / unit))
    }

    func getUsedMemory() -> UInt64? {
        var taskVMInfo = task_vm_info_data_t()
        var vmSize = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        let kernResult: kern_return_t = withUnsafeMutablePointer(to: &taskVMInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &vmSize)
            }
        }
        if kernResult == KERN_SUCCESS {
            return UInt64(taskVMInfo.phys_footprint)
        }
        return nil
    }

    func getFreeMemory() -> UInt64? {
        var vmStats = vm_statistics64()
        var vmSize = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size) / 4

        let machHost = mach_host_self()
        let ret = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(vmSize)) {
                host_statistics64(machHost, HOST_VM_INFO64, $0, &vmSize)
            }
        }

        if ret == KERN_SUCCESS {
            return UInt64(vmStats.free_count) * UInt64(vm_kernel_page_size)
        }
        return nil
    }
}
