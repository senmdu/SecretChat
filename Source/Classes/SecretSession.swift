//
//  SessionCipher.swift
//  iZSecretChat
//
//  Created by Senthil Kumar on 03/11/21.
//

import SignalProtocol

/**
 `SecretSession` is responsible for setting up signal protocol store.
 Once a session has been established, SecretSession
 can be used to encrypt/decrypt messages in that session.

 Sessions are built from one these different possible vectors:
 - A session_pre_key_bundle retrieved from a server
 - A pre_key_signal_message received from a client

 Sessions are constructed per Signal Protocol address
 (recipient name + device ID tuple). Remote logical users are identified by
 their recipient name, and each logical recipient can have multiple
 physical devices.
 */
public class SecretSession {
    
    /// The protocol store
   private final var protocolStore : SignalStore!
    
    /**
     Create a store
     */
    private func loadStore() {
        self.protocolStore = try! SignalStore(identityKeyStore: iZSIdentityStore(), preKeyStore: iZSPreKeyStore(), sessionStore: iZSSessionStore(), signedPreKeyStore: iZSSignedPrekeyStore(), senderKeyStore: iZSSenderKeyStore())
    }
    
    /**
     Create a protocolStore
     */
    public func estabilish() { self.loadStore() }
    /**
       Destablishing a protocolStore
     */
    public func deEstabilish() {
        self.protocolStore = nil
    }
    
    private(set) public static var shared = SecretSession()
    
    internal func refreshSession(for address:[SignalAddress]) {
        let remoteSessions = SecretChatDataStore.shared.getRemoteSessions(for: address)
        for session in remoteSessions {
            (self.protocolStore.sessionStore as? iZSSessionStore)?.refresh(session: session)
        }
    }

    /**
     Adding Prekey to the  protocolStore
     - parameter preKey: SessionPreKey
     */
    internal func addPreKey(_ preKey:SessionPreKey) {
        if let data =  try? preKey.data() {
            Helper.ZCDispatchOnMainThread {
                SecretChatDataStore.shared.save(preKey: preKey)
                _ = self.protocolStore.preKeyStore.store(preKey:data, for: preKey.id)
            }
        }
    }
    /**
     Adding Prekeys to the  protocolStore
     - parameter preKeys: [SessionPreKey]
     */
    func addPreKeys(_ preKeys:[SessionPreKey]) {
        for preKey in preKeys {
            self.addPreKey(preKey)
        }
    }
    /**
     Check store having session for particular userId and deviceId
     - parameter name: String
     - parameter deviceId: Int32
     - returns: `true` if have session, `false` no session
     */
    public func hasSession(name:String,deviceId:Int32) -> Bool {
        self.hasSession(address: SignalAddress(name: name, deviceId: deviceId))
    }
    /**
     Check store having session for particular signalAddress
     - parameter address: SignalAddress
     - returns: `true` if have session, `false` no session
     */
    public func hasSession(address:SignalAddress) -> Bool {
        return self.protocolStore.sessionStore.containsSession(for: address)
    }
    /**
     Check store having session for particular userId
     - parameter name: String
     - returns: `true` if have session, `false` no session
     */
    public func hasSession(name:String) -> Bool {
        if let sessionStore =  self.protocolStore.sessionStore as? iZSSessionStore,sessionStore.hasSession(name: name) {
            return true
        }
        return false
    }
    /**
     Remove session from store using singalAddress
     - parameter address: SignalAddress
     */
    public func removeSession(address:SignalAddress) {
        _ = self.protocolStore.sessionStore.deleteSession(for: address)
    }
    /**
     Building new session to the store once preKey bundle downloaded from server.
     Also saving session into local database.
     - note: Possible errors:
     - `untrustedIdentity` if the sender's identity key is not trusted
     - parameter remoteUser: RemoteUser
     - returns: `true` on success, `false` on failure
     */
    @discardableResult
    public func add(remoteUser:RemoteUser) -> Bool{
        guard Helper.canAddRemoteSession(adress: remoteUser.protocolAddress) == true else {
            return false
        }
        let preKeyBundle = SessionPreKeyBundle(registrationId: remoteUser.registrationId, deviceId: remoteUser.protocolAddress.deviceId, preKeyId: remoteUser.preKeyId, preKey: remoteUser.preKeyPublicKey, signedPreKeyId: remoteUser.signedPreKeyId, signedPreKey: remoteUser.signedPreKeyPublicKey, signature: remoteUser.signedPreKeySignature, identityKey: remoteUser.identityKeyPairPublicKey)
        SecretChatDataStore.shared.create(remoteUser: remoteUser)
        do {
            try SessionBuilder(for: remoteUser.protocolAddress, in: self.protocolStore).process(preKeyBundle: preKeyBundle)
            return true
        } catch let err {
            iZSecretChat.apiHandler.delegate?.addLog(error: "error while proccessing bundle: \(err)")
            return false
        }
    }
    
