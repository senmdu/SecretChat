//
//  AES256Crypter.swift
//  iZSecretChat
//
//  Created by Senthil Kumar on 17/03/22.
//  Copyright © 2022 Zoho Corporation. All rights reserved.
//

import CryptoSwift
import Foundation
import CommonCrypto

/**
 `AES256Crypter` can be used for AES256  key generation.
 GCM Encryption and Decryption Can be done.
 */
public struct AES256Crypter {
    
    /// Internal randomly generated aes256 key
    private var key: Array<UInt8>
    /// Internal randomIv
    private var iv: Array<UInt8>
    
    /// Internal size for randomIv
    static internal var ivSize = 12
    
    /**
     Construct a `AES256Crypter`.
     - parameter key: Randomly generated aes256 key
     - parameter iv: randomIv
     - throws: Errors of type `AES256CrypterError`
     */
    public init(key: Array<UInt8>, iv: Array<UInt8>) throws {
        guard key.count == kCCKeySizeAES256 else {
            throw AES256CrypterError.badKeyLength
        }
        guard iv.count == AES256Crypter.ivSize else {
            throw AES256CrypterError.badInputVectorLength
        }
        self.key = key
        self.iv = iv
    }
    
    /**
     Errors thrown by the `AES256Crypter`.
     */
    enum AES256CrypterError: Swift.Error {
        /// Key generation failed
        case keyGeneration(status: Int)
        /// AES Crypto failed
        case cryptoFailed(status: CCCryptorStatus)
        /// Given inuput key have bad length
        case badKeyLength
        /// Given inuput vector have bad length
        case badInputVectorLength
    }
    
    /**
     Static method to Create  random  password.
     - parameter length: Password length
     - returns: randomly generated password by length
     */
    static func randomPassword(length: Int) -> Data? {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! }).data(using: .utf8)
    }
    
    /**
     Static method to Create  random  salt.
     - returns: randomly generated 8 char length salt
     */
    static func randomSalt() -> Data {
        let length = 8
        var data = Data(count: length)
        let status = data.withUnsafeMutableBytes { mutableBytes in
            SecRandomCopyBytes(kSecRandomDefault, length, mutableBytes)
        }
        assert(status == Int32(0))
        return data
    }
    
    /**
     Encrypt a message from given data Using AES-256 GCM method.
     - note: Possible errors are:
     -  gcm encryption failed due to different block or iV.
     - parameter message: The data of the message to encrypt.
     - returns: The encrypted data on  success, nil on failure
     */
    internal func gcmEncrypt(data:Data) -> Data? {
        do {
            let gcm = GCM(iv: iv, mode: .combined)
            let aes = try AES(key: key, blockMode: gcm, padding: .noPadding)
            let encrypted = try aes.encrypt(data.bytes)
            _ = gcm.authenticationTag
            return encrypted.data
        } catch  {
            iZSecretChat.apiHandler.delegate?.addLog(error: "gcm encryption failed: \(error)")
            return nil
        }
    }
    
    /**
     Decrypt a message from a serialized AES encrypted message.
     - note: Possible errors are:
     -  GCM decryption failed due to different encrypted format
     - parameter message: The data of the message to decrypt, It should be AES-256 GCM Encrypted message
     - returns: The decrypted data on  success, nil on failure
     */
    internal func gcmDecrypt(data:Data) -> Data? {
        do {
            let gcm = GCM(iv: iv, mode: .combined)
            let aes = try AES(key: key, blockMode: gcm, padding: .noPadding)
            return try aes.decrypt(data.bytes).data
        } catch {
            iZSecretChat.apiHandler.delegate?.addLog(error: "gcm decryption failed: \(error)")
            return nil
        }
    }
    /**
     Static method to Create key using password and salt
     - parameter password: Randomly generated password data
     - parameter salt: Salt data
     - returns: randomly generated AES-256 GCM Data
     - throws: AES256CrypterError
     */
    static func createKey(password: Data, salt: Data) throws -> Data {
        let length = kCCKeySizeAES256
        var status = Int32(0)
        var derivedBytes = [UInt8](repeating: 0, count: length)
        password.withUnsafeBytes { (passwordBytes: UnsafePointer<Int8>!) in
            salt.withUnsafeBytes { (saltBytes: UnsafePointer<UInt8>!) in
                status = CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2),                  // algorithm
                    passwordBytes,                                // password
                    password.count,                               // passwordLen
                    saltBytes,                                    // salt
                    salt.count,                                   // saltLen
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1),   // prf
                    10000,                                        // rounds
                    &derivedBytes,                                // derivedKey
                    length)                                       // derivedKeyLen
            }
        }
        guard status == 0 else {
            throw AES256CrypterError.keyGeneration(status: Int(status))
        }
        return Data(bytes: UnsafePointer<UInt8>(derivedBytes), count: length)
    }
    
    /**
     Static method to Generate AES 256 - GCM Key.

     - returns: randomly generated AES-256 GCM Data on  success, nil on failure
     */
    public static func  generateAes256() -> Data? {
        guard let password = AES256Crypter.randomPassword(length: 8) else {
            iZSecretChat.apiHandler.delegate?.addLog(error: "aes 256 generation failed: random password")
            return nil
        }
        do {
            return try AES256Crypter.createKey(password: password, salt: AES256Crypter.randomSalt())
        }catch {
            iZSecretChat.apiHandler.delegate?.addLog(error: "aes 256 generation failed: \(error)")
            return nil
        }
    }
    
}
