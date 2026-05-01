import SwiftUI

struct SkirmishSetupView: View {
    @ObservedObject var controller: GameController

    var body: some View {
        ZStack {
            BattlePalette.shellBackground
                .ignoresSafeArea()

            VStack(spacing: 18) {
                BattleHeaderPanel {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("derZweiteWeltkrieg Operation Setup")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Build an Allied or Axis force to a shared points cap, let the computer draft from the opposing side, then deploy your units before play begins.")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.86))
                    }
                }

                HStack(alignment: .top, spacing: 18) {
                    BattleSidebarPanel {
                        VStack(alignment: .leading, spacing: 16) {
                            BattleSidebarSection("Your Nation") {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Nation")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    Picker("Nation", selection: Binding(
                                        get: { controller.playerOneArmyID },
                                        set: { controller.updatePlayerArmy(id: $0) }
                                    )) {
                                        ForEach(controller.armyReferences) { reference in
                                            Text("\(reference.displayName) (\(reference.allegiance.rawValue))").tag(reference.id)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(BattlePalette.playerOneAccent)

                                    Stepper(value: Binding(
                                        get: { controller.pointsLimit },
                                        set: { controller.updatePointsLimit($0) }
                                    ), in: 250...1500, step: 50) {
                                        Text("Points Cap: \(controller.pointsLimit)")
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    }

                                    Text("Current Draft: \(controller.playerSelectedPoints) pts • \(controller.playerSelectedUnitCount) unit\(controller.playerSelectedUnitCount == 1 ? "" : "s")")
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(controller.playerSelectedPoints > controller.pointsLimit ? BattlePalette.sidebarWarningText : BattlePalette.sidebarSecondaryText)
                                }
                            }

                            BattleSidebarSection("Platoon Draft") {
                                ForEach(controller.playerCatalogUnits) { unit in
                                    BattleTintedPanel(accent: BattlePalette.playerOneAccent) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack(alignment: .top) {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(unit.name)
                                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                                    Text("\(unit.points) pts each • max \(unit.maxCount)")
                                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                                        .foregroundStyle(BattlePalette.sidebarSecondaryText)
                                                }
                                                Spacer()
                                                Stepper(value: Binding(
                                                    get: { controller.selectedPlayerCount(for: unit.id) },
                                                    set: { controller.updatePlayerUnitCount(catalogID: unit.id, count: $0) }
                                                ), in: 0...unit.maxCount) {
                                                    Text("\(controller.selectedPlayerCount(for: unit.id))")
                                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                                        .frame(minWidth: 18, alignment: .trailing)
                                                }
                                                .labelsHidden()
                                            }

                                            Text(unit.unit.summaryLine)
                                                .font(.system(size: 11, design: .monospaced))
                                                .foregroundStyle(BattlePalette.sidebarSecondaryText)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    BattleSidebarPanel {
                        VStack(alignment: .leading, spacing: 16) {
                            BattleSidebarSection("Opponent AI") {
                                if let plan = controller.currentOpponentPlan {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("\(plan.army.displayName) \(plan.army.allegiance.rawValue) • \(plan.points) pts")
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                        Text("The computer drafts from the opposing side to match your current total as closely as possible while staying inside the cap.")
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(BattlePalette.sidebarSecondaryText)

                                        ForEach(controller.selectionDetails(for: plan.army.id, selections: plan.selections), id: \.0.id) { unit, count in
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("\(count)x \(unit.name)")
                                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                                Text(unit.unit.summaryLine)
                                                    .font(.system(size: 11, design: .monospaced))
                                                    .foregroundStyle(BattlePalette.sidebarSecondaryText)
                                            }
                                        }
                                    }
                                } else {
                                    Text("Add squads, guns, and vehicles to your force and the computer will draft a matched opposing force.")
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundStyle(BattlePalette.sidebarSecondaryText)
                                }
                            }

                            BattleSidebarSection("Operation Actions") {
                                VStack(alignment: .leading, spacing: 10) {
                                    Button("Deploy Force") {
                                        controller.startBattleFromSetup()
                                    }
                                    .battlePrimaryButton()
                                    .accessibilityIdentifier("deploy-force-button")
                                    .disabled(controller.playerSelectedPoints == 0 || controller.playerSelectedPoints > controller.pointsLimit || controller.currentOpponentPlan == nil)

                                    if controller.currentBattleConfiguration != nil {
                                        Button(controller.resumeBattleButtonTitle) {
                                            controller.resumeCurrentBattle()
                                        }
                                        .battleSecondaryButton()
                                    }

                                    Button("Load Saved Operation") {
                                        controller.loadBattleFromJSON()
                                    }
                                    .battleSecondaryButton()
                                }
                            }

                            if !controller.setupMessage.isEmpty {
                                BattleSidebarSection("Status") {
                                    Text(controller.setupMessage)
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundStyle(BattlePalette.sidebarPrimaryText)
                                }
                            }
                        }
                    }
                    .frame(width: 360)
                }
            }
            .padding(18)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("setup-screen")
    }
}
