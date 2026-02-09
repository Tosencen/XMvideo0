// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "XMvideo",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(
            name: "XMvideo",
            targets: ["XMvideo"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "XMvideo",
            dependencies: [],
            path: "XMvideo",
            exclude: ["Info.plist"],
            resources: []
        )
    ]
)
