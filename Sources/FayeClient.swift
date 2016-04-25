//
//  FayeClient.swift
//  FayeSwift
//
//  Created by Haris Amin on 8/31/14.
//  Copyright (c) 2014 Haris Amin. All rights reserved.
//

import Foundation
import SwiftyJSON

// MARK: BayuexChannel Messages
public enum BayeuxChannel: String {
    case Handshake = "/meta/handshake"
    case Connect = "/meta/connect"
    case Disconnect = "/meta/disconnect"
    case Subscribe = "/meta/subscribe"
    case Unsubscibe = "/meta/unsubscribe"
}

// MARK: Bayuex Parameters
public enum Bayeux: String {
    case Channel = "channel"
    case Version = "version"
    case ClientId = "clientId"
    case ConnectionType = "connectionType"
    case Data = "data"
    case Subscription = "subscription"
    case Id = "id"
    case MinimumVersion = "minimumVersion"
    case SupportedConnectionTypes = "supportedConnectionTypes"
    case Successful = "successful"
    case Error = "error"

}

// MARK: Bayuex Connection Type
public enum BayeuxConnection: String {
    case LongPolling = "long-polling"
    case Callback = "callback-polling"
    case iFrame = "iframe"
    case WebSocket = "websocket"
}

// MARK: Type Aliases
public typealias ChannelSubscriptionBlock = (NSDictionary) -> Void


// MARK: FayeClient
public class FayeClient : TransportDelegate {
  public var fayeURLString:String
  public var fayeClientId:String?
  public weak var delegate:FayeClientDelegate?
  
  private var transport:WebsocketTransport?
  private var fayeConnected:Bool?
  
  private var connectionInitiated:Bool?
  private var messageNumber:UInt32 = 0

  private var queuedSubscriptions = Array<FayeSubscriptionModel>()
  private var pendingSubscriptions = Array<FayeSubscriptionModel>()
  private var openSubscriptions = Array<FayeSubscriptionModel>()

  private var channelSubscriptionBlocks = Dictionary<String,ChannelSubscriptionBlock>()

  public init(aFayeURLString:String, channel:String?) {
    self.fayeURLString = aFayeURLString
    self.fayeConnected = false;

    self.transport = WebsocketTransport(url: aFayeURLString)
    self.transport!.delegate = self;

    if let channel = channel {
      self.queuedSubscriptions.append(FayeSubscriptionModel(subscription: channel, clientId: fayeClientId))
    }
    
    self.connectionInitiated = false
  }

  public convenience init(aFayeURLString:String, channel:String, channelBlock:ChannelSubscriptionBlock) {
    self.init(aFayeURLString: aFayeURLString, channel: channel)
    self.channelSubscriptionBlocks[channel] = channelBlock;
  }

  public func connectToServer() {
    if self.connectionInitiated != true {
      self.transport?.openConnection()
      self.connectionInitiated = true;
    }
  }

  public func disconnectFromServer() {
    self.disconnect()
  }

  public func sendMessage(messageDict: NSDictionary, channel:String) {
    self.publish(messageDict as! Dictionary, channel: channel)
  }

  public func sendMessage(messageDict:[String:AnyObject], channel:String) {
    self.publish(messageDict, channel: channel)
  }

  public func subscribeToChannel(model:FayeSubscriptionModel, block:ChannelSubscriptionBlock?=nil) -> Bool {
    if self.isSubscribedToChannel(model.subscription) || self.pendingSubscriptions.contains({ $0 == model }) {
      return false
    }
    
    self.fayeConnected == true ? self.subscribe(model) : self.queuedSubscriptions.append(model)
    
    if let block = block {
      self.channelSubscriptionBlocks[model.subscription] = block;
    }
    
    return true
  }
    
  public func subscribeToChannel(channel:String, block:ChannelSubscriptionBlock?=nil) {
    subscribeToChannel(FayeSubscriptionModel(subscription: channel, clientId: fayeClientId), block: block)
  }
    
  public func unsubscribeFromChannel(channel:String) {
    removeChannelFromQueuedSubscriptions(channel)
    
    self.unsubscribe(channel)
    self.channelSubscriptionBlocks[channel] = nil;
    
    removeChannelFromOpenSubscriptions(channel)
    removeChannelFromPendingSubscriptions(channel)
  }

  public func isSubscribedToChannel(channel:String) -> (Bool) {
    return self.openSubscriptions.contains { $0.subscription == channel }
  }

  public func isTransportConnected() -> (Bool) {
    return self.transport!.isConnected()
  }
}


// MARK: Transport Delegate
extension FayeClient {
  public func didConnect() {
    self.connectionInitiated = false;
    self.handshake()
  }

