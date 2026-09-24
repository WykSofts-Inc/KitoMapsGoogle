# ``KitoMapsGoogle``

KitoMaps pins, clusters, cards, routes and controls drawn on the Google Maps SDK for iOS.

## Overview

KitoMapsGoogle brings the KitoMaps API to Google Maps. ``KitoGoogleMapView`` takes the same
arguments as `KitoMapView` from KitoMaps — an array of `KitoMapPin` values, a selection binding,
`camera:`, `controller:` and an optional card builder — and supports the same configuration
methods, including `clustering()`, `overlays(_:)` and `controls(_:)`. Switching provider is a
one-line change.

The Google Maps SDK needs an API key with Maps SDK for iOS enabled. Provide it once at launch
with ``KitoGoogleMaps``, and keep the key out of source control, for example by setting
`GMSApiKey = $(GMS_API_KEY)` in Info.plist and supplying the value from an untracked `.xcconfig`
file. Until a key is provided, the map shows a set-up card instead of crashing.

```swift
import SwiftUI
import KitoMaps
import KitoMapsGoogle

@main
struct MyApp: App {
    init() {
        KitoGoogleMaps.provideAPIKeyFromInfoPlist()
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    @State private var selected: String?
    let places: [KitoMapPin]

    var body: some View {
        KitoGoogleMapView(pins: places, selection: $selected, style: .automatic) { pin in
            KitoMapPinCard(pin: pin)
        }
        .clustering()
        .controls(.all)
    }
}
```

``KitoGoogleMapStyle`` offers an automatic light and night style, the standard Google map, a
muted style that lets pins stand out, satellite, terrain and custom style JSON. Markers are Kito
pin views rendered to cached images inside a live marker view, so selection springs, pop-ins,
cluster fly-outs and courier pulses animate as they do on Apple Maps, and Reduce Motion turns
the springs into fades.

## Topics

### Essentials

- ``KitoGoogleMapView``
- ``KitoGoogleMaps``

### Styles

- ``KitoGoogleMapStyle``
