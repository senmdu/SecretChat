//
//  CryptProtocol.swift
//  iZSecretChat
//
//  Created by Senthil Kumar on 27/10/21.
//

import SignalProtocol
import Foundation


/**
 Errors thrown by the framework.
 */
internal struct RuntimeError: Error {
    /// Error message
    let message: String

    /**
     Create a Error message.
     - parameter message: Error message `String`.
     */
    init(_ message: String) {
        self.message = message
    }
    /// Localized description of error message
    public var localizedDescription: String {
        return message
    }
}

/**
 `iZSecretChatHelper` is static helper class that having useful and very important functions.
 Such as generating key pair.
 */
public class iZSecretChatHelper  {
    
    
   public static func ZCDispatchOnMainThread(_ block: @escaping ()->()) {
         if Thread.isMainThread {
             block()
         }
         else {
             DispatchQueue.main.async(execute: block)
         }
    }
    /**
       Checking if maximum linked devices reached.
        - returns:`true` on success `false` on failue.
     */
    public class func maxDeviceReached() -> Bool {
        return iZSecretChat.userDefault.bool(forKey: kSecretChatDidMaxLinkedDevices)
    }
    
    public class func setLoggedTime() {
        iZSecretChat.userDefault.set(Date().timeIntervalSince1970, forKey: kSecretChatLoggedInTime)
    }
    public static var loggedTime : Date? {
        if let timeStammp = iZSecretChat.userDefault.value(forKey: kSecretChatLoggedInTime) as? Double {
            return  Date(timeIntervalSince1970: timeStammp)
        }
        return nil
    }
    public static var registeredTime : Date? {
        if let timeStammp = iZSecretChat.userDefault.value(forKey: kSecretChatRegisteredTime) as? Double {
            return  Date(timeIntervalSince1970: timeStammp)
        }
        return nil
    }
    /**
       Checking weather device registered with server
     - returns:`true` on success `false` on failue.
     */
    public class func didDeviceRegistered() -> Bool {
        return iZSecretChat.userDefault.bool(forKey: kSecretChatDidRegistered)
    }
    public class func didDeviceRegisterFailed() -> Bool {
        return iZSecretChat.userDefault.bool(forKey: kSecretChatDidRegistationFailed)
    }
    
    /**
       Set to sync keys
     */
    public class func needToSyncKeys() {
        iZSecretChat.userDefault.set(true, forKey: kneedToSyncKeys)
    }
    
    public class func needToRefreshSessions(identifiers:[String]) {
        iZSecretChat.userDefault.set(identifiers, forKey: kneedToRefreshSession)
    }
    public class func sessionsToRefresh() -> [String]? {
        return iZSecretChat.userDefault.stringArray(forKey: kneedToRefreshSession)
    }
    /**
       Checking weather need to sync keys
     - returns:`true` on success `false` on failue.
     */
    public class func isNeedToSyncKeys() -> Bool {
        return iZSecretChat.userDefault.bool(forKey: kneedToSyncKeys)
    }
    /**
        Building `LocalUser` from `Registration`.
     - parameter registration : `Registration` data
     - parameter prekeys : Array of prekeys data
     - returns:`LocalUser`
     */
    public class func localUser(for registration:Registration, prekeys:[SessionPreKey] = []) -> LocalUser {
        return LocalUser(identitykey: registration.identityKeyPair, registrationId: registration.registrationId, signedPreKey: registration.signedPreKeyRecord)
    }
    /**
     Converting `LocalUser` to `Registration`.
     - parameter localuser : `LocalUser` data
     - returns:`Registration`
     */
    public class func registration(for localuser:LocalUser)  -> Registration {
        return Registration(identityKeyPair: localuser.identitykey, registrationId: localuser.registrationId, signedPreKeyRecord: localuser.signedPreKey)
    }
    /**
       Generating random numbers by given digits
     - parameter digits : Digit number need to be given
     - returns: Random numbers in `String` format
     */
    class func random(digits:Int) -> String {
         var number = String()
         for _ in 1...digits {
            number += "\(Int.random(in: 1...9))"
         }
         return number
     }
     
    /**
     Generating signal idenetity key pair.
     - returns:`IdentityKeyPair` from signal protocol
     */
     class func generateIdentityKeyPair() -> KeyPair? {
         return try? Signal.generateIdentityKeyPair()
     }
    /**
     Generating unique registration id from signal.
     - returns: unique registration id from signal protocol
     */
     class func generateRegistrationId() -> UInt32? {
         return try? Signal.generateRegistrationId()
     }
    /**
       Generating signed pre key for user from signal protocol.
     - parameter identityKeyPair : user `IdentityKeyPair`
     - parameter signedPreKeyId : random id
     - returns:`SessionSignedPreKey` from signal protocol
     */
     class func generateSignedPreKey(identityKeyPair : KeyPair, signedPreKeyId : UInt32) -> SessionSignedPreKey? {
       return try? Signal.generate(signedPreKey: signedPreKeyId, identity: identityKeyPair, timestamp: UInt64(Date().millisecondsSince1970))
     }
    /**
      Generating pre key from signal protocol.
     - returns: random `SessionPreKey`
     */
     class func generatePreKey() -> SessionPreKey?  {
            let count = SecretChatDataStore.shared.getPreKeysCount()
            let id = UInt32(count + 1)
             let preKeys =  try? Signal.generatePreKeys(start: id, count: 1)
             if let preKey = preKeys?[0] {
                 SecretSession.shared.addPreKey(preKey)
                 return preKey
             }
            iZSecretChat.apiHandler.delegate?.addLog(error: "generate pre key failed")
             return nil
     }
     
