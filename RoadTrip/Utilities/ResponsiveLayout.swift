// Utilities/ResponsiveLayout.swift
import SwiftUI

enum DeviceType {
    case iPhone
    case iPad
    case mac
}

struct ResponsiveLayoutModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    
    var deviceType: DeviceType {
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            return .iPad
        }
        return .iPhone
    }
    
    func body(content: Content) -> some View {
        content
    }
}

struct AdaptiveGridView<Item: Identifiable, Content: View>: View where Item: Hashable {
    let items: [Item]
    let isCompact: Bool
    @ViewBuilder let content: (Item) -> Content
    
    var columns: [GridItem] {
        if isCompact {
            return [GridItem(.flexible())]
        } else {
            return [
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
        }
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: AppTheme.Spacing.md) {
            ForEach(items) { item in
                content(item)
            }
        }
    }
}

struct AdaptiveStackView<Content: View>: View {
    let isVertical: Bool
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        if isVertical {
            VStack(spacing: AppTheme.Spacing.md) {
                content()
            }
        } else {
            HStack(spacing: AppTheme.Spacing.md) {
                content()
            }
        }
    }
}

struct ResponsivePaddingModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var padding: CGFloat {
        if horizontalSizeClass == .regular {
            return AppTheme.Spacing.lg
        }
        return AppTheme.Spacing.md
    }
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
    }
}

struct ResponsiveFontModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    let defaultFont: Font
    let compactFont: Font
    
    var font: Font {
        if horizontalSizeClass == .compact {
            return compactFont
        }
        return defaultFont
    }
    
    func body(content: Content) -> some View {
        content
            .font(font)
    }
}

// MARK: - Extension Methods
extension View {
    func responsivePadding() -> some View {
        modifier(ResponsivePaddingModifier())
    }
    
    func responsiveFont(_ defaultFont: Font, _ compactFont: Font) -> some View {
        modifier(ResponsiveFontModifier(defaultFont: defaultFont, compactFont: compactFont))
    }
}

// MARK: - Size Class Aware Container
struct SizeClassContainer<Content: View>: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    let compactContent: () -> Content
    let regularContent: (() -> Content)?
    
    var body: some View {
        if horizontalSizeClass == .compact {
            compactContent()
        } else if let regularContent = regularContent {
            regularContent()
        } else {
            compactContent()
        }
    }
}

// MARK: - Adaptive List Modifier
struct AdaptiveListModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            content
                .listStyle(.insetGrouped)
        } else {
            content
                .listStyle(.insetGrouped)
        }
    }
}

extension View {
    func adaptiveListStyle() -> some View {
        modifier(AdaptiveListModifier())
    }
}
