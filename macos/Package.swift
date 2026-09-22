// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "NorthstarGuard",
    platforms: [.macOS(.v12)],
    products: [.executable(name: "northstar-guard", targets: ["NorthstarGuard"])],
    targets: [
        .executableTarget(name: "NorthstarGuard"),
        .testTarget(name: "NorthstarGuardTests", dependencies: ["NorthstarGuard"])
    ]
)
