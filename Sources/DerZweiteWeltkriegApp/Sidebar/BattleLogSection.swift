import SwiftUI

struct BattleLogSection: View {
    let lines: [String]

    var body: some View {
        BattleSidebarSection("Battle Log") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 2)
                }
            }
        }
    }
}
