//
//  KitoGoogleMapView.swift
//  KitoMapsGoogle
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import GoogleMaps
import KitoCore
@_spi(KitoMapsProvider) import KitoMaps

/// A Google Map with Kito pins, clusters, routes, circles, floating controls and an optional card
/// carousel. Same arguments and modifiers as `KitoMapView`, so switching is a one-line change.
///
/// ```swift
/// KitoGoogleMapView(pins: places, selection: $selected, style: .automatic) { pin in
///     KitoMapPinCard(pin: pin)
/// }
/// .clustering()
/// ```
///
/// Call `KitoGoogleMaps.provideAPIKey(_:)` first; without a key it shows a set-up card.
public struct KitoGoogleMapView<Card: View>: View, KitoMapConfigurable {
    public var options = KitoMapOptions()

    let pins: [KitoMapPin]
    let externalSelection: Binding<String?>?
    let initialStyle: KitoGoogleMapStyle
    let camera: KitoMapCamera
    let controller: KitoMapController?
    let card: ((KitoMapPin) -> Card)?

    @State private var style: KitoGoogleMapStyle
    @State private var is3D = false
    @State private var localSelection: String?
    @State private var bottomInset: CGFloat = 0
    @State private var ownController = KitoMapController()

    @Environment(\.kitoTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale

    /// - Parameters:
    ///   - pins: The places to show.
    ///   - selection: The selected pin's id. Tapping a pin or swiping the cards changes it.
    ///   - style: The starting map style; the style switcher can change it.
    ///   - camera: Where the camera starts. Defaults to framing every pin.
    ///   - controller: Moves the camera from outside.
    ///   - card: A card per pin, shown in a carousel along the bottom.
    public init(pins: [KitoMapPin], selection: Binding<String?>? = nil, style: KitoGoogleMapStyle = .automatic,
                camera: KitoMapCamera = .fitPins, controller: KitoMapController? = nil,
                @ViewBuilder card: @escaping (KitoMapPin) -> Card) {
        self.pins = pins
        self.externalSelection = selection
        self.initialStyle = style
        self.camera = camera
        self.controller = controller
        self.card = card
        self._style = State(initialValue: style)
    }

    private var selection: Binding<String?> { externalSelection ?? $localSelection }
    private var activeController: KitoMapController { controller ?? ownController }

    public var body: some View {
        let configured = KitoGoogleMaps.isConfigured
        KitoMapScaffold(pins: pins, selection: selection, options: options, style: $style, is3D: $is3D,
                        bottomInset: $bottomInset, controller: activeController, showsControls: configured, card: configured ? card : nil) {
            if configured {
                KitoGoogleMapRepresentable(
                    pins: pins, selection: selection, options: options, style: style, is3D: is3D,
                    bottomInset: bottomInset, initialCamera: camera, request: activeController.request,
                    controller: activeController, theme: theme, colorScheme: colorScheme, displayScale: displayScale)
            } else {
                KitoGoogleMapsSetupCard()
            }
        }
        .onAppear { if options.startsIn3D { is3D = true } }
        .onChange(of: initialStyle) { _, newStyle in style = newStyle }
    }
}

public extension KitoGoogleMapView where Card == EmptyView {
    /// A map without the card carousel.
    init(pins: [KitoMapPin], selection: Binding<String?>? = nil, style: KitoGoogleMapStyle = .automatic,
         camera: KitoMapCamera = .fitPins, controller: KitoMapController? = nil) {
        self.pins = pins
        self.externalSelection = selection
        self.initialStyle = style
        self.camera = camera
        self.controller = controller
        self.card = nil
        self._style = State(initialValue: style)
    }
}

// MARK: - Set-up card

/// Shown instead of the map until an API key is provided.
struct KitoGoogleMapsSetupCard: View {
    @Environment(\.kitoTheme) private var theme

