import SwiftUI
#if SWIFT_PACKAGE
import DerZweiteWeltkriegCore
#endif

struct BattleControlsSection: View {
    @ObservedObject var controller: GameController
    @Binding var followUpChoice: FollowUpChoice

    var body: some View {
        BattleSidebarSection("Actions") {
            if controller.isDeploymentMode {
                deploymentControls
            } else if let unit = controller.selectedUnit {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Button("Rotate -45°") {
                            controller.rotateSelected(by: -45)
                        }
                        .battleSecondaryButton()

                        Button("Rotate +45°") {
                            controller.rotateSelected(by: 45)
                        }
                        .battleSecondaryButton()
                    }

                    Toggle("Manual Cover", isOn: Binding(
                        get: { unit.inCover },
                        set: { controller.toggleCover($0) }
                    ))

                    Toggle("Hull Down", isOn: Binding(
                        get: { unit.hullDown },
                        set: { controller.toggleHullDown($0) }
                    ))

                    if unit.mixedProfiles {
                        casualtyPrioritySection(for: unit)
                    }

                    if unit.smokeAvailable {
                        Button("Use Smoke") {
                            controller.useSmoke()
                        }
                        .battleSecondaryButton()
                        .keyboardShortcut("m", modifiers: [.command])
                    }

                    if unit.kind == TE_UNIT_INFANTRY && !unit.embarked {
                        ForEach(controller.eligibleEmbarkTransports(for: unit)) { transport in
                            Button("Embark \(transport.name)") {
                                controller.embarkSelected(into: transport.id)
                            }
                            .battleSecondaryButton()
                            .disabled(controller.game.phase != TE_PHASE_MOVEMENT)
                        }
                    }

                    if unit.transportCapacity > 0 && unit.embarkedUnitID > 0 {
                        Button("Disembark Passenger") {
                            controller.disembarkSelected()
                        }
                        .battleSecondaryButton()
                        .disabled(controller.game.phase != TE_PHASE_MOVEMENT)
                        .keyboardShortcut("d", modifiers: [.command])

                        Button("Passenger Fire Target") {
                            controller.firePassengerSelected()
                        }
                        .battleSecondaryButton()
                        .disabled(!controller.canFirePassenger(from: unit))
                        .keyboardShortcut("f", modifiers: [.command])
                    }

                    if unit.kind == TE_UNIT_VEHICLE {
                        Button("Tank Shock Target") {
                            controller.tankShockSelected()
                        }
                        .battleSecondaryButton()
                        .disabled(!(controller.game.phase == TE_PHASE_MOVEMENT && controller.selectedTarget != nil))
                        .keyboardShortcut("t", modifiers: [.command])
                    }

                    Divider()

                    Button("Shoot Target") {
                        controller.shootSelected()
                    }
                    .battlePrimaryButton()
                    .disabled(!(unit.canShootNow && controller.selectedTarget != nil))
                    .keyboardShortcut("s", modifiers: [.command])

                    Picker("Assault Follow-up", selection: $followUpChoice) {
                        ForEach(FollowUpChoice.allCases) { choice in
                            Text(choice.rawValue).tag(choice)
                        }
                    }
                    .pickerStyle(.segmented)

                    Button("Assault Target") {
                        controller.assaultSelected(followUp: followUpChoice)
                    }
                    .battleSecondaryButton()
                    .disabled(!(unit.canAssaultNow && controller.selectedTarget != nil))
                    .keyboardShortcut("a", modifiers: [.command])
                }
                .disabled(controller.hasPendingDecision)
            }
        }
    }

    private var deploymentControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Drag your units on the board to set their starting positions. Rotation here only changes the way the unit will face when play begins.")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(BattlePalette.sidebarSecondaryText)

            if controller.selectedUnit != nil {
                HStack {
                    Button("Rotate -45°") {
                        controller.rotateSelected(by: -45)
                    }
                    .battleSecondaryButton()

                    Button("Rotate +45°") {
                        controller.rotateSelected(by: 45)
                    }
                    .battleSecondaryButton()
                }
            }

            Button("Begin Battle") {
                controller.beginBattle()
            }
            .battlePrimaryButton()
        }
    }

    private func casualtyPrioritySection(for unit: UnitSnapshot) -> some View {
        let groups = controller.selectedUnitProfileGroups.filter { $0.models > 0 }

        return VStack(alignment: .leading, spacing: 8) {
            Text("Casualty Priority")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
            Text("Choose which live profile group should absorb mixed-profile casualties first. Auto keeps the default low-toughness screening behavior.")
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(BattlePalette.sidebarSecondaryText)

            Button("Auto") {
                controller.setPreferredCasualtyGroup(nil)
            }
            .battlePrimaryButton(tint: groups.contains(where: { $0.preferredCasualtyGroup }) ? BattlePalette.neutralButtonTint : BattlePalette.selectedButtonTint)

            ForEach(groups) { group in
                VStack(alignment: .leading, spacing: 3) {
                    Button(group.name) {
                        controller.setPreferredCasualtyGroup(group.id)
                    }
                    .battlePrimaryButton(tint: group.preferredCasualtyGroup ? BattlePalette.selectedButtonTint : BattlePalette.neutralButtonTint)

                    Text(group.summaryLine)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(BattlePalette.sidebarSecondaryText)
                }
            }

            if groups.isEmpty {
                Text("\(unit.name) has no live profile groups left to prioritize.")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(BattlePalette.sidebarSecondaryText)
            }
        }
    }
}
