import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

/// Core event tracking functionality
final class EventTracker {
    private let config: DMBIConfiguration
    private let sessionManager: SessionManager
    private let networkQueue: NetworkQueue

    private var isLoggedIn: Bool = false
    private var currentScreen: (name: String, url: String, title: String?, metadata: ScreenMetadata?)?
    private var screenEntryTime: Date?

    // Previous screen tracking (like web's previous_page_url)
    private var previousScreenUrl: String?
    private var previousScreenTitle: String?

    // UTM parameters (from deep links)
    private var currentUTM: UTMParameters?

    // Referrer (deep link source, push notification, etc.)
    private var currentReferrer: String?

    // User classification
    private var userType: UserType = .anonymous
    private var userSegments: Set<String> = []

    // Pending conversions (sent with next heartbeat like Marfeel)
    private var pendingConversions: [Conversion] = []

    // Scroll tracker reference
    private var scrollTracker: ScrollTracker?

    // Heartbeat manager reference (for interaction recording)
    private weak var heartbeatManager: HeartbeatManager?

    init(config: DMBIConfiguration, sessionManager: SessionManager, networkQueue: NetworkQueue) {
        self.config = config
        self.sessionManager = sessionManager
        self.networkQueue = networkQueue
    }

    // MARK: - Configuration

    func setScrollTracker(_ tracker: ScrollTracker) {
        self.scrollTracker = tracker
    }

    func setHeartbeatManager(_ manager: HeartbeatManager) {
        self.heartbeatManager = manager
    }

    // MARK: - User State

    func setLoggedIn(_ loggedIn: Bool) {
        self.isLoggedIn = loggedIn
        if loggedIn && userType == .anonymous {
            userType = .loggedIn
        }
    }

    func setUserType(_ type: UserType) {
        self.userType = type
        if type != .anonymous {
            isLoggedIn = true
        }
    }

    // MARK: - User Segments

    func addUserSegment(_ segment: String) {
        userSegments.insert(segment)
    }

    func removeUserSegment(_ segment: String) {
        userSegments.remove(segment)
    }

    func setUserSegments(_ segments: Set<String>) {
        userSegments = segments
    }

    func clearUserSegments() {
        userSegments.removeAll()
    }

    func getUserSegments() -> Set<String> {
        return userSegments
    }

    // MARK: - Conversions

    func trackConversion(_ conversion: Conversion) {
        pendingConversions.append(conversion)

        // Also send as immediate event
        var customData: [String: Any] = [
            "conversion_id": conversion.id,
            "conversion_type": conversion.type
        ]
        if let value = conversion.value { customData["conversion_value"] = value }
        if let currency = conversion.currency { customData["conversion_currency"] = currency }
        if let properties = conversion.properties {
            for (key, value) in properties {
                customData[key] = value
            }
        }

        let event = createEvent(
            eventType: "conversion",
            pageUrl: currentScreen?.url ?? "app://conversion",
            pageTitle: currentScreen?.title,
            customData: customData
        )
        enqueue(event)
    }

    // MARK: - UTM & Referrer

    func setUTMParameters(_ utm: UTMParameters) {
        self.currentUTM = utm
    }

    func setReferrer(_ referrer: String) {
        self.currentReferrer = referrer
    }

    func handleDeepLink(url: URL) {
        // Parse UTM parameters from deep link
        self.currentUTM = UTMParameters.from(url: url)
        // Set referrer as the deep link URL scheme
        self.currentReferrer = url.scheme ?? "deeplink"
    }

    // MARK: - User Interaction (for dynamic heartbeat)

    func recordInteraction() {
        heartbeatManager?.recordInteraction()
    }

    // MARK: - Screen Tracking

    func trackScreen(name: String, url: String, title: String?, metadata: ScreenMetadata? = nil) {
        // Record interaction
        recordInteraction()

        // Track exit from previous screen if any
        if let previous = currentScreen {
            trackScreenExit(
                name: previous.name,
                url: previous.url,
                title: previous.title,
                metadata: previous.metadata
            )
        }

        // Save previous screen info BEFORE updating current
        previousScreenUrl = currentScreen?.url
        previousScreenTitle = currentScreen?.title

        // Record new screen
        currentScreen = (name, url, title, metadata)
        screenEntryTime = Date()

        // Reset scroll tracking for new screen
        scrollTracker?.reset()

        // Format published date if present
        var publishedDateString: String? = nil
        if let date = metadata?.publishedDate {
            let formatter = ISO8601DateFormatter()
            publishedDateString = formatter.string(from: date)
        }

        let event = createEvent(
            eventType: "screen_view",
            pageUrl: url,
            pageTitle: title,
            customData: ["screen_name": name],
            // Article metadata
            creator: metadata?.creator,
            articleAuthor: metadata?.authors?.joined(separator: ", "),
            articleSection: metadata?.section,
            articleKeywords: metadata?.keywords,
            publishedDate: publishedDateString,
            contentType: metadata?.contentType
        )
        enqueue(event)
    }