    var body: some View {
        ZStack {
            LinearGradient(colors: [theme.colors.surfaceMuted, theme.colors.background], startPoint: .top, endPoint: .bottom)
            VStack(spacing: theme.spacing.md) {
                Image(systemName: "key.viewfinder")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(theme.colors.primary)
                    .frame(width: 72, height: 72)
                    .background(theme.colors.primary.opacity(0.12), in: Circle())
                Text("Add a Google Maps API key")
                    .font(theme.typography.bodyEmphasized)
                    .foregroundStyle(theme.colors.onSurface)
                Text("Call KitoGoogleMaps.provideAPIKey(_:) at launch, or add GMSApiKey to Info.plist and call provideAPIKeyFromInfoPlist().")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.onSurface.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
            .padding(theme.spacing.xl)
            .background(theme.colors.surface, in: RoundedRectangle(cornerRadius: theme.radii.xl, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 18, y: 6)
            .padding(theme.spacing.xl)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Representable

struct KitoGoogleMapRepresentable: UIViewRepresentable {
    let pins: [KitoMapPin]
    let selection: Binding<String?>
    let options: KitoMapOptions
    let style: KitoGoogleMapStyle
    let is3D: Bool
    let bottomInset: CGFloat
    let initialCamera: KitoMapCamera
    let request: KitoCameraRequest?
    let controller: KitoMapController
    let theme: KitoTheme
    let colorScheme: ColorScheme
    let displayScale: CGFloat

    func makeCoordinator() -> KitoGoogleMapCoordinator {
        KitoGoogleMapCoordinator(self)
    }

    func makeUIView(context: Context) -> KitoGoogleContainerView {
        context.coordinator.container
    }

    func updateUIView(_ uiView: KitoGoogleContainerView, context: Context) {
        context.coordinator.update(self)
    }
}

/// Hosts the map and reports layout, so the first camera fit happens once there is a size.
final class KitoGoogleContainerView: UIView {
    let mapView: GMSMapView
    var onLayout: (() -> Void)?

    init() {
        let options = GMSMapViewOptions()
        options.backgroundColor = .secondarySystemBackground
        mapView = GMSMapView(options: options)
        super.init(frame: .zero)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(mapView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        mapView.frame = bounds
        onLayout?()
    }
}

// MARK: - Coordinator

@MainActor
final class KitoGoogleMapCoordinator: NSObject {
    private(set) var parent: KitoGoogleMapRepresentable
    let container = KitoGoogleContainerView()
    private var mapView: GMSMapView { container.mapView }

    private var markers: [String: GMSMarker] = [:]
    private var markerKeys: [String: String] = [:]
    private var items: [KitoMapCluster] = []
    private var polylines: [String: GMSPolyline] = [:]
    private var circles: [String: GMSCircle] = [:]
    private var drawnOverlays: [KitoMapOverlay] = []
    private var zoomLevel: Int?
    private var hasPlacedCamera = false
    private var lastRequestID: Int?
    private var lastSelection: String?
    private var lastStyle: (KitoGoogleMapStyle, ColorScheme)?
    private var lastIs3D = false
    private var location: KitoLocationProvider?
    private var avatars: [URL: UIImage] = [:]
    private var loadingAvatars: Set<URL> = []

    private var reduceMotion: Bool { UIAccessibility.isReduceMotionEnabled }

    init(_ parent: KitoGoogleMapRepresentable) {
        self.parent = parent
        super.init()
        mapView.delegate = self
        mapView.settings.compassButton = true
        mapView.settings.myLocationButton = false
        mapView.settings.rotateGestures = true
        mapView.settings.tiltGestures = true
        mapView.paddingAdjustmentBehavior = .never
        lastSelection = parent.selection.wrappedValue
        lastRequestID = parent.request?.id
        container.onLayout = { [weak self] in self?.placeInitialCamera() }
    }

    func update(_ newParent: KitoGoogleMapRepresentable) {
        parent = newParent
        mapView.padding = UIEdgeInsets(top: 0, left: 0, bottom: parent.bottomInset, right: 0)
        applyStyle()
        applyUserLocation()
        syncOverlays()

        let selection = parent.selection.wrappedValue
        let selectionChanged = selection != lastSelection
        lastSelection = selection
        if hasPlacedCamera { syncMarkers() }
        if selectionChanged, parent.options.followsSelection { follow(selection) }

        if parent.is3D != lastIs3D {
            lastIs3D = parent.is3D
            tilt(parent.is3D)
        }
        if let request = parent.request, request.id != lastRequestID {
            lastRequestID = request.id
            apply(request.camera, animated: request.animated)
        }
        placeInitialCamera()
    }

    // MARK: Camera

    private func placeInitialCamera() {
        guard !hasPlacedCamera, container.bounds.width > 0, container.bounds.height > 0 else { return }
        if case .fitPins = parent.initialCamera, parent.pins.isEmpty, parent.options.overlays.isEmpty { return }
        hasPlacedCamera = true
        apply(parent.initialCamera, animated: false)
        zoomLevel = Int(floor(mapView.camera.zoom))
        syncMarkers()
    }

    private func apply(_ camera: KitoMapCamera, animated: Bool) {
        switch camera {
        case .fitPins:
            let pins = parent.pins.map(\.coordinate)
            fit(pins.isEmpty ? parent.options.overlays.flatMap(\.fittingCoordinates) : pins, animated: animated)
        case .fit(let coordinates):
            fit(coordinates, animated: animated)
        case .center(let coordinate, let zoom):
            move(GMSCameraUpdate.setTarget(coordinate, zoom: Float(zoom)), animated: animated)
        case .userLocation(let zoom):
            locate(zoom: zoom)
        }
    }

    private func fit(_ coordinates: [CLLocationCoordinate2D], animated: Bool, maximumZoom: Float = 16) {
        guard let first = coordinates.first else { return }
        let bounds = coordinates.dropFirst().reduce(GMSCoordinateBounds(coordinate: first, coordinate: first)) { $0.includingCoordinate($1) }
        let padding = parent.options.fitPadding
        let insets = UIEdgeInsets(top: padding.top, left: padding.leading, bottom: padding.bottom, right: padding.trailing)
        let target = mapView.camera(for: bounds, insets: insets)
        if let target, target.zoom > maximumZoom {
            move(GMSCameraUpdate.setTarget(target.target, zoom: maximumZoom), animated: animated)
        } else {
            move(GMSCameraUpdate.fit(bounds, with: insets), animated: animated)
        }
    }

    private func move(_ update: GMSCameraUpdate, animated: Bool) {
        guard animated, !reduceMotion else {
            mapView.moveCamera(update)
            return
        }
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.8)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        mapView.animate(with: update)
        CATransaction.commit()
    }

    private func follow(_ id: String?) {
        guard let id, let pin = parent.pins.first(where: { $0.id == id }) else { return }
        move(GMSCameraUpdate.setTarget(pin.coordinate), animated: true)
    }

    private func tilt(_ on: Bool) {
        let current = mapView.camera
        let target = GMSCameraPosition(target: current.target, zoom: on ? max(current.zoom, 15.5) : current.zoom,
                                       bearing: on ? current.bearing + 20 : 0, viewingAngle: on ? 55 : 0)
        move(GMSCameraUpdate.setCamera(target), animated: true)
    }

    private func locate(zoom: Double) {
        let provider = location ?? KitoLocationProvider()
        location = provider
        provider.locate { [weak self] found in
            guard let self, let found else { return }
            self.mapView.isMyLocationEnabled = true
            self.move(GMSCameraUpdate.setTarget(found.coordinate, zoom: Float(zoom)), animated: true)
        }
    }

    // MARK: Style and location

    private func applyStyle() {
        if let last = lastStyle, last.0 == parent.style, last.1 == parent.colorScheme { return }
        lastStyle = (parent.style, parent.colorScheme)
        let resolved = parent.style.resolved(for: parent.colorScheme)
        mapView.mapType = resolved.type
        mapView.mapStyle = resolved.json.flatMap { try? GMSMapStyle(jsonString: $0) }
        refreshAllMarkers()
    }

    private func applyUserLocation() {
        guard parent.options.showsUserLocation else {
            if mapView.isMyLocationEnabled, location == nil { mapView.isMyLocationEnabled = false }
            return
        }
        let provider = location ?? KitoLocationProvider()
        location = provider
        if provider.isAuthorized {
            mapView.isMyLocationEnabled = true
        } else if provider.authorization == .notDetermined {
            provider.locate { [weak self] found in if found != nil { self?.mapView.isMyLocationEnabled = true } }
        }
    }

    // MARK: Overlays

    private func syncOverlays() {
        let overlays = parent.options.overlays
        guard overlays != drawnOverlays else { return }
        drawnOverlays = overlays
        let ids = Set(overlays.map(\.id))
        for (id, line) in polylines where !ids.contains(id) { line.map = nil; polylines[id] = nil }
        for (id, circle) in circles where !ids.contains(id) { circle.map = nil; circles[id] = nil }

        for (index, overlay) in overlays.enumerated() {
            let color = UIColor(overlay.color)
            switch overlay.shape {
            case .polyline(let coordinates):
                circles[overlay.id]?.map = nil
                circles[overlay.id] = nil
                let path = GMSMutablePath()
                coordinates.forEach { path.add($0) }
                let line = polylines[overlay.id] ?? GMSPolyline()
                line.path = path
                line.strokeWidth = overlay.lineWidth
                line.geodesic = false
                line.zIndex = Int32(index)
                if overlay.isDashed {
                    line.spans = GMSStyleSpans(path, [GMSStrokeStyle.solidColor(color), GMSStrokeStyle.solidColor(.clear)],
                                               [NSNumber(value: 14), NSNumber(value: 10)], .rhumb)
                } else {
                    line.spans = nil
                    line.strokeColor = color
                }
                line.map = mapView
                polylines[overlay.id] = line
            case .circle(let center, let radius):
                polylines[overlay.id]?.map = nil
                polylines[overlay.id] = nil
                let circle = circles[overlay.id] ?? GMSCircle()
                circle.position = center
                circle.radius = radius
                circle.fillColor = color.withAlphaComponent(0.16)
                circle.strokeColor = color
                circle.strokeWidth = overlay.lineWidth
                circle.zIndex = Int32(index)
                circle.map = mapView
                circles[overlay.id] = circle
            }
        }
    }

    // MARK: Markers

    private func syncMarkers() {
        let selection = parent.selection.wrappedValue
        let zoom = Double(mapView.camera.zoom)
        let newItems = parent.options.clusterer?.clusters(for: parent.pins, zoom: zoom, excluding: selection)
            ?? parent.pins.map { KitoMapCluster(pins: [$0]) }
        let diff = KitoClusterDiff(from: items, to: newItems)
        let firstReveal = items.isEmpty

        for item in diff.removed {
            guard let marker = markers.removeValue(forKey: item.id) else { continue }
            markerKeys[item.id] = nil
            retire(marker, to: diff.mergeTargets[item.id])
        }
        for item in diff.kept {
            guard let marker = markers[item.id] else { continue }
            if marker.position.latitude != item.coordinate.latitude || marker.position.longitude != item.coordinate.longitude {
                marker.position = item.coordinate
            }
            configure(marker, item: item, bounce: true)
        }
        for (index, item) in diff.inserted.enumerated() {
            let origin = diff.origins[item.id]
            let marker = GMSMarker(position: origin ?? item.coordinate)
            marker.userData = item.id
            markers[item.id] = marker
            configure(marker, item: item, bounce: false)
            marker.map = mapView
            (marker.iconView as? KitoMarkerContentView)?.popIn(delay: firstReveal ? min(Double(index) * 0.025, 0.45) : 0)
            watchChanges(marker, for: 0.9 + (firstReveal ? 0.45 : 0))
            if origin != nil { glide(marker, to: item.coordinate) }
        }
        items = newItems
    }

    private func refreshAllMarkers() {
        for item in items {
            guard let marker = markers[item.id] else { continue }
            markerKeys[item.id] = nil
            configure(marker, item: item, bounce: false)
        }
    }

    private func configure(_ marker: GMSMarker, item: KitoMapCluster, bounce: Bool) {
        let selected = item.pin?.id == parent.selection.wrappedValue
        let key = item.visualKey(selected: selected) + "|\(parent.colorScheme)" + (item.pin.flatMap(avatarURL).flatMap { avatars[$0] } == nil ? "" : "|img")
        marker.zIndex = selected ? 1_000 : (item.isCluster ? 500 : Int32(0))
        marker.title = item.pin?.accessibilityText ?? "\(item.count) places"
        guard markerKeys[item.id] != key else { return }
        let hadImage = markerKeys[item.id] != nil
        markerKeys[item.id] = key

        let rendered: KitoPinImage?
        if let pin = item.pin {
            let avatar = avatarURL(pin).flatMap { url -> UIImage? in
                if let image = avatars[url] { return image }
                load(url)
                return nil
            }
            rendered = KitoPinRenderer.image(for: pin, selected: selected, theme: parent.theme, colorScheme: parent.colorScheme,
                                             avatarImage: avatar, displayScale: parent.displayScale)
        } else {
            rendered = KitoPinRenderer.clusterImage(count: item.count, tint: item.sharedTint, theme: parent.theme,
                                                    colorScheme: parent.colorScheme, displayScale: parent.displayScale)
        }
        guard let rendered else { return }
        let view = (marker.iconView as? KitoMarkerContentView) ?? KitoMarkerContentView()
        let pulse = item.pin.flatMap { pin in pin.pulseDiameter.map { (UIColor(pin.tint ?? parent.theme.colors.primary), $0) } }
        let sizeChanged = view.imageSize != rendered.image.size
        view.show(rendered, bounce: bounce && hadImage, pulseColor: pulse?.0, pulseDiameter: pulse?.1 ?? 34)
        marker.groundAnchor = rendered.anchor
        if marker.iconView !== view || sizeChanged {
            marker.iconView = nil
            marker.iconView = view
        }
        if pulse != nil, !reduceMotion {
            marker.tracksViewChanges = true
        } else {
            watchChanges(marker, for: 0.7)
        }
    }

    /// Lets Google Maps redraw the marker view while it animates, then stops for performance.
    private func watchChanges(_ marker: GMSMarker, for seconds: TimeInterval) {
        marker.tracksViewChanges = true
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak marker] in
            guard let marker, (marker.iconView as? KitoMarkerContentView)?.isPulsing != true else { return }
            marker.tracksViewChanges = false
        }
    }

    private func glide(_ marker: GMSMarker, to coordinate: CLLocationCoordinate2D) {
        guard !reduceMotion else {
            marker.position = coordinate
            return
        }
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.45)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
        marker.position = coordinate
        CATransaction.commit()
    }

    private func retire(_ marker: GMSMarker, to target: CLLocationCoordinate2D?) {
        marker.tracksViewChanges = true
        if let target, !reduceMotion {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.3)
            CATransaction.setCompletionBlock { marker.map = nil }
            marker.position = target
            CATransaction.commit()
        } else if let view = marker.iconView as? KitoMarkerContentView {
            view.shrinkAway { marker.map = nil }
        } else {
            marker.map = nil
        }
    }

    private func avatarURL(_ pin: KitoMapPin) -> URL? {
        if case .avatar(_, let url) = pin.style { return url }
        return nil
    }

    private func load(_ url: URL) {
        guard !loadingAvatars.contains(url) else { return }
        loadingAvatars.insert(url)
        Task { [weak self] in
            guard let (data, _) = try? await URLSession.shared.data(from: url), let image = UIImage(data: data) else { return }
            self?.avatars[url] = image
            self?.refreshAllMarkers()
        }
    }

    private func zoom(into cluster: KitoMapCluster) {
        fit(cluster.pins.map(\.coordinate), animated: true, maximumZoom: 18)
    }
}

extension KitoGoogleMapCoordinator: @preconcurrency GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        guard let id = marker.userData as? String, let item = items.first(where: { $0.id == id }) else { return true }
        if let pin = item.pin {
            withAnimation(reduceMotion ? nil : .snappy) { parent.selection.wrappedValue = pin.id }
        } else {
            zoom(into: item)
        }
        return true
    }

    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        let level = Int(floor(position.zoom))
        guard hasPlacedCamera, level != zoomLevel else { return }
        zoomLevel = level
        syncMarkers()
    }

    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        parent.controller.report(center: position.target, zoom: Double(position.zoom))
    }
}
