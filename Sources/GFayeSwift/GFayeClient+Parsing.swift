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

    fileprivate func parseSubscribeMessage(_ messageDict: JSON) {
        if let success = messageDict[Bayeux.successful.rawValue].int, success == 1 {
            if let subscription = messageDict[Bayeux.subscription.rawValue].string {
                _ = removeChannelFromPendingSubscriptions(subscription)

                self.openSubscriptions.append(
                    GFayeSubscriptionModel(subscription: subscription, clientId: gFayeClientId))
                self.delegate?.didSubscribeToChannel(self, channel: subscription)
            } else {
                print("Faye: Missing subscription for Subscribe")
            }
        } else {
            // Subscribe Failed
            if let error = messageDict[Bayeux.error.rawValue].string,
                let subscription = messageDict[Bayeux.subscription.rawValue].string {
                _ = removeChannelFromPendingSubscriptions(subscription)

                self.delegate?.subscriptionFailedWithError(
                    self,
                    error: SubscriptionError.error(subscription: subscription, error: error)
                )
            }
        }
    }

    fileprivate func parseUnsubscribeMessage(_ messageDict: JSON) {
        if let subscription = messageDict[Bayeux.subscription.rawValue].string {
            _ = removeChannelFromOpenSubscriptions(subscription)
            self.delegate?.didUnsubscribeFromChannel(self, channel: subscription)
        } else {
            print("Faye: Missing subscription for Unsubscribe")
        }
    }

    fileprivate func parseMetaChannelFayeMessage(
        _ metaChannel: BayeuxChannel,
        _ messageDict: JSON
    ) {
        switch metaChannel {
        case .handshake:
            parseHandshakeMessage(messageDict)
        case .connect:
            parseConnectMessage(messageDict)
        case .disconnect:
            parseDisconnectMessage(messageDict)
        case .subscribe:
            parseSubscribeMessage(messageDict)
        case .unsubscribe:
            parseUnsubscribeMessage(messageDict)
        }
    }

    fileprivate func parseClientChannelFayeMessage(_ channel: String, _ messageDict: JSON) {
        if self.isSubscribedToChannel(channel) {
            if messageDict[Bayeux.data.rawValue] != JSON.null {
                let data = messageDict[Bayeux.data.rawValue].dictionaryObject!
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
            } else if messageDict[Bayeux.successful.rawValue] != JSON.null {
                let successful = messageDict[Bayeux.successful.rawValue].boolValue
                if let id = messageDict[Bayeux.id.rawValue].string {
                    print("Faye: Message \(id) \(successful ? "successfully" : "failed to") sent to channel \(channel)")
                } else {
                    print("Faye: Message \(successful ? "successfully" : "failed to") sent to channel \(channel)")
                }
            } else {
                print("Faye: For some reason data is nil for channel: \(channel)")
            }
        } else {
            print("Faye: Weird channel that not been set to subscribed: \(channel)")
        }
    }

    func parseFayeMessage(_ messageJSON: JSON) {
        for (_, messageDict):(String, JSON) in messageJSON {
            if let channel = messageDict[Bayeux.channel.rawValue].string {

                // Handle Meta Channels
                if let metaChannel = BayeuxChannel(rawValue: channel) {
                    parseMetaChannelFayeMessage(metaChannel, messageDict)
                } else {
                    // Handle Client Channel
                    parseClientChannelFayeMessage(channel, messageDict)
                }
            } else {
                print("Faye: Missing channel for \(messageDict)")
            }
        }
    }
}
