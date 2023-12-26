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

internal class WebsocketTransport: Transport, WebSocketDelegate {
    
    var urlString: String
    var webSocket: WebSocket?
    var headers: [String: String]?
    internal weak var delegate: TransportDelegate?

    required internal init(url: String) {
        self.urlString = url
    }

    func openConnection() {
        self.closeConnection()
        
        if let url = URL(string: self.urlString) {
            let request = URLRequest(url: url)
            self.webSocket = WebSocket(request: request)
        } else {
            print("Faye: Error connection with \(self.urlString)")
        }

        if let webSocket = self.webSocket {
            webSocket.delegate = self
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
            webSocket.disconnect()

            self.webSocket = nil
        }
    }

    func writeString(_ aString: String) {
        self.webSocket?.write(string: aString)
    }

    func sendPing(_ data: Data, completion: (() -> Void)? = nil) {
        self.webSocket?.write(ping: data, completion: completion)
    }

    func isConnected() -> (Bool) {
        return ((self.webSocket?.connect()) != nil)
    }
    
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected(_):
            self.delegate?.didConnect()
        case .disconnected(_, _):
            self.delegate?.didDisconnect(GFayeSocketError.lostConnection)
        case .text(let text):
            self.delegate?.didReceiveMessage(text)
        case .pong(_):
            self.delegate?.didReceivePong()
        case .error(let error):
            self.delegate?.didFailConnection(error)
        default:
            return
        }
    }
}
