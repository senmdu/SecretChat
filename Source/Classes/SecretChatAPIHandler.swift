//
//  SecretChat.swift
//  iZSecretChat
//
//  Created by Senthil Kumar on 08/11/21.
//

import Foundation
import SignalProtocol

/**
 `SecretChatAPIHandlerDelegate` must be adopted to handle network calls
 */
public protocol SecretChatAPIHandlerDelegate  : AnyObject {
    func sessionHandling(url:String,params: [String:Any],_ block: SecretChatCompletion?)
    func sessionAdded(userId:String,deviceId:Int32)
    func addLog(error:String) 
}

/**
 `SecretChatAPIHandler` is a network handler.
 This class is reponsible for all network handling.
 */
public class SecretChatAPIHandler {
    
    public static let requestBundleUrl      = "api/v2/keys/requestbundle"
    public static let registerUrl           = "api/v2/keys/register"
    public static let keysUrl               = "api/v2/keys"
    public static let deregisterUrl         = "api/v2/keys/deregister"
    public static let registeredDevicesUrl  = "api/v2/keys/registrations"
    public static let syncSessionUrl        = "api/v2/keys/sync"
    
    let dispatchQueue = DispatchQueue(label: "secretQueue", qos: .background)
    internal weak var delegate : SecretChatAPIHandlerDelegate?
    
    private var preKeysSending =  false
    private var registrationProcess =  false
    
    internal init(_ delegate: SecretChatAPIHandlerDelegate) {
        self.delegate = delegate
    }
    internal init() {}
    
    public func sessionNotify(_ data: [String: Any]) {
        if data["event"] as? String == "KEY_SHORTAGE" {
            self.sendPreKeys()
        }
    }
    
    public func register(sendPrekeys:Bool, completion:@escaping ()->()) {
        guard self.registrationProcess == false && iZSecretChatHelper.didDeviceRegistered() == false else {return}
        if let user = SecretChatDataStore.shared.localUser, let params =  Helper.getRemoteParams(user: user.regisgration, preKey: false) {
            self.registrationProcess = true
            self.delegate?.sessionHandling(url: SecretChatAPIHandler.registerUrl, params: ["data":params], { data, response, error in
                self.registrationProcess = false
               // print(result)
                if response?.isSuccessResponse() == true {
                    self.delegate?.addLog(error: "secretchat registered sucessfully")
                    iZSecretChat.userDefault.set(true, forKey: kSecretChatDidRegistered)
                    iZSecretChat.userDefault.set(Date().timeIntervalSince1970, forKey: kSecretChatRegisteredTime)
                    iZSecretChat.userDefault.set(nil, forKey: kSecretChatDidMaxLinkedDevices)
                    if sendPrekeys {
                        self.sendPreKeys()
                    }
                }else if let dat = data , let result = String(data: dat, encoding: .utf8)?.jsonStringParse() as? [String:Any],  result["code"] as? String == "max_linked_devices" {
                    self.delegate?.addLog(error: "max linked devices")
                    iZSecretChat.userDefault.set(true, forKey: kSecretChatDidMaxLinkedDevices)
                        if sendPrekeys {
                            iZSecretChat.userDefault.set(true, forKey: kSecretChatDidSendPreKeys)
                        }
                }else {
                    if iZSecretChatHelper.didDeviceRegistered() == false {
                        self.delegate?.addLog(error: "secretchat registeration failed")
                        iZSecretChat.userDefault.set(true, forKey: kSecretChatDidRegistationFailed)
                        if sendPrekeys {
                            iZSecretChat.userDefault.set(true, forKey: kSecretChatDidSendPreKeys)
                        }
                    }
                }
                completion()
            })
        }
    }
    
    public func deRegister(deviceId:Int32,regId:Int, _ completion: (()->())?) {
        let params = ["registration_id":regId,"device_id":deviceId] as [String : Any]
        self.delegate?.sessionHandling(url: SecretChatAPIHandler.deregisterUrl, params: ["data":params], { data, response, error in
            completion?()
            if response?.isSuccessResponse() == true {
                print("deRegister success")
                iZSecretChat.userDefault.set(nil, forKey: kSecretChatDidRegistered)
                iZSecretChat.userDefault.set(nil, forKey: kSecretChatRegisteredTime)
            }else {
                self.delegate?.addLog(error: "deregister failed")
            }
        })
    }
    public func deRegisterCurrentDevice( _ completion: (()->())?) {
        guard let localUser = SecretChatDataStore.shared.localUser, iZSecretChatHelper.didDeviceRegistered() == true else {
            completion?()
            return
        }
        self.deRegister(deviceId: localUser.deviceID, regId: Int(localUser.registrationId), completion)
    }
    public func deRegisterAllDevices(_ list:[RegisteredDevice], exceptCurrentDevice:Bool = false, _ completion: @escaping ()->()) {
        for device in list {
            if let localUser = SecretChatDataStore.shared.localUser, exceptCurrentDevice == true,(device.deviceId == localUser.deviceID && device.registrationId == localUser.registrationId) {
                continue
            }
            self.deRegister(deviceId: device.deviceId, regId: device.registrationId, completion)
        }
    }
    
    public func syncRegisteredDevices() {
        dispatchQueue.async {
            self.delegate?.sessionHandling(url: SecretChatAPIHandler.syncSessionUrl, params: [:], { data, response, error in
                if response?.isSuccessResponse() == true {
                    iZSecretChat.userDefault.set(nil, forKey: kneedToSyncKeys)
                }else {
                    self.delegate?.addLog(error: "sync registered devices failed")
                }
            })
        }
    }
    public func sendPreKeys() {
        guard preKeysSending == false else {return}
        var params : [String:Any] = ["device_id":iZSecretChat.deviceID]
        let prekeys = Helper.generatePreKeys()
        guard prekeys.count > 0 else {
            return
        }
        let list = prekeys.map({["pub":$0.keyPair.publicKey.base64EncodedString(), "tag": Int($0.id)]})
        params["list"] = list
        self.preKeysSending = true
        Helper.savePreKeys(prekeys)
        self.delegate?.sessionHandling(url: SecretChatAPIHandler.keysUrl, params: params, { data, response, error in
            self.preKeysSending = false
            if response?.isSuccessResponse() == true {
                
            }else {
                self.delegate?.addLog(error: "send prekeys failed")
            }
        })
    }
    
    public func proccessBundle(_ items: [[String:Any]], completion:((Bool)->())?) {
        var didDevicesAdded = false
        Helper.ZCDispatchOnMainThread {
            for item in items {
                if let userId = item["user_id"] as? String {
                    if let user = Helper.createRemoteUser(userId: userId, data: item) {
                            if SecretSession.shared.add(remoteUser: user) {
                                didDevicesAdded = true
                                self.delegate?.sessionAdded(userId: user.userId, deviceId: user.protocolAddress.deviceId)
                            }
                    }else {
                        self.delegate?.addLog(error: "create remote user failed")
                    }
                }
            }
            completion?(didDevicesAdded)
        }
        
    }
    public func requestBundle(for recieptIDs:[String],excludeIDs:[String], block: @escaping SecretChatCompletion) {
        print("exclude devices: \(excludeIDs)")
        let params = ["recipients": recieptIDs,"exclude_devices":excludeIDs]
        self.delegate?.sessionHandling(url: SecretChatAPIHandler.requestBundleUrl, params: params, block)
    }
}