  public func didDisconnect(error: NSError?) {
    self.delegate?.disconnectedFromServer(self)
    self.connectionInitiated = false
    self.fayeConnected = false
  }

  public func didFailConnection(error: NSError?) {
    self.delegate?.connectionFailed(self)
    self.connectionInitiated = false
    self.fayeConnected = false
  }

  public func didWriteError(error: NSError?) {
    self.delegate?.fayeClientError(self, error: error ?? NSError(error: .TransportWrite))
  }

  public func didReceiveMessage(text: String) {
    self.receive(text)
  }

}

// MARK: Private Bayuex Methods
private extension FayeClient {

  func parseFayeMessage(messageJSON:JSON) {
    let messageDict = messageJSON[0]
    if let channel = messageDict[Bayeux.Channel.rawValue].string {

      // Handle Meta Channels
      if let metaChannel = BayeuxChannel(rawValue: channel) {
        switch(metaChannel) {
        case .Handshake:
          self.fayeClientId = messageDict[Bayeux.ClientId.rawValue].stringValue
          if messageDict[Bayeux.Successful.rawValue].int == 1 {
            self.delegate?.connectedToServer(self)
            self.fayeConnected = true;
            self.connect()
            self.subscribeQueuedSubscriptions()

          } else {
            // OOPS
          }
        case .Connect:
          if messageDict[Bayeux.Successful.rawValue].int == 1 {
            self.fayeConnected = true;
            self.connect()
          } else {
            // OOPS
          }
        case .Disconnect:
          if messageDict[Bayeux.Successful.rawValue].int == 1 {
            self.fayeConnected = false;
            self.transport?.closeConnection()
            self.delegate?.disconnectedFromServer(self)
          } else {
            // OOPS
          }
        case .Subscribe:
          if let success = messageJSON[0][Bayeux.Successful.rawValue].int where success == 1 {
            if let subscription = messageJSON[0][Bayeux.Subscription.rawValue].string {
              removeChannelFromPendingSubscriptions(subscription)
              
              self.openSubscriptions.append(FayeSubscriptionModel(subscription: subscription, clientId: fayeClientId))
              self.delegate?.didSubscribeToChannel(self, channel: subscription)
            } else {
              print("Missing subscription for Subscribe")
            }
          } else {
            // Subscribe Failed
            if let error = messageJSON[0][Bayeux.Error.rawValue].string {
              self.delegate?.subscriptionFailedWithError(self, error: error)
            }
          }
        case .Unsubscibe:
          if let subscription = messageJSON[0][Bayeux.Subscription.rawValue].string {
            removeChannelFromOpenSubscriptions(subscription)
            self.delegate?.didUnsubscribeFromChannel(self, channel: subscription)
          } else {
            print("Missing subscription for Unsubscribe")
          }
        }
      } else {
        // Handle Client Channel
        if self.isSubscribedToChannel(channel) {
          if messageJSON[0][Bayeux.Data.rawValue] != JSON.null {
            let data: AnyObject = messageJSON[0][Bayeux.Data.rawValue].object
            if let channelBlock = self.channelSubscriptionBlocks[channel] {
              channelBlock(data as! NSDictionary)
            } else {
              self.delegate?.messageReceived(self, messageDict: data as! NSDictionary, channel: channel)
            }
          } else {
            print("For some reason data is nil, maybe double posting?!")
          }
        } else {
          print("weird channel")
        }
      }
    } else {
      print("Missing channel")
    }
  }

  /**
   Bayeux messages
   */

  // Bayeux Handshake
  // "channel": "/meta/handshake",
  // "version": "1.0",
  // "minimumVersion": "1.0beta",
  // "supportedConnectionTypes": ["long-polling", "callback-polling", "iframe", "websocket]
  func handshake() {
    let connTypes:NSArray = [BayeuxConnection.LongPolling.rawValue, BayeuxConnection.Callback.rawValue, BayeuxConnection.iFrame.rawValue, BayeuxConnection.WebSocket.rawValue]
    var dict = [String: AnyObject]()
    dict[Bayeux.Channel.rawValue] = BayeuxChannel.Handshake.rawValue
    dict[Bayeux.Version.rawValue] = "1.0"
    dict[Bayeux.MinimumVersion.rawValue] = "1.0beta"
    dict[Bayeux.SupportedConnectionTypes.rawValue] = connTypes

    if let string = JSON(dict).rawString() {
      self.transport?.writeString(string)
    }
  }