    private func trackScreenExit(name: String, url: String, title: String?, metadata: ScreenMetadata?) {
        guard let entryTime = screenEntryTime else { return }

        let duration = Int(Date().timeIntervalSince(entryTime))
        let scrollDepth = scrollTracker?.maxScrollDepth

        let event = createEvent(
            eventType: "screen_exit",
            pageUrl: url,
            pageTitle: title,
            duration: duration,
            scrollDepth: scrollDepth,
            customData: ["screen_name": name]
        )
        enqueue(event)
    }

    // MARK: - Scroll Tracking

    func reportScrollDepth(_ percent: Int) {
        scrollTracker?.reportScrollDepth(percent)
        recordInteraction()
    }

    func getCurrentScrollDepth() -> Int {
        return scrollTracker?.maxScrollDepth ?? 0
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
            trackScreenExit(
                name: current.name,
                url: current.url,
                title: current.title,
                metadata: current.metadata
            )
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
        recordInteraction()
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
        recordInteraction()
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
        recordInteraction()
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
        recordInteraction()
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
        recordInteraction()
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
        // Set referrer when opening from push
        self.currentReferrer = "push_notification"

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

    func trackHeartbeat(activeTimeSeconds: Int, pingCounter: Int) {
        // Include pending conversions in heartbeat (like Marfeel)
        var customData: [String: Any]? = nil

        if !pendingConversions.isEmpty {
            let conversions = pendingConversions.map { $0.toDict() }
            if let data = try? JSONSerialization.data(withJSONObject: conversions),
               let string = String(data: data, encoding: .utf8) {
                customData = ["pending_conversions": string]
            }
            pendingConversions.removeAll()
        }

        let event = createEvent(
            eventType: "heartbeat",
            pageUrl: currentScreen?.url ?? "app://heartbeat",
            pageTitle: currentScreen?.title,
            scrollDepth: scrollTracker?.maxScrollDepth,
            customData: customData,
            activeTimeSeconds: activeTimeSeconds,
            pingCounter: pingCounter
        )
        enqueue(event)
    }

    // MARK: - Custom Events

    func trackCustomEvent(name: String, properties: [String: Any]?) {
        recordInteraction()
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

    // MARK: - Screen Dimensions

    private func getScreenDimensions() -> (width: Int, height: Int) {
        #if os(iOS) || os(tvOS)
        let screen = UIScreen.main.bounds
        return (Int(screen.width), Int(screen.height))
        #elseif os(watchOS)
        let screen = WKInterfaceDevice.current().screenBounds
        return (Int(screen.width), Int(screen.height))
        #else
        return (0, 0)
        #endif
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
        videoPercent: Int? = nil,
        // Article metadata
        creator: String? = nil,
        articleAuthor: String? = nil,
        articleSection: String? = nil,
        articleKeywords: [String]? = nil,
        publishedDate: String? = nil,
        contentType: String? = nil,
        // Engagement
        activeTimeSeconds: Int? = nil,
        pingCounter: Int? = nil
    ) -> AnalyticsEvent {
        sessionManager.updateActivity()

        var customDataString: String? = nil
        if let customData = customData, !customData.isEmpty {
            if let data = try? JSONSerialization.data(withJSONObject: customData),
               let string = String(data: data, encoding: .utf8) {
                customDataString = string
            }
        }

        let screenDimensions = getScreenDimensions()

        return AnalyticsEvent(
            siteId: config.siteId,
            sessionId: sessionManager.sessionId,
            userId: sessionManager.userId,
            eventType: eventType,
            pageUrl: pageUrl,
            pageTitle: pageTitle,
            referrer: currentReferrer,
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
            videoPercent: videoPercent,
            // Article metadata
            creator: creator,
            articleAuthor: articleAuthor,
            articleSection: articleSection,
            articleKeywords: articleKeywords,
            publishedDate: publishedDate,
            contentType: contentType,
            // Previous screen
            previousPageUrl: previousScreenUrl,
            previousPageTitle: previousScreenTitle,
            // Screen dimensions
            screenWidth: screenDimensions.width,
            screenHeight: screenDimensions.height,
            // UTM parameters
            utmSource: currentUTM?.source,
            utmMedium: currentUTM?.medium,
            utmCampaign: currentUTM?.campaign,
            utmContent: currentUTM?.content,
            utmTerm: currentUTM?.term,
            // Engagement
            activeTimeSeconds: activeTimeSeconds,
            pingCounter: pingCounter,
            // User
            userType: userType.rawValue,
            userSegments: userSegments.isEmpty ? nil : Array(userSegments)
        )
    }

    private func enqueue(_ event: AnalyticsEvent) {
        networkQueue.enqueue(event)

        if config.debugLogging {
            print("[DMBIAnalytics] Event: \(event.eventType) - \(event.pageUrl)")
        }
    }
}
