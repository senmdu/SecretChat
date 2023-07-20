//
//  RemoteSession.swift
//  iZSecretChat
//
//  Created by Senthil Kumar on 01/12/21.
//

import SignalProtocol
/**
 `RemoteSession` is a struct that holds information of remote user session.
 It can be one of several types.
 */
extension String {
    var signalAddress : SignalAddress? {
        let comps = self.components(separatedBy: "_")
        if let userID = comps.first, let deviceId = Int32(comps[2]) {
            return SignalAddress(name: userID, deviceId: deviceId)
        }
        return nil
    }
}
public struct RemoteSession {
    internal init(deviceId : Int32,registrationID:UInt32,userId:String,sessionRecord:Data?,userRecord:Data?,identityKey:Data?) {
        self.userId = userId
        self.protocolAddress = SignalAddress(name: userId, deviceId: deviceId)
        self.sessionRecord = sessionRecord
        self.userRecord = userRecord
        self.registrationID = registrationID
        self.identityKey = identityKey
    }
    
    public let identityKey : Data?
    var userRecord : Data?
    var sessionRecord : Data?
    public let protocolAddress : SignalAddress
    public let userId : String
    public let registrationID : UInt32
    
    public var identifier : String {
        return "\(userId)_\(registrationID)_\(protocolAddress.deviceId)"
    }
    public static func isRemoteSessionAvailable(for userId:String?) -> Bool {
        if let userId = userId {
           return SecretChatDataStore.shared.checkRemoteSession(userId: userId)
        }
        return false
    }
    public static func get(for userId:String, sessions: @escaping ([RemoteSession])->()) {
        SecretChatDataStore.shared.getRemoteSessions(userId: userId, sessions: sessions)
    }
    public static func get(userId:String,deviceID: Int32) -> RemoteSession? {
        let address = SignalAddress(name: userId, deviceId: deviceID)
        return SecretChatDataStore.shared.getRemoteSession(address: address)
    }
    public static func get(for userId:[String]) -> [RemoteSession] {
        return SecretChatDataStore.shared.getRemoteSessions(userId: userId)
    }
    public static func refreshSessions(for identifiers:[String]) {
        let addresses = identifiers.compactMap({$0.signalAddress})
        if addresses.count > 0 {
            SecretSession.shared.refreshSession(for: addresses)
        }
        iZSecretChat.userDefault.set(nil, forKey: kneedToRefreshSession)
    }
    public static func getAllRemoteSessions() -> [RemoteSession] {
        return SecretChatDataStore.shared.getAllRemoteSessions()
    }
    public static func getAesKey(messageId:String,chid:String) -> Data? {
        return SecretChatDataStore.shared.getAesKey(messageId: messageId, chid: chid)
    }
    public static func saveAesKey(messageId:String,chid:String,aesKey:Data) {
        if chid != "" && messageId != "" {
            SecretChatDataStore.shared.save(aes: aesKey, messageId: messageId, chid: chid)
        }
    }
  
    public static func remove(userId:String,deviceId:Int32) {
        let address = SignalAddress(name: userId, deviceId: deviceId)
        SecretSession.shared.removeSession(address: address)
    }
    public static func remove(userId:[String]) {
        let sessions = RemoteSession.get(for: userId)
        for session in sessions {
            self.remove(userId: session.userId, deviceId: session.protocolAddress.deviceId)
        }
    }
    public static func getBundleIdentifiers(for userId:String) -> [String] {
        SecretChatDataStore.shared.getUserIdentifiers(userId: userId)
    }
}
