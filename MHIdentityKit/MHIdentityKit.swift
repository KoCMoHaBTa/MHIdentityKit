//
//  MHIdentityKit.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 4/11/17.
//  Copyright © 2017 Milen Halachev. All rights reserved.
//

import Foundation

public let bundleIdentifier = Bundle(for: OAuth2IdentityManager.self).bundleIdentifier!

extension Notification.Name {
    
    public static let AuthorizationGrantFlowWillAuthenticate = Notification.Name(rawValue: bundleIdentifier + ".notification.name." + "AuthorizationGrantFlowWillAuthenticate")
    public static let AuthorizationGrantFlowDidAuthenticate = Notification.Name(rawValue: bundleIdentifier + ".notification.name." + "AuthorizationGrantFlowDidAuthenticate")
    public static let AuthorizationGrantFlowDidFailToAuthenticate = Notification.Name(rawValue: bundleIdentifier + ".notification.name." + "AuthorizationGrantFlowDidFailToAuthenticate")
}

public let AccessTokenResponseUserInfoKey = bundleIdentifier + ".userInfo.key." + "accessTokenResponse"
public let ErrorUserInfoKey = bundleIdentifier + ".userInfo.key." + "error"
