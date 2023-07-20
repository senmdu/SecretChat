//
//  iZSecretChat.swift
//  iZSecretChat
//
//  Created by Senthil Kumar on 10/03/22.
//

import Foundation
import SignalProtocol

/**
 The main entry point for `iZSecretChat` library encrypt/decrypt operations.

 */
public class iZSecretChat {
    
    /// API Handling delegate that needs to be confirmed to call important api's
    public static let apiHandler : SecretChatAPIHandler = SecretChatAPIHandler()
    
    /// Caching user defaults
    internal static var userDefault = UserDefaults.standard
    
    /// Unique ID of the current user
    public static var userId : String? {
        get {
            return userDefault.value(forKey: kSecretChatUserId) as? String
        }
        set {
            userDefault.set(newValue, forKey: kSecretChatUserId)
        }
    }
    /// Device ID of the current user
    public static var deviceID : Int32 {
        if let deviceid = userDefault.value(forKey: kSecretChatDeviceId) as? Int32 {
            return deviceid
        }else {
            let timeInterval = Date().timeIntervalSince1970
            var deviceID : String!
            let time = String(format: "%.0lf", timeInterval)
            let randomDigit = Helper.random(digits: 7)
            deviceID = String(abs((randomDigit + time).hashValue))
            if deviceID.count > 9 {
               deviceID =  String(deviceID.dropLast(deviceID.count - 9))
            }
            let integerDeviceID = Int32(deviceID) ?? 0
            userDefault.set(integerDeviceID, forKey: kSecretChatDeviceId)
            return integerDeviceID
        }
    }
    
    /// LocalUser data
    public static var localUser : LocalUser? {
        return SecretChatDataStore.shared.localUser
    }
    
    /**
     At install time, a initiate needs to be called.
     - To generate identity keys, registration id, and prekeys. initiating whole operation.
     - parameter sharedContainerUrl: App document directory url to hold local database. This is optional.
     - parameter memoryDefault: local memoryDefault. This is optional.
     - parameter mainThread: This is to intimating the library whether thread running in main or background. Defualt will be mainthread.
     */
    public class func initiate(sharedContainerUrl:URL? = nil, memoryDefault:UserDefaults? = nil, mainThread:Bool = true) {
        if let defaultMemory = memoryDefault {
            userDefault = defaultMemory
        }
        SecretChatDataStore.shared.intiate(sharedContainerUrl: sharedContainerUrl, mainThread: mainThread)
    }
    
    /**
       This function is to conform the `SecretChatAPIHandlerDelegate` protocol.
     - parameter delegate: `SecretChatAPIHandlerDelegate`
     */
    public class func addApiHandler(delegate:SecretChatAPIHandlerDelegate) {
        self.apiHandler.delegate = delegate
    }
    
    /**
       This function is for registering current keys to the server.
     - parameter sendPrekeys: if sensendPrekeys was true prekeys will be uploaded to the server
     */
    public class func register(sendPrekeys:Bool) {
        self.apiHandler.register(sendPrekeys: sendPrekeys) {
            NotificationCenter.default.post(name: .secretChatSessionRegisterd, object: nil, userInfo: nil)
        }
    }
    
