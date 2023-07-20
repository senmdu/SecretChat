//
//  AES256.swift
//  iZSecretChat
//
//  Created by Senthil Kumar on 11/02/22.
//

import Foundation
import CryptoSwift

//MARK: - AES Keys Encrypt
/**
 `AesKeysEncrypt` is a struct that holds encrypted key .
 It can be one of several types.
 */
public struct AesKeysEncrypt {
    /// Device Id
    public let deviceId : Int32
    /// Orginal key without encrypted
    public let orginalKey : Data
    /// Encrypted key
    public let encryptedKey : Data
    /// Orginal key base64
    public var orginalKeyBase64 : String {
        return orginalKey.base64EncodedString()
    }
    /// Encrypted key base64
    public var encryptedKeyBase64 : String {
        return encryptedKey.base64EncodedString()
    }
    /// User Remote Session
    public let remoteSession : RemoteSession
    /**
     Create a `AesKeysEncrypt`  with essential data .
     - parameter deviceId: Device id of user
     - parameter orginalKey: Orginal aes key without encrypted
     - parameter encryptedKey: Encrypted aes key
     - parameter remoteSession: Remote user session
     */
    public init(deviceId: Int32, orginalKey: Data, encryptedKey: Data, remoteSession: RemoteSession) {
        self.deviceId = deviceId
        self.orginalKey = orginalKey
        self.encryptedKey = encryptedKey
        self.remoteSession = remoteSession
    }
}

//MARK: - AES Encryption
/**
 A `AESEncrypt` is a class that ready for encrypt the message.
 It can be one of several types.
 */
public class AESEncrypt {
    /// The aesKey Data
    public let aesKey : Data
    /**
     Construct a AESEncrypt  aesKey .
     - parameter aesKey: Data of aesKey
     */
    public init(aesKey:Data) {
        self.aesKey = aesKey
    }
    /**
     Encrypt a message from given data Using AES-256 GCM method.
     - note: Possible errors are:
     -  gcm encryption failed due to different block or iV.
     - parameter message: The string of the message to encrypt.
     - returns: `AESEncryptedMessage` on  success, nil on failure
     */
   public func perform(message:String) -> AESEncryptedMessage? {
        guard let messageData = message.data(using: .utf8) else {
            return nil
        }
        return self.perform(message: messageData)
    }
    /**
     Encrypt a message from given data Using AES-256 GCM method.
     - note: Possible errors are:
     -  gcm encryption failed due to different block or iV.
     - parameter message: The data of the message to encrypt.
     - returns: `AESEncryptedMessage` on  success, nil on failure
     */
    public func perform(file messageData:Data, aesIv:[UInt8]? = nil) -> AESEncryptedFile? {
        var randomIv = aesIv
        if randomIv == nil {
            randomIv  = AES.randomIV(AES256Crypter.ivSize)
        }
        do {
            let aesEncrypt = try AES256Crypter(key: aesKey.bytes, iv: randomIv!)
            if let mess =  aesEncrypt.gcmEncrypt(data: messageData) {
                var encryptedMessage = AESEncryptedFile(data: mess, aesKey: aesKey)
                encryptedMessage.randomIV = randomIv?.toBase64()
                return encryptedMessage
            }
        } catch  {
            iZSecretChat.apiHandler.delegate?.addLog(error: "Failed to encrypt aes file: \(error)")
        }
        return nil
    }
    public func perform(largeFile file:URL) -> AESEncryptedFile? {
        let randomIv = AES.randomIV(AES256Crypter.ivSize)
        do {
            let gcm = GCM(iv: randomIv, mode: .combined)
            if let enCryptedFile = try SecretChatFileHandler.crypt(gcm: gcm, fileUrl: file, aes: self.aesKey,action: .encrypt) {
                var encryptedFile = AESEncryptedFile(file: enCryptedFile, aesKey: aesKey)
                encryptedFile.randomIV = randomIv.toBase64()
                return encryptedFile
            }else {
                iZSecretChat.apiHandler.delegate?.addLog(error: "Failed to encrypt large file: file url nil")
            }
        } catch  {
            iZSecretChat.apiHandler.delegate?.addLog(error: "Failed to encrypt aes file: \(error)")
        }
        return nil
    }
    public func perform(message messageData:Data) -> AESEncryptedMessage? {
        let randomIv = AES.randomIV(AES256Crypter.ivSize)
        let base64IV = randomIv.toBase64()
        do {
            let aesEncrypt = try AES256Crypter(key: aesKey.bytes, iv: randomIv)
            if let encryptedMessage =  aesEncrypt.gcmEncrypt(data: messageData) {
                let message =  base64IV+"$"+(encryptedMessage.base64EncodedString())
                return AESEncryptedMessage(message: message, aesKey: aesKey)
            }
        } catch  {
            iZSecretChat.apiHandler.delegate?.addLog(error: "Failed to encrypt aes message: \(error)")
        }
        return nil
    }
}

