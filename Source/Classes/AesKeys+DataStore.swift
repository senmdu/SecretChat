//
//  SignalPreKeys+CoreDataClass.swift
//  iZSecretChat
//
//  Created by Senthil Kumar on 15/11/21.
//
//

import Foundation
import CoreData
import SignalProtocol

@objc(AesKeys)
fileprivate class AesKeys: NSManagedObject {

}

fileprivate extension AesKeys {

    @nonobjc class func fetchRequest() -> NSFetchRequest<AesKeys> {
        return NSFetchRequest<AesKeys>(entityName: "AesKeys")
    }

    @NSManaged var key: Data?
    @NSManaged var chatId: String?
    @NSManaged var messageId: String?

}

//MARK: - AesKeys SecretChatDataStore

extension SecretChatDataStore {

    internal func getAesKey(messageId:String,chid:String) -> Data? {
        let fetchRequest : NSFetchRequest<AesKeys> = AesKeys.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "chatId == %@ && messageId == %@",chid,messageId)
        do {
            let fetchedResults = try context.fetch(fetchRequest)
            return  fetchedResults.first?.key
        } catch {
            return nil
        }
    }
    internal func save(aes:Data,messageId:String,chid:String) {
        let fetchRequest : NSFetchRequest<AesKeys> = AesKeys.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "chatId == %@ && messageId == %@",chid,messageId)
        let fetchedResults = try? context.fetch(fetchRequest)
        var aesKeyRecord : AesKeys!
        if fetchedResults?.count ?? 0 > 0 {
            aesKeyRecord = fetchedResults?.first
        }else {
            aesKeyRecord = AesKeys(context: context)
        }
        aesKeyRecord.messageId = messageId
        aesKeyRecord.chatId = chid
        aesKeyRecord.key = aes
        do {
            try context.save()
        }catch {
            
        }
    }
    internal func removeAesKeys() {
        let fetchRequest : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "AesKeys")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {

        }
    }
}
