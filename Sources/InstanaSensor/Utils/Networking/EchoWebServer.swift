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
final class EchoWebServer {
    private let queue = DispatchQueue.global()
    private let port: NWEndpoint.Port = 81
    private let listener: NWListener
    private var connectionsByID: [Int: Connection] = [:]
    var connections: [Connection] { connectionsByID.map {$0.value} }
    var removeConnectionAtEnd = false

    static var shared: EchoWebServer = {
        let server = EchoWebServer()
        server.start()
        return server
    }()

    init() {
        let tcpprotocol = NWProtocolTCP.Options()
        tcpprotocol.enableKeepalive = true
        tcpprotocol.enableFastOpen = true
        listener = try! NWListener(using: NWParameters(tls: nil, tcp: tcpprotocol), on: port)
    }

    func start() {
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

    func stop() {
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
}


@available(iOS 12.0, *)
class Connection {
    private static var nextID: Int = 0
    let nwConnection: NWConnection
    var didStopCallback: ((Error?) -> Void)? = nil
    let id: Int
    var receivedData: Data?

    init(nwConnection: NWConnection) {
        self.nwConnection = nwConnection
        self.id = Connection.nextID
        Connection.nextID += 1
    }

    func start() {
        print("connection \(id) will start")
        nwConnection.stateUpdateHandler = stateDidChange(to:)
        nwConnection.start(queue: .main)
        setupReceive()
    }

    func stop(error: Error? = nil) {
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
            self.connectionDidEnd()
            print("Connection \(self.id) did send, data: \(String(describing: String(data: data, encoding:.utf8)))")
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
        nwConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536) {[weak self] (data, _, isComplete, error) in
            guard let self = self else { return }
            if let data = data, !data.isEmpty {
                let string = String(data: data, encoding:.utf8)
                print("Echo Webserver did receive:\n \(string ?? "none")")
            }
            self.receivedData = data
            if let data = data, let responseData = HTTPResponse.create(origin: data) {
                self.respond(data: responseData)
            } else if let error = error {
                self.connectionDidFail(error: error)
            } else if isComplete {
                self.connectionDidEnd()
            } else {
                self.setupReceive()
            }
        }
    }
}

struct HTTPResponse {
    static func create(origin: Data) -> Data? {
        guard let http = String(data: origin, encoding:.utf8) else {
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
