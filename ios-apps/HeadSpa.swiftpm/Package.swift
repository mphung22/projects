// swift-tools-version: 5.9

// Swift Playgrounds / Xcode app package.
// Open this folder in Xcode 15+ on a Mac, or in Swift Playgrounds 4.4+ on iPad or Mac.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Head Spa",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "Head Spa",
            targets: ["AppModule"],
            bundleIdentifier: "com.seren.consent.headspa",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .flower),
            accentColor: .presetColor(.purple),
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
