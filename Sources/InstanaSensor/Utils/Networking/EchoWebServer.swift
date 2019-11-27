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
        self.connectionsByID.removeValue(forKey: connection.id)
        print("server did close connection \(connection.id)")
    }

    private func stop() {
        self.listener.stateUpdateHandler = nil
        self.listener.newConnectionHandler = nil
        self.listener.cancel()
        for connection in self.connectionsByID.values {
            connection.didStopCallback = nil
            connection.stop()
        }
        self.connectionsByID.removeAll()
    }
}


@available(iOS 12.0, *)
class Connection {
    init(nwConnection: NWConnection) {
        self.nwConnection = nwConnection
        self.id = Connection.nextID
        Connection.nextID += 1
    }

    private static var nextID: Int = 0
    let nwConnection: NWConnection
    let id: Int
    var didStopCallback: ((Error?) -> Void)? = nil

    func start() {
        print("connection \(self.id) will start")
        self.nwConnection.stateUpdateHandler = self.stateDidChange(to:)
        self.setupReceive()
        self.nwConnection.start(queue: .main)
    }

    func send(data: Data) {
        self.nwConnection.send(content: data, completion: .contentProcessed( { error in
            if let error = error {
                self.connectionDidFail(error: error)
                return
            }
            print("connection \(self.id) did send, data: \(data as NSData)")
            self.connectionDidEnd()
        }))
    }

    func stop() {
        print("connection \(self.id) will stop")
    }

    private func stateDidChange(to state: NWConnection.State) {
        switch state {
        case .setup:
            break
        case .waiting(let error):
            self.connectionDidFail(error: error)
        case .preparing:
            break
        case .ready:
            print("connection \(self.id) ready")
        case .failed(let error):
            self.connectionDidFail(error: error)
        case .cancelled:
            break
        default:
            break
        }
    }

    private func connectionDidFail(error: Error) {
        print("connection \(self.id) did fail, error: \(error)")
        self.stop(error: error)
    }

    private func connectionDidEnd() {
        print("connection \(self.id) did end")
        self.stop(error: nil)
    }

    private func stop(error: Error?) {
        self.nwConnection.stateUpdateHandler = nil
        self.nwConnection.cancel()
        if let didStopCallback = self.didStopCallback {
            self.didStopCallback = nil
            didStopCallback(error)
        }
    }

    private func setupReceive() {
        self.nwConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { (data, _, isComplete, error) in
            if let data = data, !data.isEmpty {
                let string = String(data: data, encoding:.utf8)
                print("connection \(self.id) did receive: \(string ?? "none")")
            }

            if let data = data {
                self.send(data: HTTPResponse.create(origin: data))
            } else if let error = error {
                self.connectionDidFail(error: error)
            } else {
                self.setupReceive()
            }
        }
    }
}

struct HTTPResponse {
    static func create(origin: Data) -> Data {
        var response = ""
        let components = String(data: origin, encoding:.utf8)?.components(separatedBy: "\n")
        let json = components?.last ?? ""
        response.append("HTTP/1.1 200 OK\r\n")

        if let jsonData = json.data(using: .utf8), jsonData.count >= 0 {
            response.append("Content-Length: \(jsonData.count)\r\n")
            response.append("Content-Type: application/json")
        }

        response.append("\r\n")
        response.append("\r\n")
        response.append(json)
        print(response)
        return response.data(using: .utf8) ?? Data()
    }
}