    /**
     Encrypt a message using signal protocol.
     - note: Possible errors are:
     - `unknownError`: The cipher could not be created, or other error
     - `invalidMessage`: The input is not valid ciphertext
     - `legacyMessage`: The input is a message formatted by a protocol version that is no longer supported
     - `invalidKeyId`: There is no local pre key record that corresponds to the pre key Id in the message
     - `invalidKey`: The message is formatted incorrectly
     - `untrustedIdentity`: The identity key of the sender is untrusted
     - `noSession`: There is no established session for this contact
     - parameter session: `RemoteSession` that having session details.
     - parameter message: The  message bytes.
     - returns: The encrypted message on success, nil on failure
     */
    public func signalEncrypt(session:RemoteSession,message:Data) -> Data? {
        let remoteSessionCipher = SessionCipher(for: SignalAddress(name: session.userId, deviceId: session.protocolAddress.deviceId), in: self.protocolStore)
        do {
            let ciper = try remoteSessionCipher.encrypt(message)
            return ciper.message
        } catch let err {
            iZSecretChat.apiHandler.delegate?.addLog(error: "Could not encrypt signal message: \(err)")
            return nil
        }
    }
    
    /**
     Encrypt a message using signal protocol.
     - note: Possible errors are:
     - `unknownError`: The cipher could not be created, or other error
     - `invalidMessage`: The input is not valid ciphertext
     - `legacyMessage`: The input is a message formatted by a protocol version that is no longer supported
     - `invalidKeyId`: There is no local pre key record that corresponds to the pre key Id in the message
     - `invalidKey`: The message is formatted incorrectly
     - `untrustedIdentity`: The identity key of the sender is untrusted
     - `noSession`: There is no established session for this contact
     - parameter name: userId `String`
     - parameter deviceID: Device id`Int32`.
     - parameter message: The  message bytes.
     - returns: The encrypted message on success, nil on failure
     */
    public func signalEncrypt(name:String,deviceID:Int32,message : Data) -> Data? {
        let remoteSessionCipher = SessionCipher(for: SignalAddress(name: name, deviceId: deviceID), in: self.protocolStore)
        do {
            let ciper = try remoteSessionCipher.encrypt(message)
            return ciper.message
        } catch let err {
            iZSecretChat.apiHandler.delegate?.addLog(error: "Could not encrypt signal message: \(err)")
            return nil
        }
    }
    
