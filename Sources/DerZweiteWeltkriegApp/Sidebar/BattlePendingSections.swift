import SwiftUI

struct BattlePendingWeaponDestroySection: View {
    @ObservedObject var controller: GameController
    let pendingChoice: PendingWeaponDestroyChoiceSnapshot

    var body: some View {
        BattleSidebarSection("Pending Damage") {
            Text("\(pendingChoice.chooserOwnerName) must resolve a Weapon Destroyed result before play continues.")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(BattlePalette.sidebarSecondaryText)
            Text("\(pendingChoice.chooserName) chooses which weapon \(pendingChoice.targetName) loses.")
                .font(.system(size: 13, weight: .semibold, design: .rounded))

            ForEach(pendingChoice.options) { option in
                Button("Destroy \(option.name)") {
                    controller.resolvePendingWeaponDestroy(option)
                }
                .battlePrimaryButton()
            }
        }
    }
}

struct BattlePendingAllocationSection: View {
    @ObservedObject var controller: GameController
    let pendingAllocation: PendingHitAllocationChoiceSnapshot

    var body: some View {
        BattleSidebarSection("Pending Allocation") {
            Text("\(pendingAllocation.chooserOwnerName) must assign the mixed-profile hits before play continues.")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(BattlePalette.sidebarSecondaryText)
            Text("\(pendingAllocation.attackerName)'s \(pendingAllocation.sourceName) has \(pendingAllocation.hitsRemaining) of \(pendingAllocation.totalHits) hit\(pendingAllocation.totalHits == 1 ? "" : "s") left to allocate on \(pendingAllocation.targetName).")
                .font(.system(size: 13, weight: .semibold, design: .rounded))

            ForEach(controller.pendingHitAllocationGroups.filter { $0.models > 0 }) { group in
                VStack(alignment: .leading, spacing: 4) {
                    Button("Assign to \(group.name)") {
                        controller.resolvePendingHitAllocation(group)
                    }
                    .battlePrimaryButton()

                    Text("Assigned hits: \(group.pendingAllocatedHits) • \(group.summaryLine)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(BattlePalette.sidebarSecondaryText)
                }
            }

            Text("Assigned so far: \(pendingAllocation.hitsAssigned)/\(pendingAllocation.totalHits)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(BattlePalette.sidebarSecondaryText)
        }
    }
}
