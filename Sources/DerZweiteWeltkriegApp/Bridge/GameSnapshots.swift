import Foundation
import CoreGraphics
#if SWIFT_PACKAGE
import DerZweiteWeltkriegCore
#endif

enum FollowUpChoice: String, CaseIterable, Identifiable {
    case advance = "Advance"
    case consolidate = "Consolidate"

    var id: String { rawValue }

    var cValue: follow_up_t {
        switch self {
        case .advance:
            return DZW_FOLLOW_UP_ADVANCE
        case .consolidate:
            return DZW_FOLLOW_UP_CONSOLIDATE
        }
    }
}

struct GameSnapshot {
    let turnNumber: Int
    let activePlayer: player_t
    let phase: phase_t

    var phaseName: String {
        switch phase {
        case DZW_PHASE_MOVEMENT:
            return "Movement"
        case DZW_PHASE_SHOOTING:
            return "Shooting"
        case DZW_PHASE_ASSAULT:
            return "Assault"
        default:
            return "Unknown"
        }
    }

    var activePlayerName: String {
        activePlayer == DZW_PLAYER_ONE ? "Player 1" : "Player 2"
    }
}

struct ObjectiveSnapshot: Identifiable {
    let id: Int
    let name: String
    let x: CGFloat
    let y: CGFloat
    let radius: CGFloat
    let controller: player_t?
    let playerOnePresence: Int
    let playerTwoPresence: Int

    init(raw: objective_view_t) {
        id = Int(raw.id)
        name = raw.name.map { String(cString: $0) } ?? "Objective"
        x = CGFloat(raw.x)
        y = CGFloat(raw.y)
        radius = CGFloat(raw.radius)
        controller = raw.controller == DZW_PLAYER_NONE ? nil : raw.controller
        playerOnePresence = Int(raw.player_one_presence)
        playerTwoPresence = Int(raw.player_two_presence)
    }

    var isContested: Bool {
        playerOnePresence > 0 && playerTwoPresence > 0 && playerOnePresence == playerTwoPresence
    }

    var statusText: String {
        if isContested {
            return "Contested \(playerOnePresence)-\(playerTwoPresence)"
        }
        if let controller {
            return controller == DZW_PLAYER_ONE
                ? "Player 1 controls (\(playerOnePresence)-\(playerTwoPresence))"
                : "Player 2 controls (\(playerTwoPresence)-\(playerOnePresence))"
        }
        return "Unclaimed"
    }
}

struct MissionSnapshot {
    let name: String
    let targetScore: Int
    let playerOneScore: Int
    let playerTwoScore: Int
    let winner: player_t?

    init(
        name: String = "Bocage Breakout",
        targetScore: Int = 8,
        playerOneScore: Int = 0,
        playerTwoScore: Int = 0,
        winner: player_t? = nil
    ) {
        self.name = name
        self.targetScore = targetScore
        self.playerOneScore = playerOneScore
        self.playerTwoScore = playerTwoScore
        self.winner = winner
    }

    init(raw: mission_view_t) {
        name = raw.name.map { String(cString: $0) } ?? "Mission"
        targetScore = Int(raw.target_score)
        playerOneScore = Int(raw.player_one_score)
        playerTwoScore = Int(raw.player_two_score)
        winner = raw.winner == DZW_PLAYER_NONE ? nil : raw.winner
    }

    var scoreLine: String {
        "P1 \(playerOneScore) - \(playerTwoScore) P2"
    }

    var leaderLine: String {
        if let winnerName {
            return "\(winnerName) wins the scenario"
        }
        if playerOneScore == playerTwoScore {
            return "Score tied"
        }
        let lead = abs(playerOneScore - playerTwoScore)
        return playerOneScore > playerTwoScore
            ? "Player 1 leads by \(lead)"
            : "Player 2 leads by \(lead)"
    }

    var winnerName: String? {
        if winner == DZW_PLAYER_ONE {
            return "Player 1"
        }
        if winner == DZW_PLAYER_TWO {
            return "Player 2"
        }
        return nil
    }
}

struct ArmyRosterUnitSnapshot: Identifiable {
    let id: Int
    let name: String
    let kind: unit_kind_t
    let models: Int
    let woundsPerModel: Int
    let totalWounds: Int
    let mixedProfiles: Bool
    let transportCapacity: Int
    let frontArmour: Int
    let sideArmour: Int
    let rearArmour: Int
    let fast: Bool
    let recon: Bool
    let openTopped: Bool
    let primaryWeaponName: String
    let embarkedUnitName: String?
    let embarkedTransportName: String?

