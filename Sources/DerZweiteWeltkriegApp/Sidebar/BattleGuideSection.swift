import SwiftUI

struct BattleGuideSection: View {
    var body: some View {
        BattleSidebarSection("Demo Guide") {
            ForEach(BattleDisplayLabels.demoGuide, id: \.0) { step, text in
                HStack(alignment: .top, spacing: 10) {
                    Text(step)
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Circle().fill(BattlePalette.legendBadgeGold))
                    Text(text)
                        .font(.system(size: 12, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