    /**
    This function is for registering again current keys to the server
     with checking whether prekeys need to be send or not.
     */
    public class func reRegister() {
            let sendPreKey = iZSecretChat.userDefault.bool(forKey: kSecretChatDidSendPreKeys)
            iZSecretChat.userDefault.set(nil, forKey: kSecretChatDidRegistered)
            iZSecretChat.userDefault.set(nil, forKey: kSecretChatRegisteredTime)
            iZSecretChat.userDefault.set(nil, forKey: kSecretChatDidRegistationFailed)
            self.register(sendPrekeys: sendPreKey)
            iZSecretChat.userDefault.set(nil, forKey: kSecretChatDidSendPreKeys)
    }
    /**
       Sednign prekeys to the server.
     */
    public class func sendPreKeys() {
        self.apiHandler.sendPreKeys()
    }
    /**
       This function should be called if user configuration changes.
     - parameter userID: unique id of the current user.
     */
    public class func refresh(userID:String?) {
        iZSecretChat.userId = userID
    }
    /**
       E2EE server events notifier.
     - parameter data: Which contains event data
     */
    public class func eventNotify(_ data:[String : Any]) {
        self.apiHandler.sessionNotify(data)
    }
    //MARK: - SecretChatManager Request proccess
    /**
       Requesting remote user bundle from server.
    - Remote user bundle will process here.
    - After bundle process session will be stored in database
    - parameter recieptIDs: Array of remote user unique id which needed to download its bundles from server.
    - parameter completion: Call back after bundle downloaded. return false if failed to save new bundles.
    */
    public class func requestBundle(for recieptIDs:[String], completion:((Bool)->())? = nil) {
        var recieptIDs = recieptIDs
        guard recieptIDs.count > 0 else {
            completion?(false)
            return
        }

            
        let recieptID : String? = recieptIDs.first(where: {$0 != self.userId ?? ""})
        if recieptID == nil {
            recieptIDs.append(self.userId ?? "")
        }
        var excludeDeviceIDs : [String] = []
        if let ownId =  self.localUser?.identifier {
            excludeDeviceIDs.append("\(ownId)")
        }
        for recID in recieptIDs {
            let deviceIds = RemoteSession.getBundleIdentifiers(for: recID)
            excludeDeviceIDs.append(contentsOf: deviceIds)
        }
        self.apiHandler.requestBundle(for: recieptIDs, excludeIDs: excludeDeviceIDs) { data, response, error in
            if let httpResponseCode = response as? HTTPURLResponse, (httpResponseCode.statusCode == 200 || httpResponseCode.statusCode == 204), let dat = data, let result = String(data: dat, encoding: .utf8)?.jsonStringParse() as? [String:Any]  {
                
                if let message = result["message"] as? [String:Any], let resultData = message["data"] as? [[String:Any]], resultData.count > 0  {
                    self.apiHandler.proccessBundle(resultData, completion: completion)
                }
            }else {
                self.apiHandler.delegate?.addLog(error: "secretchat request bundle failed for \(recieptID ?? "")")
                completion?(false)
            }
        }
    }
    /**
       Processing conflicted bundles
    - parameter bundles: Array of remote user bundle data.
    */
    public class func processConflictBundles(bundles: [String:Any]) {
        var newBundles : [[String:Any]] = []
        bundles.forEach { bundle in
            if let identifier = iZSecretChat.localUser?.identifier  {
                if bundle.key != identifier {
                    if let bundleVal = bundle.value as? [String:Any] {
                        newBundles.append(bundleVal)
                    }
                }
            }
        }
        if newBundles.count > 0 {
            iZSecretChat.apiHandler.proccessBundle(newBundles) { didDevice in
            }
        }
    }
    /**
       Clearing the remote user sessions from database.
    - parameter bundles: Array of remote user unique id.
    */
    public class func clearBundles(bundles:[String]) {
        for bundle in bundles {
            let comp = bundle.components(separatedBy: "_")
            guard comp.count == 3 else {return}
            let usrId = comp[0]
            guard let deviceID = Int32(comp[2]) else {return}
            RemoteSession.remove(userId: usrId, deviceId: deviceID)
        }
        NotificationCenter.default.post(name: .secretChatSessionChanged, object: nil, userInfo: nil)
    }
    /**
       Complete clean up of current user data.
     */
    public class func shut() {
        clearKeys()
        SecretChatDataStore.shared.clearSession()
        SecretSession.shared.deEstabilish()
    }
    /**
       This will generate fresh set of keys for current user.
     That can used for encryption/decyption.
    - returns: `Registration` that holds information about current user keys.
    - throws: `RuntimeError`
    */
    internal class func generateKeys() throws -> Registration {
            if let registrationId = userDefault.value(forKey: kSecretChatRegistrationId) as? UInt32,
               let identityKeyPairPublic = userDefault.value(forKey: kSecretChatIdentityPublicKey) as? Data,
               let identityKeyPairPrivate = userDefault.value(forKey: kSecretChatIdentityPrivateKey) as? Data,
               let signedPreKey = userDefault.value(forKey: kSecretChatSignedPreKey) as? Data{
                
                return try Registration(identityKeyPair: (publicKey: identityKeyPairPublic, privateKey: identityKeyPairPrivate), registrationId: registrationId, signedPreKeyRecord: signedPreKey)
            }else {
                let maxVal : UInt32 = 16777215
                if let identityKeyPair = Helper.generateIdentityKeyPair(),  let registrationId = Helper.generateRegistrationId(), let signedPreKey = Helper.generateSignedPreKey(identityKeyPair: identityKeyPair, signedPreKeyId: UInt32.random(in: 1...maxVal - 1)),  let signedPreKeyData = try? signedPreKey.data() {
                    let identityKeyPublic = identityKeyPair.publicKey
                    let identityKeyPrivate = identityKeyPair.privateKey
                    userDefault.setValue(registrationId, forKey: kSecretChatRegistrationId)
                    userDefault.set(identityKeyPublic, forKey: kSecretChatIdentityPublicKey)
                    userDefault.set(identityKeyPrivate, forKey: kSecretChatIdentityPrivateKey)
                    userDefault.set(signedPreKeyData, forKey: kSecretChatSignedPreKey)
                    userDefault.synchronize()
                    return Registration(identityKeyPair: identityKeyPair, registrationId: registrationId, signedPreKeyRecord: signedPreKey)
                }else {
                    throw RuntimeError("eror")
                }

            }
    }
    /**
       Clearing all saved configuration for current user.
     */
    internal class func clearKeys() {
        userId = nil
        userDefault.set(nil, forKey: kSecretChatDeviceId)
        userDefault.set(nil, forKey: kSecretChatUserId)
        userDefault.set(nil, forKey: kSecretChatRegistrationId)
        userDefault.set(nil, forKey: kSecretChatIdentityPublicKey)
        userDefault.set(nil, forKey: kSecretChatIdentityPrivateKey)
        userDefault.set(nil, forKey: kSecretChatSignedPreKey)
        userDefault.set(nil, forKey: kSecretChatDidSendPreKeys)
        userDefault.set(nil, forKey: kSecretChatDidRegistered)
        userDefault.set(nil, forKey: kSecretChatRegisteredTime)
        userDefault.set(nil, forKey: kSecretChatLoggedInTime)
        userDefault.set(nil, forKey: kSecretChatDidRegistationFailed)
        userDefault.set(nil, forKey: kSecretChatDidMaxLinkedDevices)
        userDefault.set(nil, forKey: kneedToSyncKeys)
        userDefault.set(nil, forKey: kneedToRefreshSession)
        userDefault.synchronize()
    }
}
