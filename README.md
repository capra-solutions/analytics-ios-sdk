# Capra Analytics iOS SDK

Native iOS SDK for Capra Analytics platform. Track screen views, video engagement, push notifications, scroll depth, conversions, and custom events.

## Features

- **Heartbeat with Dynamic Intervals**: 30s base interval, increases to 120s when user is inactive
- **Active Time Tracking**: Only counts foreground time, excludes background
- **Scroll Depth Tracking**: UIScrollView, UITableView, UICollectionView support
- **User Segments**: Cohort analysis with custom segments
- **Conversion Tracking**: Track subscriptions, purchases, registrations
- **Offline Support**: Events are queued and sent when network is available
- **Automatic Session Management**: New session after 30 min background

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/capra-solutions/analytics-ios-sdk.git", from: "3.0.0")
]
```

Or in Xcode: File > Add Packages > Enter URL: `https://github.com/capra-solutions/analytics-ios-sdk.git`

### CocoaPods

Add to your `Podfile`:

```ruby
pod 'CapraAnalytics', '~> 3.0'
```

Then run `pod install`.

## Migration from DMBIAnalytics 1.x

If upgrading from version 1.x:

1. Update import: `import DMBIAnalytics` -> `import CapraAnalytics`
2. Rename class: `DMBIAnalytics` -> `CapraAnalytics`
3. Rename config: `DMBIConfiguration` -> `CapraConfiguration`
4. Update endpoint: `https://realtime.dmbi.site/e` veya `https://t.capra.solutions/e` -> `https://analytics-ingestion.demirorenmedya.com/e`

Note: Storage keys have changed, so user sessions will be reset after upgrade.

## Migration from 2.x to 3.0.0

Version 3.0.0 includes a breaking change for Dailymotion player integration:

1. **Update Dailymotion SDK**: `DailymotionPlayerSDK` → `DailymotionPlayerSDK-iOS` (or SPM)
2. **Update player initialization**: `DMPlayerViewController` → `DMPlayerView`
3. **Wrapper uses new delegate pattern**: `DMVideoDelegate` + `DMPlayerDelegate`

If you're not using DailymotionPlayerWrapper, no changes are needed.

## Migration from 3.0.x to 3.1.0

Version 3.1.0 adds required `DMPlayerDelegate` methods for Dailymotion SDK compatibility:

**Breaking change for DailymotionPlayerWrapper:**

```swift
// Before (3.0.x):
DailymotionPlayerWrapper(player: player)

// After (3.1.0):
DailymotionPlayerWrapper(player: player, presentingViewController: self)
```

The `presentingViewController` is required for fullscreen playback and ad presentation.

## Kıble & Kuran Entegrasyonu

Kıble modülü ekranlarının analytics'e gönderilmesi için her ekranda `trackScreen` çağrısı yapılmalıdır. URL formatı **Android ile aynı** olmalıdır.

### URL Formatı

| Ekran | URL | Title |
|-------|-----|-------|
| Ana Sayfa | `https://www.{domain}/kible/anasayfa` | Kible |
| Seccade | `https://www.{domain}/kible/seccade` | Seccade |
| Vakitler | `https://www.{domain}/kible/vakitler` | Namaz Vakitleri |
| Sure | `https://www.{domain}/kible/sure` | Sure Oku |
| Pusula | `https://www.{domain}/kible/pusula` | Kible Pusulasi |
| Harita | `https://www.{domain}/kible/harita` | Kible Haritasi |
| Menu | `https://www.{domain}/kible/menu` | Menu |
| Cüz | `https://www.{domain}/kible/cuz` | Cuz Oku |
| Takvim | `https://www.{domain}/kible/takvim` | Takvim |
| Kaydedilen | `https://www.{domain}/kible/kaydedilen` | Kaydedilen |
| 99 İsim | `https://www.{domain}/kible/99ismi` | 99 Isim |
| Hadisler | `https://www.{domain}/kible/hadisler` | Hadisler |
| Zikir | `https://www.{domain}/kible/zikir` | Zikir |
| Cuma Mesajları | `https://www.{domain}/kible/cuma-mesajlari` | Cuma Mesajlari |

> **domain** marka bazlıdır: `hurriyet.com.tr`, `cnnturk.com`, `fanatik.com.tr`, `posta.com.tr`

### SwiftUI (Önerilen)

```swift
import CapraAnalytics

struct KibleVakitlerView: View {
    let domain = "hurriyet.com.tr" // Marka bazlı

    var body: some View {
        VStack {
            // Vakitler içeriği
        }
        .capraScreen(
            name: "kible_vakitler",
            url: "https://www.\(domain)/kible/vakitler",
            title: "Namaz Vakitleri"
        )
    }
}
```

