//
//  SignalProtocolStore.swift
//  iZSecretChat
//
//  Created by Senthil Kumar on 01/12/21.
//

import SignalProtocol

/**
 The `iZSIdentityStore`class is for providing the storage for identity keys
 
 It's confiring to `IdentityKeyStore` protocol.
 */
final class iZSIdentityStore: IdentityKeyStore {

    /// Storage of identity keys.
    var keys = [SignalAddress : Data]()
    
    /**
     Construct a identity key store for storing identity keys.
     */
    init() {}
    
    /**
     Get the local client's identity key pair.
     - returns: The identity key pair on success, nil on failure
     */
    func identityKeyPair() -> KeyPair? {
        return SecretChatDataStore.shared.localUser?.identitykey
    }
    /**
     Return the local client's registration ID.

     Clients should maintain a registration ID, a random number
     between 1 and 16380 that's generated once at install time.

     - returns: The registration id on success, nil on failure
     */
    func localRegistrationId() -> UInt32? {
        return SecretChatDataStore.shared.localUser?.registrationId
    }
    /**
     Save a remote client's identity key

     Store a remote client's identity key as trusted.
     The value of `identity` may be nil. In this case remove the key data
     from the identity store, but retain any metadata that may be kept
     alongside it.

     - parameter identity: The remote client's identity key, may be nil
     - parameter address: The address of the remote client
     - returns: `true` on success, `false` on failure
     */
    func save(identity: Data?, for address: SignalAddress) -> Bool {
        keys[address] = identity
        return true
    }
    /**
     Verify a remote client's identity key.

     Determine whether a remote client's identity is trusted. Convention is that the Signal protocol is 'trust on first use.' This means that an identity key is considered 'trusted' if there is no entry for the recipient in the local store, or if it matches the saved key for a recipient in the local store.  Only if it mismatches an entry in the local store is it considered 'untrusted.'

     - parameter address: The address of the remote client
     - parameter identity: The identity key to verify
     - returns: `true` if trusted, `false` if untrusted, nil on failure
     */
    func isTrusted(identity: Data, for address: SignalAddress) -> Bool? {
        guard let savedIdentity = keys[address] else {
            return true
        }
        return savedIdentity == identity
    }
    /**
     Function called to perform cleanup when the data store context is being
     destroyed.
     */
    func destroy() {
        
    }
}

/**
 The `iZSPreKeyStore`class is for providing the storage for pre keys.
 
 It's confiring to `PreKeyStore` protocol.
 */
final class iZSPreKeyStore: PreKeyStore {

    /// Storage of pre keys.
    var keys = [UInt32 : Data]()
    
    /**
     Construct a pre key store for storing pre keys.
     */
    init() {
        let prekeys = SecretChatDataStore.shared.getPreKeys()
        if prekeys.count > 0  {
            do {
                for preKey in prekeys {
                   keys[preKey.id] =  try preKey.data()
                }
            } catch {

            }
        }
    }

    /**
     Load a local serialized PreKey record.
     - parameter preKey: The ID of the local serialized PreKey record
     - returns: The record, if found, or nil
     */
    func load(preKey: UInt32) -> Data? {
        return keys[preKey]
    }

    /**
     Store a local serialized PreKey record.
     - parameter preKey: The serialized record
     - parameter id: The ID of the PreKey record to store.
     - returns: `true` on success, `false` on failure
     */
    func store(preKey: Data, for id: UInt32) -> Bool {
        keys[id] = preKey
        return true
    }
    /**
     Determine whether there is a committed PreKey record matching the
     provided ID.
     - parameter preKey: A PreKey record ID.
     - returns: `true` if the store has a record for the PreKey ID, `false` otherwise
     */
    func contains(preKey: UInt32) -> Bool {
        return keys[preKey] != nil
    }
    /**
     Delete a PreKey record from local storage.
     - parameter preKey: The ID of the PreKey record to remove.
     - returns: `true` on success, `false` on failure
     */
    func remove(preKey: UInt32) -> Bool {
        keys[preKey] = nil
        return true
    }
    
    /**
     Function called to perform cleanup when the data store context is being
     destroyed.
     */
    func destroy() {
        
    }
}
/**
 The `iZSSignedPrekeyStore`class is for providing the storage for signed pre keys.
 
 It's confiring to `SignedPreKeyStore` protocol.
 */
final class iZSSignedPrekeyStore: SignedPreKeyStore {

    /// Storage of signed pre keys.
    var keys = [UInt32 : Data]()
    
    /**
     Construct a signed pre key store for storing signed pre keys.
     */
    init() {
        if let localUser = SecretChatDataStore.shared.localUser {
            do {
                keys[localUser.signedPreKey.id] = try localUser.signedPreKey.data()
            } catch {

            }
        }
    }
    /**
     Load a local serialized signed PreKey record.
     - parameter signedPreKey: The ID of the local signed PreKey record
     - returns: The record, if found, or nil
     */
    func load(signedPreKey: UInt32) -> Data? {
        return keys[signedPreKey]
    }
    /**
     Store a local serialized signed PreKey record.
     - parameter signedPreKey: The serialized record
     - parameter id: the Id of the signed PreKey record to store
     - returns: `true` on success, `false` on failure
     */
    func store(signedPreKey: Data, for id: UInt32) -> Bool {
        keys[id] = signedPreKey
        return true
    }
    
    /**
     Determine whether there is a committed signed PreKey record matching
     the provided ID.
     - parameter singedPreKey: A signed PreKey record ID
     - returns: `true` if the store has a record for the signed PreKey ID, `false` otherwise
     */
    func contains(signedPreKey: UInt32) -> Bool {
        return keys[signedPreKey] != nil
    }
    
