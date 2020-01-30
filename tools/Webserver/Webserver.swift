//
//  Server.swift
//
//
//  Created by Christian Menschel on 27.11.19.
//

import Foundation
import Network
import XCTest

// Inspired by https://forums.swift.org/t/socket-api/19971/10

/// Responds with the same body which has been received in the request
@available(iOS 12.0, *)
public class Webserver {
    public struct HTTPStatusCode: ExpressibleByIntegerLiteral, RawRepresentable {
        let code: Int
        public init(rawValue value: Int) {
            self.code = value
        }
        public init(integerLiteral value: Int) {
            self.code = value
        }
        public var rawValue: Int { code }
        var response: Data { .response(statusCode: code) }
        var canReceive: Bool { 100 ... 399 ~= code }
        static var `default`: HTTPStatusCode { 200 }
    }
    private let queue = DispatchQueue.global()
    private let listener: NWListener
    private var stubbedCode: HTTPStatusCode = .default
    private var connectionsByID: [Int: Connection] = [:]
    var connections: [Connection] { connectionsByID.map {$0.value} }
    var removeConnectionAtEnd = false

    init(port: UInt16) {
        let tcpprotocol = NWProtocolTCP.Options()
        tcpprotocol.enableKeepalive = true
        tcpprotocol.connectionTimeout = 60
        tcpprotocol.keepaliveIdle = 5
        tcpprotocol.enableFastOpen = true
        listener = try! NWListener(using: NWParameters(tls: nil, tcp: tcpprotocol), on: NWEndpoint.Port(rawValue: port)!)
    }

    func start() {
        listener.stateUpdateHandler = stateDidChange(to:)
        listener.newConnectionHandler = didAccept(nwConnection:)
        listener.start(queue: .main)
        print("Signaling server started listening on port \(listener.port!)")
    }

    public func stop() {
        listener.stateUpdateHandler = nil
        listener.newConnectionHandler = nil
        listener.cancel()
        for connection in connectionsByID.values {
            connection.stop()
            connection.didStopCallback = nil
        }
        if removeConnectionAtEnd {
            connectionsByID.removeAll()
        }
    }

    func stub(httpStatusResponse: HTTPStatusCode) {
        stubbedCode = httpStatusResponse
    }

    func stateDidChange(to newState: NWListener.State) {
        switch newState {
        case .setup:
            break
        case .waiting:
            break
        case .ready:
            break
        case .failed(let error):
            print("server did fail, error: \(error)")
            stop()
        case .cancelled:
            stop()
        default:
            break
        }
    }

    private func didAccept(nwConnection: NWConnection) {
        let connection = Connection(nwConnection: nwConnection, stubbedCode: stubbedCode)
        connectionsByID[connection.id] = connection
        connection.didStopCallback = { _ in
            self.connectionDidStop(connection)
        }
        connection.start()
        print("server did open connection \(connection.id)")
    }

    private func connectionDidStop(_ connection: Connection) {
        if removeConnectionAtEnd {
            connectionsByID.removeValue(forKey: connection.id)
            print("server did close connection \(connection.id)")
        }
    }

    @discardableResult
    func verifyBeaconReceived(key: String, value: String, file: StaticString = #file, line: UInt = #line) -> Bool {
        let keyValuePair = "\(key)\t\(value)"
        let hasValue = connections.flatMap {$0.received}.first(where: { $0.contains(keyValuePair) }) != nil
        if !hasValue {
            XCTFail("Could not find value: \(value) for key: \(key)", file: file, line: line)
        }
        return hasValue
    }

    @discardableResult
    func verifyBeaconNotReceived(key: String, value: String, file: StaticString = #file, line: UInt = #line) -> Bool {
        let keyValuePair = "\(key)\t\(value)"
        let hasValue = connections.flatMap {$0.received}.first(where: { $0.contains(keyValuePair) }) != nil
        if hasValue {
            XCTFail("Did find value: \(value) for key: \(key)", file: file, line: line)
        }
        return !hasValue
    }
}


