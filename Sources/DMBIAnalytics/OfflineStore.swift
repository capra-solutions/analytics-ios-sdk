import Foundation

/// SQLite-based offline event storage
final class OfflineStore {
    private let fileURL: URL
    private let maxEvents: Int
    private let retentionDays: Int
    private let queue = DispatchQueue(label: "site.dmbi.analytics.offline", qos: .utility)

    private var events: [StoredEvent] = []

    init(maxEvents: Int, retentionDays: Int) {
        self.maxEvents = maxEvents
        self.retentionDays = retentionDays

        // Store in Application Support directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let analyticsDir = appSupport.appendingPathComponent("DMBIAnalytics", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: analyticsDir, withIntermediateDirectories: true)

        self.fileURL = analyticsDir.appendingPathComponent("events.json")

        // Load existing events
        loadEvents()

        // Clean up old events
        cleanupOldEvents()
    }

    /// Store an event for later sending
    func store(_ event: AnalyticsEvent) {
        queue.async { [weak self] in
            guard let self = self else { return }

            let storedEvent = StoredEvent(event: event)
            self.events.append(storedEvent)

            // Trim if over limit
            if self.events.count > self.maxEvents {
                self.events.removeFirst(self.events.count - self.maxEvents)
            }

            self.saveEvents()
        }
    }

    /// Fetch pending events for retry
    func fetchPendingEvents() -> [StoredEvent] {
        var result: [StoredEvent] = []
        queue.sync {
            result = events
        }
        return result
    }

    /// Delete events by IDs (after successful send)
    func delete(ids: [String]) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.events.removeAll { ids.contains($0.id) }
            self.saveEvents()
        }
    }

    /// Increment retry count for an event
    func incrementRetry(id: String, maxRetries: Int) {
        queue.async { [weak self] in
            guard let self = self else { return }

            if let index = self.events.firstIndex(where: { $0.id == id }) {
                self.events[index].retryCount += 1

                // Remove if exceeded max retries
                if self.events[index].retryCount > maxRetries {
                    self.events.remove(at: index)
                }

                self.saveEvents()
            }
        }
    }

    // MARK: - Persistence

    private func loadEvents() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            events = try decoder.decode([StoredEvent].self, from: data)
        } catch {
            // If corrupted, start fresh
            events = []
        }
    }

    private func saveEvents() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(events)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Silently fail - not critical
        }
    }

    private func cleanupOldEvents() {
        queue.async { [weak self] in
            guard let self = self else { return }

            let cutoffDate = Calendar.current.date(byAdding: .day, value: -self.retentionDays, to: Date())!

            let originalCount = self.events.count
            self.events.removeAll { $0.createdAt < cutoffDate }

            if self.events.count != originalCount {
                self.saveEvents()
            }
        }
    }
}
