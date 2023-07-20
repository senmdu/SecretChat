//
//  RemoteUsers+CoreDataClass.swift
//  iZSecretChat
//
//  Created by Senthil Kumar on 15/11/21.
//
//

import CoreData
import SignalProtocol

@objc(RemoteSessions)
fileprivate class RemoteSessions: NSManagedObject {

}

fileprivate extension RemoteSessions {

    @nonobjc class func fetchRequest() -> NSFetchRequest<RemoteSessions> {
        return NSFetchRequest<RemoteSessions>(entityName: "RemoteSessions")
    }
    @NSManaged var deviceId: Int32
    @NSManaged var userId: String?
    @NSManaged var session: Data?
    @NSManaged var userRecord: Data?
    @NSManaged var identityKey: Data?
    @NSManaged var registrationID : Int32
    
    func toRemoteUser() -> RemoteSession? {
        let remote = self
        let deviceId = remote.deviceId
        guard let userId = remote.userId else {
            print("no record")
            return nil
        }
        return  RemoteSession(deviceId: deviceId, registrationID: UInt32(remote.registrationID), userId: userId, sessionRecord: remote.session, userRecord: remote.userRecord, identityKey: remote.identityKey)
    }

}

//MARK: - RemoteSessions SecretChatDataStore

extension SecretChatDataStore {
    
