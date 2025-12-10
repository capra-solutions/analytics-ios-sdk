# DMBI Analytics iOS SDK

Native iOS SDK for DMBI Analytics platform. Track screen views, video engagement, push notifications, and custom events.

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/dmbi-analytics/analytics-ios-sdk.git", from: "1.0.0")
]
```

Or in Xcode: File > Add Packages > Enter URL: `https://github.com/dmbi-analytics/analytics-ios-sdk.git`

### CocoaPods

```ruby
pod 'DMBIAnalytics', '~> 1.0'
```

## Quick Start

### 1. Initialize in AppDelegate

```swift
import DMBIAnalytics

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        DMBIAnalytics.configure(
            siteId: "your-site-ios",
            endpoint: "https://realtime.dmbi.site/e"
        )

        return true
    }
}
```

### 2. Track Screens

```swift
// In your view controllers
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    DMBIAnalytics.trackScreen(
        name: "ArticleDetail",
        url: "app://article/\(articleId)",
        title: article.title
    )
}
```

### 3. Track Videos

```swift
// Video started playing
DMBIAnalytics.trackVideoPlay(
    videoId: "vid123",
    title: "Video Title",
    duration: 180,
    position: 0
)

// Video progress (quartiles)
DMBIAnalytics.trackVideoProgress(
    videoId: "vid123",
    duration: 180,
    position: 45,
    percent: 25
)

// Video paused
DMBIAnalytics.trackVideoPause(
    videoId: "vid123",
    position: 90,
    percent: 50
)

// Video completed
DMBIAnalytics.trackVideoComplete(
    videoId: "vid123",
    duration: 180
)
```

### 4. Track Push Notifications

```swift
// In your notification delegate
func userNotificationCenter(_ center: UNUserNotificationCenter,
                           didReceive response: UNNotificationResponse,
                           withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo

    DMBIAnalytics.trackPushOpened(
        notificationId: userInfo["notification_id"] as? String,
        title: response.notification.request.content.title,
        campaign: userInfo["campaign"] as? String
    )

    completionHandler()
}
```

### 5. User Login State

```swift
// When user logs in
DMBIAnalytics.setLoggedIn(true)

// When user logs out
DMBIAnalytics.setLoggedIn(false)
```

### 6. Custom Events

```swift
DMBIAnalytics.trackEvent(
    name: "article_share",
    properties: [
        "article_id": "12345",
        "share_platform": "twitter"
    ]
)
```

## Advanced Configuration

```swift
var config = DMBIConfiguration(
    siteId: "your-site-ios",
    endpoint: "https://realtime.dmbi.site/e"
)

// Customize settings
config.heartbeatInterval = 60        // Heartbeat every 60 seconds
config.batchSize = 10                // Send events in batches of 10
config.flushInterval = 30            // Flush every 30 seconds
config.sessionTimeout = 30 * 60      // New session after 30 min background
config.debugLogging = true           // Enable debug logs

DMBIAnalytics.configure(with: config)
```

## Features

- **Automatic Session Management**: Sessions are automatically created on app launch and after 30 minutes of inactivity
- **Persistent User ID**: User ID is stored in Keychain and persists across app reinstalls
- **Offline Support**: Events are queued and sent when network is available
- **Heartbeat**: Periodic heartbeats enable real-time concurrent user tracking
- **App Lifecycle**: Automatic tracking of app open/close events
- **Video Tracking**: Track video impressions, plays, progress, pauses, and completions

## Requirements

- iOS 13.0+
- tvOS 13.0+
- watchOS 6.0+
- macOS 10.15+
- Swift 5.7+

## License

MIT License
