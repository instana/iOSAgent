//
//  Server.swift
//
//
//  Created by Christian Menschel on 27.11.19.
//

import Foundation
import Network

// Inspired by https://forums.swift.org/t/socket-api/19971/10

/// Responds with the same body which has been received in the request
@available(iOS 12.0, *)
public class Webserver {
    private let queue = DispatchQueue.global()
    private let port: NWEndpoint.Port
    private let listener: NWListener
    private var connectionsByID: [Int: Connection] = [:]
    var connections: [Connection] { connectionsByID.map {$0.value} }
    var removeConnectionAtEnd = false

    public init(port: UInt16) {
        let tcpprotocol = NWProtocolTCP.Options()
        tcpprotocol.enableKeepalive = true
        tcpprotocol.connectionTimeout = 60
        tcpprotocol.keepaliveIdle = 5
        tcpprotocol.enableFastOpen = true
        self.port = NWEndpoint.Port(rawValue: port)!
        listener = try! NWListener(using: NWParameters(tls: nil, tcp: tcpprotocol), on: self.port)
    }

    public func start() {
        self.listener.stateUpdateHandler = stateDidChange(to:)
        self.listener.newConnectionHandler = didAccept(nwConnection:)
        self.listener.start(queue: .main)
        print("Signaling server started listening on port \(port)")
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
        let connection = Connection(nwConnection: nwConnection)
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

    func verify(key: String, value: String) -> Bool {
        let keyValuePair = "\(key)\t\(value)"
        let result = connections.compactMap {$0.receivedData}.map {String(data: $0, encoding: .utf8)}.filter { (receivedBody) -> Bool in
            guard let body = receivedBody else { return false }
            return body.contains(keyValuePair)
        }
        return result.count > 0
    }
}


@available(iOS 12.0, *)
public class Connection {
    private static var nextID: Int = 0
    let nwConnection: NWConnection
    var didStopCallback: ((Error?) -> Void)? = nil
    let id: Int
    var receivedData: Data?
    let MTU = 65536

    init(nwConnection: NWConnection) {
        self.nwConnection = nwConnection
        self.id = Connection.nextID
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

    func respond(data: Data) {
        nwConnection.send(content: data, completion: .contentProcessed( {[weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.connectionDidFail(error: error)
                return
            }
            print("Connection \(self.id) did send, data: \(String(describing: String(data: data, encoding:.utf8)))")
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
            if let data = data, !data.isEmpty {
                print("EchoWebServer connection \(self.id) did receive: \(String(data: data, encoding: .utf8) ?? "")")
                self.receivedData = data
            }
            if let responseData = self.receivedData?.response {
                self.respond(data: responseData)
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
    var response: Data? {
        let data = self
        guard let http = String(data: data, encoding:.utf8) else {
            return nil
        }
        let lines = http.components(separatedBy: "\n")
        let kvPairs = lines.reduce([String: Any](), {result, line -> [String: Any] in
            let components = line.components(separatedBy: ":")
            guard let key = components.first, let value = components.last else { return result }
            var newResult = result
            newResult[key] = value
            return newResult
        })

        var response = ""
        response.append("HTTP/1.1 200 OK\r\n")
        response.append("Connection: close")
        let contentType = kvPairs["Content-Type"] ?? "text/plain"
        if let body = http.components(separatedBy: "\r\n").last, let data = body.data(using: .utf8), body.count > 0 {
            response.append("Content-Length: \(data.count)\r\n")
            response.append("Content-Type: \(contentType)")

            response.append("\r\n")
            response.append("\r\n")
            response.append(body)
        }

        return response.data(using: .utf8) ?? Data()
    }
}
