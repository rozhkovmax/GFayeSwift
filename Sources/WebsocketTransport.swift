//
//  WebsocketTransport.swift
//  Pods
//
//  Created by Haris Amin on 2/20/16.
//
//  Updated by Cindy Wong on 2019-06-25.
//  Copyright (c) 2019 Cindy Wong.
//

import Foundation
import Starscream

internal class WebsocketTransport: Transport, WebSocketDelegate, WebSocketPongDelegate {
        
  var urlString:String
  var webSocket:WebSocket?
  var headers: [String: String]? = nil
  internal weak var delegate:TransportDelegate?
  
  required internal init(url: String) {
    self.urlString = url
  }
  
  func openConnection() {
    self.closeConnection()
    self.webSocket = WebSocket(url: URL(string:self.urlString)!)
    
    if let webSocket = self.webSocket {
      webSocket.delegate = self
      webSocket.pongDelegate = self
      if let headers = self.headers {
        for (key, value) in headers {
          webSocket.request.addValue(value, forHTTPHeaderField: key)
        }
      }
      webSocket.connect()

      print("Faye: Opening connection with \(self.urlString)")
    }
  }
  
  func closeConnection() {
    if let webSocket = self.webSocket {
      print("Faye: Closing connection")
        
      webSocket.delegate = nil
      webSocket.disconnect(forceTimeout: 0)
      
      self.webSocket = nil
    }
  }
  
  func writeString(_ aString:String) {
    self.webSocket?.write(string: aString)
  }
  
  func sendPing(_ data: Data, completion: (() -> ())? = nil) {
    self.webSocket?.write(ping: data, completion: completion)
  }
  
  func isConnected() -> (Bool) {
    return self.webSocket?.isConnected ?? false
  }
  
  // MARK: Websocket Delegate
    internal func websocketDidConnect(socket: WebSocketClient) {
    self.delegate?.didConnect()
  }
  
    internal func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
    if error == nil {
      self.delegate?.didDisconnect(GFayeSocketError.lostConnection)
    } else {
        self.delegate?.didFailConnection(error)
    }
  }
  
  internal func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
    self.delegate?.didReceiveMessage(text)
  }
  
  // MARK: TODO
  internal func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
    print("Faye: Received data: \(data.count)")
    //self.socket.writeData(data)
  }

  // MARK: WebSocket Pong Delegate
  internal func websocketDidReceivePong(_ socket: WebSocket) {
    self.delegate?.didReceivePong()
  }
    
  internal func websocketDidReceivePong(socket: WebSocketClient, data: Data?) {
    self.delegate?.didReceivePong()
  }
}
