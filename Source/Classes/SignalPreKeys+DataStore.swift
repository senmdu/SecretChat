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

@objc(SignalPreKeys)
fileprivate class SignalPreKeys: NSManagedObject {

}

fileprivate extension SignalPreKeys {

    @nonobjc class func fetchRequest() -> NSFetchRequest<SignalPreKeys> {
        return NSFetchRequest<SignalPreKeys>(entityName: "SignalPreKeys")
    }

    @NSManaged var preKeyId: NSNumber?
    @NSManaged var key: Data?

}


//MARK: - SignalPreKeys SecretChatDataStore

extension SecretChatDataStore {

    internal func getPreKeys() -> [SessionPreKey] {
        let fetchRequest : NSFetchRequest<SignalPreKeys> = SignalPreKeys.fetchRequest()
        do {
            let fetchedResults = try context.fetch(fetchRequest)
            return  try fetchedResults.compactMap({$0.key != nil ? (try  SessionPreKey(from: $0.key!)) : nil})
        } catch {
            return []
        }
        
    }
    
    internal func getPreKeysCount() -> Int {
        let fetchRequest : NSFetchRequest<SignalPreKeys> = SignalPreKeys.fetchRequest()
        do {
            let count = try  context.count(for: fetchRequest)
            return  count
        } catch {
            return 0
        }
        
    }
    internal func save(preKey:SessionPreKey) {
        let fetchRequest : NSFetchRequest<SignalPreKeys> = SignalPreKeys.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "preKeyId == \(preKey.id)")
        let fetchedResults = try? context.fetch(fetchRequest)
        var preKeyRecord : SignalPreKeys!
        if fetchedResults?.count ?? 0 > 0 {
            preKeyRecord = fetchedResults?.first
        }else {
            preKeyRecord = SignalPreKeys(context: context)
        }
        preKeyRecord.preKeyId = NSNumber(value: preKey.id)
        do {
            preKeyRecord.key = try preKey.data()
            try context.save()
        }catch {
            
        }
    }
    internal func removePreKeys() {
        let fetchRequest : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "SignalPreKeys")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {

        }
    }
    
}
