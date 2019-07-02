# GFayeSwift

![swift](https://raw.githubusercontent.com/ckpwong/GFayeSwift/master/swift-logo.png)


A simple Swift client library for the [Faye](http://faye.jcoglan.com/) publish-subscribe messaging server. Faye is based on the Bayeux protocol and is compatible with CometD server.

GFayeSwift is implemented atop the [Starscream](https://github.com/daltoniam/starscream) Swift web socket library and will work on both Mac (pending Xcode 6 Swift update) and iPhone projects.

GFayeSwift is forked from [FayeSwift](https://github.com/hamin/FayeSwift) to support Swift 4.2.  Version 0.5.0 supports Swift 5.0.

FayeSwift  was heavily inspired by the Objective-C client found here: [FayeObjc](https://github.com/pcrawfor/FayeObjC)

___**Note**: For Swift 2.2 please use FayeSwift 0.2.0___

___**Note**: For Swift 3.2 please use FayeSwift 0.3.0___

## Example

### Installation

#### Cocoapods

GFayeSwift is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:     

```ruby
  pod "GFayeSwift"
```

#### Swift Package Manager

Add GFayeSwift to dependencies:

```swift
    dependencies: [
        .package(url: "https://github.com/ckpwong/GFayeSwift.git", from: "0.5.1"),
    ],
    targets: [
        .target(
            name: "My_Swift_Target",
            dependencies: [
                "GFayeSwift", 
            ]
        ),
    ]
```

### Initializing Client

You can open a connection to your Faye/Bayeux/CometD server. Note that `client` is probably best as a property, so your delegate can stick around. You can initiate a client with a subscription to a specific channel.

```swift
client = GFayeClient(aGFayeURLString: "ws://localhost:5222/faye", channel: "/cool")
client.delegate = self
client.connectToServer()
```

You can then also subscribe to additional channels either with block handlers like so:

```swift
let channelBlock:ChannelSubscriptionBlock = {(messageDict) -> Void in
  let text: AnyObject? = messageDict["text"]
  println("Here is the Block message: \(text)")
}
client.subscribeToChannel("/awesome", block: channelBlock)
```

or without them letting the delegate handle them like so:

```swift
self.client.subscribeToChannel("/delegates_still_rock")
```

After you are connected, there are some optional delegate methods that we can implement.

### connectedToServer

connectedToServer is called as soon as the client connects to the server.

```swift
func connectedToServer(client: GFayeClient) {
   println("Connected to server")
}
```

### connectionFailed

connectionFailed is called when a cleint fails to connect to server either initially or on a retry.

```swift
func connectionFailed(client: GFayeClient) {
   println("Failed to connect to server!")
}
```

### disconnectedFromServer

disconnectedFromServer is called as soon as the client is disconnected from the server.

```swift
func disconnectedFromServer(client: GFayeClient) {
   println("Disconnected from server")
}
```

### didSubscribeToChannel

didSubscribeToChannel is called when the subscribes to a channel.

```swift
func didSubscribeToChannel(client: GFayeClient, channel: String) {
   println("subscribed to channel \(channel)")
}
```

### didUnsubscribeFromChannel

didUnsubscribeFromChannel is called when the client unsubscribes to a channel.

```swift
func didUnsubscribeFromChannel(client: GFayeClient, channel: String) {
   println("Unsubscribed from channel \(channel)")
}
```

### subscriptionFailedWithError

The subscriptionFailedWithError method is called when the client fails to subscribe to a channel.

```swift
func subscriptionFailedWithError(client: GFayeClient, error: subscriptionError) {
   println("SUBSCRIPTION FAILED!!!!")
}
```

### messageReceived

The messageReceived is called when the client receives a message from any channel that it is subscribed to.	

```swift
func messageReceived(client: GFayeClient, messageDict: NSDictionary, channel: String) {
   let text: AnyObject? = messageDict["text"]
   println("Here is the message: \(text)")
   
   self.client.unsubscribeFromChannel(channel)
}
```

The delegate methods give you a simple way to handle data from the server, but how do you publish data to a channel?


### sendMessage

You can call sendMessage to send a dictionary object to a channel

```swift
client.sendMessage(["text": textField.text], channel: "/cool")
```

## Example Server

There is a sample Faye server using the NodeJS Faye library. If you have NodeJS installed just run the following commands to install the package:

```javascript
npm install
```

And then you can start the Faye server like so:

```javascript
node faye_server.js
```
## Example Project

Check out the GFayeSwiftDemo project to see how to setup a simple connection to a Faye server.

## Requirements

GFayeSwift requires at least iOS 8/OSX 10.10 or above.

## License

GFayeSwift is licensed under the MIT License.

## Libraries

* [Starscream](https://github.com/daltoniam/Starscream)
* [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)