  // Bayeux Connect
  // "channel": "/meta/connect",
  // "clientId": "Un1q31d3nt1f13r",
  // "connectionType": "long-polling"
  func connect() {
    let dict:[String:AnyObject] = [Bayeux.Channel.rawValue: BayeuxChannel.Connect.rawValue, Bayeux.ClientId.rawValue: self.fayeClientId!, Bayeux.ConnectionType.rawValue: BayeuxConnection.WebSocket.rawValue]

    if let string = JSON(dict).rawString() {
      self.transport?.writeString(string)
    }
  }

  // Bayeux Disconnect
  // "channel": "/meta/disconnect",
  // "clientId": "Un1q31d3nt1f13r"
  func disconnect() {
    let dict:[String:AnyObject] = [Bayeux.Channel.rawValue: BayeuxChannel.Disconnect.rawValue, Bayeux.ClientId.rawValue: self.fayeClientId!, Bayeux.ConnectionType.rawValue: BayeuxConnection.WebSocket.rawValue]
    if let string = JSON(dict).rawString() {
      self.transport?.writeString(string)
    }
  }

  // Bayeux Subscribe
  // "channel": "/meta/subscribe",
  // "clientId": "Un1q31d3nt1f13r",
  // "subscription": "/foo/**"
  func subscribe(model:FayeSubscriptionModel) {
    do {
        let json = try model.jsonString()
        
        self.transport?.writeString(json)
        self.pendingSubscriptions.append(model)
    } catch FayeSubscriptionModelError.ConversationError {
        
    } catch FayeSubscriptionModelError.ClientIdNotValid where fayeClientId?.characters.count > 0 {
        model.clientId = fayeClientId
        subscribe(model)
    } catch {
        
    }
  }

  // Bayeux Unsubscribe
  // {
  // "channel": "/meta/unsubscribe",
  // "clientId": "Un1q31d3nt1f13r",
  // "subscription": "/foo/**"
  // }
  func unsubscribe(channel:String) {
    if let clientId = self.fayeClientId {
      let dict:[String:AnyObject] = [Bayeux.Channel.rawValue: BayeuxChannel.Unsubscibe.rawValue, Bayeux.ClientId.rawValue: clientId, Bayeux.Subscription.rawValue: channel]
      if let string = JSON(dict).rawString() {
        self.transport?.writeString(string)
      }
    }
  }

  // Bayeux Publish
  // {
  // "channel": "/some/channel",
  // "clientId": "Un1q31d3nt1f13r",
  // "data": "some application string or JSON encoded object",
  // "id": "some unique message id"
  // }
  func publish(data:[String:AnyObject], channel:String) {
    if self.fayeConnected == true {
      let dict:[String:AnyObject] = [Bayeux.Channel.rawValue: channel, Bayeux.ClientId.rawValue: self.fayeClientId!, Bayeux.Id.rawValue: self.nextMessageId(), Bayeux.Data.rawValue: data]

      if let string = JSON(dict).rawString() {
        print("THIS IS THE PUBSLISH STRING: \(string)")
        self.transport?.writeString(string)
      }
    } else {
      // Faye is not connected
    }
  }
}

// MARK: Private Internal methods
private extension FayeClient {
  func subscribeQueuedSubscriptions() {
    // if there are any outstanding open subscriptions resubscribe
    for channel in self.queuedSubscriptions {
      self.subscribe(channel)
      removeChannelFromQueuedSubscriptions(channel.subscription)
    }
  }

  func send(message: NSDictionary) {
    // Parse JSON
    if let string = JSON(message).rawString() {
      self.transport?.writeString(string)
    }
  }

  func receive(message: String) {
    // Parse JSON
    if let jsonData = message.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
      let json = JSON(data: jsonData)
      self.parseFayeMessage(json)
    }
  }

  func nextMessageId() -> String {
    self.messageNumber += 1
    if self.messageNumber >= UINT32_MAX {
      messageNumber = 0
    }
    return "\(self.messageNumber)".encodedString()
  }
    
  private func removeChannelFromQueuedSubscriptions(channel: String) {
    for (idx, element) in self.queuedSubscriptions.enumerate() where element.subscription == channel {
      self.queuedSubscriptions.removeAtIndex(idx)
    }
  }

  private func removeChannelFromPendingSubscriptions(channel: String) {
    for (idx, element) in self.pendingSubscriptions.enumerate() where element.subscription == channel {
      self.pendingSubscriptions.removeAtIndex(idx)
    }
  }

  private func removeChannelFromOpenSubscriptions(channel: String) {
    for (idx, element) in self.openSubscriptions.enumerate() where element.subscription == channel {
      self.openSubscriptions.removeAtIndex(idx)
    }
  }
}
