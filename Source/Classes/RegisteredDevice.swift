//
//  RegisteredDevice.swift
//  iZSecretChat
//
//  Created by Senthil Kumar on 16/03/22.
//

import Foundation

/**
   `RegisteredDevice` holds information about current registered device details.
 It can be one of several types.
 */
public struct RegisteredDevice {
    /// Device id
    public let deviceId : Int32
    /// Registration id
    public let registrationId : Int
    /// Link time of registered device
    public let linkTime : Int64
    /// Identity key of registered device
    public var identityKey : String?
    
    /**
     Construct a `RegisteredDevice` .
     - parameter deviceId: Device id
     - parameter registrationId: Registration id
     - parameter linkTime: Link time of registered device
     - parameter linkTime: Identity key of registered device
     */
    init(deviceId:Int32,registrationId:Int,linkTime:Int64,identityKey:String?) {
        self.deviceId = deviceId
        self.registrationId = registrationId
        self.linkTime = linkTime
        self.identityKey = identityKey
    }
    /**
     Construct a `RegisteredDevice`  .
     - parameter list: Dictonary that holds data for registered device
     */
    init(_ list:[String:Any]) {
        self.deviceId =  list["device_id"] as? Int32 ?? 0
        self.registrationId =  list["registration_id"] as? Int ?? 0
        self.linkTime =  list["link_time"] as? Int64 ?? 0
        if let ident =  list["identity_key"] as? [String:Any] {
            self.identityKey = ident["pub"] as? String
        }
    }
}

