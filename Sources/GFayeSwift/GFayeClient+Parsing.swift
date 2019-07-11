//
//  GFayeClient+Parsing.swift
//  Pods
//
//  Created by Shams Ahmed on 19/07/2016.
//
//  Updated by Cindy Wong on 2019-06-25.
//  Copyright (c) 2019 Cindy Wong.
//

import Foundation
import SwiftyJSON

extension GFayeClient {

    // MARK: 
    // MARK: Parsing

    fileprivate func parseHandshakeMessage(_ messageDict: JSON) {
        self.gFayeClientId = messageDict[Bayeux.clientId.rawValue].stringValue
        if messageDict[Bayeux.successful.rawValue].int == 1 {
            self.delegate?.connectedToServer(self)
            self.gFayeConnected = true
            self.connect()
            self.subscribeQueuedSubscriptions()
            _ = pendingSubscriptionSchedule.isValid
        } else {
            // OOPS
        }
    }

    fileprivate func parseConnectMessage(_ messageDict: JSON) {
        if messageDict[Bayeux.successful.rawValue].int == 1 {
            self.gFayeConnected = true
            self.connect()
        } else {
            // OOPS
        }
    }

    fileprivate func parseDisconnectMessage(_ messageDict: JSON) {
        if messageDict[Bayeux.successful.rawValue].int == 1 {
            self.gFayeConnected = false
            self.transport?.closeConnection()
            self.delegate?.disconnectedFromServer(self)
        } else {
            // OOPS
        }
    }

    fileprivate func parseSubscribeMessage(_ messageJSON: JSON) {
        if let success = messageJSON[0][Bayeux.successful.rawValue].int, success == 1 {
            if let subscription = messageJSON[0][Bayeux.subscription.rawValue].string {
                _ = removeChannelFromPendingSubscriptions(subscription)

                self.openSubscriptions.append(
                    GFayeSubscriptionModel(subscription: subscription, clientId: gFayeClientId))
                self.delegate?.didSubscribeToChannel(self, channel: subscription)
            } else {
                print("Faye: Missing subscription for Subscribe")
            }
        } else {
            // Subscribe Failed
            if let error = messageJSON[0][Bayeux.error.rawValue].string,
                let subscription = messageJSON[0][Bayeux.subscription.rawValue].string {
                _ = removeChannelFromPendingSubscriptions(subscription)

                self.delegate?.subscriptionFailedWithError(
                    self,
                    error: SubscriptionError.error(subscription: subscription, error: error)
                )
            }
        }
    }

    fileprivate func parseUnsubscribeMessage(_ messageJSON: JSON) {
        if let subscription = messageJSON[0][Bayeux.subscription.rawValue].string {
            _ = removeChannelFromOpenSubscriptions(subscription)
            self.delegate?.didUnsubscribeFromChannel(self, channel: subscription)
        } else {
            print("Faye: Missing subscription for Unsubscribe")
        }
    }

    fileprivate func parseMetaChannelFayeMessage(
        _ metaChannel: BayeuxChannel,
        _ messageDict: JSON,
        _ messageJSON: JSON
    ) {
        switch metaChannel {
        case .handshake:
            parseHandshakeMessage(messageDict)
        case .connect:
            parseConnectMessage(messageDict)
        case .disconnect:
            parseDisconnectMessage(messageDict)
        case .subscribe:
            parseSubscribeMessage(messageJSON)
        case .unsubscribe:
            parseUnsubscribeMessage(messageJSON)
        }
    }

    fileprivate func parseClientChannelFayeMessage(_ channel: String, _ messageJSON: JSON) {
        if self.isSubscribedToChannel(channel) {
            if messageJSON[0][Bayeux.data.rawValue] != JSON.null {
                let data = messageJSON[0][Bayeux.data.rawValue].dictionaryObject!
                if let channelBlock = self.channelSubscriptionBlocks[channel] {
                    channelBlock(data)
                } else {
                    print("Faye: Failed to get channel block for : \(channel)")
                }

                self.delegate?.messageReceived(
                    self,
                    messageDict: data,
                    channel: channel
                )
            } else {
                print("Faye: For some reason data is nil for channel: \(channel)")
            }
        } else {
            print("Faye: Weird channel that not been set to subscribed: \(channel)")
        }
    }

    func parseFayeMessage(_ messageJSON: JSON) {
        let messageDict = messageJSON[0]
        if let channel = messageDict[Bayeux.channel.rawValue].string {

            // Handle Meta Channels
            if let metaChannel = BayeuxChannel(rawValue: channel) {
                parseMetaChannelFayeMessage(metaChannel, messageDict, messageJSON)
            } else {
                // Handle Client Channel
                parseClientChannelFayeMessage(channel, messageJSON)
            }
        } else {
            print("Faye: Missing channel for \(messageDict)")
        }
    }
}
