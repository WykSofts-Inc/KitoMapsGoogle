//
//  KitoGoogleMaps.swift
//  KitoMapsGoogle
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation
import GoogleMaps

/// Google Maps SDK set-up. Provide your API key once at launch, before showing a map.
///
/// ```swift
/// @main struct MyApp: App {
///     init() { KitoGoogleMaps.provideAPIKeyFromInfoPlist() }   // reads GMSApiKey
///     …
/// }
/// ```
///
/// Until a key is provided, `KitoGoogleMapView` shows a set-up card instead of a map.
@MainActor
public enum KitoGoogleMaps {
    /// `true` once a key has been accepted.
    public private(set) static var isConfigured = false

    /// Hands your key to the Google Maps SDK. Empty keys are ignored. Returns `isConfigured`.
    @discardableResult
    public static func provideAPIKey(_ key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isConfigured, !trimmed.isEmpty else { return isConfigured }
        isConfigured = GMSServices.provideAPIKey(trimmed)
        return isConfigured
    }

    /// Reads the key from your Info.plist (`GMSApiKey` by default) and provides it, if present.
    @discardableResult
    public static func provideAPIKeyFromInfoPlist(_ infoKey: String = "GMSApiKey", bundle: Bundle = .main) -> Bool {
        guard let key = bundle.object(forInfoDictionaryKey: infoKey) as? String else { return isConfigured }
        return provideAPIKey(key)
    }

    /// The Google Maps SDK version, e.g. "11.1.0".
    public static var sdkVersion: String { GMSServices.sdkVersion() }
}
