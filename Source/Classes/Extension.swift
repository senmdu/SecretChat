//
//  CommonExt.swift
//  iZSecretChat
//
//  Created by Senthil Kumar on 03/11/21.
//

import Foundation
import SignalProtocol

public typealias SecretChatCompletion = (_ data: Data?, _ response: URLResponse?, _ error: Any?)->()
internal typealias Helper = iZSecretChatHelper

internal let kSecretChatUserId = "secretchat_user_id"
internal let kSecretChatDeviceId = "secretchat_device_id"
internal let kSecretChatRegistrationId = "signal_registration_id"
internal let kSecretChatIdentityPublicKey = "signal_identity_key_pair_public"
internal let kSecretChatIdentityPrivateKey = "signal_identity_key_pair_private"
internal let kSecretChatSignedPreKey = "signal_signed_prekey"
internal let kSecretChatDidSendPreKeys = "sendPreKeys"
internal let kSecretChatDidMaxLinkedDevices = "maxLinkedDevices"
internal let kSecretChatDidRegistered = "secretChatRegistered"
internal let kSecretChatRegisteredTime = "secretChatRegisteredTime"
internal let kSecretChatDidRegistationFailed = "secretChatRegisterationFailed"
internal let kSecretChatLoggedInTime = "secretChatLoggedTime"
internal let kneedToSyncKeys = "needToSyncKeys"
internal let kneedToRefreshSession = "needToRefreshSession"

public extension Notification.Name {
    static let secretChatSessionChanged = Notification.Name("secretSessionChanged")
    static let secretChatSessionRegisterd = Notification.Name("secretChatRegistrationUpdate")
}

extension String {
    func toUInt8() -> [UInt8] {
        if let data = Data(base64Encoded: self) {
            return  Array(data)
        }
       return []
    }
    func toBase64Data() -> Data {
        if let data = Data(base64Encoded: self) {
            return data
        }
       return Data()
    }
    func jsonStringParse() -> Any? {
        if self.isEmpty == false {
            var object: Any? = nil
            do {
                object = try JSONSerialization.jsonObject(with: self.data(using: String.Encoding.utf8, allowLossyConversion: true)!, options: .mutableContainers)
            } catch {
                
            }
            return object
        }
        return nil
    }
}
extension UInt32 {
    public func toInt() -> Int {
        return Int(self)
    }
}
extension Date {
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }

    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}
extension Data {
    var bytes: [UInt8] {
        let count = self.count / MemoryLayout<UInt8>.size
        var bytesArray = [UInt8](repeating: 0, count: count)
        self.copyBytes(to: &bytesArray, count: count * MemoryLayout<UInt8>.size)
        return bytesArray
    }
    var hexString: String {
        return self.reduce("", { $0 + String(format: "%02x", $1) })
    }
}
extension URLResponse {
    public func isSuccessResponse() -> Bool {
        if let statusCode = (self as? HTTPURLResponse)?.statusCode, statusCode == 200 || statusCode == 204 {
            return true
        }
        return false
    }
}
extension Array {
    var rootInfo: [String:Any]? {
        return self.first as? [String:Any]
    }
}

extension Array where Element == UInt8 {
    func toBase64() -> String {
        let data = Data(self)
        return data.base64EncodedString()
    }
    var data: Data {
        return Data(self)
    }
}
extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
    var objStatus: String? {
        return self["status"] as? String
    }
    var objStringFromRoot: Any? {
        return self["objString"]
    }
    var dataFromRoot: Any? {
        return self["objString"]
    }
    var moduleFromRoot: String? {
        return self["module"] as? String
    }
}
extension SignalAddress {
    var identifier : String {
        return "\(self.name)_\(self.deviceId)"
    }
}
extension NSMutableData {
    
    /// Append string to NSMutableData
    ///
    /// Rather than littering my code with calls to `dataUsingEncoding` to convert strings to NSData, and then add that data to the NSMutableData, this wraps it in a nice convenient little extension to NSMutableData. This converts using UTF-8.
    ///
    /// - parameter string:       The string to be added to the `NSMutableData`.
    
    func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    }
}


extension URL{
    func fileSize() -> Int {
        if let fileSizeValue = try? self.resourceValues(forKeys: [URLResourceKey.fileSizeKey]).allValues.first?.value as? Double ?? 0.0 {
            return Int(fileSizeValue)
        }
        return 0
    }
}