### UIKit

```swift
import CapraAnalytics

class KibleVakitlerViewController: UIViewController {
    let domain = "hurriyet.com.tr"

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        CapraAnalytics.trackScreen(
            name: "kible_vakitler",
            url: "https://www.\(domain)/kible/vakitler",
            title: "Namaz Vakitleri"
        )
    }
}
```

### Tüm Ekranları Tek Helper ile Yönetme

```swift
enum KibleScreen: String {
    case anasayfa, seccade, vakitler, sure, pusula, harita
    case menu, cuz, takvim, kaydedilen, isimler = "99ismi"
    case hadisler, zikir, cumaMesajlari = "cuma-mesajlari"

    var title: String {
        switch self {
        case .anasayfa: return "Kible"
        case .seccade: return "Seccade"
        case .vakitler: return "Namaz Vakitleri"
        case .sure: return "Sure Oku"
        case .pusula: return "Kible Pusulasi"
        case .harita: return "Kible Haritasi"
        case .menu: return "Menu"
        case .cuz: return "Cuz Oku"
        case .takvim: return "Takvim"
        case .kaydedilen: return "Kaydedilen"
        case .isimler: return "99 Isim"
        case .hadisler: return "Hadisler"
        case .zikir: return "Zikir"
        case .cumaMesajlari: return "Cuma Mesajlari"
        }
    }

    func track(domain: String) {
        CapraAnalytics.trackScreen(
            name: "kible_\(rawValue)",
            url: "https://www.\(domain)/kible/\(rawValue)",
            title: title
        )
    }
}

// Kullanım:
KibleScreen.vakitler.track(domain: "hurriyet.com.tr")
```

## Quick Start

### 1. Initialize in AppDelegate

```swift
import CapraAnalytics

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        CapraAnalytics.configure(
            siteId: "your-site-ios",
            endpoint: "https://analytics-ingestion.demirorenmedya.com/e"
        )

        return true
    }
}
```

### 2. Track Screens

```swift
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    CapraAnalytics.trackScreen(
        name: "ArticleDetail",
        url: "app://article/\(articleId)",
        title: article.title
    )
}
```

### 3. Scroll Tracking

```swift
// Attach to UIScrollView, UITableView, or UICollectionView
CapraAnalytics.attachScrollTracking(to: tableView)

// Or report manually (for SwiftUI or custom implementations)
CapraAnalytics.reportScrollDepth(75) // 75%

// Get current scroll depth
let depth = CapraAnalytics.getCurrentScrollDepth()

// Detach when leaving screen
CapraAnalytics.detachScrollTracking()
```

### 4. User Types & Segments

```swift
// Set user type
CapraAnalytics.setUserType(.subscriber) // .anonymous, .loggedIn, .subscriber, .premium

// Add user segments for cohort analysis
CapraAnalytics.addUserSegment("sports_fan")
CapraAnalytics.addUserSegment("premium_reader")

// Remove segment
CapraAnalytics.removeUserSegment("sports_fan")

// Get all segments
let segments = CapraAnalytics.getUserSegments()
```

### 5. Conversion Tracking

```swift
// Simple conversion
CapraAnalytics.trackConversion(
    id: "sub_123",
    type: "subscription",
    value: 99.99,
    currency: "TRY"
)

// Detailed conversion with properties
CapraAnalytics.trackConversion(
    Conversion(
        id: "purchase_456",
        type: "purchase",
        value: 149.99,
        currency: "TRY",
        properties: [
            "product_id": "prod_123",
            "category": "premium"
        ]
    )
)
```

### 6. Video Tracking

#### Manual Tracking

```swift
// Video started playing
CapraAnalytics.trackVideoPlay(
    videoId: "vid123",
    title: "Video Title",
    duration: 180,
    position: 0
)

// Video progress (quartiles)
CapraAnalytics.trackVideoProgress(
    videoId: "vid123",
    duration: 180,
    position: 45,
    percent: 25
)

// Video completed
CapraAnalytics.trackVideoComplete(
    videoId: "vid123",
    duration: 180
)
```

#### Auto-Tracking with Player Wrappers

SDK includes wrappers for popular video players that automatically track play, pause, progress (25%, 50%, 75%, 100%), and complete events.

**AVPlayer (Native):**
```swift
import CapraAnalytics

let player = AVPlayer(url: videoURL)
let wrapper = AVPlayerWrapper(player: player)
wrapper.attach(
    videoId: "vid123",
    title: "Video Title"
)

// When done:
wrapper.detach()
```

