//
//  LocalUser.swift
//  iZSecretChat
//
//  Created by Senthil Kumar on 03/11/21.
//

import SignalProtocol

/**
 `LocalUser` struct holds information about current user such as userId, registrationId.
 This data is useful for secretchat encryption and decryption.
 It can be one of several types.
 */
public struct LocalUser {
    /// Current user Identity KeyPair
    public let identitykey : KeyPair
    /// Current user registration id
    public let registrationId : UInt32
//    /// Current user prekeys.
//    var preKeys : [SessionPreKey]
    /// Current user signed key
    var signedPreKey : SessionSignedPreKey
    /// Current user device id
    public var deviceID : Int32 {
        iZSecretChat.deviceID
    }
    /// Current user  id
    public var userId : String? {
        iZSecretChat.userId
    }
    /// Current user signal address that can be used to identify in session store.
    var address : SignalAddress {
        return SignalAddress(name: userId ?? "0", deviceId: deviceID)
    }
    /// Convert `LocalUser` user type to `Registration`
    var regisgration : Registration {
        Helper.registration(for: self)
    }
    /// Current user unique  identifier.
    /// That is combine of userId + registrationId and deviceID.
    public var identifier : String? {
        guard let usrID = userId else {return nil}
        return "\(usrID)_\(registrationId)_\(deviceID)"
    }
    /**
     Construct a `LocalUser` with information.
     - parameter identitykey: Current user Identity KeyPair
     - parameter registrationId: Current user registration id
     - parameter preKeys: Current user pre keys
     - parameter signedPreKey: Current user signedPreKey
     - throws: Errors of type `AES256CrypterError`
     */
    public init(identitykey: KeyPair,
                  registrationId: UInt32,
                  signedPreKey: SessionSignedPreKey
    ) {
        self.identitykey = identitykey
        self.registrationId = registrationId
        self.signedPreKey = signedPreKey
    }
    /**
     Construct a `LocalUser` with information.
     - parameter publicKey: Public key of current user identity key
     - parameter privateKey: Private key of current user identity key
     - parameter registrationId: Current user registration id
     - parameter preKeys: Pre keys of current user
     - parameter signedPreKey: Current user signedPreKey
     - throws: Errors of type `AES256CrypterError`
     */
    public init(publicKey: Data,
                privateKey: Data,
                  registrationId: UInt32,
                  signedPreKey: Data) throws {
        self.identitykey = KeyPair(publicKey: publicKey, privateKey: privateKey)
        self.registrationId = registrationId
        self.signedPreKey = try SessionSignedPreKey(from: signedPreKey)
    }
    
    /**
       Storing generated pre keys.
     - parameter preKey: `SessionPreKey`.
     */
//    mutating func add(preKey:SessionPreKey) {
//        if let index =  self.preKeys.firstIndex(where: {$0.id == preKey.id}) {
//            self.preKeys[index] = preKey
//        }else {
//            self.preKeys.append(preKey)
//        }
//    }
}
