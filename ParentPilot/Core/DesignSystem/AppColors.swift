import SwiftUI

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

enum AppColors {
    static let primaryText: Color = .primary
    static let secondaryText: Color = .secondary
    static let tertiaryText: Color = .secondary.opacity(0.72)
    static let background: Color = {
        #if canImport(UIKit)
            Color(uiColor: .systemBackground)
        #else
            Color(nsColor: .windowBackgroundColor)
        #endif
    }()
    static let surface: Color = {
        #if canImport(UIKit)
            Color(uiColor: .secondarySystemBackground)
        #else
            Color(nsColor: .controlBackgroundColor)
        #endif
    }()
    static let accent: Color = .accentColor
    static let accentSoft: Color = .accentColor.opacity(0.12)
    static let success: Color = .green
    static let successSoft: Color = .green.opacity(0.12)
    static let warning: Color = .orange
    static let warningSoft: Color = .orange.opacity(0.14)
    static let destructive: Color = .red
    static let destructiveSoft: Color = .red.opacity(0.10)
    static let divider: Color = .secondary.opacity(0.18)
}