    /**
        Converting `LocalUser` to `Registration`
     */
     class func generatePreKeys() -> [SessionPreKey] {
          let count = SecretChatDataStore.shared.getPreKeysCount()
          let preKeyId = UInt32(count + 1)
          if let preKeys =  try? Signal.generatePreKeys(start: preKeyId, count: 100) {
             return preKeys
          }
          return []
     }
    /**
     Adding Prekeys to the  protocolStore
     - parameter preKeys: [SessionPreKey]
     */
     class func savePreKeys(_ preKeys: [SessionPreKey]) {
         SecretSession.shared.addPreKeys(preKeys)
     }
    
    /**
       Constructing parameters for registration api
      - parameter chatId: This is optional
     - parameter reg: `Registration` data
     - parameter preKey: Pre key will be attached if true
     - returns: parameter
     */
    class func getRemoteParams(for chatId:String? = nil, user reg:Registration, preKey:Bool) -> [String:Any]? {
            var params: [String: Any] = ["registration_id": Int(reg.registrationId), "device_id": reg.deviceID]
            params["identity_key"] = ["pub": reg.identityKeyPublicBase64(),"tag":1]
            params["signed_prekey"] = ["sign": reg.signedPreKeyRecordSignatureBase64(), "pub": reg.signedPreKeyPublicKeyBase64(), "tag": Int(reg.signedPreKeyId())]
            if preKey {
                if let preKey = self.generatePreKey() {
                    let preKeyID =  preKey.id
                    let pubPre =  preKey.keyPair.publicKey
                    params["onetime_prekey"] = ["pub": pubPre.base64EncodedString(), "tag": Int(preKeyID)]
                }
            }
            if let chatId = chatId {
                params["session_chat_id"] = chatId
            }
            return params
    }

    /**
       Construct `RemoteUser` using data fetched from server
      - parameter userId: userId
     - parameter data: Data fetched from server
     */
    class func createRemoteUser(userId:String?=nil,data:[String:Any]) -> RemoteUser? {
        guard let userId = userId ?? data["user_id"] as? String else {
            return nil
        }
        guard let identityKey = data["identity_key"] as? [String:Any], let publicIdentityKey = identityKey["pub"] as? String else {
            return nil
        }
        var registrationIdNil = data["registration_id"] as? Int
        if let regString = data["registration_id"] as? String,regString.count > 1 {
            registrationIdNil =  Int(regString)
        }
        guard let registrationId = registrationIdNil else {return nil}
        var reciptDeviceID = data["device_id"] as? Int ?? 0
        if let devString = data["device_id"] as? String {
            reciptDeviceID =  Int(devString) ?? 0
        }
        guard reciptDeviceID != 0 || registrationId != 0 else {return nil}
        guard let signedPreKey = data["signed_prekey"] as? [String:Any], let signedPreKeyPub = signedPreKey["pub"] as? String,
              let signedPreKeyId = signedPreKey["tag"] as? Int, let signedSign = signedPreKey["sign"] as? String else {return nil}
        let signedPreKeyPublic = signedPreKeyPub.toBase64Data()
        let identity =  publicIdentityKey.toBase64Data()
        var remoteUser = RemoteUser(signedPreKeyId: UInt32(signedPreKeyId), signedPreKeyPublicKey: signedPreKeyPublic, signedPreKeySignature: signedSign.toBase64Data(), identityKeyPairPublicKey: identity, deviceId: Int32(reciptDeviceID), registrationId: UInt32(registrationId), userId: userId)
        if let onePreKey = data["onetime_prekey"] as? [String:Any], let preKey = onePreKey["pub"] as? String, let preKeyId = onePreKey["tag"] as? Int {
            let preKeyPublic =  preKey.toBase64Data()
            remoteUser.addPreKey(preKeyId: UInt32(preKeyId), preKeyPublicKey: preKeyPublic)
        }
        return remoteUser
    }
    
    /**
       Checking can add remote session
      - parameter adress: `SignalAddress` of user
     */
    class func canAddRemoteSession(adress:SignalAddress) -> Bool {
        guard let usrAddress = SecretChatDataStore.shared.localUser?.address else {return false}
        if adress.deviceId == usrAddress.deviceId && adress.name == usrAddress.name {
            iZSecretChat.apiHandler.delegate?.addLog(error: "cannot add remote user: own session")
            return false
        }
        if RemoteSession.get(userId: adress.name, deviceID: adress.deviceId) != nil {
            iZSecretChat.apiHandler.delegate?.addLog(error: "cannot add remote user: session exist")
            return false
        }
        return true
    }

}

