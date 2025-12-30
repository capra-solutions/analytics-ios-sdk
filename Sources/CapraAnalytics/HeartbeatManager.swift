import Foundation

/// Manages periodic heartbeat events for concurrent user tracking
/// Features:
/// - Dynamic interval: increases when user is inactive
/// - Active time tracking: only counts foreground time
/// - Pause/resume on app background
final class HeartbeatManager {
    private var timer: Timer?
    private let baseInterval: TimeInterval
    private let maxInterval: TimeInterval
    private let inactivityThreshold: TimeInterval
    private weak var tracker: EventTracker?

    // Active time tracking
    private var sessionStartTime: Date = Date()
    private var totalActiveTime: TimeInterval = 0
    private var lastPauseTime: Date?

    // Dynamic interval
    private var lastInteractionTime: Date = Date()
    private var currentInterval: TimeInterval

    // Heartbeat counter
    private var pingCounter: Int = 0

    /// Total active time in seconds (excluding background time)
    var activeTimeSeconds: Int {
        var total = totalActiveTime
        if lastPauseTime == nil {
            total += Date().timeIntervalSince(sessionStartTime)
        }
        return Int(total)
    }

    /// Current ping counter
    var currentPingCounter: Int {
        return pingCounter
    }

    init(
        interval: TimeInterval,
        maxInterval: TimeInterval? = nil,
        inactivityThreshold: TimeInterval = 30
    ) {
        self.baseInterval = interval
        self.maxInterval = maxInterval ?? (interval * 4)
        self.inactivityThreshold = inactivityThreshold
        self.currentInterval = interval
    }

    func setTracker(_ tracker: EventTracker) {
        self.tracker = tracker
    }

    /// Record user interaction to reset inactivity timer
    func recordInteraction() {
        lastInteractionTime = Date()
        // Reset to base interval on interaction
        if currentInterval != baseInterval {
            currentInterval = baseInterval
            // Restart timer with new interval
            if timer != nil {
                start()
            }
        }
    }

    /// Start sending heartbeats
    func start() {
        stop() // Stop any existing timer
        sessionStartTime = Date()
        lastPauseTime = nil
        pingCounter = 0

        scheduleNextHeartbeat()
    }

    private func scheduleNextHeartbeat() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.timer = Timer.scheduledTimer(withTimeInterval: self.currentInterval, repeats: false) { [weak self] _ in
                self?.sendHeartbeat()
            }
        }
    }

    /// Stop sending heartbeats
    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Pause heartbeats (when app goes to background)
    func pause() {
        // Record active time before pausing
        if lastPauseTime == nil {
            totalActiveTime += Date().timeIntervalSince(sessionStartTime)
        }
        lastPauseTime = Date()
        stop()
    }

    /// Resume heartbeats (when app returns to foreground)
    func resume() {
        sessionStartTime = Date()
        lastPauseTime = nil
        // Don't reset pingCounter or totalActiveTime - continue from where we left
        scheduleNextHeartbeat()
    }

    /// Reset all tracking (for new session)
    func resetSession() {
        totalActiveTime = 0
        sessionStartTime = Date()
        lastPauseTime = nil
        pingCounter = 0
        currentInterval = baseInterval
        lastInteractionTime = Date()
    }

    private func sendHeartbeat() {
        // Calculate dynamic interval based on inactivity
        let timeSinceInteraction = Date().timeIntervalSince(lastInteractionTime)
        if timeSinceInteraction > inactivityThreshold {
            // Gradually increase interval when inactive (up to maxInterval)
            currentInterval = min(currentInterval * 1.5, maxInterval)
        } else {
            currentInterval = baseInterval
        }

        pingCounter += 1
        tracker?.trackHeartbeat(activeTimeSeconds: activeTimeSeconds, pingCounter: pingCounter)

        // Schedule next heartbeat
        scheduleNextHeartbeat()
    }

    deinit {
        stop()
    }
}
