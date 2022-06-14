import Foundation
@testable import InstanaAgent

class MockRedactionHandler: RedactionHandler {

    var didCallRedactURL: URL?
    override func redact(url: URL) -> URL {
        didCallRedactURL = url
        return super.redact(url: url)
    }
}
