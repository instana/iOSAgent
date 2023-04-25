//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation

struct CallStackTree: Codable {
    let callStacks: [DiagnosticThread]
    let callStackPerThread: Bool?

    public static func deserialize(data: Data) -> CallStackTree? {
        do {
            return try JSONDecoder().decode(CallStackTree.self, from: data)
        } catch {
            Instana.current?.session.logger.add("CallStackTree deserialize \(error)", level: .error)
        }
        return nil
    }
}
