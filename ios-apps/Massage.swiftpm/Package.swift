// swift-tools-version: 5.9

// Swift Playgrounds / Xcode app package.
// Open this folder in Xcode 15+ on a Mac, or in Swift Playgrounds 4.4+ on iPad or Mac.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Massage",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "Massage",
            targets: ["AppModule"],
            bundleIdentifier: "com.seren.consent.massage",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .leaf),
            accentColor: .presetColor(.teal),
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
