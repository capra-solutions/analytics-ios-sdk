import Foundation
#if os(iOS) || os(tvOS)
import UIKit

/// Tracks scroll depth for UIScrollView, UITableView, UICollectionView
public final class ScrollTracker: NSObject {
    private var maxScrollPercent: Int = 0
    private weak var currentScrollView: UIScrollView?
    private var observation: NSKeyValueObservation?

    /// Current maximum scroll depth reached (0-100)
    public var maxScrollDepth: Int {
        return maxScrollPercent
    }

    /// Attach to a UIScrollView (or subclass like UITableView, UICollectionView)
    /// - Parameter scrollView: The scroll view to track
    public func attach(to scrollView: UIScrollView) {
        detach()
        currentScrollView = scrollView

        // Use KVO to observe contentOffset changes
        observation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] scrollView, _ in
            self?.handleScroll(scrollView)
        }
    }

    /// Report scroll depth manually (for custom scroll implementations like SwiftUI)
    /// - Parameter percent: Scroll percentage (0-100)
    public func reportScrollDepth(_ percent: Int) {
        let clamped = min(max(percent, 0), 100)
        if clamped > maxScrollPercent {
            maxScrollPercent = clamped
        }
    }

    /// Reset scroll tracking (call when navigating to a new screen)
    public func reset() {
        maxScrollPercent = 0
    }

    /// Detach from current scroll view
    public func detach() {
        observation?.invalidate()
        observation = nil
        currentScrollView = nil
    }

    private func handleScroll(_ scrollView: UIScrollView) {
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.height
        let contentInset = scrollView.contentInset.top + scrollView.contentInset.bottom

        let scrollableHeight = contentHeight - frameHeight + contentInset
        guard scrollableHeight > 0 else {
            maxScrollPercent = 100
            return
        }

        let scrollOffset = scrollView.contentOffset.y + scrollView.contentInset.top
        let percent = Int((scrollOffset / scrollableHeight) * 100)
        let clamped = min(max(percent, 0), 100)

        if clamped > maxScrollPercent {
            maxScrollPercent = clamped
        }
    }

    deinit {
        detach()
    }
}

#else
// Minimal implementation for non-iOS platforms
public final class ScrollTracker {
    private var maxScrollPercent: Int = 0

    public var maxScrollDepth: Int {
        return maxScrollPercent
    }

    public func reportScrollDepth(_ percent: Int) {
        let clamped = min(max(percent, 0), 100)
        if clamped > maxScrollPercent {
            maxScrollPercent = clamped
        }
    }

    public func reset() {
        maxScrollPercent = 0
    }
}
#endif