**YouTube Player:**
```swift
// Add pod: pod 'youtube-ios-player-helper'

import CapraAnalytics

class VideoViewController: UIViewController {
    @IBOutlet weak var playerView: YTPlayerView!
    private var wrapper: YouTubePlayerWrapper?

    override func viewDidLoad() {
        super.viewDidLoad()
        wrapper = YouTubePlayerWrapper(playerView: playerView)
        wrapper?.attach(videoId: "dQw4w9WgXcQ", title: "Video Title")
        playerView.delegate = wrapper
        playerView.load(withVideoId: "dQw4w9WgXcQ")
    }
}
```

**Dailymotion Player:**
```swift
// Requires new Dailymotion SDK: pod 'DailymotionPlayerSDK-iOS' or SPM

import CapraAnalytics

class VideoViewController: UIViewController {
    private var wrapper: DailymotionPlayerWrapper?

    func setupPlayer() {
        Dailymotion.createPlayer(
            playerId: "YOUR_PLAYER_ID",
            videoId: "x8abc123"
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let player):
                // Pass self as presentingViewController for fullscreen/ad support
                self.wrapper = DailymotionPlayerWrapper(
                    player: player,
                    presentingViewController: self
                )
                self.wrapper?.attach(videoId: "x8abc123", title: "Video Title")
                // Add player view to hierarchy
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
}
```

> **Auto-play Support:** The wrapper automatically detects video changes (including auto-play) and tracks each video with the correct video ID using the `getState()` API.

### 7. Push Notifications

```swift
func userNotificationCenter(_ center: UNUserNotificationCenter,
                           didReceive response: UNNotificationResponse,
                           withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo

    CapraAnalytics.trackPushOpened(
        notificationId: userInfo["notification_id"] as? String,
        title: response.notification.request.content.title,
        campaign: userInfo["campaign"] as? String
    )

    completionHandler()
}
```

### 8. Engagement Metrics

```swift
// Get active time (excludes background)
let activeSeconds = CapraAnalytics.getActiveTimeSeconds()

// Get heartbeat count
let pingCount = CapraAnalytics.getPingCounter()

// Record user interaction (resets inactivity timer)
CapraAnalytics.recordInteraction()
```

### 9. Custom Events

```swift
CapraAnalytics.trackEvent(
    name: "article_share",
    properties: [
        "article_id": "12345",
        "share_platform": "twitter"
    ]
)
```

## Advanced Configuration

```swift
var config = CapraConfiguration(
    siteId: "your-site-ios",
    endpoint: "https://analytics-ingestion.demirorenmedya.com/e"
)

// Customize settings
config.heartbeatInterval = 30           // Base heartbeat: 30 seconds
config.maxHeartbeatInterval = 120       // Max when inactive: 120 seconds
config.inactivityThreshold = 30         // Inactive after 30 seconds
config.batchSize = 10                   // Send events in batches of 10
config.flushInterval = 30               // Flush every 30 seconds
config.sessionTimeout = 30 * 60         // New session after 30 min background
config.debugLogging = true              // Enable debug logs

CapraAnalytics.configure(with: config)
```

## SwiftUI Support

```swift
struct ArticleView: View {
    let article: Article

    var body: some View {
        ScrollView {
            // Your content
        }
        .onAppear {
            CapraAnalytics.trackScreen(
                name: "ArticleDetail",
                url: "app://article/\(article.id)",
                title: article.title
            )
        }
        .onDisappear {
            CapraAnalytics.detachScrollTracking()
        }
    }
}

// For scroll tracking in SwiftUI, use GeometryReader
struct ScrollTrackingView: View {
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack {
                    // Content
                }
                .background(
                    GeometryReader { contentGeo in
                        Color.clear.onChange(of: contentGeo.frame(in: .global).minY) { value in
                            let scrollOffset = -value
                            let contentHeight = contentGeo.size.height - geo.size.height
                            if contentHeight > 0 {
                                let percent = Int((scrollOffset / contentHeight) * 100)
                                CapraAnalytics.reportScrollDepth(percent)
                            }
                        }
                    }
                )
            }
        }
    }
}
```

## Comparison with Competitors

| Feature | Chartbeat | Marfeel | Capra SDK |
|---------|-----------|---------|-----------|
| Heartbeat | 15s | 10s | 30s (dynamic) |
| Scroll tracking | Yes | Yes | Yes |
| Active time | ? | Yes | Yes |
| Dynamic interval | Yes | No | Yes |
| Conversions | No | Yes | Yes |
| User segments | Yes | Yes | Yes |
| Offline storage | No | No | Yes |

## Requirements

- iOS 13.0+
- tvOS 13.0+
- watchOS 6.0+
- macOS 10.15+
- Swift 5.7+

## License

MIT License
