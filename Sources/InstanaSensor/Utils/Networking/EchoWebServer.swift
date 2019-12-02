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
    private let port: NWEndpoint.Port = 8080
    private let listener: NWListener
    private var connectionsByID: [Int: Connection] = [:]
    var connections: [Connection] { connectionsByID.map {$0.value} }
    var removeConnectionAtEnd = false

    init() {
       listener = try! NWListener(using: .tcp, on: port)
    }

    func start() {
        self.listener.stateUpdateHandler = self.stateDidChange(to:)
        self.listener.newConnectionHandler = self.didAccept(nwConnection:)
        self.listener.start(queue: .main)
        print("Signaling server started listening on port \(self.port)")
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
            self.stop()
        case .cancelled:
            break
        default:
            break
        }
    }

    private func didAccept(nwConnection: NWConnection) {
        let connection = Connection(nwConnection: nwConnection)
        self.connectionsByID[connection.id] = connection
        connection.didStopCallback = { _ in
            self.connectionDidStop(connection)
        }
        connection.start()
        print("server did open connection \(connection.id)")
    }

    private func connectionDidStop(_ connection: Connection) {
        if removeConnectionAtEnd {
            self.connectionsByID.removeValue(forKey: connection.id)
            print("server did close connection \(connection.id)")
        }
    }

    private func stop() {
        listener.stateUpdateHandler = nil
        listener.newConnectionHandler = nil
        listener.cancel()
        for connection in connectionsByID.values {
            connection.didStopCallback = nil
            connection.stop()
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
        print("connection \(self.id) will start")
        nwConnection.stateUpdateHandler = self.stateDidChange(to:)
        setupReceive()
        nwConnection.start(queue: .main)
    }

    func respond(data: Data) {
        nwConnection.send(content: data, completion: .contentProcessed( { error in
            if let error = error {
                self.connectionDidFail(error: error)
                return
            }
            print("connection \(self.id) did send, data: \(data as NSData)")
            self.connectionDidEnd()
        }))
    }

    func stop() {
        print("connection \(id) will stop")
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

    private func stop(error: Error?) {
        nwConnection.stateUpdateHandler = nil
        nwConnection.cancel()
        if let callback = didStopCallback {
            didStopCallback = nil
            callback(error)
        }
    }

    private func setupReceive() {
        nwConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { (data, _, isComplete, error) in
            if let data = data, !data.isEmpty {
                let string = String(data: data, encoding:.utf8)
                print("Echo Webserver did receive: \(string ?? "none")")
            }
            self.receivedData = data
            if let data = data, let responseData = HTTPResponse.create(origin: data) {
                self.respond(data: responseData)
            } else if let error = error {
                self.connectionDidFail(error: error)
            } else {
                self.setupReceive()
            }
            self.setupReceive()
        }
    }
}

struct HTTPResponse {
    static func create(origin: Data) -> Data? {
        guard let body = String(data: origin, encoding:.utf8)?.components(separatedBy: "\n").last else {
            return nil
        }
        var response = ""
        response.append("HTTP/1.1 200 OK\r\n")

        if let data = body.data(using: .utf8), data.count >= 0 {
            response.append("Content-Length: \(data.count)\r\n")
            response.append("Content-Type: text/plain")
        }

        response.append("\r\n")
        response.append("\r\n")
        response.append(body)
        return response.data(using: .utf8) ?? Data()
    }
}
