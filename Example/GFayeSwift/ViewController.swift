//
//  ViewController.swift
//  FayeSwift
//
//  Created by Haris Amin on 01/25/2016.
//  Copyright (c) 2016 Haris Amin. All rights reserved.
//
//  Updated by Cindy Wong on 2019-06-25.
//  Copyright (c) 2019 Cindy Wong.
//

import UIKit
import GFayeSwift

class ViewController: UIViewController, UITextFieldDelegate, GFayeClientDelegate {

  @IBOutlet weak var textField: UITextField!
  @IBOutlet weak var textView: UITextView!
  
  /// Example GFayeClient
    let client:GFayeClient = GFayeClient(aGFayeURLString: "ws://localhost:5222/faye")

  // MARK:
  // MARK: Lifecycle
    
  override func viewDidLoad() {
    super.viewDidLoad()
    
    client.delegate = self;
    client.transportHeaders = ["X-Custom-Header": "Custom Value"]
    client.connectToServer()
    
    let channelBlock:ChannelSubscriptionBlock = {(messageDict) -> Void in
      if let text = messageDict["text"] {
        print("Here is the Block message: \(text)")
      }
    }
    _ = client.subscribeToChannel("/cool", block: channelBlock)
    _ = client.subscribeToChannel("/awesome", block: channelBlock)
    
    let delayTime = DispatchTime.now() + Double(Int64(5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    DispatchQueue.main.asyncAfter(deadline: delayTime) {
      self.client.unsubscribeFromChannel("/awesome")
    }
    
    DispatchQueue.main.asyncAfter(deadline: delayTime) {
      let model = GFayeSubscriptionModel(subscription: "/awesome", clientId: nil)
        
      _ = self.client.subscribeToChannel(model, block: { [unowned self] messages in
        print("awesome response: \(messages)")
        
        self.client.sendPing("Ping".data(using: String.Encoding.utf8)!, completion: {
          print("got pong")
        })
      })
    }
  }
    
  // MARK:
  // MARK: TextfieldDelegate

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    client.sendMessage(["text" : textField.text!], channel: "/cool")
    textView.text.append("[me] \(textField.text!)\n")
    return false;
  }
    
  // MARK:
  // MARK: GFayeClientDelegate
  
  func connectedtoser(_ client: GFayeClient) {
    print("Connected to Faye server")
  }
  
  func connectionFailed(_ client: GFayeClient) {
    print("Failed to connect to Faye server!")
  }
  
  func disconnectedFromServer(_ client: GFayeClient) {
    print("Disconnected from Faye server")
  }
  
  func didSubscribeToChannel(_ client: GFayeClient, channel: String) {
    print("Subscribed to channel \(channel)")
  }
  
  func didUnsubscribeFromChannel(_ client: GFayeClient, channel: String) {
    print("Unsubscribed from channel \(channel)")
  }
  
  func subscriptionFailedWithError(_ client: GFayeClient, error: SubscriptionError) {
    print("Subscription failed")
  }
  
  func messageReceived(_ client: GFayeClient, messageDict: GFayeMessage, channel: String) {
    print("Message received: \(messageDict)")
    if let text = messageDict["text"] {
      print("Here is the message: \(text)")
        self.textView.text.append("\(channel): \(text)\n")
    }
  }
  
  func pongReceived(_ client: GFayeClient) {
    print("pong")
  }
}
