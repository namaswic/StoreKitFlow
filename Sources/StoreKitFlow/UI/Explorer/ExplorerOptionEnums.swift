import SwiftUI
import StoreKit

enum ProductViewStyleOption: String, CaseIterable, Identifiable {
    case large, regular, compact
    var id: String { rawValue }
    var label: String { ".\(rawValue)" }
}

enum SubscriptionControlStyleOption: String, CaseIterable, Identifiable {
    case buttons, picker, prominentPicker, compactPicker
    var id: String { rawValue }
    var label: String {
        switch self {
        case .buttons: return ".buttons"
        case .picker: return ".picker"
        case .prominentPicker: return ".prominentPicker"
        case .compactPicker: return ".compactPicker"
        }
    }
}

enum SubscriptionOfferStyleOption: String, CaseIterable, Identifiable {
    case automatic, compact
    var id: String { rawValue }
    var label: String { ".\(rawValue)" }
}

enum ButtonLabelOption: String, CaseIterable, Identifiable {
    case action, displayName, price, multiline
    var id: String { rawValue }
    var label: String { ".\(rawValue)" }
}

enum ControlBackgroundOption: String, CaseIterable, Identifiable {
    case automatic, clear
    var id: String { rawValue }
    var label: String { ".\(rawValue)" }
}

enum PickerItemBgOption: String, CaseIterable, Identifiable {
    case regularMaterial, thinMaterial, clear
    var id: String { rawValue }
    var label: String { ".\(rawValue)" }
}

enum ContainerPlacementOption: String, CaseIterable, Identifiable {
    case subscriptionStore, subscriptionStoreHeader, subscriptionStoreFullHeight
    var id: String { rawValue }
    var label: String { ".\(rawValue)" }
}

enum ContainerColorOption: String, CaseIterable, Identifiable {
    case purple, blue, green, orange
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var color: Color {
        switch self {
        case .purple: return .purple
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        }
    }
}

enum AccentColorOption: String, CaseIterable, Identifiable {
    case purple, blue, green, orange, pink
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var color: Color {
        switch self {
        case .purple: return .purple
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .pink: return .pink
        }
    }
}

enum OverlayPositionOption: String, CaseIterable, Identifiable {
    case bottom, bottomRaised
    var id: String { rawValue }
    var label: String { ".\(rawValue)" }
    var skPosition: SKOverlay.Position {
        switch self {
        case .bottom: return .bottom
        case .bottomRaised: return .bottomRaised
        }
    }
}
