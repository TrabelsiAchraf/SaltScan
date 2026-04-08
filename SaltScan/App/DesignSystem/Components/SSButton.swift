//
//  SSButton.swift
//  SaltScan
//
//  Primary / secondary / ghost buttons with consistent sizing, haptics and
//  disabled handling. Replaces the legacy PrimaryButton.
//

import SwiftUI

enum SSButtonStyle {
    case primary
    case secondary
    case ghost
    case destructive
}

enum SSButtonSize {
    case regular
    case compact

    var verticalPadding: CGFloat {
        switch self {
        case .regular: SSSpacing.md
        case .compact: SSSpacing.sm
        }
    }

    var font: Font {
        switch self {
        case .regular: SSFont.headline()
        case .compact: SSFont.subheadline().weight(.semibold)
        }
    }
}

struct SSButton: View {
    let title: LocalizedStringKey
    var icon: String? = nil
    var style: SSButtonStyle = .primary
    var size: SSButtonSize = .regular
    var isLoading: Bool = false
    var isEnabled: Bool = true
    var action: () -> Void

    @Environment(\.isEnabled) private var environmentEnabled
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        Button {
            haptic.impactOccurred()
            action()
        } label: {
            HStack(spacing: SSSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(foreground)
                } else if let icon {
                    Image(systemName: icon)
                        .font(size.font)
                }
                Text(title)
                    .font(size.font)
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, SSSpacing.md)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: SSRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SSRadius.md, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
            .contentShape(RoundedRectangle(cornerRadius: SSRadius.md, style: .continuous))
            .opacity(effectiveEnabled ? 1 : 0.5)
        }
        .buttonStyle(SSPressStyle())
        .disabled(!effectiveEnabled || isLoading)
        .onAppear { haptic.prepare() }
    }

    private var effectiveEnabled: Bool { isEnabled && environmentEnabled }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            LinearGradient(
                colors: [.ssPrimary, .ssPrimary.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            Color.ssSurface
        case .ghost:
            Color.clear
        case .destructive:
            Color.ssSeverityHigh
        }
    }

    private var foreground: Color {
        switch style {
        case .primary, .destructive: .white
        case .secondary: .ssTextPrimary
        case .ghost: .ssPrimary
        }
    }

    private var borderColor: Color {
        switch style {
        case .ghost: .ssPrimary.opacity(0.6)
        case .secondary: .ssTextTertiary.opacity(0.25)
        default: .clear
        }
    }

    private var borderWidth: CGFloat {
        switch style {
        case .ghost, .secondary: 1
        default: 0
        }
    }
}

private struct SSPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: SSSpacing.md) {
        SSButton(title: "onboarding.button.start") {}
        SSButton(title: "home.scanProduct.button.start", icon: "barcode.viewfinder", style: .primary) {}
        SSButton(title: "ds.severity.medium", style: .secondary) {}
        SSButton(title: "ds.severity.low", style: .ghost) {}
        SSButton(title: "contactUs.button.send", style: .destructive) {}
        SSButton(title: "result.product.loading", isLoading: true) {}
        SSButton(title: "contactUs.button.send", isEnabled: false) {}
    }
    .padding()
}
