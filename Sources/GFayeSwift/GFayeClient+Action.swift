//
//  GFayeClient+Action.swift
//  Pods
//
//  Created by Shams Ahmed on 19/07/2016.
//
//  Updated by Cindy Wong on 2019-06-25.
//  Copyright (c) 2019 Cindy Wong.
//

import Foundation

extension GFayeClient {
    
    // MARK: Private - Timer Action
    @objc
    func pendingSubscriptionsAction(_ timer: Timer) {
        guard gFayeConnected == true else {
            print("GFaye: Failed to resubscribe to all pending channels, socket disconnected")
            
            return
        }
        
        resubscribeToPendingSubscriptions()
    }
}
