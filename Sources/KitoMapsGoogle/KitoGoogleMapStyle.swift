//
//  KitoGoogleMapStyle.swift
//  KitoMapsGoogle
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import GoogleMaps
import KitoMaps

/// Google Maps styles.
public enum KitoGoogleMapStyle: Hashable, Sendable, KitoMapStyleOption {
    /// Standard in light mode, dark in dark mode.
    case automatic
    /// Google's default map.
    case standard
    /// Soft greys and no business labels, so your pins stand out.
    case muted
    /// A deep navy night map.
    case dark
    /// Satellite imagery with labels.
    case satellite
    /// Relief shading.
    case terrain
    /// Your own style JSON from the Google Maps styling wizard.
    case json(String)

    public static var presets: [KitoGoogleMapStyle] { [.automatic, .standard, .muted, .dark, .satellite, .terrain] }

    public var title: String {
        switch self {
        case .automatic: return "Automatic"
        case .standard: return "Standard"
        case .muted: return "Muted"
        case .dark: return "Dark"
        case .satellite: return "Satellite"
        case .terrain: return "Terrain"
        case .json: return "Custom"
        }
    }

    public var systemImage: String {
        switch self {
        case .automatic: return "circle.lefthalf.filled"
        case .standard: return "map"
        case .muted: return "map.circle"
        case .dark: return "moon.stars.fill"
        case .satellite: return "globe.europe.africa.fill"
        case .terrain: return "mountain.2.fill"
        case .json: return "paintpalette"
        }
    }

    /// The map type and optional style JSON for a colour scheme.
    func resolved(for colorScheme: ColorScheme) -> (type: GMSMapViewType, json: String?) {
        switch self {
        case .automatic: return (.normal, colorScheme == .dark ? Self.darkJSON : nil)
        case .standard: return (.normal, nil)
        case .muted: return (.normal, Self.mutedJSON)
        case .dark: return (.normal, Self.darkJSON)
        case .satellite: return (.hybrid, nil)
        case .terrain: return (.terrain, nil)
        case .json(let json): return (.normal, json)
        }
    }

    static let darkJSON = """
    [
      {"elementType":"geometry","stylers":[{"color":"#1b2130"}]},
      {"elementType":"labels.text.fill","stylers":[{"color":"#8d96a8"}]},
      {"elementType":"labels.text.stroke","stylers":[{"color":"#121620"}]},
      {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#394155"}]},
      {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#c3c9d6"}]},
      {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#20283a"}]},
      {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6f7a90"}]},
      {"featureType":"poi.business","stylers":[{"visibility":"off"}]},
      {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#17302a"}]},
      {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2b3347"}]},
      {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#171c27"}]},
      {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9aa3b6"}]},
      {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3a4560"}]},
      {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1c2231"}]},
      {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#252d3f"}]},
      {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0d1524"}]},
      {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4c6a8a"}]}
    ]
    """

    static let mutedJSON = """
    [
      {"elementType":"geometry","stylers":[{"color":"#f3f4f6"}]},
      {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
      {"elementType":"labels.text.fill","stylers":[{"color":"#6b7280"}]},
      {"elementType":"labels.text.stroke","stylers":[{"color":"#f9fafb"}]},
      {"featureType":"poi","stylers":[{"visibility":"off"}]},
      {"featureType":"poi.park","stylers":[{"visibility":"on"}]},
      {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#e3eee6"}]},
      {"featureType":"poi.park","elementType":"labels","stylers":[{"visibility":"off"}]},
      {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
      {"featureType":"road.arterial","elementType":"labels.text.fill","stylers":[{"color":"#9ca3af"}]},
      {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#e5e7eb"}]},
      {"featureType":"transit","stylers":[{"visibility":"off"}]},
      {"featureType":"water","elementType":"geometry","stylers":[{"color":"#d6e4f0"}]}
    ]
    """
}
