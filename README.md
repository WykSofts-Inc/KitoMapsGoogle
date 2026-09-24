# KitoMapsGoogle

[KitoMaps](https://github.com/WykSofts-Inc/KitoMaps) on the Google Maps SDK for iOS: the same pins,
clusters, cards, routes and controls as `KitoMapView`, drawn on a Google Map. Part of the
[Kito](https://github.com/WykSofts-Inc/KitoDevKit) ecosystem.

## Set up your key

The Google Maps SDK needs an API key with **Maps SDK for iOS** enabled
([get one](https://developers.google.com/maps/documentation/ios-sdk/get-api-key)). Provide it once
at launch — never commit it to source control:

```swift
import KitoMapsGoogle

@main struct MyApp: App {
    init() {
        KitoGoogleMaps.provideAPIKeyFromInfoPlist()   // reads the GMSApiKey Info.plist value
        // or: KitoGoogleMaps.provideAPIKey(key)
    }
    var body: some Scene { WindowGroup { ContentView() } }
}
```

A handy pattern is `GMSApiKey = $(GMS_API_KEY)` in Info.plist with the value in an untracked
`.xcconfig`. Until a key is provided, `KitoGoogleMapView` shows a set-up card instead of crashing;
check `KitoGoogleMaps.isConfigured` to decide for yourself.

**Cost:** the Maps SDK for iOS is free to use within Google's usage quotas (mobile map loads are
currently unlimited at no charge), but Google requires a billing-enabled Cloud project for the key.
Check [Google Maps Platform pricing](https://mapsplatform.google.com/pricing/) for your case.

## A map with cards

```swift
@State private var selected: String?

KitoGoogleMapView(pins: places, selection: $selected, style: .automatic) { pin in
    KitoMapPinCard(pin: pin)
}
.clustering()
.controls(.all)
.overlays([.route(route, color: .blue), .circle(center: store, radius: 2_000, color: .orange)])
```

It is `KitoMapView` with a different name: same `KitoMapPin`s, `selection`, `camera:`,
`controller:`, card builder and modifiers (`.clustering()`, `.overlays(_:)`, `.controls(_:)`,
`.showsUserLocation()`, `.fitPadding(_:)`, `.followsSelection(_:)`, `.startsIn3D()`), so switching
provider is a one-line change.

## Styles

| Style | Look |
|---|---|
| `.automatic` | Standard in light mode, a navy night map in dark mode (default) |
| `.standard` | Google's default map |
| `.muted` | Soft greys with no business labels, so your pins stand out |
| `.dark` | The night map, always |
| `.satellite` | Satellite imagery with labels |
| `.terrain` | Relief shading |
| `.json(styleJSON)` | Your own style from the Google Maps styling wizard |

## How pins are drawn

Markers are `KitoMapPinView`s rendered to images (cached) inside a live marker view, so selection
springs, pop-ins, cluster fly-outs and courier pulses animate just like on Apple Maps. Avatar photos
are downloaded and swapped in when they arrive. Reduce Motion turns the springs into fades.

## Migrating from 0.1

0.2.0 needs KitoMaps 0.2.0, which renamed `KitoRoute` to `KitoMapRoute` so KitoMaps no longer
clashes with KitoNavigation's `KitoRoute`. Nothing in this package was renamed; update KitoMaps
alongside it and replace `KitoRoute` with `KitoMapRoute` wherever your own code spells it out.

## Installation

```swift
.package(url: "https://github.com/WykSofts-Inc/KitoMapsGoogle.git", from: "0.2.0")
```

iOS 17+. Brings in [KitoMaps](https://github.com/WykSofts-Inc/KitoMaps) and Google's
[ios-maps-sdk](https://github.com/googlemaps/ios-maps-sdk) package (11.1.0 or later). The SDK is a
large static library — about 39 MB for arm64 before linking, plus a 3 MB resource bundle — so expect
your app to grow by roughly 20–30 MB.

## License

MIT — see [LICENSE](LICENSE). The Google Maps SDK is subject to the
[Google Maps Platform Terms of Service](https://cloud.google.com/maps-platform/terms).
