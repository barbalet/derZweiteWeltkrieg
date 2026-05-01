import SwiftUI

private enum BattleButtonProminence {
    case primary
    case secondary
}

private struct BattleButtonModifier: ViewModifier {
    let prominence: BattleButtonProminence
    let tint: Color?

    @ViewBuilder
    func body(content: Content) -> some View {
        switch prominence {
        case .primary:
            if let tint {
                content
                    .buttonStyle(.borderedProminent)
                    .tint(tint)
            } else {
                content.buttonStyle(.borderedProminent)
            }
        case .secondary:
            if let tint {
                content
                    .buttonStyle(.bordered)
                    .tint(tint)
            } else {
                content.buttonStyle(.bordered)
            }
        }
    }
}

extension View {
    func battlePrimaryButton(tint: Color? = nil) -> some View {
        modifier(BattleButtonModifier(prominence: .primary, tint: tint))
    }

    func battleSecondaryButton(tint: Color? = nil) -> some View {
        modifier(BattleButtonModifier(prominence: .secondary, tint: tint))
    }
}