    /**
     Delete a SignedPreKeyRecord from local storage.

     - parameter signedPreKey: The ID of the signed PreKey record to remove.
     - returns: `true` on success, `false` on failure
     */
    func remove(signedPreKey: UInt32) -> Bool {
        keys[signedPreKey] = nil
        return true
    }
    /**
     Function called to perform cleanup when the data store context is being
     destroyed.
     */
    func destroy() {
        
    }
}

/**
 The `iZSSessionStore`class is for providing the storage for sessions.
 
 It's confiring to `SessionStore` protocol.
 */
final class iZSSessionStore: SessionStore {

    /// Sessions will be stored here.
    private var sessions = [SignalAddress : Data]()

    /// Storage of additional user records.
    private var records = [SignalAddress : Data]()
    
    /**
     Construct a session store.
       
     Sessions will be fetched from local database.
     */
    init() {
        let remoteSessions = SecretChatDataStore.shared.getAllRemoteSessions()
        if remoteSessions.count > 0 {
            for session in remoteSessions {
                if let record = session.sessionRecord {
                    self.sessions[session.protocolAddress] = record
                }
                self.records[session.protocolAddress] = session.userRecord
            }
        }
    }
    
    func refresh(session:RemoteSession) {
        if let sessionRecord = session.sessionRecord {
            sessions[session.protocolAddress] = sessionRecord
        }
        if let userRecord = session.userRecord {
            records[session.protocolAddress] = userRecord
        }
    }
    /**
     Returns a copy of the serialized session record corresponding to the
     provided recipient ID + device ID tuple.

     - parameter address: The address of the remote client
     - returns: The session and optional user record, or nil on failure
     */
    func loadSession(for address: SignalAddress) -> (session: Data, userRecord: Data?)? {
        guard let session = sessions[address] else {
            return nil
        }
        return (session, records[address])
    }

    /**
     Returns all known devices with active sessions for a recipient
     - parameter name: The name of the remote client
     - returns: The ids of all active devices
     */
    func subDeviceSessions(for name: String) -> [Int32]? {
        return sessions.keys.filter({ $0.name == name }).map { $0.deviceId }
    }
    
    /**
     Commit to storage the session record for a given
     recipient ID + device ID tuple.

     - parameter session: The serialized session record
     - parameter userRecord: Application specific data to be stored alongside the serialized session record for the remote client. If no such data exists, then this parameter will be nil.
     - parameter address: The address of the remote client
     - returns: `true` on sucess, `false` on failure.
     */
    func store(session: Data, for address: SignalAddress, userRecord: Data?) -> Bool {
        sessions[address] = session
        records[address] = userRecord
        SecretChatDataStore.shared.updateRemoteSession(for: address, sessionRecord: session, userRecord: userRecord)
        return true
    }
    /**
     Determine whether there is a committed session record for a
     recipient ID

     - parameter name: The recipient id of the remote client
     - returns: `true` if a session record exists, `false` otherwise.
     */
    func hasSession(name:String) -> Bool {
        let address: [SignalAddress] = Array(self.sessions.keys)
        let userIds = address.compactMap({$0.name})
        return userIds.contains(name)
    }
    
    /**
     Determine whether there is a committed session record for a
     recipient ID + device ID tuple.

     - parameter address: The address of the remote client
     - returns: `true` if a session record exists, `false` otherwise.
     */
    func containsSession(for address: SignalAddress) -> Bool {
        return sessions[address] != nil
    }
    
    /**
     Remove a session record for a recipient ID + device ID tuple.

     - parameter address: The address of the remote client
     - returns: `true` if a session was deleted, `false` if a session was not deleted, nil on error
     */
    func deleteSession(for address: SignalAddress) -> Bool? {
        sessions[address] = nil
        records[address] = nil
        SecretChatDataStore.shared.removeSession(address: address)
        return true
    }
    
    /**
     Remove the session records corresponding to all devices of a recipient Id.

     - parameter name: The name of the remote client
     - returns: The number of deleted sessions on success, nil on failure
     */
    func deleteAllSessions(for name: String) -> Int? {
        let matches = sessions.keys.filter({ $0.name == name })
        for item in matches {
            sessions[item] = nil
            SecretChatDataStore.shared.removeSession(address: item)
        }
        return matches.count
    }
    
    /**
     Function called to perform cleanup when the data store context is being
     destroyed.
     */
    func destroy() {
        
    }
}


/**
 The `iZSSenderKeyStore`class is for providing the storage for sender keys.
 
 It's confiring to `SenderKeyStore` protocol.
 */

final class iZSSenderKeyStore: SenderKeyStore {

    
    var keys = [SignalSenderKeyName: Data]()

    /// Storage of additional user records.
    var records = [SignalSenderKeyName: Data]()

    /**
     Store a serialized sender key record for a given
     (groupId + senderId + deviceId) tuple.

     - parameter senderKey: The serialized record
     - parameter address: the (groupId + senderId + deviceId) tuple
     - parameter userRecord: Containing application specific
     data to be stored alongside the serialized record. If no such
     data exists, then this parameter will be nil.
     - returns: `true` on success, `false` on failure
     */
    func store(senderKey: Data, for address: SignalSenderKeyName, userRecord: Data?) -> Bool {
        keys[address] = senderKey
        records[address] = userRecord
        return true
    }
    /**
     Returns a copy of the sender key record corresponding to the
     (groupId + senderId + deviceId) tuple.

     - parameter address: the (groupId + senderId + deviceId) tuple
     - returns: The sender key and optional user record, or nil on failure
     */
    func loadSenderKey(for address: SignalSenderKeyName) -> (senderKey: Data, userRecord: Data?)? {
        guard let key = keys[address] else {
            return nil
        }
        return (key, records[address])
    }
}
