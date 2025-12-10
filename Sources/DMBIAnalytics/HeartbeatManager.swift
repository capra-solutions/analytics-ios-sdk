import Foundation

/// Manages periodic heartbeat events for concurrent user tracking
final class HeartbeatManager {
    private var timer: Timer?
    private let interval: TimeInterval
    private weak var tracker: EventTracker?

    init(interval: TimeInterval) {
        self.interval = interval
    }

    func setTracker(_ tracker: EventTracker) {
        self.tracker = tracker
    }

    /// Start sending heartbeats
    func start() {
        stop() // Stop any existing timer

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.timer = Timer.scheduledTimer(withTimeInterval: self.interval, repeats: true) { [weak self] _ in
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
        stop()
    }

    /// Resume heartbeats (when app returns to foreground)
    func resume() {
        start()
    }

    private func sendHeartbeat() {
        tracker?.trackHeartbeat()
    }

    deinit {
        stop()
    }
}
