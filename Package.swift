// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SideMirror",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "SideMirror",
            path: "Sources/SideMirror",
            resources: [.process("Resources")]
        )
    ]
)
