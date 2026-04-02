import Foundation

final class EmbeddedHTTPServer {
    private let sessionStore: SessionStore
    private let authTokenProvider: AuthTokenProvider
    private let bridgeWriter: BridgeWriting

    private(set) var port: Int?
    private(set) var token: String?

    init(
        sessionStore: SessionStore,
        authTokenProvider: AuthTokenProvider = AuthTokenProvider(),
        bridgeWriter: BridgeWriting = BridgeFileWriter()
    ) {
        self.sessionStore = sessionStore
        self.authTokenProvider = authTokenProvider
        self.bridgeWriter = bridgeWriter
    }

    func start(port: Int = 48127) throws {
        let token = try authTokenProvider.loadOrCreateToken()
        self.port = port
        self.token = token
        try bridgeWriter.write(port: port, token: token)
    }

    func makeController() -> EventIngestionController? {
        guard let token else {
            return nil
        }

        return EventIngestionController(expectedToken: token, sessionStore: sessionStore)
    }
}
