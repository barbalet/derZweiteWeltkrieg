import SwiftUI

struct BattleArmiesSection: View {
    @ObservedObject var controller: GameController

    var body: some View {
        BattleSidebarSection("Matchup") {
            if let configuration = controller.currentBattleConfiguration,
               let playerArmy = controller.armyReference(id: configuration.playerArmyID),
               let aiArmy = controller.armyReference(id: configuration.aiArmyID) {
                Text(controller.isDeploymentMode ? "Your force is locked in. Drag Player 1’s squads, guns, and vehicles on the board to deploy them before the battle starts." : "You built the left-side force. The computer drafted the opposing force and will take over automatically whenever Player 2 becomes active.")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(BattlePalette.sidebarSecondaryText)

                rosterCard(
                    title: "Player 1 • \(playerArmy.displayName)",
                    armyID: configuration.playerArmyID,
                    selections: configuration.playerSelections,
                    accent: BattlePalette.playerOneAccent,
                    points: controller.points(for: playerArmy.preset, selections: configuration.playerSelections)
                )

                rosterCard(
                    title: "Player 2 • \(aiArmy.displayName)",
                    armyID: configuration.aiArmyID,
                    selections: configuration.aiSelections,
                    accent: BattlePalette.playerTwoAccent,
                    points: controller.points(for: aiArmy.preset, selections: configuration.aiSelections)
                )

                if !controller.setupMessage.isEmpty {
                    Text(controller.setupMessage)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(BattlePalette.sidebarSecondaryText)
                }
            } else {
                Text("No operation is loaded yet.")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(BattlePalette.sidebarSecondaryText)
            }
        }
    }

    private func rosterCard(title: String, armyID: String, selections: [ArmyListSelection], accent: Color, points: Int) -> some View {
        BattleTintedPanel(accent: accent) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Text("\(points) pts • \(selections.reduce(0) { $0 + $1.count }) selections")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(accent)

                ForEach(Array(controller.selectionDetails(for: armyID, selections: selections).enumerated()), id: \.offset) { _, detail in
                    let unit = detail.0
                    let count = detail.1
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(count)x \(unit.name)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                        Text(unit.unit.summaryLine)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(BattlePalette.sidebarSecondaryText)
                    }
                    .padding(.vertical, 1)
                }
            }
        }
    }
}