    internal func create(remoteUser:RemoteUser) {
        let userID = remoteUser.userId
        let deviceId = remoteUser.protocolAddress.deviceId
        let registrationID = Int32(remoteUser.registrationId)
        let identityKeyPairPublicKey = remoteUser.identityKeyPairPublicKey
        let fetchRequest : NSFetchRequest<RemoteSessions> = RemoteSessions.fetchRequest()
        let predicate1 = NSPredicate(format: "deviceId == %i", deviceId)
        let predicate2 = NSPredicate(format: "userId == %@", userID)
        let predicate:NSPredicate  = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1,predicate2])
        fetchRequest.predicate = predicate
        do {
            let fetchedResults = try context.fetch(fetchRequest)
            var remoteRecord : RemoteSessions!
            if fetchedResults.count > 0 {
                remoteRecord = fetchedResults.first
            }else {
                remoteRecord = RemoteSessions(context: context)
            }
            remoteRecord.deviceId = deviceId
            remoteRecord.userId = userID
            remoteRecord.registrationID = registrationID
            remoteRecord.identityKey = identityKeyPairPublicKey
            try context.save()
        } catch let eror {
            print("unable to save: \(eror)")
        }
    }
    internal func updateRemoteSession(for address:SignalAddress,sessionRecord:Data,userRecord:Data?) {
        let userID = address.name
        let deviceId = address.deviceId
        let fetchRequest : NSFetchRequest<RemoteSessions> = RemoteSessions.fetchRequest()
        let predicate1 = NSPredicate(format: "deviceId == %i", deviceId)
        let predicate2 = NSPredicate(format: "userId == %@", userID)
        let predicate:NSPredicate  = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1,predicate2])
        fetchRequest.predicate = predicate
        do {
            let fetchedResults = try context.fetch(fetchRequest)
            var remoteRecord : RemoteSessions!
            if fetchedResults.count  > 0 {
                remoteRecord = fetchedResults.first
            }else {
                remoteRecord = RemoteSessions(context: context)
            }
            remoteRecord.deviceId = deviceId
            remoteRecord.userId = userID
            remoteRecord.session = sessionRecord
            remoteRecord.userRecord = userRecord
            try context.save()
        } catch {
            
        }
    }
    internal func getUserIdentifiers(userId: String) -> [String] {
        let fetchRequest : NSFetchRequest<RemoteSessions> = RemoteSessions.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %@", userId)
           do {
              let fetchedResults = try context.fetch(fetchRequest)
               return fetchedResults.compactMap({ remote in
                   return remote.toRemoteUser()?.identifier
               })
            } catch {
                return []
            }
    }
    internal func getRemoteSession(address:SignalAddress) -> RemoteSession? {
        var session : RemoteSession?
        let fetchRequest : NSFetchRequest<RemoteSessions> = RemoteSessions.fetchRequest()
        let predicate1 = NSPredicate(format: "deviceId == %i", address.deviceId)
        let predicate2 = NSPredicate(format: "userId == %@", address.name)
        let predicate:NSPredicate  = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1,predicate2])
        fetchRequest.predicate = predicate
        do {
                let fetchedResults = try context.fetch(fetchRequest)
                if fetchedResults.count > 0 {
                    session = fetchedResults[0].toRemoteUser()
                }
            } catch let err {
                 print("unable to get session:\(err)")
            }
        
        return session
    }
    
    internal func getRemoteSessions(for addresss: [SignalAddress]) -> [RemoteSession] {
        let fetchRequest : NSFetchRequest<RemoteSessions> = RemoteSessions.fetchRequest()
        let userIDs = addresss.compactMap({$0.name})
        let deviceIDs = addresss.compactMap({$0.deviceId})
        let predicate1 = NSPredicate(format: "userId IN %@", userIDs)
        let predicate2 = NSPredicate(format: "deviceId IN %@", deviceIDs)
        let predicate:NSPredicate  = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1,predicate2])
        fetchRequest.predicate = predicate
             do {
                 let fetchedResults = try context.fetch(fetchRequest)
                 return  fetchedResults.compactMap {$0.toRemoteUser()}
             } catch let error {
                 print(error)
                 return []
             }
     }
   internal func getRemoteSessions(userId: String, sessions: @escaping ([RemoteSession])->()){
        let context = newBackgroundContext()
        context.perform {
            let fetchRequest : NSFetchRequest<RemoteSessions> = RemoteSessions.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "userId == %@", userId)
                do {
                    let fetchedResults = try context.fetch(fetchRequest)
                    sessions(fetchedResults.compactMap {$0.toRemoteUser()})
                } catch {
                    sessions([])
                }
        }
   }
    internal func checkRemoteSession(userId: String) -> Bool {
         let fetchRequest : NSFetchRequest<RemoteSessions> = RemoteSessions.fetchRequest()
         fetchRequest.predicate = NSPredicate(format: "userId == %@", userId)
         fetchRequest.fetchLimit = 1
         do {
             let fetchedResults = try context.fetch(fetchRequest)
             return  fetchedResults.count > 0
         } catch let error {
             print(error)
             return false
         }
     }
   internal func getRemoteSessions(userId: [String]) -> [RemoteSession] {
        let fetchRequest : NSFetchRequest<RemoteSessions> = RemoteSessions.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId IN %@", userId)
            do {
                let fetchedResults = try context.fetch(fetchRequest)
                return  fetchedResults.compactMap {$0.toRemoteUser()}
            } catch let error {
                print(error)
                return []
            }
    }
    internal func getAllRemoteSessions() -> [RemoteSession] {
        let fetchRequest : NSFetchRequest<RemoteSessions> = RemoteSessions.fetchRequest()
        do {
            let fetchedResults = try context.fetch(fetchRequest)
            return fetchedResults.compactMap { $0.toRemoteUser() }
            } catch {
             
        }
        return []
    }
    internal func getRemoteSessions(_ sessions: @escaping ([RemoteSession])->()) {
        let context = newBackgroundContext()
        let fetchRequest : NSFetchRequest<RemoteSessions> = RemoteSessions.fetchRequest()
        context.perform {
            do {
                let fetchedResults = try context.fetch(fetchRequest)
                sessions(fetchedResults.compactMap { $0.toRemoteUser() })
                } catch {
                    sessions([])
                }
           }
    }
    internal func removeSession(address:SignalAddress) {
        let fetchRequest : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "RemoteSessions")
        let predicate1 = NSPredicate(format: "deviceId == %i", address.deviceId)
        let predicate2 = NSPredicate(format: "userId == %@", address.name)
        let predicate:NSPredicate  = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1,predicate2])
        fetchRequest.predicate = predicate
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {

        }
    }
    internal func removeSessions() {
        let fetchRequest : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "RemoteSessions")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {

        }
    }
    
}
