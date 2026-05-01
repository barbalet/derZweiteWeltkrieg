import SwiftUI

struct BattleErrorSection: View {
    let message: String

    var body: some View {
        BattleSidebarSection("Last Error") {
            Text(message)
                .foregroundStyle(BattlePalette.sidebarErrorText)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
        }
    }
}
