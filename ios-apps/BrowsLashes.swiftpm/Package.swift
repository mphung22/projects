// swift-tools-version: 5.9

// Swift Playgrounds / Xcode app package.
// Open this folder in Xcode 15+ on a Mac, or in Swift Playgrounds 4.4+ on iPad or Mac.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Brows and Lashes",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "Brows and Lashes",
            targets: ["AppModule"],
            bundleIdentifier: "com.seren.consent.brows",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .heart),
            accentColor: .presetColor(.brown),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "."
        )
    ]
)
