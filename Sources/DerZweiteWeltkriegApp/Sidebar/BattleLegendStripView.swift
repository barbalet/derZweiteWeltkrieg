import SwiftUI

struct BattleLegendStripView: View {
    var body: some View {
        BattleSidebarSection("Token Legend") {
            ForEach(BattleDisplayLabels.tokenLegend, id: \.0) { badge, text in
                HStack(alignment: .top, spacing: 10) {
                    Text(badge)
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, badge == "Smoke" ? 8 : 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(BattlePalette.legendBadgeGreen))
                    Text(text)
                        .font(.system(size: 12, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
