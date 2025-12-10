import Foundation

/// Core event tracking functionality
final class EventTracker {
    private let config: DMBIConfiguration
    private let sessionManager: SessionManager
    private let networkQueue: NetworkQueue

    private var isLoggedIn: Bool = false
    private var currentScreen: (name: String, url: String, title: String?)?
    private var screenEntryTime: Date?

    init(config: DMBIConfiguration, sessionManager: SessionManager, networkQueue: NetworkQueue) {
        self.config = config
        self.sessionManager = sessionManager
        self.networkQueue = networkQueue
    }

    // MARK: - User State

    func setLoggedIn(_ loggedIn: Bool) {
        self.isLoggedIn = loggedIn
    }

    // MARK: - Screen Tracking

    func trackScreen(name: String, url: String, title: String?) {
        // Track exit from previous screen if any
        if let previous = currentScreen {
            trackScreenExit(name: previous.name, url: previous.url, title: previous.title)
        }

        // Record new screen
        currentScreen = (name, url, title)
        screenEntryTime = Date()

        let event = createEvent(
            eventType: "screen_view",
            pageUrl: url,
            pageTitle: title,
            customData: ["screen_name": name]
        )
        enqueue(event)
    }

    private func trackScreenExit(name: String, url: String, title: String?) {
        guard let entryTime = screenEntryTime else { return }

        let duration = Int(Date().timeIntervalSince(entryTime))

        let event = createEvent(
            eventType: "screen_exit",
            pageUrl: url,
            pageTitle: title,
            duration: duration,
            customData: ["screen_name": name]
        )
        enqueue(event)
    }

    // MARK: - App Lifecycle

    func trackAppOpen(isNewSession: Bool) {
        let event = createEvent(
            eventType: "app_open",
            pageUrl: currentScreen?.url ?? "app://launch",
            pageTitle: nil,
            customData: ["is_new_session": isNewSession]
        )
        enqueue(event)
    }

    func trackAppClose() {
        // Track screen exit for current screen
        if let current = currentScreen {
            trackScreenExit(name: current.name, url: current.url, title: current.title)
        }

        let event = createEvent(
            eventType: "app_close",
            pageUrl: currentScreen?.url ?? "app://close",
            pageTitle: nil
        )
        enqueue(event)
    }

    // MARK: - Video Tracking

    func trackVideoImpression(videoId: String, title: String?, duration: Float?) {
        let event = createEvent(
            eventType: "video_impression",
            pageUrl: currentScreen?.url ?? "app://video",
            pageTitle: currentScreen?.title,
            videoId: videoId,
            videoTitle: title,
            videoDuration: duration
        )
        enqueue(event)
    }

    func trackVideoPlay(videoId: String, title: String?, duration: Float?, position: Float?) {
        let event = createEvent(
            eventType: "video_play",
            pageUrl: currentScreen?.url ?? "app://video",
            pageTitle: currentScreen?.title,
            videoId: videoId,
            videoTitle: title,
            videoDuration: duration,
            videoPosition: position
        )
        enqueue(event)
    }

    func trackVideoProgress(videoId: String, duration: Float?, position: Float?, percent: Int) {
        let event = createEvent(
            eventType: "video_quartile",
            pageUrl: currentScreen?.url ?? "app://video",
            pageTitle: currentScreen?.title,
            videoId: videoId,
            videoDuration: duration,
            videoPosition: position,
            videoPercent: percent
        )
        enqueue(event)
    }

    func trackVideoPause(videoId: String, position: Float?, percent: Int?) {
        let event = createEvent(
            eventType: "video_pause",
            pageUrl: currentScreen?.url ?? "app://video",
            pageTitle: currentScreen?.title,
            videoId: videoId,
            videoPosition: position,
            videoPercent: percent
        )
        enqueue(event)
    }

    func trackVideoComplete(videoId: String, duration: Float?) {
        let event = createEvent(
            eventType: "video_complete",
            pageUrl: currentScreen?.url ?? "app://video",
            pageTitle: currentScreen?.title,
            videoId: videoId,
            videoDuration: duration,
            videoPercent: 100
        )
        enqueue(event)
    }

    // MARK: - Push Notification Tracking

    func trackPushReceived(notificationId: String?, title: String?, campaign: String?) {
        var customData: [String: Any] = [:]
        if let notificationId = notificationId { customData["notification_id"] = notificationId }
        if let campaign = campaign { customData["campaign"] = campaign }

        let event = createEvent(
            eventType: "push_received",
            pageUrl: "app://push",
            pageTitle: title,
            customData: customData.isEmpty ? nil : customData
        )
        enqueue(event)
    }

    func trackPushOpened(notificationId: String?, title: String?, campaign: String?) {
        var customData: [String: Any] = [:]
        if let notificationId = notificationId { customData["notification_id"] = notificationId }
        if let campaign = campaign { customData["campaign"] = campaign }

        let event = createEvent(
            eventType: "push_opened",
            pageUrl: "app://push",
            pageTitle: title,
            customData: customData.isEmpty ? nil : customData
        )
        enqueue(event)
    }

    // MARK: - Heartbeat

    func trackHeartbeat() {
        let event = createEvent(
            eventType: "heartbeat",
            pageUrl: currentScreen?.url ?? "app://heartbeat",
            pageTitle: currentScreen?.title
        )
        enqueue(event)
    }

    // MARK: - Custom Events

    func trackCustomEvent(name: String, properties: [String: Any]?) {
        let event = createEvent(
            eventType: name,
            pageUrl: currentScreen?.url ?? "app://custom",
            pageTitle: currentScreen?.title,
            customData: properties
        )
        enqueue(event)
    }

    // MARK: - Network

    func flush() {
        networkQueue.flush()
    }

    func retryOfflineEvents() {
        networkQueue.retryOfflineEvents()
    }

    // MARK: - Event Creation

    private func createEvent(
        eventType: String,
        pageUrl: String,
        pageTitle: String?,
        duration: Int? = nil,
        scrollDepth: Int? = nil,
        customData: [String: Any]? = nil,
        videoId: String? = nil,
        videoTitle: String? = nil,
        videoDuration: Float? = nil,
        videoPosition: Float? = nil,
        videoPercent: Int? = nil
    ) -> AnalyticsEvent {
        sessionManager.updateActivity()

        var customDataString: String? = nil
        if let customData = customData, !customData.isEmpty {
            if let data = try? JSONSerialization.data(withJSONObject: customData),
               let string = String(data: data, encoding: .utf8) {
                customDataString = string
            }
        }

        return AnalyticsEvent(
            siteId: config.siteId,
            sessionId: sessionManager.sessionId,
            userId: sessionManager.userId,
            eventType: eventType,
            pageUrl: pageUrl,
            pageTitle: pageTitle,
            referrer: nil,
            deviceType: sessionManager.deviceType,
            userAgent: sessionManager.userAgent,
            isLoggedIn: isLoggedIn,
            timestamp: Date(),
            duration: duration,
            scrollDepth: scrollDepth,
            customData: customDataString,
            videoId: videoId,
            videoTitle: videoTitle,
            videoDuration: videoDuration,
            videoPosition: videoPosition,
            videoPercent: videoPercent
        )
    }

    private func enqueue(_ event: AnalyticsEvent) {
        networkQueue.enqueue(event)

        if config.debugLogging {
            print("[DMBIAnalytics] Event: \(event.eventType) - \(event.pageUrl)")
        }
    }
}