    /**
     Decrypt a message from a encrypted aes key.
     - note: Possible errors are:
     - `invalidArgument` if the ciphertext message type is not `preKey` or `signal`
     - `unknownError`: The cipher could not be created, or other error
     - `invalidMessage`: The input is not valid ciphertext
     - `duplicateMessage`: The input is a message that has already been received
     - `legacyMessage`: The input is a message formatted by a protocol version that is no longer supported
     - `invalidKeyId`: There is no local pre key record that corresponds to the pre key Id in the message
     - `invalidKey`: The message is formatted incorrectly
     - `untrustedIdentity`: The identity key of the sender is untrusted
     - `noSession`: There is no established session for this contact
     - parameter sender: Userid `String`
     - parameter deviceID: Device id`Int32`.
     - parameter encAesKey: Encrypted AESKey `String`
     - returns: The decrypted data on success, nil on failure
     */
    public func signalDecrypt(_ sender:String,deviceId:Int32, encAesKey : String) -> Data? {
        self.signalDecrypt(SignalAddress(name: sender, deviceId: deviceId), message: encAesKey.toBase64Data())
    }
    /**
     Decrypt a message from a encrypted aes key using `RemoteSession`.
     - note: Possible errors are:
     - `invalidArgument` if the ciphertext message type is not `preKey` or `signal`
     - `unknownError`: The cipher could not be created, or other error
     - `invalidMessage`: The input is not valid ciphertext
     - `duplicateMessage`: The input is a message that has already been received
     - `legacyMessage`: The input is a message formatted by a protocol version that is no longer supported
     - `invalidKeyId`: There is no local pre key record that corresponds to the pre key Id in the message
     - `invalidKey`: The message is formatted incorrectly
     - `untrustedIdentity`: The identity key of the sender is untrusted
     - `noSession`: There is no established session for this contact
     - parameter session: Userid `RemoteSession`
     - parameter encAesKey: Encrypted AESKey `String`
     - returns: The decrypted data on success, nil on failure
     */
    public func signalDecrypt(_ session:RemoteSession, encAesKey : String) -> Data? {
        self.signalDecrypt(session.protocolAddress, message: encAesKey.toBase64Data())
    }
    
    /**
     Decrypt a message from a serialized ciphertext message.
     - note: Possible errors are:
     - `invalidArgument` if the ciphertext message type is not `preKey` or `signal`
     - `unknownError`: The cipher could not be created, or other error
     - `invalidMessage`: The input is not valid ciphertext
     - `duplicateMessage`: The input is a message that has already been received
     - `legacyMessage`: The input is a message formatted by a protocol version that is no longer supported
     - `invalidKeyId`: There is no local pre key record that corresponds to the pre key Id in the message
     - `invalidKey`: The message is formatted incorrectly
     - `untrustedIdentity`: The identity key of the sender is untrusted
     - `noSession`: There is no established session for this contact
     - parameter address: `SignalAddress`
     - parameter message: The data of the message to decrypt, either pre key message or signal message
     - returns: The decrypted data on success, nil on failure
     */
    public func signalDecrypt(_ address:SignalAddress, message : Data) -> Data? {
        let remoteSessionCipher = SessionCipher(for: address, in: self.protocolStore)
        var error = ""
        var signalMessage = self.signalCipherDecrypt(session: remoteSessionCipher, message: message)
        if signalMessage.message == nil {
            error = signalMessage.error ?? ""
            signalMessage = self.preKeyCipherDecrypt(session: remoteSessionCipher, message: message)
            error = signalMessage.error ?? ""
        }
        if error != "" {
            iZSecretChat.apiHandler.delegate?.addLog(error: "could not decrypt \(error)")
        }
        return signalMessage.message
    }
    
    private func signalCipherDecrypt(session:SessionCipher, message : Data)  -> (message:Data?,error:String?) {
        do {
            let decryptedMessage = try session.decrypt(signalMessage: message)
            return (decryptedMessage,nil)
        } catch let error  {
            return (nil,"signal message: \(error)")
        }
    }
    
    private func preKeyCipherDecrypt(session:SessionCipher, message : Data)  -> (message:Data?,error:String?) {
        do {
            let decryptedMessage = try session.decrypt(preKeySignalMessage: message)
            return (decryptedMessage,nil)
        } catch let error  {
            return (nil,"prekey signal message: \(error)")
        }
    }
}

