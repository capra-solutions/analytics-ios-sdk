import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#endif

/// Tracks app lifecycle events (open, close, background, foreground)
final class LifecycleTracker {
    private weak var tracker: EventTracker?
    private weak var sessionManager: SessionManager?
    private weak var heartbeatManager: HeartbeatManager?

    private var backgroundTime: Date?
    private let sessionTimeout: TimeInterval

    init(sessionTimeout: TimeInterval) {
        self.sessionTimeout = sessionTimeout
    }

    func configure(tracker: EventTracker, sessionManager: SessionManager, heartbeatManager: HeartbeatManager?) {
        self.tracker = tracker
        self.sessionManager = sessionManager
        self.heartbeatManager = heartbeatManager

        setupNotifications()
    }

    private func setupNotifications() {
        #if os(iOS) || os(tvOS)
        let center = NotificationCenter.default

        // App becomes active (foreground)
        center.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        // App goes to background
        center.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        // App will terminate
        center.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
        #endif
    }

    @objc private func appDidBecomeActive() {
        let shouldStartNewSession: Bool

        if let backgroundTime = backgroundTime {
            // Check if we were in background longer than session timeout
            let backgroundDuration = Date().timeIntervalSince(backgroundTime)
            shouldStartNewSession = backgroundDuration > sessionTimeout
        } else {
            // First launch
            shouldStartNewSession = true
        }

        if shouldStartNewSession {
            sessionManager?.startNewSession()
            // Reset heartbeat manager for new session
            heartbeatManager?.resetSession()
        }

        // Track app open
        tracker?.trackAppOpen(isNewSession: shouldStartNewSession)

        // Resume heartbeats
        heartbeatManager?.resume()

        // Retry offline events when coming back online
        tracker?.retryOfflineEvents()

        backgroundTime = nil
    }

    @objc private func appDidEnterBackground() {
        backgroundTime = Date()

        // Track app close
        tracker?.trackAppClose()

        // Pause heartbeats
        heartbeatManager?.pause()

        // Flush any pending events
        tracker?.flush()
    }

    @objc private func appWillTerminate() {
        tracker?.trackAppClose()
        tracker?.flush()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
