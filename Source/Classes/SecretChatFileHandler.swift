//
//  SecretChatFileHandler.swift
//  ZohoChat
//
//  Created by Senthil Kumar on 27/01/23.
//  Copyright © 2023 ZOHO. All rights reserved.
//

import Foundation
import CryptoSwift

public class LargeFileEncryptor {
    
    let aes : Data
    let randomIv : [UInt8]
    
    public var cryptor : Cryptor & Updatable
    
    public static func generateRandomIv() -> [UInt8] {
       return AES.randomIV(AES256Crypter.ivSize)
    }
    
    public init(aes: Data, randomIv: [UInt8], action:SecretChatFileHandlerAction = .encrypt) throws {
        self.aes = aes
        self.randomIv = randomIv
        let gcm = GCM(iv: randomIv, mode: .combined)
        let crypt =  try AES(key: aes.bytes, blockMode: gcm, padding: .noPadding)
        if action == .encrypt {
            cryptor = try crypt.makeEncryptor()
        }else {
            cryptor = try crypt.makeDecryptor()
        }
    }
    
    public func updateCrypt(withBytes bytes: ArraySlice<UInt8>) throws  -> Array<UInt8>  {
        try cryptor.update(withBytes: bytes)
    }
//    
    public func finish() throws -> Array<UInt8> {
        try cryptor.finish()
    }
    
    
}
public enum SecretChatFileHandlerAction {
    case encrypt
    case decrypt
}

struct SecretChatFileHandler {
    
    static let fileSplitSizeMB = 50
    
    static func createPath(_ fileUrl: URL, action:SecretChatFileHandlerAction)  -> String {
        let filePath = fileUrl.path
        let path = (filePath as NSString).deletingLastPathComponent
        return "\(path)/\( action == .decrypt ? "decrypted" : "encrypted")_\((filePath as NSString).lastPathComponent)"
    }
    
    static func crypt(gcm:GCM,fileUrl:URL,aes:Data,action:SecretChatFileHandlerAction) throws -> URL?  {
        var chunkSize : Int = fileSplitSizeMB * 1024 * 1024
        
        let fileSize = fileUrl.fileSize()
        if fileSize <= chunkSize {
            chunkSize = fileSize / 2
        }
        
        let file = try FileHandle(forReadingFrom: fileUrl)
        let cryptedfilePath = createPath(fileUrl, action: action)
        var cryptor : Cryptor & Updatable
        if action == .encrypt {
            cryptor =  try AES(key: aes.bytes, blockMode: gcm, padding: .noPadding).makeEncryptor()
        }else {
            cryptor =  try AES(key: aes.bytes, blockMode: gcm, padding: .noPadding).makeDecryptor()
        }
        var cryptedUrl : URL?
        var cryptedFile : FileHandle?
        file.seekToEndOfFile()
        let length = Int(file.offsetInFile)
     //   print("file lenght: \(length)")
        var offset = 0
        repeat {
          try autoreleasepool {
                let thisChunkSize = ((length - offset) > chunkSize) ? chunkSize : (length - offset);
                file.seek(toFileOffset: UInt64(offset))
                let chunk = file.readData(ofLength: thisChunkSize).bytes
                print(chunk.count / (1024 * 1024))
                let cryptedData = try cryptor.update(withBytes: chunk).data
                if cryptedFile == nil {
                        if (FileManager.default.createFile(atPath: cryptedfilePath, contents: cryptedData)) {
                            let fle =  URL(fileURLWithPath: cryptedfilePath)
                            cryptedFile =  try FileHandle(forWritingTo: fle)
                            cryptedFile!.seekToEndOfFile()
                            cryptedUrl = fle
                        }
                }else {
                        if cryptedFile != nil {
                            cryptedFile!.seekToEndOfFile()
                            cryptedFile!.write(cryptedData)
                        }
                }
                offset += thisChunkSize;
            }
        } while (offset < length);
        let finaldata = try cryptor.finish()
        cryptedFile?.write(finaldata.data)
        return cryptedUrl
    }
    
}
