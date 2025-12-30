import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif
import Security

/// Manages session and user identifiers
final class SessionManager {
    private let keychainService = "solutions.capra.analytics"
    private let userIdKey = "capra_user_id"
    private let sessionIdKey = "capra_session_id"
    private let lastActiveKey = "capra_last_active"

    private var _sessionId: String?
    private var _userId: String?
    private var lastActiveTime: Date?
    private var sessionTimeout: TimeInterval

    var sessionId: String {
        if _sessionId == nil || shouldStartNewSession() {
            _sessionId = UUID().uuidString
            UserDefaults.standard.set(_sessionId, forKey: sessionIdKey)
        }
        return _sessionId!
    }

    var userId: String {
        if _userId == nil {
            _userId = loadUserIdFromKeychain() ?? createAndStoreUserId()
        }
        return _userId!
    }

    init(sessionTimeout: TimeInterval) {
        self.sessionTimeout = sessionTimeout
        self._sessionId = UserDefaults.standard.string(forKey: sessionIdKey)
        self.lastActiveTime = UserDefaults.standard.object(forKey: lastActiveKey) as? Date
    }

    /// Update last active time (called on each event)
    func updateActivity() {
        lastActiveTime = Date()
        UserDefaults.standard.set(lastActiveTime, forKey: lastActiveKey)
    }

    /// Check if we should start a new session
    private func shouldStartNewSession() -> Bool {
        guard let lastActive = lastActiveTime else { return true }
        return Date().timeIntervalSince(lastActive) > sessionTimeout
    }

    /// Start a new session (called on app launch or resume)
    func startNewSession() {
        _sessionId = UUID().uuidString
        UserDefaults.standard.set(_sessionId, forKey: sessionIdKey)
        updateActivity()
    }

    // MARK: - Keychain Operations

    private func loadUserIdFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: userIdKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let userId = String(data: data, encoding: .utf8) else {
            return nil
        }

        return userId
    }

    private func createAndStoreUserId() -> String {
        let userId = UUID().uuidString

        let data = userId.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: userIdKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        // Delete any existing item first
        SecItemDelete(query as CFDictionary)

        // Add the new item
        SecItemAdd(query as CFDictionary, nil)

        return userId
    }

    // MARK: - Device Info

    /// Get device type (ios_phone, ios_tablet, etc.)
    var deviceType: String {
        #if os(iOS)
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return "ios_phone"
        case .pad:
            return "ios_tablet"
        default:
            return "ios_unknown"
        }
        #elseif os(tvOS)
        return "tvos"
        #elseif os(watchOS)
        return "watchos"
        #elseif os(macOS)
        return "macos"
        #else
        return "ios_unknown"
        #endif
    }

    /// Get user agent string
    var userAgent: String {
        #if os(iOS) || os(tvOS)
        let osVersion = UIDevice.current.systemVersion
        let deviceModel = getDeviceModel()
        return "CapraAnalytics/\(SDKConstants.version) iOS/\(osVersion) (\(deviceModel))"
        #elseif os(watchOS)
        let osVersion = WKInterfaceDevice.current().systemVersion
        return "CapraAnalytics/\(SDKConstants.version) watchOS/\(osVersion)"
        #elseif os(macOS)
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        return "CapraAnalytics/\(SDKConstants.version) macOS/\(osVersion)"
        #else
        return "CapraAnalytics/\(SDKConstants.version)"
        #endif
    }

    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
