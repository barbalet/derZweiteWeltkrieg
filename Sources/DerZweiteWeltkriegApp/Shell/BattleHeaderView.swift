import SwiftUI

struct BattleHeaderView: View {
    @ObservedObject var controller: GameController

    var body: some View {
        BattleHeaderPanel {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(controller.isDeploymentMode ? "derZweiteWeltkrieg Deployment" : "derZweiteWeltkrieg Operations Map")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    if let configuration = controller.currentBattleConfiguration,
                       let playerArmy = controller.armyReference(id: configuration.playerArmyID),
                       let aiArmy = controller.armyReference(id: configuration.aiArmyID) {
                        Text("\(playerArmy.displayName) vs \(aiArmy.displayName) • \(controller.pointsLimit) pt cap")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(BattlePalette.missionHighlight)
                    }
                    if controller.isDeploymentMode {
                        Text("Deployment staging • Arrange Player 1 before Turn \(controller.game.turnNumber) begins")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.90))
                    } else {
                        Text("Turn \(controller.game.turnNumber) • \(controller.game.activePlayerName) • \(controller.game.phaseName)")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.90))
                    }
                    Text("\(controller.mission.name) • \(controller.mission.scoreLine)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(BattlePalette.missionHighlight)
                    Text(statusLine)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.84))
                }

                Spacer()

                HStack(spacing: 10) {
                    TextField("Seed", text: $controller.seedText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 110)

                    Button("Setup") {
                        controller.returnToSetup()
                    }
                    .battleSecondaryButton()

                    Button("Restart") {
                        controller.reset()
                    }
                    .battleSecondaryButton()
                    .keyboardShortcut("r", modifiers: [.command])

                    Button("Save") {
                        controller.saveBattleToJSON()
                    }
                    .battleSecondaryButton()

                    Button("Load") {
                        controller.loadBattleFromJSON()
                    }
                    .battleSecondaryButton()

                    if controller.isDeploymentMode {
                        Button("Begin Battle") {
                            controller.beginBattle()
                        }
                        .battlePrimaryButton()
                        .keyboardShortcut(.return, modifiers: [.command])
                    } else {
                        Button("Next Phase") {
                            controller.advancePhase()
                        }
                        .battlePrimaryButton()
                        .keyboardShortcut("n", modifiers: [.command])
                        .disabled(controller.hasPendingDecision || !controller.isHumanTurn || controller.isAITurnInProgress)
                    }
                }
            }
        }
    }

    private var statusLine: String {
        if controller.isDeploymentMode {
                return "Drag squads, guns, and vehicles to set their starting positions and facing."
            }
            if controller.isAITurnInProgress {
                return "The opposing force is resolving its turn."
            }
        return controller.mission.leaderLine
    }
}
