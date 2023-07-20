//
//  Registration.swift
//  iZSecretChat
//
//  Created by Senthil Kumar on 17/03/22.
//

import Foundation
import SignalProtocol


/**
 `Registration` holds information about current user.
 It can be one of several types.
 */
public struct Registration {
    
    public var deviceID : Int32 {
        iZSecretChat.deviceID
    }
    public var userId : String? {
        iZSecretChat.userId
    }
    public init(identityKeyPair: KeyPair, registrationId: UInt32, signedPreKeyRecord: SessionSignedPreKey) {
        self.identityKeyPair = identityKeyPair
        self.registrationId = registrationId
        self.signedPreKeyRecord = signedPreKeyRecord
    }
    
    // Mark: - String values are BASE64
    public init(identityKeyPair: (publicKey:Data,privateKey:Data), registrationId: UInt32, signedPreKeyRecord: Data) throws {
        self.identityKeyPair =  KeyPair(publicKey: identityKeyPair.publicKey, privateKey: identityKeyPair.privateKey)
        self.registrationId = registrationId
        self.signedPreKeyRecord = try SessionSignedPreKey(from: signedPreKeyRecord)
    }
    
    let identityKeyPair : KeyPair
    let registrationId : UInt32
    let signedPreKeyRecord : SessionSignedPreKey
    
    
    public func identityKeyPrivateBase64() -> String {
        return identityKeyPair.privateKey.base64EncodedString()
    }
    
    public func identityKeyPublicBase64() -> String {
        return identityKeyPair.publicKey.base64EncodedString()
    }

    
    public func signedPreKeyRecordBase64() -> String? {
        return try? signedPreKeyRecord.data().base64EncodedString()
    }
    
    
    public  func signedPreKeyPublicKeyBase64() -> String {
        return signedPreKeyRecord.keyPair.publicKey.base64EncodedString()
    }
    
    public func signedPreKeyId() -> UInt32 {
        return signedPreKeyRecord.id
    }
    
    public func signedPreKeyRecordSignatureBase64() -> String {
        return signedPreKeyRecord.signature.base64EncodedString()
    }
}
