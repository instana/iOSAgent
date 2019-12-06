//
//  File.swift
//  
//
//  Created by Christian Menschel on 02.12.19.
//

import Foundation
@testable import InstanaSensor

extension HTTPBeacon {
    static func createMock(timestamp: Int64 = Date().millisecondsSince1970,
              method: String = "POST",
              url: URL = URL(string: "https://www.example.com")!,
        connectionType: NetworkMonitor.ConnectionType = .wifi) -> HTTPBeacon {
        return HTTPBeacon(timestamp: timestamp,
                         method: method,
                         url: url,
                         connectionType: connectionType,
                         result: "RESULT")
    }
}