/**
 A `AESEncryptedMessage` is an AES encrypted message ready for delivery.
 It can be one of several types.
 */

public struct AESEncryptedFile {
    
    /// Random IV  String
    public var randomIV : String?
    /// The datafile
    public var data : Data?
    
    /// The file
    public var file : URL?
    /// The aesKey
    public let aesKey : Data
    /// The aesKey Base64 string
    public var aesKeyBase64 : String {
        aesKey.base64EncodedString()
    }
    public var dataBase64 : String? {
        data?.base64EncodedString()
    }
    /**
     Create a AESEncryptedMessage  type from a message String and aesKey Data .
     - parameter message: Message
     - parameter aesKey: aesKey
     */
    public init(data:Data,aesKey:Data) {
        self.aesKey = aesKey
        self.data = data
    }
    public init(file:URL,aesKey:Data) {
        self.aesKey = aesKey
        self.file = file
    }
    
    /**
     Decrypt a message from a serialized AES encrypted message.
     - note: Possible errors are:
     -  gcm decryption failed due to different encrypted format
     - parameter message: The data of the message to decrypt, It should be AES-256 GCM Encrypted message
     - returns: The decrypted data on  success, nil on failure
     */
    public func decrypt() -> Data? {
        guard var messageData = self.data else {
            iZSecretChat.apiHandler.delegate?.addLog(error: "Failed to decrypt aes data file: data nil")
            return nil
        }
        let userAes = self.aesKey
        var iv : Data?
        if let random = randomIV, let randomIV = Data(base64Encoded: random) {
            iv = randomIV
        }else {
            let messageStr = String(data: messageData, encoding: .utf8)
            if let messageIv =  messageStr?.components(separatedBy: "$"),let Iv64 = messageIv.first {
                iv = Data(base64Encoded: Iv64)
                if let messageBase64 = messageIv.last, let mess =  Data(base64Encoded: messageBase64) {
                    messageData = mess
                }
            }
        }
        if let Iv = iv {
            do {
                let aes = try AES256Crypter(key: userAes.bytes, iv: Iv.bytes)
                if let decryptedData =  aes.gcmDecrypt(data: messageData) {
                    return decryptedData
                }
            } catch {
                iZSecretChat.apiHandler.delegate?.addLog(error: "Failed to decrypt aes data: \(error)")
                return nil
            }
        }else {
            iZSecretChat.apiHandler.delegate?.addLog(error: "Failed to decrypt aes data file: iv nil")
        }
        return nil
    }
    
    public func decryptFile() -> URL? {
        guard let file = self.file,let random = self.randomIV, let randomIV = Data(base64Encoded: random)?.bytes  else {
            iZSecretChat.apiHandler.delegate?.addLog(error: "Failed to decrypt aes large file iv not found")
            return nil
        }
        do {
            let gcm = GCM(iv: randomIV, mode: .combined)
            if let deCryptedFile =  try SecretChatFileHandler.crypt(gcm: gcm, fileUrl: file, aes: self.aesKey,action: .decrypt) {
                return deCryptedFile
            }else {
                iZSecretChat.apiHandler.delegate?.addLog(error: "Failed to decrypt aes large file: file url nil")
                return nil
            }
        } catch {
            iZSecretChat.apiHandler.delegate?.addLog(error: "Failed to decrypt aes file: \(error)")
            return nil
        }
    }
}

public struct AESEncryptedMessage {
    
    /// The message
    public let message : String
    /// The aesKey
    public let aesKey : Data
    /// The aesKey Base64 string
    public var aesKeyBase64 : String {
        aesKey.base64EncodedString()
    }
    /**
     Create a AESEncryptedMessage  type from a message String and aesKey Data .
     - parameter message: Message
     - parameter aesKey: aesKey
     */
    public init(message:String,aesKey:Data) {
        self.message = message
        self.aesKey = aesKey
    }
    
    /**
     Decrypt a message from a serialized AES encrypted message.
     - note: Possible errors are:
     -  gcm decryption failed due to different encrypted format
     - parameter message: The data of the message to decrypt, It should be AES-256 GCM Encrypted message
     - returns: The decrypted data on  success, nil on failure
     */
    public func decrypt() -> Data? {
        let userAes = self.aesKey
        let messageIv =  self.message.components(separatedBy: "$")
        if let Iv64 = messageIv.first, let Iv = Data(base64Encoded: Iv64), let messageBase64 = messageIv.last, let mess = Data(base64Encoded: messageBase64) {
            do {
                let aes = try AES256Crypter(key: userAes.bytes, iv: Iv.bytes)
                if let decryptedData =  aes.gcmDecrypt(data: mess) {
                    return decryptedData
                }
            } catch {
                iZSecretChat.apiHandler.delegate?.addLog(error: "Failed to decrypt aes message: \(error)")
                return nil
            }
        }
        return nil
    }
}
