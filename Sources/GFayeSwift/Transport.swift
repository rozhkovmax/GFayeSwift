//
//  Transport.swift
//  Pods
//
//  Created by Haris Amin on 2/20/16.
//
//  Updated by Cindy Wong on 2019-06-25.
//  Copyright (c) 2019 Cindy Wong.
//

public protocol Transport {
    func writeString(_ aString: String)
    func openConnection()
    func closeConnection()
    func isConnected() -> (Bool)
}

public protocol TransportDelegate: class {
    func didConnect()
    func didFailConnection(_ error: Error?)
    func didDisconnect(_ error: Error?)
    func didWriteError(_ error: Error?)
    func didReceiveMessage(_ text: String)
    func didReceivePong()
}
