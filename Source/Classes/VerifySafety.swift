//
//  VerifySafety.swift
//  iZSecretChat
//
//  Created by Senthil Kumar on 10/03/22.
//

import Foundation
import SignalProtocol

/**
 `VerifySafety` can be used to compare identity keys across devices.
 A VerifySafety consists of a human readable string of numbers and
 a data that can be transmitted to another device (e.g. through a QR Code).
 */
public class VerifySafety {
    let remoteSession : [RemoteSession]
    var localIdentity : [Data]
    public var fingerPrint : Fingerprint?
    public init(localIdentity:[Data],remoteSessions:[RemoteSession]) {
        self.remoteSession =  remoteSessions
        self.localIdentity =  localIdentity
        self.loadVerify()
    }
    
    @discardableResult
    public func loadVerify() -> VerifySafety {
        if remoteSession.count > 0 && localIdentity.count > 0 {
            let remoteIdentifier = remoteSession[0].userId
            let remoteData = remoteSession.compactMap({$0.identityKey})
            if remoteData.count > 0 {
                do {
                    fingerPrint = try Fingerprint(iterations: 1024, localIdentifier: iZSecretChat.userId ?? "", localIdentityList: localIdentity, remoteIdentifier: remoteIdentifier, remoteIdentityList: remoteData)
                } catch {
                    print("error creating verify")
                }
            }
           
        }else {
            print("error creating verify")
        }
        return self
    }
    
    public func getVerificationDisplayText() -> String? {
        return self.fingerPrint?.displayable
    }
    public func getScanableCode() -> String? {
        if let code =  self.fingerPrint?.scannable.base64EncodedString() {
            return "secretChatVerifyCode=\(code)"
        }
        return nil
    }
    public func verify(code:String) -> Bool {
        if let encoded = Data(base64Encoded: code) {
            if (try? self.fingerPrint?.matches(scannable: encoded)) != nil {
                return true
            }
        }
        return false
    }
    
}
