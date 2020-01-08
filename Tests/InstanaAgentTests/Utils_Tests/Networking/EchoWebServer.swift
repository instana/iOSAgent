
import Foundation
import NIO
import NIOHTTP1

///
// Inspired from: https://github.com/ilyapuchka/SwiftNIOMock
//
open class EchoWebServer {


    public class RequestStorage {
        private let lock = NSLock()
        private var _unsafe_storage = [HTTPHandler.Request]()
        public var receivedRequests: [HTTPHandler.Request] {
            get {
                lock.lock()
                defer {
                    lock.unlock()
                }
                return _unsafe_storage
            }
            set {
                lock.lock()
                _unsafe_storage = newValue
                lock.unlock()
            }
        }
    }
    public static let requestStorage = RequestStorage()
    public let port: Int
    private(set) var group: EventLoopGroup!
    private(set) var bootstrap: ServerBootstrap!
    private(set) var serverChannel: Channel!

    public init(port: Int) {
        self.port = port
    }

    public func start() throws {
        EchoWebServer.requestStorage.receivedRequests.removeAll()
        group = group ?? MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        bootstrap = bootstrap ?? bootstrapServer()

        serverChannel = try bootstrap.bind(host: "localhost", port: port).wait()
        print("Server listening on:", serverChannel.localAddress!)

        serverChannel.closeFuture.whenComplete {
            print("Server stopped")
        }
    }

    public func stop() throws {
        try serverChannel?.close().wait()
        try group.syncShutdownGracefully()
        serverChannel = nil
        bootstrap = nil
        group = nil
    }

    private func bootstrapServer() -> ServerBootstrap {
        return ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true)
                    .then {
                        channel.pipeline.add(handler: HTTPHandler())
                    }.then {
                        channel.pipeline.add(handler: HTTPResponseCompressor())
                }
            }
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
    }
}

extension EchoWebServer {
    public class HTTPHandler: ChannelInboundHandler {
        public typealias InboundIn = HTTPServerRequestPart
        private var state: State = .idle

        public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
            defer {
                ctx.fireChannelRead(data)
            }

            switch unwrapInboundIn(data) {
            case let .head(head):
                state.requestReceived(head: head)
            case let .body(buffer):
                state.bodyReceived(buffer: buffer)
            case .end:
                let (head, buffer) = state.requestComplete()

                var httpBody: Data?
                if var body = buffer {
                    httpBody = body.readString(length: body.readableBytes)?.data(using: .utf8)
                }
                let request = Request(head: head, body: httpBody, ctx: ctx)
                EchoWebServer.requestStorage.receivedRequests.append(request)
                var responseBuffer = ctx.channel.allocator.buffer(capacity: 0)
                let eventLoop = ctx.channel.eventLoop
                let response = Response()
                response.body = request.body
                response.statusCode = .ok
                eventLoop.execute {
                    _ = ctx.channel.write(HTTPServerResponsePart.head(
                        HTTPResponseHead(version: head.version, status: response.statusCode, headers: response.headers))
                    )
                    _ = response.body
                        .flatMap { String(data: $0, encoding: .utf8) }
                        .flatMap { responseBuffer.write(string: $0) }

                    _ = ctx.channel.write(HTTPServerResponsePart.body(.byteBuffer(responseBuffer)))

                    _ = ctx.channel.writeAndFlush(HTTPServerResponsePart.end(nil)).then {
                        ctx.channel.close()
                    }
                    self.state.responseComplete()
                }
            }
        }
    }
}

extension EchoWebServer.HTTPHandler {
    enum State {
        case idle
        case ignoringRequest
        case receivingRequest(HTTPRequestHead, ByteBuffer?)
        case sendingResponse

        mutating func requestReceived(head: HTTPRequestHead) {
            guard case .idle = self else {
                preconditionFailure("Invalid state for \(#function): \(self)")
            }
            print("Received request: ", head)
            self = .receivingRequest(head, nil)
        }

        mutating func bodyReceived(buffer: ByteBuffer) {
            var body = buffer
            guard case .receivingRequest(let header, var buffer) = self else {
                preconditionFailure("Invalid state for \(#function): \(self)")
            }
            if buffer == nil {
                buffer = body
            } else {
                buffer?.write(buffer: &body)
            }
            self = .receivingRequest(header, buffer)
        }

        mutating func requestComplete() -> (HTTPRequestHead, ByteBuffer?)  {
            guard case let .receivingRequest(header, buffer) = self else {
                preconditionFailure("Invalid state for \(#function): \(self)")
            }
            if var buffer = buffer {
                print("Received body: \(buffer.readString(length: buffer.readableBytes) ?? "nil")")
            }
            self = .sendingResponse
            return (header, buffer)
        }

        mutating func responseComplete() {
            guard case .sendingResponse = self else {
                preconditionFailure("Invalid state for response complete: \(self)")
            }
            self = .idle
        }
    }
}

extension EchoWebServer.HTTPHandler {
    public struct Request {
        public let head: HTTPRequestHead
        public let body: Data?
        public let ctx: ChannelHandlerContext

        public init(head: HTTPRequestHead, body: Data?, ctx: ChannelHandlerContext) {
            self.head = head
            self.body = body
            self.ctx = ctx
        }
    }
}

extension EchoWebServer.HTTPHandler {
    public class Response {
        var state: State = .idle
        public var statusCode: HTTPResponseStatus = .ok
        public var headers: HTTPHeaders = HTTPHeaders()
        public var body: Data?
    }
}
