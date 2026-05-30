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
    let ruleset: dzw_ruleset_t

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

    var rulesetName: String {
        String(cString: game_ruleset_name(ruleset))
    }

    var usesLegacyPhaseFlow: Bool {
        ruleset == DZW_RULESET_FIXED_PHASES
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
    let movedDistance: CGFloat
    let canMoveNow: Bool
    let shotThisTurn: Bool
    let assaultedThisTurn: Bool
    let canShootNow: Bool
    let canAssaultNow: Bool
    let lockedInAssault: Bool
    let pinned: Bool
    let fallingBack: Bool
    let currentOrder: dzw_order_t
    let actedThisTurn: Bool
    let retainedOrder: Bool
    let pinCount: Int
    let moraleQuality: dzw_morale_quality_t
    let lastOrderTestResult: dzw_order_test_result_t
    let lastOrderTestRoll: Int
    let lastOrderTestTarget: Int
    let lastOrderTestPinModifier: Int
    let lastOrderTestOfficerModifier: Int
    let lastFubarResult: dzw_fubar_result_t
    let lastFubarTargetID: Int
    let downOrderActive: Bool
    let ambushOrderActive: Bool
    let defensiveToHitModifier: Int
    let lastRallyRoll: Int
    let lastRallyPinsRemoved: Int
    let advanceMoveAllowance: CGFloat
    let runMoveAllowance: CGFloat
    let assaultMoveAllowance: CGFloat
    let currentOrderMoveAllowance: CGFloat
    let reverseMoveAllowance: CGFloat
    let canReverseNow: Bool
    let pivotBudget: Int
    let pivotCountUsed: Int
    let lastReverseDistance: CGFloat
    let movementRestrictionReason: String?
    let lastShootingTargetID: Int
    let lastShootingRange: CGFloat
    let lastShootingTargetReaction: dzw_target_reaction_t
    let lastShootingRangeChecked: Bool
    let lastShootingHitRollsResolved: Bool
    let lastShootingDamageResolved: Bool
    let lastShootingBaseToHit: Int
    let lastShootingPointBlankModifier: Int
    let lastShootingPinModifier: Int
    let lastShootingLongRangeModifier: Int
    let lastShootingInexperiencedModifier: Int
    let lastShootingMoveModifier: Int
    let lastShootingDownModifier: Int
    let lastShootingSmallUnitModifier: Int
    let lastShootingCoverModifier: Int
    let lastShootingToHitModifier: Int
    let lastShootingNeededToHit: Int
    let lastShootingDamageValue: Int
    let lastShootingPenetrationModifier: Int
    let lastShootingDamageRoll: Int
    let lastShootingDamageSuccess: Bool
    let lastShootingVehicleArmourModifier: Int
    let lastShootingVehicleLongRangePenalty: Int
    let lastShootingVehicleOpenToppedIndirectModifier: Int
    let lastShootingVehicleDamageClass: dzw_vehicle_damage_class_t
    let lastVehicleDamageTableRoll: Int
    let lastVehicleDamageResult: dzw_vehicle_damage_result_t
    let lastVehicleDamageMoraleRoll: Int
    let lastVehicleDamageMoraleTarget: Int
    let lastVehicleDamageMoraleFailed: Bool
    let lastShootingModelsRemoved: Int
    let lastShootingPinsAdded: Int
    let lastShootingMoraleChecked: Bool
    let lastShootingMoraleRoll: Int
    let lastShootingMoraleTarget: Int
    let lastShootingMoralePinModifier: Int
    let lastShootingMoraleOfficerModifier: Int
    let lastShootingMoraleFailed: Bool
    let embarked: Bool
    let embarkedUnitID: Int
    let embarkedInTransportID: Int
    let transportCapacity: Int
    let destroyed: Bool
    let wrecked: Bool
    let wreckBlocksMovement: Bool
    let lastAssaultTargetID: Int
    let lastAssaultRange: CGFloat
    let lastAssaultTargetReaction: dzw_target_reaction_t
    let lastAssaultAttackerWounds: Int
    let lastAssaultDefenderWounds: Int
    let lastAssaultDrawRounds: Int
    let lastAssaultWinnerID: Int
    let lastAssaultLoserID: Int
    let lastAssaultLoserDestroyed: Bool
    let lastAssaultRegroupDistance: CGFloat
    let lastAssaultVehicleTarget: Bool
    let lastAssaultAntitankEquipped: Bool
    let lastAssaultEnclosedArmourOrderTestRequired: Bool
    let lastAssaultEnclosedArmourOrderTestRoll: Int
    let lastAssaultEnclosedArmourOrderTestTarget: Int
    let lastAssaultEnclosedArmourOrderTestFailed: Bool
    let lastAssaultVehicleDefensiveFireResolved: Bool
    let lastAssaultVehicleHits: Int
    let lastAssaultVehicleDamageValue: Int
    let lastAssaultVehiclePenetrationModifier: Int
    let lastAssaultVehicleDamageRoll: Int
    let lastAssaultVehicleDamageClass: dzw_vehicle_damage_class_t

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
        movedDistance = CGFloat(raw.moved_distance)
        canMoveNow = raw.can_move_now
        shotThisTurn = raw.shot_this_turn
        assaultedThisTurn = raw.assaulted_this_turn
        canShootNow = raw.can_shoot_now
        canAssaultNow = raw.can_assault_now
        lockedInAssault = raw.locked_in_assault
        pinned = raw.pinned
        fallingBack = raw.falling_back
        currentOrder = raw.current_order
        actedThisTurn = raw.acted_this_turn
        retainedOrder = raw.retained_order
        pinCount = Int(raw.pin_count)
        moraleQuality = raw.morale_quality
        lastOrderTestResult = raw.last_order_test_result
        lastOrderTestRoll = Int(raw.last_order_test_roll)
        lastOrderTestTarget = Int(raw.last_order_test_target)
        lastOrderTestPinModifier = Int(raw.last_order_test_pin_modifier)
        lastOrderTestOfficerModifier = Int(raw.last_order_test_officer_modifier)
        lastFubarResult = raw.last_fubar_result
        lastFubarTargetID = Int(raw.last_fubar_target_id)
        downOrderActive = raw.down_order_active
        ambushOrderActive = raw.ambush_order_active
        defensiveToHitModifier = Int(raw.defensive_to_hit_modifier)
        lastRallyRoll = Int(raw.last_rally_roll)
        lastRallyPinsRemoved = Int(raw.last_rally_pins_removed)
        advanceMoveAllowance = CGFloat(raw.advance_move_allowance)
        runMoveAllowance = CGFloat(raw.run_move_allowance)
        assaultMoveAllowance = CGFloat(raw.assault_move_allowance)
        currentOrderMoveAllowance = CGFloat(raw.current_order_move_allowance)
        reverseMoveAllowance = CGFloat(raw.reverse_move_allowance)
        canReverseNow = raw.can_reverse_now
        pivotBudget = Int(raw.pivot_budget)
        pivotCountUsed = Int(raw.pivot_count_used)
        lastReverseDistance = CGFloat(raw.last_reverse_distance)
        movementRestrictionReason = raw.movement_rejection_reason.map { String(cString: $0) }
        lastShootingTargetID = Int(raw.last_shooting_target_id)
        lastShootingRange = CGFloat(raw.last_shooting_range)
        lastShootingTargetReaction = raw.last_shooting_target_reaction
        lastShootingRangeChecked = raw.last_shooting_range_checked
        lastShootingHitRollsResolved = raw.last_shooting_hit_rolls_resolved
        lastShootingDamageResolved = raw.last_shooting_damage_resolved
        lastShootingBaseToHit = Int(raw.last_shooting_base_to_hit)
        lastShootingPointBlankModifier = Int(raw.last_shooting_point_blank_modifier)
        lastShootingPinModifier = Int(raw.last_shooting_pin_modifier)
        lastShootingLongRangeModifier = Int(raw.last_shooting_long_range_modifier)
        lastShootingInexperiencedModifier = Int(raw.last_shooting_inexperienced_modifier)
        lastShootingMoveModifier = Int(raw.last_shooting_move_modifier)
        lastShootingDownModifier = Int(raw.last_shooting_down_modifier)
        lastShootingSmallUnitModifier = Int(raw.last_shooting_small_unit_modifier)
        lastShootingCoverModifier = Int(raw.last_shooting_cover_modifier)
        lastShootingToHitModifier = Int(raw.last_shooting_to_hit_modifier)
        lastShootingNeededToHit = Int(raw.last_shooting_needed_to_hit)
        lastShootingDamageValue = Int(raw.last_shooting_damage_value)
        lastShootingPenetrationModifier = Int(raw.last_shooting_penetration_modifier)
        lastShootingDamageRoll = Int(raw.last_shooting_damage_roll)
        lastShootingDamageSuccess = raw.last_shooting_damage_success
        lastShootingVehicleArmourModifier = Int(raw.last_shooting_vehicle_armour_modifier)
        lastShootingVehicleLongRangePenalty = Int(raw.last_shooting_vehicle_long_range_penalty)
        lastShootingVehicleOpenToppedIndirectModifier = Int(raw.last_shooting_vehicle_open_topped_indirect_modifier)
        lastShootingVehicleDamageClass = raw.last_shooting_vehicle_damage_class
        lastVehicleDamageTableRoll = Int(raw.last_vehicle_damage_table_roll)
        lastVehicleDamageResult = raw.last_vehicle_damage_result
        lastVehicleDamageMoraleRoll = Int(raw.last_vehicle_damage_morale_roll)
        lastVehicleDamageMoraleTarget = Int(raw.last_vehicle_damage_morale_target)
        lastVehicleDamageMoraleFailed = raw.last_vehicle_damage_morale_failed
        lastShootingModelsRemoved = Int(raw.last_shooting_models_removed)
        lastShootingPinsAdded = Int(raw.last_shooting_pins_added)
        lastShootingMoraleChecked = raw.last_shooting_morale_checked
        lastShootingMoraleRoll = Int(raw.last_shooting_morale_roll)
        lastShootingMoraleTarget = Int(raw.last_shooting_morale_target)
        lastShootingMoralePinModifier = Int(raw.last_shooting_morale_pin_modifier)
        lastShootingMoraleOfficerModifier = Int(raw.last_shooting_morale_officer_modifier)
        lastShootingMoraleFailed = raw.last_shooting_morale_failed
        embarked = raw.embarked
        embarkedUnitID = Int(raw.embarked_unit_id)
        embarkedInTransportID = Int(raw.embarked_in_transport_id)
        transportCapacity = Int(raw.transport_capacity)
        destroyed = raw.destroyed
        wrecked = raw.wrecked
        wreckBlocksMovement = raw.wreck_blocks_movement
        lastAssaultTargetID = Int(raw.last_assault_target_id)
        lastAssaultRange = CGFloat(raw.last_assault_range)
        lastAssaultTargetReaction = raw.last_assault_target_reaction
        lastAssaultAttackerWounds = Int(raw.last_assault_attacker_wounds)
        lastAssaultDefenderWounds = Int(raw.last_assault_defender_wounds)
        lastAssaultDrawRounds = Int(raw.last_assault_draw_rounds)
        lastAssaultWinnerID = Int(raw.last_assault_winner_id)
        lastAssaultLoserID = Int(raw.last_assault_loser_id)
        lastAssaultLoserDestroyed = raw.last_assault_loser_destroyed
        lastAssaultRegroupDistance = CGFloat(raw.last_assault_regroup_distance)
        lastAssaultVehicleTarget = raw.last_assault_vehicle_target
        lastAssaultAntitankEquipped = raw.last_assault_antitank_equipped
        lastAssaultEnclosedArmourOrderTestRequired = raw.last_assault_enclosed_armour_order_test_required
        lastAssaultEnclosedArmourOrderTestRoll = Int(raw.last_assault_enclosed_armour_order_test_roll)
        lastAssaultEnclosedArmourOrderTestTarget = Int(raw.last_assault_enclosed_armour_order_test_target)
        lastAssaultEnclosedArmourOrderTestFailed = raw.last_assault_enclosed_armour_order_test_failed
        lastAssaultVehicleDefensiveFireResolved = raw.last_assault_vehicle_defensive_fire_resolved
        lastAssaultVehicleHits = Int(raw.last_assault_vehicle_hits)
        lastAssaultVehicleDamageValue = Int(raw.last_assault_vehicle_damage_value)
        lastAssaultVehiclePenetrationModifier = Int(raw.last_assault_vehicle_penetration_modifier)
        lastAssaultVehicleDamageRoll = Int(raw.last_assault_vehicle_damage_roll)
        lastAssaultVehicleDamageClass = raw.last_assault_vehicle_damage_class
    }

    var ownerName: String {
        owner == DZW_PLAYER_ONE ? "Player 1" : "Player 2"
    }

    var currentOrderName: String {
        String(cString: game_order_name(currentOrder))
    }

    var moraleQualityName: String {
        String(cString: game_morale_quality_name(moraleQuality))
    }

    var lastOrderTestResultName: String {
        String(cString: game_order_test_result_name(lastOrderTestResult))
    }

    var lastFubarResultName: String {
        String(cString: game_fubar_result_name(lastFubarResult))
    }

    var lastShootingTargetReactionName: String {
        String(cString: game_target_reaction_name(lastShootingTargetReaction))
    }

    var lastVehicleDamageResultName: String {
        String(cString: game_vehicle_damage_result_name(lastVehicleDamageResult))
    }

    var lastAssaultTargetReactionName: String {
        String(cString: game_target_reaction_name(lastAssaultTargetReaction))
    }

    var orderDiceSummary: String {
        var parts = ["Order \(currentOrderName)", "\(moraleQualityName)", "Pins \(pinCount)"]
        if actedThisTurn {
            parts.append("Acted")
        }
        if retainedOrder {
            parts.append("Retained")
        }
        if downOrderActive {
            parts.append("Down \(defensiveToHitModifier > 0 ? "-\(defensiveToHitModifier) to hit" : "active")")
        }
        if ambushOrderActive {
            parts.append("Ambush waiting")
        }
        if lastRallyRoll > 0 {
            parts.append("Rally -\(lastRallyPinsRemoved)")
        }
        if pivotBudget > 0 {
            parts.append("Pivots \(pivotCountUsed)/\(pivotBudget)")
        }
        if lastReverseDistance > 0 {
            parts.append("Reverse \(String(format: "%.1f", Double(lastReverseDistance)))")
        }
        if lastShootingRangeChecked {
            parts.append("Shot \(String(format: "%.1f", Double(lastShootingRange)))")
        }
        if lastShootingNeededToHit > 0 {
            parts.append("Hit \(lastShootingNeededToHit)+")
        }
        if lastShootingDamageValue > 0 {
            parts.append("DV \(lastShootingDamageValue)")
        }
        if lastShootingMoraleRoll > 0 {
            parts.append("Morale \(lastShootingMoraleRoll)/\(lastShootingMoraleTarget)")
        }
        if lastVehicleDamageResult != DZW_VEHICLE_DAMAGE_RESULT_NONE {
            parts.append("Vehicle \(lastVehicleDamageResultName)")
        }
        if wreckBlocksMovement {
            parts.append("Wreck")
        }
        if lastAssaultTargetID > 0 {
            parts.append("Assault \(lastAssaultTargetID)")
            if lastAssaultTargetReaction != DZW_TARGET_REACTION_NONE {
                parts.append(lastAssaultTargetReactionName)
            }
            if lastAssaultVehicleTarget {
                parts.append(lastAssaultAntitankEquipped ? "AT assault" : "Tank nerve")
                if lastAssaultEnclosedArmourOrderTestRequired {
                    parts.append("Tank test \(lastAssaultEnclosedArmourOrderTestRoll)/\(lastAssaultEnclosedArmourOrderTestTarget)")
                }
                if lastAssaultVehicleDefensiveFireResolved {
                    parts.append("Defensive fire")
                }
                if lastAssaultVehicleHits > 0 {
                    parts.append("Vehicle hits \(lastAssaultVehicleHits)")
                }
                if lastAssaultVehicleDamageValue > 0 {
                    parts.append("Assault DV \(lastAssaultVehicleDamageValue)")
                }
            }
            if lastAssaultLoserDestroyed {
                parts.append("Loser destroyed")
            }
        }
        if lastOrderTestResult != DZW_ORDER_TEST_NOT_REQUIRED {
            parts.append(lastOrderTestResultName)
        }
        if lastFubarResult != DZW_FUBAR_NONE {
            parts.append(lastFubarResultName)
        }
        return parts.joined(separator: " • ")
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
