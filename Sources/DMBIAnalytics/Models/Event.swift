import Foundation

/// Analytics event model matching the backend schema
public struct AnalyticsEvent: Codable {
    public let siteId: String
    public let sessionId: String
    public let userId: String
    public let eventType: String
    public let pageUrl: String
    public let pageTitle: String?
    public let referrer: String?
    public let deviceType: String
    public let userAgent: String
    public let isLoggedIn: Bool
    public let timestamp: Date
    public let duration: Int?
    public let scrollDepth: Int?
    public let customData: String?

    // Video fields
    public let videoId: String?
    public let videoTitle: String?
    public let videoDuration: Float?
    public let videoPosition: Float?
    public let videoPercent: Int?

    enum CodingKeys: String, CodingKey {
        case siteId = "site_id"
        case sessionId = "session_id"
        case userId = "user_id"
        case eventType = "event_type"
        case pageUrl = "page_url"
        case pageTitle = "page_title"
        case referrer
        case deviceType = "device_type"
        case userAgent = "user_agent"
        case isLoggedIn = "is_logged_in"
        case timestamp
        case duration
        case scrollDepth = "scroll_depth"
        case customData = "custom_data"
        case videoId = "video_id"
        case videoTitle = "video_title"
        case videoDuration = "video_duration"
        case videoPosition = "video_position"
        case videoPercent = "video_percent"
    }

    public init(
        siteId: String,
        sessionId: String,
        userId: String,
        eventType: String,
        pageUrl: String,
        pageTitle: String? = nil,
        referrer: String? = nil,
        deviceType: String,
        userAgent: String,
        isLoggedIn: Bool = false,
        timestamp: Date = Date(),
        duration: Int? = nil,
        scrollDepth: Int? = nil,
        customData: String? = nil,
        videoId: String? = nil,
        videoTitle: String? = nil,
        videoDuration: Float? = nil,
        videoPosition: Float? = nil,
        videoPercent: Int? = nil
    ) {
        self.siteId = siteId
        self.sessionId = sessionId
        self.userId = userId
        self.eventType = eventType
        self.pageUrl = pageUrl
        self.pageTitle = pageTitle
        self.referrer = referrer
        self.deviceType = deviceType
        self.userAgent = userAgent
        self.isLoggedIn = isLoggedIn
        self.timestamp = timestamp
        self.duration = duration
        self.scrollDepth = scrollDepth
        self.customData = customData
        self.videoId = videoId
        self.videoTitle = videoTitle
        self.videoDuration = videoDuration
        self.videoPosition = videoPosition
        self.videoPercent = videoPercent
    }
}

/// Stored event for offline persistence
struct StoredEvent: Codable {
    let id: String
    let event: AnalyticsEvent
    let createdAt: Date
    var retryCount: Int

    init(event: AnalyticsEvent) {
        self.id = UUID().uuidString
        self.event = event
        self.createdAt = Date()
        self.retryCount = 0
    }
}
