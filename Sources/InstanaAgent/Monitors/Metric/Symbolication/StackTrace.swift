//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation

class StackTrace: Codable {
    var header: [StHeader]
    var threads: [StThread]
    var binaryImages: [StBinaryImage]

    init() {
        header = []
        threads = []
        binaryImages = []
    }

    func setHeader(stHeaders: [StHeader]) {
        header = stHeaders
    }

    func appendThread(stThread: StThread) {
        threads.append(stThread)
    }

    // swiftlint:disable function_parameter_count
    func appendBinaryImage(startAddr: String, endAddr: String?, name: String,
                           arch: String?, uuid: String, path: String?) {
        binaryImages.append(StBinaryImage(startAddr: startAddr, endAddr: endAddr,
                                          name: name, arch: arch, uuid: uuid, path: path))
    }

    func serialize() -> String? {
        do {
            let data = try JSONEncoder().encode(self)
            let str = String(decoding: data, as: UTF8.self)
            return str
        } catch {
            Instana.current?.session.logger.add("Diagnostic payload format to JSON error \(error)", level: .error)
        }
        return nil
    }
}

struct StHeader: Codable {
    let key: String
    let value: String

    private enum CodingKeys: String, CodingKey {
        case key = "k"
        case value = "v"
    }

    init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

class StThread: Codable {
    let state: String?
    var frames: [StFrame]

    private enum CodingKeys: String, CodingKey {
        case state
        case frames = "st"
    }

    init(state: String?) {
        self.state = state
        frames = []
    }

    func appendFrame(name: String, address: String, symbol: String?, offset: String?) {
        frames.append(StFrame(name: name, address: address, symbol: symbol, offset: offset))
    }
}

struct StFrame: Codable {
    let name: String
    let address: String
    let symbol: String?
    let offset: String?

    private enum CodingKeys: String, CodingKey {
        case name = "n"
        case address = "a"
        case symbol = "f"
        case offset = "o"
    }

    init(name: String, address: String, symbol: String?, offset: String?) {
        self.name = name
        self.address = address
        self.symbol = symbol
        self.offset = offset
    }
}

struct StBinaryImage: Codable {
    let startAddr: String
    let endAddr: String?
    let name: String
    let arch: String?
    let uuid: String
    let path: String?

    private enum CodingKeys: String, CodingKey {
        case startAddr = "a1"
        case endAddr = "a2"
        case name = "n"
        case arch = "a"
        case uuid = "id"
        case path = "p"
    }

    init(startAddr: String, endAddr: String?, name: String, arch: String?, uuid: String, path: String?) {
        self.startAddr = startAddr
        self.endAddr = endAddr
        self.name = name
        self.arch = arch
        self.uuid = uuid
        self.path = path
    }
}
