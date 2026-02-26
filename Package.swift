// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SkyTrack",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "SkyTrack",
            targets: ["SkyTrack"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SkyTrack",
            path: "SkyTrack"
        ),
        .testTarget(
            name: "SkyTrackTests",
            dependencies: ["SkyTrack"],
            path: "SkyTrackTests",
            resources: [
                .copy("Fixtures")
            ]
        ),
    ]
)