    init(index: Int, raw: army_roster_unit_view_t) {
        id = index
        name = raw.name.map { String(cString: $0) } ?? "Unit"
        kind = raw.kind
        models = Int(raw.models)
        woundsPerModel = Int(raw.wounds_per_model)
        totalWounds = Int(raw.total_wounds)
        mixedProfiles = raw.mixed_profiles
        transportCapacity = Int(raw.transport_capacity)
        frontArmour = Int(raw.front_armour)
        sideArmour = Int(raw.side_armour)
        rearArmour = Int(raw.rear_armour)
        fast = raw.fast
        recon = raw.recon
        openTopped = raw.open_topped
        primaryWeaponName = raw.primary_weapon_name.map { String(cString: $0) } ?? "Unarmed"
        embarkedUnitName = raw.embarked_unit_name.map { String(cString: $0) }
        embarkedTransportName = raw.embarked_transport_name.map { String(cString: $0) }
    }

    var summaryLine: String {
        if kind == DZW_UNIT_ASSAULT_GUN {
            return "Assault gun AV \(frontArmour)/\(sideArmour)/\(rearArmour) • \(primaryWeaponName)"
        }
        if kind == DZW_UNIT_VEHICLE {
            var tags: [String] = ["AV \(frontArmour)/\(sideArmour)/\(rearArmour)"]
            if transportCapacity > 0 {
                tags.append("Transport \(transportCapacity)")
            }
            if fast {
                tags.append("Fast")
            }
            if recon {
                tags.append("Recon")
            }
            if openTopped {
                tags.append("Open-topped")
            }
            tags.append(primaryWeaponName)
            if let embarkedUnitName, !embarkedUnitName.isEmpty {
                tags.append("Starts with \(embarkedUnitName) embarked")
            }
            return tags.joined(separator: " • ")
        }

        var tags: [String] = ["\(models) models"]
        if mixedProfiles {
            tags.append("Mixed profiles")
        } else {
            tags.append("W \(woundsPerModel)")
        }
        tags.append("\(totalWounds) total wounds")
        tags.append(primaryWeaponName)
        if let embarkedTransportName, !embarkedTransportName.isEmpty {
            tags.append("Starts in \(embarkedTransportName)")
        }
        return tags.joined(separator: " • ")
    }
}

struct ArmyForceOptionSnapshot: Identifiable, Hashable {
    let id: Int
    let name: String
    let summary: String

    init(raw: army_force_view_t) {
        id = Int(raw.id)
        name = raw.name.map { String(cString: $0) } ?? "Preset"
        summary = raw.summary.map { String(cString: $0) } ?? ""
    }
}

struct VehicleWeaponOptionSnapshot: Identifiable, Hashable {
    let id: Int
    let name: String

    init(raw: vehicle_weapon_view_t) {
        id = Int(raw.weapon_index)
        name = raw.name.map { String(cString: $0) } ?? "Weapon"
    }
}

struct ProfileGroupSnapshot: Identifiable, Hashable {
    let id: Int
    let name: String
    let models: Int
    let woundsPerModel: Int
    let leadModelWounds: Int
    let weaponSkill: Int
    let ballisticSkill: Int
    let strength: Int
    let toughness: Int
    let initiative: Int
    let attacks: Int
    let leadership: Int
    let save: Int
    let preferredCasualtyGroup: Bool
    let pendingAllocatedHits: Int

    init(raw: profile_group_view_t) {
        id = Int(raw.index)
        name = raw.name.map { String(cString: $0) } ?? "Profile Group"
        models = Int(raw.models)
        woundsPerModel = Int(raw.wounds_per_model)
        leadModelWounds = Int(raw.lead_model_wounds)
        weaponSkill = Int(raw.weapon_skill)
        ballisticSkill = Int(raw.ballistic_skill)
        strength = Int(raw.strength)
        toughness = Int(raw.toughness)
        initiative = Int(raw.initiative)
        attacks = Int(raw.attacks)
        leadership = Int(raw.leadership)
        save = Int(raw.save)
        preferredCasualtyGroup = raw.preferred_casualty_group
        pendingAllocatedHits = Int(raw.pending_allocated_hits)
    }

    var summaryLine: String {
        var parts = ["\(models) models"]
        if woundsPerModel > 1 {
            parts.append("W \(woundsPerModel)")
            if leadModelWounds > 0 && leadModelWounds < woundsPerModel {
                parts.append("Lead \(leadModelWounds)/\(woundsPerModel)")
            }
        }
        parts.append("WS \(weaponSkill)")
        parts.append("BS \(ballisticSkill)")
        parts.append("S \(strength)")
        parts.append("T \(toughness)")
        parts.append("I \(initiative)")
        parts.append("A \(attacks)")
        parts.append("Ld \(leadership)")
        if save > 0 {
            parts.append("Sv \(save)+")
        }
        return parts.joined(separator: " • ")
    }
}

