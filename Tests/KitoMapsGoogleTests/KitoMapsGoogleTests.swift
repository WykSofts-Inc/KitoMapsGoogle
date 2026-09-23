//
//  KitoMapsGoogleTests.swift
//  KitoMapsGoogle
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
import SwiftUI
import GoogleMaps
import KitoMaps
@testable import KitoMapsGoogle

@MainActor
final class KitoMapsGoogleTests: XCTestCase {
    private let pins = [
        KitoMapPin(id: "carnivore", coordinate: .init(latitude: -1.3281, longitude: 36.8054), title: "Carnivore", style: .icon("fork.knife")),
        KitoMapPin(id: "kicc", coordinate: .init(latitude: -1.2884, longitude: 36.8233), title: "KICC", style: .teardrop),
    ]

    func testEmptyKeysAreIgnored() {
        XCTAssertFalse(KitoGoogleMaps.provideAPIKey("   "))
        XCTAssertFalse(KitoGoogleMaps.isConfigured)
        XCTAssertFalse(KitoGoogleMaps.provideAPIKeyFromInfoPlist("KitoMissingKey"))
    }

    func testSDKIsLinked() {
        // The SDK itself needs its resource bundle in the app, so only check the classes link.
        XCTAssertNotNil(NSClassFromString("GMSMapView"))
        XCTAssertNotNil(NSClassFromString("GMSMarker"))
    }

    func testBundledStylesAreValidJSON() throws {
        for style in KitoGoogleMapStyle.presets {
            for scheme in [ColorScheme.light, .dark] {
                if let json = style.resolved(for: scheme).json {
                    XCTAssertNoThrow(try GMSMapStyle(jsonString: json), style.title)
                }
            }
        }
        XCTAssertNotNil(KitoGoogleMapStyle.automatic.resolved(for: .dark).json)
        XCTAssertNil(KitoGoogleMapStyle.automatic.resolved(for: .light).json)
        XCTAssertEqual(KitoGoogleMapStyle.satellite.resolved(for: .light).type, .hybrid)
    }

    func testStylesHaveTitlesAndSymbols() {
        XCTAssertEqual(KitoGoogleMapStyle.presets.count, 6)
        XCTAssertTrue(KitoGoogleMapStyle.presets.allSatisfy { !$0.title.isEmpty && UIImage(systemName: $0.systemImage) != nil })
    }

    func testSharesTheKitoMapModifiers() {
        let map = KitoGoogleMapView(pins: pins, style: .dark)
            .clustering()
            .controls(.all)
            .overlays([.circle(center: pins[0].coordinate, radius: 800)])
        XCTAssertNotNil(map.options.clusterer)
        XCTAssertEqual(map.options.controls, .all)
        XCTAssertEqual(map.options.overlays.count, 1)
    }

    func testMarkerImagesRender() {
        XCTAssertNotNil(KitoPinRenderer.image(for: pins[0], displayScale: 2))
        XCTAssertNotNil(KitoPinRenderer.clusterImage(count: 7, displayScale: 2))
    }
}
