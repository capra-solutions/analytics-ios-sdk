import SwiftUI

/// SwiftUI View modifier for automatic screen tracking
///
/// Usage:
/// ```swift
/// ContentView()
///     .capraScreen(name: "Home", url: "https://www.hurriyet.com.tr/kible/anasayfa", title: "Ana Sayfa")
/// ```
@available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
struct CapraScreenModifier: ViewModifier {
    let name: String
    let url: String
    let title: String?
    let metadata: ScreenMetadata?

    func body(content: Content) -> some View {
        content
            .onAppear {
                if let metadata = metadata {
                    CapraAnalytics.trackScreen(name: name, url: url, title: title, metadata: metadata)
                } else {
                    CapraAnalytics.trackScreen(name: name, url: url, title: title)
                }
            }
    }
}

@available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
public extension View {
    /// Track screen view automatically when this view appears
    /// - Parameters:
    ///   - name: Screen name identifier (e.g., "kible_vakitler")
    ///   - url: Full URL for the screen (e.g., "https://www.hurriyet.com.tr/kible/vakitler")
    ///   - title: Optional screen title (e.g., "Namaz Vakitleri")
    func capraScreen(name: String, url: String, title: String? = nil) -> some View {
        modifier(CapraScreenModifier(name: name, url: url, title: title, metadata: nil))
    }

    /// Track screen view with metadata when this view appears
    /// - Parameters:
    ///   - name: Screen name identifier
    ///   - url: Full URL for the screen
    ///   - title: Optional screen title
    ///   - metadata: Screen metadata (section, authors, etc.)
    func capraScreen(name: String, url: String, title: String? = nil, metadata: ScreenMetadata) -> some View {
        modifier(CapraScreenModifier(name: name, url: url, title: title, metadata: metadata))
    }
}
