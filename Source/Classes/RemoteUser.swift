//
//  RemoteUser.swift
//  iZSecretChat
//
//  Created by Senthil Kumar on 03/11/21.
//

import SignalProtocol

/**
 `RemoteUser` holds information about remote user data.
 such as remote user signedPreKeyPublicKey, userId
 It can be one of several types.
 */
public struct RemoteUser {
    /**
       Constructing remote user.
     - parameter signedPreKeyId: Signed Pre key id of remote user
     - parameter signedPreKeyPublicKey: Public Signed Pre key of remote user
     - parameter signedPreKeySignature: Signed Pre key signature of remote user
     - parameter identityKeyPairPublicKey: Public identity key of remote user
     - parameter deviceId: Device Id of remote user
     - parameter registrationId: Registration Id of remote user
     - parameter userId: User Id of remote user
     */
    internal init(signedPreKeyId: UInt32, signedPreKeyPublicKey: Data, signedPreKeySignature: Data, identityKeyPairPublicKey: Data,deviceId : Int32,registrationId : UInt32,userId:String) {
        self.signedPreKeyId = signedPreKeyId
        self.signedPreKeyPublicKey = signedPreKeyPublicKey
        self.signedPreKeySignature = signedPreKeySignature
        self.identityKeyPairPublicKey = identityKeyPairPublicKey
        self.registrationId = registrationId
        self.userId = userId
        self.protocolAddress = SignalAddress(name: userId, deviceId: deviceId)
    }
    /**
       Adding pre key data of remote user .
     - parameter preKeyId: Pre key Id of remote user.
     - parameter preKeyPublicKey: One Time Public Pre key of remote user.
     */
    mutating func addPreKey(preKeyId: UInt32, preKeyPublicKey: Data) {
        self.preKeyId = preKeyId
        self.preKeyPublicKey = preKeyPublicKey
    }
    /// User Id of remote user
    public let userId : String
    /// Registration Id of remote user
    let registrationId : UInt32
    /// Pre key Id of remote user
    var preKeyId : UInt32?
    /// One Time Public Pre key of remote user
    var preKeyPublicKey : Data?
    /// Signed Pre key id of remote user
    let signedPreKeyId : UInt32
    /// Public Signed Pre key of remote user
    let signedPreKeyPublicKey : Data
    /// Signed Pre key signature of remote user
    let signedPreKeySignature :Data
    /// Public identity key of remote user
    let identityKeyPairPublicKey : Data
    /// `SignalAddress` of remote user
    let protocolAddress : SignalAddress
    
    /// Remote user unique  identifier.
    /// That is combine of userId + registrationId and deviceID.
    public var identifier : String {
        return "\(userId)_\(registrationId)_\(protocolAddress.deviceId)"
    }
}
