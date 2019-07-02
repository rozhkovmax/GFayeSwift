//
//  NSError+Helper.swift
//  Pods
//
//  Created by Shams Ahmed on 17/02/2016.
//
//  Updated by Cindy Wong on 2019-06-25.
//  Copyright (c) 2019 Cindy Wong.
//

import Foundation

public enum GFayeSocketError: Int, Swift.Error {
    case lostConnection = 1001
    case transportWrite = 1002
}

extension GFayeSocketError: CustomNSError {
    
    /// return the error domain of GFayeSocketError
    public static var errorDomain: String { return "com.ckpwong.gfayeswift" }
    
    /// return the error code of GFayeSocketError
    public var errorCode: Int { return self.rawValue }
    
    /// return the userInfo of GFayeSocketError
    public var errorUserInfo: [String: Any] {
        switch self {
        case .lostConnection:
            return [NSLocalizedDescriptionKey: "Connection Lost."]
        case .transportWrite:
            return [NSLocalizedDescriptionKey: "Error writing to transport."]
        }
    }
}
