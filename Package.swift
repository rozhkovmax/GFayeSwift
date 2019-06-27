import PackageDescription

let package = Package(
    name: "FayeSwift",
    targets: [],
    dependencies: [
        .Package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", versions: "4.2.0" ..< Version.max),
		.Package(url: "https://github.com/daltoniam/Starscream.git", versions: "3.0.0" ..< Version.max)
    ]
)
