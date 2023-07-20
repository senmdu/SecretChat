//
//  SecretChatDataStore.swift
//  iZSecretChat
//
//  Created by Senthil Kumar on 28/10/21.
//

import CoreData
import SignalProtocol


/**
 This class is reponsible all data handling.
 Storing sessions and prekeys into local database.
 */
final public class SecretChatDataStore {

    internal static let shared = SecretChatDataStore()
    
    internal var localUser : LocalUser?
    
    private init() {}
    private var sharedContainer : URL?
    
    internal func intiate(sharedContainerUrl:URL? = nil, mainThread:Bool = true) {
        self.sharedContainer = sharedContainerUrl
        if mainThread {
            Helper.ZCDispatchOnMainThread {
                self.intiateProcess()
            }
        }else {
            intiateProcess()
        }
    }
    
   private func intiateProcess() {
        if let registration = try? iZSecretChat.generateKeys() {
            let preKeys = SecretChatDataStore.shared.getPreKeys()
            self.localUser = Helper.localUser(for: registration, prekeys: preKeys)
        }
        SecretSession.shared.estabilish()
    }

    internal func clearSession() {
        self.localUser = nil
        self.clearData()
    }
    private lazy var managedObjectModel: NSManagedObjectModel? = {
            // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let bundle =  Bundle(for: SecretChatDataStore.self)
        guard  let bundleUrl = bundle.url(forResource: "iZSecretChat", withExtension: "bundle") else {
            return nil
        }
        let modelBundle = Bundle(url: bundleUrl)
        guard let modelURL = modelBundle?.url(forResource: "SecretChat", withExtension: "momd") else {
            return nil
        }
        return NSManagedObjectModel(contentsOf: modelURL)
    }()
    
    internal var context : NSManagedObjectContext {
        self.persistentContainer.viewContext
    }
    
    internal func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        return context
    }
    
    private lazy var persistentContainer: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: "SecretChat", managedObjectModel: managedObjectModel!)
        if let sharedContainer = sharedContainer {
            let description = NSPersistentStoreDescription(url: sharedContainer.appendingPathComponent("SecretChat.sqlite"))
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            container.persistentStoreDescriptions = [description]
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        return container
    }()
    
    private func clearData() {
        let context = newBackgroundContext()
        let fetchRequestKeys : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "SignalPreKeys")
        let deleteRequestKeys = NSBatchDeleteRequest(fetchRequest: fetchRequestKeys)
        let fetchRequestSession : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "RemoteSessions")
        let deleteRequestSession = NSBatchDeleteRequest(fetchRequest: fetchRequestSession)
        let fetchRequestAes : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "AesKeys")
        let deleteAes = NSBatchDeleteRequest(fetchRequest: fetchRequestAes)
        context.perform {
            do {
                try context.execute(deleteRequestKeys)
                try context.execute(deleteRequestSession)
                try context.execute(deleteAes)
                try context.save()
            } catch {

            }
        }

    }
    
    private func saveContext () {
          let context = persistentContainer.viewContext
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
    }
    
}

