import Foundation

struct SessionEvent: Codable, Equatable {
    struct Payload: Codable, Equatable {
        let message: String?
        let error: String?
        let requiresAttentionReason: String?

        init(message: String? = nil, error: String? = nil, requiresAttentionReason: String? = nil) {
            self.message = message
            self.error = error
            self.requiresAttentionReason = requiresAttentionReason
        }
    }

    let source: String
    let version: Int
    let eventId: String
    let eventType: String
    let sentAt: Date
    let session: SessionSnapshot
    let payload: Payload

    init(
        source: String = "opencode",
        version: Int = 1,
        eventId: String,
        eventType: String,
        sentAt: Date,
        session: SessionSnapshot,
        payload: Payload = Payload()
    ) {
        self.source = source
        self.version = version
        self.eventId = eventId
        self.eventType = eventType
        self.sentAt = sentAt
        self.session = session
        self.payload = payload
    }
}
