// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "GFayeSwift",
    products: [
        .library(name: "GFayeSwift", targets: ["GFayeSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
        .package(url: "https://github.com/daltoniam/Starscream.git", .upToNextMajor(from: "4.0.0")),
    ],
    targets: [
        .target(
            name: "GFayeSwift",
            dependencies: ["SwiftyJSON", "Starscream"]),
    ]
)

