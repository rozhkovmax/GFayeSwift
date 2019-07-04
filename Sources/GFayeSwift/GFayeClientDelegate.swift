//
//  GFayeClientDelegate.swift
//  Pods
//
//  Created by Haris Amin on 2/20/16.
//
//  Updated by Cindy Wong on 2019-06-25.
//  Copyright (c) 2019 Cindy Wong.
//

import Foundation

public enum SubscriptionError: Error {
    case error(subscription: String, error: String)
}

// MARK: GFayeClientDelegate Protocol
public protocol GFayeClientDelegate: NSObjectProtocol {
    func messageReceived(_ client: GFayeClient, messageDict: NSDictionary, channel: String)
    func pongReceived(_ client: GFayeClient)
    func connectedToServer(_ client: GFayeClient)
    func disconnectedFromServer(_ client: GFayeClient)
    func connectionFailed(_ client: GFayeClient)
    func didSubscribeToChannel(_ client: GFayeClient, channel: String)
    func didUnsubscribeFromChannel(_ client: GFayeClient, channel: String)
    func subscriptionFailedWithError(_ client: GFayeClient, error: SubscriptionError)
    func fayeClientError(_ client: GFayeClient, error: Error)
}

public extension GFayeClientDelegate {
    func messageReceived(_ client: GFayeClient, messageDict: NSDictionary, channel: String) {}
    func pongReceived(_ client: GFayeClient) {}
    func connectedToServer(_ client: GFayeClient) {}
    func disconnectedFromServer(_ client: GFayeClient) {}
    func connectionFailed(_ client: GFayeClient) {}
    func didSubscribeToChannel(_ client: GFayeClient, channel: String) {}
    func didUnsubscribeFromChannel(_ client: GFayeClient, channel: String) {}
    func subscriptionFailedWithError(_ client: GFayeClient, error: SubscriptionError) {}
    func fayeClientError(_ client: GFayeClient, error: Error) {}
}
