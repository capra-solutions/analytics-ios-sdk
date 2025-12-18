import Foundation
import CommonCrypto

/// Helper for generating HMAC-SHA256 signatures for request authentication.
///
/// The signature is generated as:
/// HMAC-SHA256(secretKey, timestamp + SHA256(payload))
///
/// This prevents:
/// - Request forgery (attacker doesn't know the secret key)
/// - Replay attacks (timestamp is validated server-side within 5 min window)
/// - Payload tampering (payload hash is included in signature)
public enum SignatureHelper {

    private static var secretKey: String = ""

    /// Initialize with the secret key.
    /// Should be called during SDK initialization.
    ///
    /// - Parameter key: The secret key (should be stored securely)
    public static func initialize(key: String) {
        secretKey = key
    }

    /// Check if signature helper is initialized with a valid key.
    public static var isInitialized: Bool {
        return !secretKey.isEmpty
    }

    /// Generate signature for a request.
    ///
    /// - Parameters:
    ///   - timestamp: Unix timestamp in milliseconds
    ///   - payload: The data payload to be sent
    /// - Returns: The hex-encoded HMAC-SHA256 signature, or empty string if not initialized
    public static func sign(timestamp: Int64, payload: Data) -> String {
        guard !secretKey.isEmpty else {
            return ""
        }

        let payloadHash = sha256(payload)
        let message = "\(timestamp)\(payloadHash)"
        return hmacSHA256(key: secretKey, message: message)
    }

    /// Calculate SHA256 hash of data.
    private static func sha256(_ data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    /// Calculate HMAC-SHA256.
    private static func hmacSHA256(key: String, message: String) -> String {
        guard let keyData = key.data(using: .utf8),
              let messageData = message.data(using: .utf8) else {
            return ""
        }

        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

        keyData.withUnsafeBytes { keyPtr in
            messageData.withUnsafeBytes { msgPtr in
                CCHmac(
                    CCHmacAlgorithm(kCCHmacAlgSHA256),
                    keyPtr.baseAddress,
                    keyData.count,
                    msgPtr.baseAddress,
                    messageData.count,
                    &hash
                )
            }
        }

        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