@available(iOS 12.0, *)
public class Connection {
    private static var nextID: Int = 0
    let nwConnection: NWConnection
    var didStopCallback: ((Error?) -> Void)? = nil
    let id: Int
    var received = [String]()
    let MTU = 65536
    let stubbedCode: Webserver.HTTPStatusCode

    init(nwConnection: NWConnection, stubbedCode: Webserver.HTTPStatusCode = .default) {
        self.nwConnection = nwConnection
        self.id = Connection.nextID
        self.stubbedCode = stubbedCode
        Connection.nextID += 1
    }

    func start() {
        print("connection \(id) will start")
        nwConnection.stateUpdateHandler = stateDidChange(to:)
        setupReceive()
        nwConnection.start(queue: .main)
    }

    func stop(error: Error? = nil) {
        print("connection \(id) will stop")
        nwConnection.stateUpdateHandler = nil
        nwConnection.cancel()
        if let callback = didStopCallback {
            didStopCallback = nil
            callback(error)
        }
    }

    func respond() {
        nwConnection.send(content: stubbedCode.response, completion: .contentProcessed( {[weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.connectionDidFail(error: error)
                return
            }
            print("Connection \(self.id) did send, data: \(String(describing: String(data: self.stubbedCode.response, encoding:.utf8)))")
            self.connectionDidEnd()
        }))
    }

    private func stateDidChange(to state: NWConnection.State) {
        switch state {
        case .setup:
            break
        case .waiting(let error):
            connectionDidFail(error: error)
        case .preparing:
            break
        case .ready:
            print("connection \(id) ready")
        case .failed(let error):
            connectionDidFail(error: error)
        case .cancelled:
            break
        default:
            break
        }
    }

    private func connectionDidFail(error: Error) {
        print("connection \(id) did fail, error: \(error)")
        stop(error: error)
    }

    private func connectionDidEnd() {
        print("connection \(id) did end")
        stop(error: nil)
    }

    private func setupReceive() {
        nwConnection.receive(minimumIncompleteLength: 1, maximumLength: MTU) {[weak self] (data, _, isComplete, error) in
            guard let self = self else { return }
            if self.stubbedCode.canReceive, let data = data, let received = String(data: data, encoding:.utf8) {
                print("MockWebServer connection \(self.id) did receive: \(received)")
                self.received.append(received)
            }
            if data?.body != nil {
                self.respond()
            }
            if isComplete {
                self.connectionDidEnd()
            } else if let error = error {
                self.connectionDidFail(error: error)
            } else {
                self.setupReceive()
            }
        }
    }
}

extension Data {

    var body: String? {
        guard let http = String(data: self, encoding:.utf8),
            let body = http.components(separatedBy: "\r\n").last,
            body.contains("\t") else {
            return nil
        }
        return body
    }

    static func response(statusCode: Int) -> Data {
        let message: String
        switch statusCode {
        case 200: message = "OK"
        case 400: message = "Bad Request"
        case 403: message = "Forbidden"
        case 404: message = "Not Found"
        case 503: message = "Server Error"
        case 200...299: message = "OK"
        case 300...399: message = ""
        case 400...499: message = "Client Error"
        case 500...599: message = "Server Error"
        default: message = ""
        }
        let dateString = DateFormatter.http.string(from: Date())
        let value = """
        HTTP/1.1 \(statusCode) \(message)\r\n
        Date: \(dateString)\r\n
        Server: Apache/2.4.25 (Debian)\r\n
        Cache-Control: no-cache, private\r\n
        Access-Control-Allow-Origin: *\r\n
        Content-Type: text/html; charset=UTF-8\n
        Connection: close
        """
        return value.data(using: .utf8) ?? Data()
    }
}

extension DateFormatter {
    static var http: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE',' dd' 'MMM' 'yyyy HH':'mm':'ss zzz"
        return dateFormatter
    }
}
