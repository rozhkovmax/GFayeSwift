//
//  GFayeClient+Helper.swift
//  Pods
//
//  Created by Shams Ahmed on 19/07/2016.
//
//  Updated by Cindy Wong on 2019-06-25.
//  Copyright (c) 2019 Cindy Wong.
//

import Foundation

public extension GFayeClient {

    // MARK: Helper

    ///  Validate whatever a subscription has been subscribed correctly
    func isSubscribedToChannel(_ channel: String) -> Bool {
        return self.openSubscriptions.contains { $0.subscription == channel }
    }

    ///  Validate faye transport is connected
    func isTransportConnected() -> Bool {
        return self.transport!.isConnected()
    }
}
