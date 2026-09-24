// swift-tools-version: 5.9
//
//  Package.swift
//  KitoMapsGoogle
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "KitoMapsGoogle",
    platforms: [.iOS(.v17)],
    products: [.library(name: "KitoMapsGoogle", targets: ["KitoMapsGoogle"])],
    dependencies: [
        .package(url: "https://github.com/WykSofts-Inc/KitoMaps.git", from: "0.2.0"),
        .package(url: "https://github.com/googlemaps/ios-maps-sdk", from: "11.1.0"),
    ],
    targets: [
        .target(name: "KitoMapsGoogle", dependencies: [
            .product(name: "KitoMaps", package: "KitoMaps"),
            .product(name: "GoogleMaps", package: "ios-maps-sdk"),
        ]),
        .testTarget(name: "KitoMapsGoogleTests", dependencies: ["KitoMapsGoogle"]),
    ]
)