struct PendingHitAllocationChoiceSnapshot {
    let chooserOwner: player_t?
    let attackerName: String
    let sourceName: String
    let targetID: Int
    let targetName: String
    let hitsAssigned: Int
    let hitsRemaining: Int
    let totalHits: Int

    init?(handle: OpaquePointer) {
        let raw = game_pending_hit_allocation_view(handle)
        guard raw.active else {
            return nil
        }

        chooserOwner = raw.chooser_owner == DZW_PLAYER_NONE ? nil : raw.chooser_owner
        attackerName = raw.attacker_name.map { String(cString: $0) } ?? "Attacker"
        sourceName = raw.source_name.map { String(cString: $0) } ?? "Weapon"
        targetID = Int(raw.target_id)
        targetName = raw.target_name.map { String(cString: $0) } ?? "Mixed-profile Unit"
        hitsAssigned = Int(raw.hits_assigned)
        hitsRemaining = Int(raw.hits_remaining)
        totalHits = Int(raw.total_hits)
    }

    var chooserOwnerName: String {
        if chooserOwner == DZW_PLAYER_ONE {
            return "Player 1"
        }
        if chooserOwner == DZW_PLAYER_TWO {
            return "Player 2"
        }
        return "Defender"
    }
}

struct PendingWeaponDestroyChoiceSnapshot {
    let chooserID: Int
    let chooserOwner: player_t?
    let chooserName: String
    let targetID: Int
    let targetName: String
    let options: [VehicleWeaponOptionSnapshot]

    init?(handle: OpaquePointer) {
        let raw = game_pending_weapon_destroy_view(handle)
        guard raw.active else {
            return nil
        }

        chooserID = Int(raw.chooser_id)
        chooserOwner = raw.chooser_owner == DZW_PLAYER_NONE ? nil : raw.chooser_owner
        chooserName = raw.chooser_name.map { String(cString: $0) } ?? "Attacker"
        targetID = Int(raw.target_id)
        targetName = raw.target_name.map { String(cString: $0) } ?? "Vehicle"
        options = (0..<Int(game_pending_weapon_destroy_option_count(handle))).map { index in
            VehicleWeaponOptionSnapshot(raw: game_pending_weapon_destroy_option_view(handle, Int32(index)))
        }
    }

    var chooserOwnerName: String {
        if chooserOwner == DZW_PLAYER_ONE {
            return "Player 1"
        }
        if chooserOwner == DZW_PLAYER_TWO {
            return "Player 2"
        }
        return "Attacker"
    }
}

struct ArmyRosterPreviewSnapshot {
    let army: army_list_t
    let forceIndex: Int
    let forceName: String
    let forceSummary: String
    let units: [ArmyRosterUnitSnapshot]

    var unitCount: Int {
        units.count
    }

    var totalModels: Int {
        units.reduce(0) { $0 + max($1.models, 1) }
    }

    var infantryCount: Int {
        units.filter { $0.kind == DZW_UNIT_INFANTRY }.count
    }

    var vehicleCount: Int {
        units.filter { $0.kind == DZW_UNIT_VEHICLE }.count
    }

    var assaultGunCount: Int {
        units.filter { $0.kind == DZW_UNIT_ASSAULT_GUN }.count
    }

    var summaryLine: String {
        var parts = ["\(unitCount) units", "\(totalModels) models"]
        if infantryCount > 0 {
            parts.append("\(infantryCount) infantry")
        }
        if vehicleCount > 0 {
            parts.append("\(vehicleCount) vehicles")
        }
        if assaultGunCount > 0 {
            parts.append("\(assaultGunCount) assault guns")
        }
        return parts.joined(separator: " • ")
    }
}

struct ZoneSnapshot: Identifiable {
    let id: Int
    let name: String
    let kind: terrain_kind_t
    let rect: CGRect
    let coverSave: Int
    let blocksLineOfSight: Bool
    let hullDown: Bool

    init(raw: zone_view_t) {
        id = Int(raw.id)
        name = raw.name.map { String(cString: $0) } ?? "Zone"
        kind = raw.kind
        rect = CGRect(
            x: CGFloat(raw.rect.x),
            y: CGFloat(raw.rect.y),
            width: CGFloat(raw.rect.width),
            height: CGFloat(raw.rect.height)
        )
        coverSave = Int(raw.cover_save)
        blocksLineOfSight = raw.blocks_line_of_sight
        hullDown = raw.hull_down
    }
}

