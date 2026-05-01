import SwiftUI

struct BattleObjectivesSection: View {
    @ObservedObject var controller: GameController

    var body: some View {
        BattleSidebarSection("Objectives") {
            Text("Score 1 VP per secured objective at the end of each player's turn. First to \(controller.mission.targetScore) wins.")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(BattlePalette.sidebarSecondaryText)

            ForEach(controller.objectiveStates) { objective in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(objective.name)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                        Spacer()
                        Text(objective.statusText)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(objective.isContested ? BattlePalette.sidebarWarningText : BattlePalette.sidebarSecondaryText)
                    }
                    Text("Control P1 \(objective.playerOnePresence) • P2 \(objective.playerTwoPresence)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(BattlePalette.sidebarSecondaryText)
                }
                .padding(.vertical, 2)
            }
        }
    }
}