struct UnitSnapshot: Identifiable {
    let id: Int
    let name: String
    let owner: player_t
    let kind: unit_kind_t
    let x: CGFloat
    let y: CGFloat
    let facingDegrees: CGFloat
    let footprintRadius: CGFloat
    let models: Int
    let woundsPerModel: Int
    let leadModelWounds: Int
    let totalWoundsRemaining: Int
    let mixedProfiles: Bool
    let startingModels: Int
    let weaponSkill: Int
    let ballisticSkill: Int
    let strength: Int
    let toughness: Int
    let initiative: Int
    let attacks: Int
    let leadership: Int
    let save: Int
    let frontArmour: Int
    let sideArmour: Int
    let rearArmour: Int
    let fast: Bool
    let recon: Bool
    let openTopped: Bool
    let inCover: Bool
    let hullDown: Bool
    let smokeAvailable: Bool
    let smokeActive: Bool
    let movedThisTurn: Bool
    let canMoveNow: Bool
    let shotThisTurn: Bool
    let assaultedThisTurn: Bool
    let canShootNow: Bool
    let canAssaultNow: Bool
    let lockedInAssault: Bool
    let pinned: Bool
    let fallingBack: Bool
    let embarked: Bool
    let embarkedUnitID: Int
    let embarkedInTransportID: Int
    let transportCapacity: Int
    let destroyed: Bool

    init(raw: unit_view_t) {
        id = Int(raw.id)
        name = raw.name.map { String(cString: $0) } ?? "Unit"
        owner = raw.owner
        kind = raw.kind
        x = CGFloat(raw.x)
        y = CGFloat(raw.y)
        facingDegrees = CGFloat(raw.facing_degrees)
        footprintRadius = CGFloat(raw.footprint_radius)
        models = Int(raw.models)
        woundsPerModel = Int(raw.wounds_per_model)
        leadModelWounds = Int(raw.lead_model_wounds)
        totalWoundsRemaining = Int(raw.total_wounds_remaining)
        mixedProfiles = raw.mixed_profiles
        startingModels = Int(raw.starting_models)
        weaponSkill = Int(raw.weapon_skill)
        ballisticSkill = Int(raw.ballistic_skill)
        strength = Int(raw.strength)
        toughness = Int(raw.toughness)
        initiative = Int(raw.initiative)
        attacks = Int(raw.attacks)
        leadership = Int(raw.leadership)
        save = Int(raw.save)
        frontArmour = Int(raw.front_armour)
        sideArmour = Int(raw.side_armour)
        rearArmour = Int(raw.rear_armour)
        fast = raw.fast
        recon = raw.recon
        openTopped = raw.open_topped
        inCover = raw.in_cover
        hullDown = raw.hull_down
        smokeAvailable = raw.smoke_available
        smokeActive = raw.smoke_active
        movedThisTurn = raw.moved_this_turn
        canMoveNow = raw.can_move_now
        shotThisTurn = raw.shot_this_turn
        assaultedThisTurn = raw.assaulted_this_turn
        canShootNow = raw.can_shoot_now
        canAssaultNow = raw.can_assault_now
        lockedInAssault = raw.locked_in_assault
        pinned = raw.pinned
        fallingBack = raw.falling_back
        embarked = raw.embarked
        embarkedUnitID = Int(raw.embarked_unit_id)
        embarkedInTransportID = Int(raw.embarked_in_transport_id)
        transportCapacity = Int(raw.transport_capacity)
        destroyed = raw.destroyed
    }

    var ownerName: String {
        owner == DZW_PLAYER_ONE ? "Player 1" : "Player 2"
    }

    var usesVehicleRules: Bool {
        kind == DZW_UNIT_VEHICLE || kind == DZW_UNIT_ASSAULT_GUN
    }

    var isMultiWound: Bool {
        woundsPerModel > 1
    }

    var hasPartialLeadingWound: Bool {
        isMultiWound && models > 0 && leadModelWounds > 0 && leadModelWounds < woundsPerModel
    }

    var shortStatus: String {
        if destroyed { return "Destroyed" }
        if embarked { return "Embarked" }
        if fallingBack { return "Falling Back" }
        if pinned { return "Pinned" }
        if lockedInAssault { return "Locked" }
        return "Ready"
    }

    var detailSummary: String {
        if kind == DZW_UNIT_ASSAULT_GUN {
            return "Assault gun WS \(weaponSkill) S \(strength) I \(initiative) A \(attacks) • AV \(frontArmour)/\(sideArmour)/\(rearArmour)"
        }
        if kind == DZW_UNIT_VEHICLE {
            let transportText = transportCapacity > 0 ? " • Transport \(transportCapacity)" : ""
            return "AV \(frontArmour)/\(sideArmour)/\(rearArmour)\(transportText)"
        }
        if mixedProfiles {
            return "Mixed profile unit • \(models) models • \(totalWoundsRemaining) total wounds"
        }
        return "WS \(weaponSkill) BS \(ballisticSkill) S \(strength) T \(toughness) W \(woundsPerModel) I \(initiative) A \(attacks) Ld \(leadership) Sv \(save)+"
    }
}
