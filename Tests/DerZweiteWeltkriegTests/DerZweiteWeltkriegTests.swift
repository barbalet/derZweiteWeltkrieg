import XCTest
#if SWIFT_PACKAGE
import DerZweiteWeltkriegCore
#endif

final class DerZweiteWeltkriegTests: XCTestCase {
    func testDemoLoadsCoreState() {
        guard let game = game_create_demo(1) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        let view = game_view(game)
        XCTAssertEqual(Int(view.turn_number), 1)
        XCTAssertEqual(view.active_player, DZW_PLAYER_ONE)
        XCTAssertEqual(view.phase, DZW_PHASE_MOVEMENT)
        XCTAssertEqual(Int(game_unit_count(game)), 14)
        XCTAssertEqual(Int(game_zone_count(game)), 4)

        let sovietGuards = unitView(withID: 13, in: game)
        XCTAssertEqual(Int(sovietGuards.wounds_per_model), 2)
        XCTAssertEqual(Int(sovietGuards.lead_model_wounds), 2)
        XCTAssertEqual(Int(sovietGuards.total_wounds_remaining), 6)

        let bersaglieri = unitView(withID: 14, in: game)
        XCTAssertTrue(bersaglieri.mixed_profiles)
        XCTAssertEqual(Int(bersaglieri.total_wounds_remaining), 4)
    }

    func testOrderDiceRulesetMigrationGateReportsFixedPhaseBlockers() {
        guard let game = game_create_demo(1) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        let view = game_view(game)
        XCTAssertEqual(view.ruleset, DZW_RULESET_FIXED_PHASES)
        XCTAssertEqual(game_ruleset(game), DZW_RULESET_FIXED_PHASES)
        XCTAssertEqual(String(cString: game_ruleset_name(view.ruleset)), "Fixed Phases")
        XCTAssertTrue(game_uses_legacy_phase_flow(game))

        let blockerCount = Int(game_phase_flow_migration_blocker_count(game))
        XCTAssertGreaterThanOrEqual(blockerCount, 5)

        let blockers = (0..<blockerCount).map { index in
            String(cString: game_phase_flow_migration_blocker(game, Int32(index)))
        }
        XCTAssertTrue(blockers.contains { $0.contains("game_advance_phase") })
        XCTAssertTrue(blockers.contains { $0.contains("game_move_unit") })
        XCTAssertTrue(blockers.contains { $0.contains("game_shoot_unit") })
        XCTAssertTrue(blockers.contains { $0.contains("game_assault_unit") })
        XCTAssertEqual(String(cString: game_phase_flow_migration_blocker(game, Int32(blockerCount))), "")
    }

    func testOrderDicePublicUnitPrimitivesDefaultToReadyRegularState() {
        guard let game = game_create_demo(1) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        let unit = game_unit_view(game, 0)
        XCTAssertEqual(unit.current_order, DZW_ORDER_NONE)
        XCTAssertFalse(unit.acted_this_turn)
        XCTAssertFalse(unit.retained_order)
        XCTAssertEqual(Int(unit.pin_count), 0)
        XCTAssertEqual(unit.morale_quality, DZW_MORALE_REGULAR)
        XCTAssertEqual(unit.last_order_test_result, DZW_ORDER_TEST_NOT_REQUIRED)
        XCTAssertEqual(String(cString: game_order_name(unit.current_order)), "None")
        XCTAssertEqual(String(cString: game_morale_quality_name(unit.morale_quality)), "Regular")
        XCTAssertEqual(String(cString: game_order_test_result_name(unit.last_order_test_result)), "Not Required")
    }

    func testOrderDicePublicNamesFollowReferenceOrderList() {
        let orders: [(dzw_order_t, String)] = [
            (DZW_ORDER_FIRE, "Fire"),
            (DZW_ORDER_ADVANCE, "Advance"),
            (DZW_ORDER_RUN, "Run"),
            (DZW_ORDER_AMBUSH, "Ambush"),
            (DZW_ORDER_RALLY, "Rally"),
            (DZW_ORDER_DOWN, "Down"),
        ]

        XCTAssertEqual(String(cString: game_ruleset_name(DZW_RULESET_ORDER_DICE)), "Order Dice")
        for (order, name) in orders {
            XCTAssertEqual(String(cString: game_order_name(order)), name)
        }
        XCTAssertEqual(String(cString: game_morale_quality_name(DZW_MORALE_INEXPERIENCED)), "Inexperienced")
        XCTAssertEqual(String(cString: game_morale_quality_name(DZW_MORALE_REGULAR)), "Regular")
        XCTAssertEqual(String(cString: game_morale_quality_name(DZW_MORALE_VETERAN)), "Veteran")
        XCTAssertEqual(String(cString: game_order_test_result_name(DZW_ORDER_TEST_PASSED)), "Passed")
        XCTAssertEqual(String(cString: game_order_test_result_name(DZW_ORDER_TEST_FAILED)), "Failed")
        XCTAssertEqual(String(cString: game_order_test_result_name(DZW_ORDER_TEST_FUBAR)), "FUBAR")
    }

    func testOrderDiceCupBuildsDeterministicSeededRemainingDice() {
        guard let firstGame = game_create_demo(21),
              let secondGame = game_create_demo(21) else {
            XCTFail("Failed to create demo games")
            return
        }
        defer {
            game_destroy(firstGame)
            game_destroy(secondGame)
        }

        XCTAssertTrue(game_set_ruleset(firstGame, DZW_RULESET_ORDER_DICE))
        XCTAssertTrue(game_set_ruleset(secondGame, DZW_RULESET_ORDER_DICE))

        let expectedDice = orderDiceEligibleUnitCount(in: firstGame)
        XCTAssertGreaterThan(expectedDice, 0)
        XCTAssertEqual(Int(game_order_dice_remaining_count(firstGame)), expectedDice)
        XCTAssertEqual(Int(game_order_dice_spent_count(firstGame)), 0)
        XCTAssertEqual(Int(game_order_dice_retained_count(firstGame)), 0)
        XCTAssertFalse(game_current_order_die_view(firstGame).available)
        XCTAssertEqual(game_order_dice_replay_signature(firstGame), game_order_dice_replay_signature(secondGame))
        XCTAssertGreaterThan(game_order_dice_replay_signature(firstGame), 0)

        for index in 0..<expectedDice {
            let firstDie = game_order_dice_remaining_view(firstGame, Int32(index))
            let secondDie = game_order_dice_remaining_view(secondGame, Int32(index))
            XCTAssertTrue(firstDie.available)
            XCTAssertEqual(firstDie.owner, secondDie.owner)
            XCTAssertEqual(Int(firstDie.sequence), Int(secondDie.sequence))
        }
    }

    func testOrderDiceDrawLifecycleRejectsAssignmentWithoutCurrentDie() {
        guard let game = game_create_demo(22) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        XCTAssertTrue(game_set_ruleset(game, DZW_RULESET_ORDER_DICE))
        let startingDice = Int(game_order_dice_remaining_count(game))
        let firstUnit = firstOrderAssignableUnit(owner: DZW_PLAYER_ONE, in: game)

        XCTAssertFalse(game_assign_order(game, firstUnit.id, DZW_ORDER_FIRE))
        XCTAssertTrue(String(cString: game_last_error(game)).contains("Draw an order die"))

        XCTAssertTrue(game_draw_order_die(game))
        let currentDie = game_current_order_die_view(game)
        XCTAssertTrue(currentDie.available)
        XCTAssertNotEqual(currentDie.owner, DZW_PLAYER_NONE)
        XCTAssertEqual(Int(game_order_dice_remaining_count(game)), startingDice - 1)

        XCTAssertFalse(game_draw_order_die(game))
        XCTAssertTrue(String(cString: game_last_error(game)).contains("Assign the current order die"))
    }

    func testOrderDiceAssignOrderConsumesCurrentDieAndMarksUnitActed() {
        guard let game = game_create_demo(23) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        XCTAssertTrue(game_set_ruleset(game, DZW_RULESET_ORDER_DICE))
        XCTAssertTrue(game_draw_order_die(game))
        let currentDie = game_current_order_die_view(game)
        let unit = firstOrderAssignableUnit(owner: currentDie.owner, in: game)

        let eligibility = game_unit_order_eligibility_view(game, unit.id, DZW_ORDER_FIRE)
        XCTAssertTrue(eligibility.eligible)
        XCTAssertFalse(eligibility.requires_order_test)
        XCTAssertEqual(String(cString: eligibility.reason), "Eligible.")

        XCTAssertTrue(game_assign_order(game, unit.id, DZW_ORDER_FIRE))
        XCTAssertFalse(game_current_order_die_view(game).available)
        XCTAssertEqual(Int(game_order_dice_spent_count(game)), 1)
        XCTAssertEqual(Int(game_order_dice_retained_count(game)), 0)

        let updated = unitView(withID: unit.id, in: game)
        XCTAssertEqual(updated.current_order, DZW_ORDER_FIRE)
        XCTAssertTrue(updated.acted_this_turn)
        XCTAssertFalse(updated.retained_order)
        XCTAssertFalse(updated.shot_this_turn)
        XCTAssertFalse(updated.can_move_now)
        XCTAssertTrue(updated.can_shoot_now)
    }

    func testOrderDiceRetainedOrdersMoveDieToRetainedPool() {
        guard let game = game_create_demo(24) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        XCTAssertTrue(game_set_ruleset(game, DZW_RULESET_ORDER_DICE))
        XCTAssertTrue(game_draw_order_die(game))
        let currentDie = game_current_order_die_view(game)
        let unit = firstOrderAssignableUnit(owner: currentDie.owner, in: game)

        XCTAssertTrue(game_assign_order(game, unit.id, DZW_ORDER_AMBUSH))
        XCTAssertEqual(Int(game_order_dice_spent_count(game)), 0)
        XCTAssertEqual(Int(game_order_dice_retained_count(game)), 1)
        XCTAssertEqual(game_order_dice_retained_view(game, 0).owner, currentDie.owner)

        let updated = unitView(withID: unit.id, in: game)
        XCTAssertEqual(updated.current_order, DZW_ORDER_AMBUSH)
        XCTAssertTrue(updated.acted_this_turn)
        XCTAssertTrue(updated.retained_order)
        XCTAssertFalse(updated.can_move_now)
        XCTAssertFalse(updated.can_shoot_now)
    }

    func testOrderDiceEligibilityReportsWrongOwnerAndAlreadyOrderedReasons() {
        guard let game = game_create_demo(25) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        XCTAssertTrue(game_set_ruleset(game, DZW_RULESET_ORDER_DICE))

        let noDieUnit = firstOrderAssignableUnit(owner: DZW_PLAYER_ONE, in: game)
        let noDieEligibility = game_unit_order_eligibility_view(game, noDieUnit.id, DZW_ORDER_ADVANCE)
        XCTAssertFalse(noDieEligibility.eligible)
        XCTAssertTrue(String(cString: noDieEligibility.reason).contains("Draw an order die"))

        XCTAssertTrue(game_draw_order_die(game))
        let currentDie = game_current_order_die_view(game)
        let activeUnit = firstOrderAssignableUnit(owner: currentDie.owner, in: game)
        let opposingOwner = currentDie.owner == DZW_PLAYER_ONE ? DZW_PLAYER_TWO : DZW_PLAYER_ONE
        let opposingUnit = firstOrderAssignableUnit(owner: opposingOwner, in: game)

        let wrongOwnerEligibility = game_unit_order_eligibility_view(game, opposingUnit.id, DZW_ORDER_ADVANCE)
        XCTAssertFalse(wrongOwnerEligibility.eligible)
        XCTAssertTrue(String(cString: wrongOwnerEligibility.reason).contains("opposing side"))

        XCTAssertTrue(game_assign_order(game, activeUnit.id, DZW_ORDER_DOWN))
        XCTAssertTrue(drawUntilCurrentDie(owner: activeUnit.owner, in: game))
        let alreadyOrdered = game_unit_order_eligibility_view(game, activeUnit.id, DZW_ORDER_ADVANCE)
        XCTAssertFalse(alreadyOrdered.eligible)
        let reason = String(cString: alreadyOrdered.reason)
        XCTAssertTrue(reason.contains("retaining") || reason.contains("already received"))
    }

    func testArmyPresetDemoLoadsSelectedMatchup() {
        guard let game = game_create_demo_with_armies(500, DZW_ARMY_BRITISH, DZW_ARMY_ITALIAN) else {
            XCTFail("Failed to create army preset demo")
            return
        }
        defer { game_destroy(game) }

        XCTAssertEqual(game_player_army(game, DZW_PLAYER_ONE), DZW_ARMY_BRITISH)
        XCTAssertEqual(game_player_army(game, DZW_PLAYER_TWO), DZW_ARMY_ITALIAN)
        XCTAssertEqual(String(cString: army_name(DZW_ARMY_BRITISH)), "British")
        XCTAssertEqual(Int(game_unit_count(game)), 13)

        let names = unitNames(in: game)
        XCTAssertTrue(names.contains("Sherman Firefly"))
        XCTAssertTrue(names.contains("Universal Carrier Transport"))
        XCTAssertTrue(names.contains("Italian Rifle Squad"))
        XCTAssertFalse(names.contains("Italian Rifle Section"))
        XCTAssertFalse(names.contains("Soviet Guards SMG Squad"))
    }

    func testArmyPresetResetCanSwapToAustralianVersusSoviet() {
        guard let game = game_create_demo(501) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        game_reset_demo_with_armies(game, 501, DZW_ARMY_AUSTRALIAN, DZW_ARMY_SOVIET)

        XCTAssertEqual(game_player_army(game, DZW_PLAYER_ONE), DZW_ARMY_AUSTRALIAN)
        XCTAssertEqual(game_player_army(game, DZW_PLAYER_TWO), DZW_ARMY_SOVIET)
        XCTAssertEqual(Int(game_unit_count(game)), 11)

        let names = unitNames(in: game)
        XCTAssertTrue(names.contains("Australian Rifle Section"))
        XCTAssertTrue(names.contains("Australian Carrier"))
        XCTAssertTrue(names.contains("Soviet Sapper Assault Group"))
        XCTAssertTrue(names.contains("Soviet Guards SMG Squad"))
        XCTAssertFalse(names.contains("British Rifle Section"))
        XCTAssertFalse(names.contains("Italian Rifle Squad"))
    }

    func testArmyForceCatalogExposesCuratedVariants() {
        XCTAssertEqual(Int(army_force_count(DZW_ARMY_BRITISH)), 2)
        XCTAssertEqual(Int(army_force_count(DZW_ARMY_ITALIAN)), 2)

        let britishDefault = army_force_view(DZW_ARMY_BRITISH, 0)
        XCTAssertEqual(britishDefault.name.map { String(cString: $0) }, "British Rifle Platoon")

        let italianVariant = army_force_view(DZW_ARMY_ITALIAN, 1)
        XCTAssertEqual(italianVariant.name.map { String(cString: $0) }, "Italian Alpini Detachment")
        XCTAssertFalse((italianVariant.summary.map { String(cString: $0) } ?? "").isEmpty)
    }

    func testArmyCatalogExposesUnitChoicesWithPoints() {
        XCTAssertGreaterThan(Int(army_catalog_unit_count(DZW_ARMY_AMERICAN)), 0)

        let tactical = army_catalog_unit_view(DZW_ARMY_AMERICAN, 0)
        XCTAssertEqual(tactical.name.map { String(cString: $0) }, "US Rifle Squad")
        XCTAssertEqual(Int(tactical.points), 150)
        XCTAssertEqual(Int(tactical.max_count), 2)
        XCTAssertTrue(cString(tactical.source_note).contains("American roster"))
        XCTAssertEqual(tactical.unit.kind, DZW_UNIT_INFANTRY)
        XCTAssertEqual(Int(tactical.unit.models), 10)
    }

    func testEveryNationForcePresetLoadsPlayableRoster() {
        for army in playableArmies {
            let armyName = cString(army_name(army))
            let forceCount = Int(army_force_count(army))
            XCTAssertEqual(forceCount, 2, "\(armyName) should expose two force presets")

            for forceIndex in 0..<forceCount {
                let force = army_force_view(army, Int32(forceIndex))
                XCTAssertFalse(cString(force.name).isEmpty, "\(armyName) force \(forceIndex) should have a name")
                XCTAssertFalse(cString(force.summary).isEmpty, "\(armyName) force \(forceIndex) should have a summary")

                let rosterCount = Int(army_force_roster_unit_count(army, Int32(forceIndex)))
                XCTAssertGreaterThan(rosterCount, 0, "\(armyName) force \(forceIndex) should preview units")

                var hasInfantry = false
                for unitIndex in 0..<rosterCount {
                    let unit = army_force_roster_unit_view(army, Int32(forceIndex), Int32(unitIndex))
                    XCTAssertFalse(cString(unit.name).isEmpty, "\(armyName) force \(forceIndex) unit \(unitIndex) should have a name")
                    XCTAssertGreaterThan(Int(unit.models), 0, "\(armyName) force \(forceIndex) unit \(unitIndex) should have models")
                    XCTAssertGreaterThan(Int(unit.total_wounds), 0, "\(armyName) force \(forceIndex) unit \(unitIndex) should have wounds")

                    if unit.kind == DZW_UNIT_INFANTRY {
                        hasInfantry = true
                    } else {
                        XCTAssertGreaterThan(Int(unit.front_armour), 0, "\(armyName) vehicle \(unitIndex) should have front armour")
                        XCTAssertGreaterThan(Int(unit.side_armour), 0, "\(armyName) vehicle \(unitIndex) should have side armour")
                        XCTAssertGreaterThan(Int(unit.rear_armour), 0, "\(armyName) vehicle \(unitIndex) should have rear armour")
                    }

                    if unit.primary_weapon_name != nil {
                        XCTAssertFalse(cString(unit.primary_weapon_name).isEmpty, "\(armyName) force \(forceIndex) unit \(unitIndex) should not expose a blank weapon")
                    }
                }
                XCTAssertTrue(hasInfantry, "\(armyName) force \(forceIndex) should include infantry")

                guard let game = game_create_demo_with_forces(
                    UInt32(7_000 + forceIndex),
                    army,
                    Int32(forceIndex),
                    opposingArmy(for: army),
                    0
                ) else {
                    XCTFail("Failed to create \(armyName) force \(forceIndex) demo")
                    continue
                }

                XCTAssertEqual(game_player_army(game, DZW_PLAYER_ONE), army)
                XCTAssertEqual(game_player_force(game, DZW_PLAYER_ONE), Int32(forceIndex))
                XCTAssertGreaterThan(Int(game_unit_count(game)), 0)
                game_destroy(game)
            }
        }
    }

    func testEveryCatalogEntryCarriesSourceAndPlayablePreview() {
        for army in playableArmies {
            let armyName = cString(army_name(army))
            let catalogCount = Int(army_catalog_unit_count(army))
            XCTAssertGreaterThan(catalogCount, 0, "\(armyName) should expose catalog entries")

            for index in 0..<catalogCount {
                let entry = army_catalog_unit_view(army, Int32(index))
                let unitName = cString(entry.name)
                let sourceNote = cString(entry.source_note)

                XCTAssertEqual(Int(entry.catalog_id), index)
                XCTAssertFalse(unitName.isEmpty, "\(armyName) catalog \(index) should have a name")
                XCTAssertGreaterThan(Int(entry.points), 0, "\(unitName) should have points")
                XCTAssertGreaterThan(Int(entry.max_count), 0, "\(unitName) should have max count")
                XCTAssertTrue(sourceNote.contains("Wikipedia-backed"), "\(unitName) should carry a source note")
                XCTAssertTrue(sourceNote.contains("docs/wwii_demo_scope.md"), "\(unitName) should point at source docs")
                XCTAssertFalse(cString(entry.unit.name).isEmpty, "\(unitName) preview should name the generated unit")
                XCTAssertGreaterThan(Int(entry.unit.models), 0, "\(unitName) preview should have models")
                XCTAssertGreaterThan(Int(entry.unit.total_wounds), 0, "\(unitName) preview should have wounds")

                if entry.unit.kind == DZW_UNIT_VEHICLE || entry.unit.kind == DZW_UNIT_ASSAULT_GUN {
                    XCTAssertGreaterThan(Int(entry.unit.front_armour), 0, "\(unitName) should expose front armour")
                    XCTAssertGreaterThan(Int(entry.unit.side_armour), 0, "\(unitName) should expose side armour")
                    XCTAssertGreaterThan(Int(entry.unit.rear_armour), 0, "\(unitName) should expose rear armour")
                }
            }
        }
    }

    func testRepresentativeWeaponBalanceProfilesAreStable() {
        let rifle = weaponProfile(named: "Lee-Enfield No.4 Mk I")
        XCTAssertEqual(Int(rifle.range), 24)
        XCTAssertEqual(Int(rifle.strength), 4)
        XCTAssertEqual(Int(rifle.ap), 5)
        XCTAssertTrue(rifle.rapid_fire)

        let garand = weaponProfile(named: "M1 Garand")
        XCTAssertEqual(Int(garand.range), 24)
        XCTAssertEqual(Int(garand.strength), 4)
        XCTAssertTrue(garand.rapid_fire)

        let smg = weaponProfile(named: "PPSh-41 SMG")
        XCTAssertEqual(Int(smg.range), 18)
        XCTAssertEqual(Int(smg.strength), 5)
        XCTAssertTrue(smg.assault)

        let mp40 = weaponProfile(named: "MP 40 SMG")
        XCTAssertEqual(Int(mp40.range), 12)
        XCTAssertTrue(mp40.assault)

        let mg42 = weaponProfile(named: "MG42")
        XCTAssertEqual(Int(mg42.range), 36)
        XCTAssertEqual(Int(mg42.shots), 3)
        XCTAssertTrue(mg42.heavy)

        let vickers = weaponProfile(named: "Vickers HMG")
        XCTAssertEqual(Int(vickers.range), 36)
        XCTAssertEqual(Int(vickers.shots), 3)
        XCTAssertTrue(vickers.heavy)

        let flamethrower = weaponProfile(named: "Flamethrower")
        XCTAssertEqual(Int(flamethrower.range), 8)
        XCTAssertTrue(flamethrower.assault)
        XCTAssertTrue(flamethrower.flame)
        XCTAssertTrue(flamethrower.ignores_cover)

        let mortar = weaponProfile(named: "81mm Mortar Battery")
        XCTAssertEqual(Int(mortar.blast_diameter), 5)
        XCTAssertTrue(mortar.ordnance)
        XCTAssertTrue(mortar.barrage)

        let bazooka = weaponProfile(named: "M1 Bazooka")
        XCTAssertEqual(Int(bazooka.range), 24)
        XCTAssertEqual(Int(bazooka.strength), 7)
        XCTAssertEqual(Int(bazooka.ap), 2)

        let piat = weaponProfile(named: "PIAT")
        XCTAssertEqual(Int(piat.range), 24)
        XCTAssertEqual(Int(piat.strength), 7)
        XCTAssertEqual(Int(piat.ap), 2)

        let panzerfaust = weaponProfile(named: "Panzerfaust")
        XCTAssertEqual(Int(panzerfaust.range), 12)
        XCTAssertTrue(panzerfaust.assault)

        let antiTankGun = weaponProfile(named: "17-pounder Anti-Tank Gun")
        XCTAssertEqual(Int(antiTankGun.range), 48)
        XCTAssertEqual(Int(antiTankGun.strength), 9)
        XCTAssertEqual(Int(antiTankGun.ap), 2)
        XCTAssertTrue(antiTankGun.heavy)

        let tankGun = weaponProfile(named: "75mm Tank Gun")
        XCTAssertEqual(Int(tankGun.range), 72)
        XCTAssertEqual(Int(tankGun.strength), 8)
        XCTAssertEqual(Int(tankGun.blast_diameter), 5)
        XCTAssertTrue(tankGun.ordnance)

        let heavyMortar = weaponProfile(named: "120mm Mortar")
        XCTAssertEqual(Int(heavyMortar.strength), 8)
        XCTAssertEqual(Int(heavyMortar.blast_diameter), 3)
        XCTAssertTrue(heavyMortar.heavy)
    }

    func testArmyListTotalPointsUsesSelectedEntries() {
        let selections = [
            army_list_entry_t(catalog_id: 0, count: 1),
            army_list_entry_t(catalog_id: 7, count: 1),
        ]

        let total = selections.withUnsafeBufferPointer { buffer in
            army_list_total_points(DZW_ARMY_AMERICAN, buffer.baseAddress, Int32(buffer.count))
        }

        XCTAssertEqual(Int(total), 200)
        XCTAssertEqual(Int(army_list_total_points(DZW_ARMY_AMERICAN, nil, 0)), 0)
    }

    func testSkirmishCreationLoadsCustomArmyLists() {
        let americans = [
            army_list_entry_t(catalog_id: 0, count: 1),
            army_list_entry_t(catalog_id: 7, count: 1),
        ]
        let italians = [
            army_list_entry_t(catalog_id: 0, count: 1),
            army_list_entry_t(catalog_id: 4, count: 1),
        ]

        let game = americans.withUnsafeBufferPointer { americanBuffer in
            italians.withUnsafeBufferPointer { italianBuffer in
                game_create_skirmish(
                    90210,
                    DZW_ARMY_AMERICAN,
                    americanBuffer.baseAddress,
                    Int32(americanBuffer.count),
                    DZW_ARMY_ITALIAN,
                    italianBuffer.baseAddress,
                    Int32(italianBuffer.count)
                )
            }
        }

        guard let game else {
            XCTFail("Failed to create skirmish game")
            return
        }
        defer { game_destroy(game) }

        XCTAssertEqual(game_player_army(game, DZW_PLAYER_ONE), DZW_ARMY_AMERICAN)
        XCTAssertEqual(game_player_army(game, DZW_PLAYER_TWO), DZW_ARMY_ITALIAN)
        XCTAssertEqual(Int(game_unit_count(game)), 4)

        let names = unitNames(in: game)
        XCTAssertTrue(names.contains("US Rifle Squad"))
        XCTAssertTrue(names.contains("M3 Half-track"))
        XCTAssertTrue(names.contains("Italian Rifle Squad"))
        XCTAssertTrue(names.contains("Semovente 75/18"))
    }

    func testDeploymentMoveRepositionsUnitWithoutConsumingMovement() {
        let americans = [
            army_list_entry_t(catalog_id: 0, count: 1),
        ]
        let italians = [
            army_list_entry_t(catalog_id: 0, count: 1),
        ]

        let game = americans.withUnsafeBufferPointer { americanBuffer in
            italians.withUnsafeBufferPointer { italianBuffer in
                game_create_skirmish(
                    4444,
                    DZW_ARMY_AMERICAN,
                    americanBuffer.baseAddress,
                    Int32(americanBuffer.count),
                    DZW_ARMY_ITALIAN,
                    italianBuffer.baseAddress,
                    Int32(italianBuffer.count)
                )
            }
        }

        guard let game else {
            XCTFail("Failed to create skirmish game")
            return
        }
        defer { game_destroy(game) }

        let unit = game_unit_view(game, 0)
        let destinationX = unit.x + 8
        let destinationY = unit.y + 4

        XCTAssertTrue(game_deploy_unit(game, Int32(unit.id), destinationX, destinationY))

        let updated = unitView(withID: unit.id, in: game)
        XCTAssertEqual(updated.x, destinationX, accuracy: 0.01)
        XCTAssertEqual(updated.y, destinationY, accuracy: 0.01)
        XCTAssertTrue(updated.can_move_now)
        XCTAssertFalse(updated.moved_this_turn)
    }

    func testDeploymentRotateUpdatesFacingWithoutSpendingAction() {
        guard let game = game_create_demo(88) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        let unit = game_unit_view(game, 0)
        XCTAssertTrue(game_deploy_rotate_unit(game, Int32(unit.id), 135))

        let updated = unitView(withID: unit.id, in: game)
        XCTAssertEqual(updated.facing_degrees, 135, accuracy: 0.01)
        XCTAssertTrue(updated.can_move_now)
        XCTAssertFalse(updated.moved_this_turn)
    }

    func testArmyRosterPreviewExposesPresetUnits() {
        XCTAssertEqual(Int(army_roster_unit_count(DZW_ARMY_BRITISH)), 8)
        XCTAssertEqual(Int(army_roster_unit_count(DZW_ARMY_ITALIAN)), 5)

        let firstBritishUnit = army_roster_unit_view(DZW_ARMY_BRITISH, 0)
        XCTAssertEqual(firstBritishUnit.name.map { String(cString: $0) }, "British Rifle Section")
        XCTAssertEqual(firstBritishUnit.kind, DZW_UNIT_INFANTRY)
        XCTAssertEqual(Int(firstBritishUnit.models), 10)
        XCTAssertEqual(firstBritishUnit.primary_weapon_name.map { String(cString: $0) }, "Lee-Enfield No.4 Mk I")

        let australianRifle = army_roster_unit_view(DZW_ARMY_AUSTRALIAN, 0)
        XCTAssertEqual(australianRifle.name.map { String(cString: $0) }, "Australian Rifle Section")
        XCTAssertTrue(australianRifle.mixed_profiles)

        let firefly = army_roster_unit_view(DZW_ARMY_AUSTRALIAN, 4)
        XCTAssertEqual(firefly.name.map { String(cString: $0) }, "Matilda II")
        XCTAssertEqual(firefly.kind, DZW_UNIT_VEHICLE)
        XCTAssertEqual(Int(firefly.front_armour), 14)
        XCTAssertEqual(Int(firefly.side_armour), 12)
        XCTAssertEqual(Int(firefly.rear_armour), 10)
        XCTAssertEqual(firefly.primary_weapon_name.map { String(cString: $0) }, "17-pounder Anti-Tank Gun")

        let bersaglieri = army_roster_unit_view(DZW_ARMY_ITALIAN, 2)
        XCTAssertEqual(bersaglieri.name.map { String(cString: $0) }, "Italian Bersaglieri Squad")
        XCTAssertTrue(bersaglieri.mixed_profiles)
        XCTAssertEqual(Int(bersaglieri.total_wounds), 4)
    }

    func testArmyForceRosterPreviewExposesAlternateVariantUnits() {
        XCTAssertEqual(Int(army_force_roster_unit_count(DZW_ARMY_AMERICAN, 1)), 7)

        let names = (0..<Int(army_force_roster_unit_count(DZW_ARMY_AMERICAN, 1))).map { index in
            army_force_roster_unit_view(DZW_ARMY_AMERICAN, 1, Int32(index)).name.map { String(cString: $0) } ?? ""
        }

        XCTAssertTrue(names.contains("M10 Tank Destroyer"))
        XCTAssertFalse(names.contains("British Commando Section"))
    }

    func testArmyRosterPreviewExposesStartingTransportDeployment() {
        let command = army_roster_unit_view(DZW_ARMY_BRITISH, 5)
        XCTAssertEqual(command.name.map { String(cString: $0) }, "British Platoon HQ")
        XCTAssertEqual(command.embarked_transport_name.map { String(cString: $0) }, "Universal Carrier Transport")

        let transport = army_roster_unit_view(DZW_ARMY_BRITISH, 7)
        XCTAssertEqual(transport.name.map { String(cString: $0) }, "Universal Carrier Transport")
        XCTAssertEqual(transport.embarked_unit_name.map { String(cString: $0) }, "British Platoon HQ")
    }

    func testArmyForceRosterPreviewExposesAlternateTransportDeployment() {
        let bersaglieriAssaultSquad = army_force_roster_unit_view(DZW_ARMY_ITALIAN, 1, 1)
        XCTAssertEqual(bersaglieriAssaultSquad.name.map { String(cString: $0) }, "Bersaglieri Assault Squad")
        XCTAssertEqual(bersaglieriAssaultSquad.embarked_transport_name.map { String(cString: $0) }, "Italian Truck")

        let truck = army_force_roster_unit_view(DZW_ARMY_ITALIAN, 1, 2)
        XCTAssertEqual(truck.name.map { String(cString: $0) }, "Italian Truck")
        XCTAssertEqual(truck.embarked_unit_name.map { String(cString: $0) }, "Bersaglieri Assault Squad")
    }

    func testArmyRosterPreviewRejectsOutOfRangeIndex() {
        let invalid = army_roster_unit_view(DZW_ARMY_SOVIET, 99)
        XCTAssertNil(invalid.name)
        XCTAssertEqual(Int(invalid.models), 0)
    }

    func testMissionScenarioLoadsObjectiveState() {
        guard let game = game_create_demo(140) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        let mission = game_mission_view(game)
        XCTAssertEqual(mission.name.map { String(cString: $0) }, "Bocage Breakout")
        XCTAssertEqual(Int(mission.target_score), 8)
        XCTAssertEqual(Int(mission.player_one_score), 0)
        XCTAssertEqual(Int(mission.player_two_score), 0)
        XCTAssertEqual(mission.winner, DZW_PLAYER_NONE)
        XCTAssertEqual(Int(game_objective_count(game)), 4)
        XCTAssertEqual(Int(game_zone_count(game)), 4)

        let ammunitionCache = objectiveView(withID: 1, in: game)
        let observationPost = objectiveView(withID: 2, in: game)
        let roadJunction = objectiveView(withID: 3, in: game)
        let fuelDump = objectiveView(withID: 4, in: game)
        let ruinedFarmhouse = zoneView(withID: 1, in: game)
        let bocageRidge = zoneView(withID: 2, in: game)
        let shellHoleField = zoneView(withID: 3, in: game)
        let markedMinefield = zoneView(withID: 4, in: game)

        XCTAssertEqual(ammunitionCache.name.map { String(cString: $0) }, "Ammunition Cache")
        XCTAssertEqual(observationPost.name.map { String(cString: $0) }, "Observation Post")
        XCTAssertEqual(roadJunction.name.map { String(cString: $0) }, "Road Junction")
        XCTAssertEqual(fuelDump.name.map { String(cString: $0) }, "Fuel Dump")
        XCTAssertEqual(ruinedFarmhouse.name.map { String(cString: $0) }, "Ruined Farmhouse")
        XCTAssertEqual(bocageRidge.name.map { String(cString: $0) }, "Bocage Ridge")
        XCTAssertEqual(shellHoleField.name.map { String(cString: $0) }, "Shell-Hole Field")
        XCTAssertEqual(markedMinefield.name.map { String(cString: $0) }, "Marked Minefield")
        XCTAssertEqual(markedMinefield.kind, DZW_TERRAIN_IMPASSABLE)
        XCTAssertEqual(ammunitionCache.controller, DZW_PLAYER_TWO)
        XCTAssertEqual(observationPost.controller, DZW_PLAYER_ONE)
        XCTAssertEqual(roadJunction.controller, DZW_PLAYER_NONE)
    }

    func testArmyPresetDeploymentStartsPassengersEmbarked() {
        guard let game = game_create_demo_with_armies(502, DZW_ARMY_AUSTRALIAN, DZW_ARMY_GERMAN) else {
            XCTFail("Failed to create army preset demo")
            return
        }
        defer { game_destroy(game) }

        let infantry = unitView(named: "Australian Rifle Section", owner: DZW_PLAYER_ONE, in: game)
        let carrier = unitView(named: "Australian Carrier", owner: DZW_PLAYER_ONE, in: game)
        XCTAssertTrue(infantry.embarked)
        XCTAssertEqual(infantry.embarked_in_transport_id, carrier.id)
        XCTAssertEqual(carrier.embarked_unit_id, infantry.id)

        let pioneers = unitView(named: "German Pioneer Squad", owner: DZW_PLAYER_TWO, in: game)
        let transport = unitView(named: "Sd.Kfz. 251 Half-track", owner: DZW_PLAYER_TWO, in: game)
        XCTAssertTrue(pioneers.embarked)
        XCTAssertEqual(pioneers.embarked_in_transport_id, transport.id)
        XCTAssertEqual(transport.embarked_unit_id, pioneers.id)
    }

    func testArmyForceDemoCreatesSelectedVariantMatchup() {
        guard let game = game_create_demo_with_forces(503, DZW_ARMY_AMERICAN, 1, DZW_ARMY_ITALIAN, 1) else {
            XCTFail("Failed to create force preset demo")
            return
        }
        defer { game_destroy(game) }

        XCTAssertEqual(game_player_force(game, DZW_PLAYER_ONE), 1)
        XCTAssertEqual(game_player_force(game, DZW_PLAYER_TWO), 1)

        let names = unitNames(in: game)
        XCTAssertTrue(names.contains("M10 Tank Destroyer"))
        XCTAssertTrue(names.contains("Italian Truck"))
        XCTAssertFalse(names.contains("British Commando Section"))
        XCTAssertFalse(names.contains("Italian Bersaglieri Squad"))

        let bersaglieriAssaultSquad = unitView(named: "Bersaglieri Assault Squad", owner: DZW_PLAYER_TWO, in: game)
        let truck = unitView(named: "Italian Truck", owner: DZW_PLAYER_TWO, in: game)
        XCTAssertTrue(bersaglieriAssaultSquad.embarked)
        XCTAssertEqual(bersaglieriAssaultSquad.embarked_in_transport_id, truck.id)
        XCTAssertEqual(truck.embarked_unit_id, bersaglieriAssaultSquad.id)
    }

    func testMissionScoresControlledObjectivesAtEndOfTurn() {
        guard let game = game_create_demo(141) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        game_advance_phase(game)
        game_advance_phase(game)
        game_advance_phase(game)

        let mission = game_mission_view(game)
        XCTAssertEqual(Int(mission.player_one_score), 1)
        XCTAssertEqual(Int(mission.player_two_score), 1)
        XCTAssertEqual(mission.winner, DZW_PLAYER_NONE)

        let gameView = game_view(game)
        XCTAssertEqual(Int(gameView.turn_number), 2)
        XCTAssertEqual(gameView.active_player, DZW_PLAYER_TWO)
        XCTAssertEqual(gameView.phase, DZW_PHASE_MOVEMENT)
    }

    func testMovementRejectsTooLongAnInfantryMove() {
        guard let game = game_create_demo(2) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        XCTAssertFalse(game_move_unit(game, 1, 26, 36))
        XCTAssertFalse(String(cString: game_last_error(game)).isEmpty)
    }

    func testFastVehicleCanMoveAndShootInSameTurn() {
        guard let game = game_create_demo(3) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        XCTAssertTrue(game_move_unit(game, 3, 22, 12))
        game_advance_phase(game)
        XCTAssertTrue(game_shoot_unit(game, 3, 4))

        let reconVehicle = unitView(withID: 3, in: game)
        XCTAssertTrue(reconVehicle.shot_this_turn)
    }

    func testFlamerCanShootWithinTemplateRange() {
        guard let game = game_create_demo(302) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        game_advance_phase(game)
        XCTAssertTrue(game_shoot_unit(game, 12, 4))

        let flamer = unitView(withID: 12, in: game)
        XCTAssertTrue(flamer.shot_this_turn)
    }

    func testFlamerIgnoresCoverAcrossSeeds() {
        var causedCasualty = false

        for seed in 330...350 {
            guard let uncovered = game_create_demo(UInt32(seed)),
                  let covered = game_create_demo(UInt32(seed)) else {
                XCTFail("Failed to create demo game")
                return
            }

            game_advance_phase(uncovered)
            XCTAssertTrue(game_shoot_unit(uncovered, 12, 4))
            let openModels = unitView(withID: 4, in: uncovered).models
            if openModels < 10 {
                causedCasualty = true
            }

            XCTAssertTrue(game_toggle_cover(covered, 4, true))
            game_advance_phase(covered)
            XCTAssertTrue(game_shoot_unit(covered, 12, 4))
            let coveredModels = unitView(withID: 4, in: covered).models

            XCTAssertEqual(openModels, coveredModels)
            game_destroy(uncovered)
            game_destroy(covered)
        }

        XCTAssertTrue(causedCasualty)
    }

    func testVehicleFireArcBlocksRearTarget() {
        guard let game = game_create_demo(300) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        XCTAssertTrue(game_rotate_unit(game, 3, 180))
        game_advance_phase(game)
        XCTAssertFalse(game_shoot_unit(game, 3, 4))
        XCTAssertFalse(String(cString: game_last_error(game)).isEmpty)
    }

    func testVehicleLineOfFireCanBeBlockedByOtherVehicle() {
        guard let game = game_create_demo(301) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        XCTAssertTrue(game_move_unit(game, 3, 20, 12))
        XCTAssertTrue(game_move_unit(game, 7, 27, 12))
        game_advance_phase(game)
        XCTAssertFalse(game_shoot_unit(game, 3, 4))
        XCTAssertFalse(String(cString: game_last_error(game)).isEmpty)
    }

    func testPhaseCycleHandsTurnToOpponent() {
        guard let game = game_create_demo(4) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        game_advance_phase(game)
        game_advance_phase(game)
        game_advance_phase(game)

        let view = game_view(game)
        XCTAssertEqual(Int(view.turn_number), 2)
        XCTAssertEqual(view.active_player, DZW_PLAYER_TWO)
        XCTAssertEqual(view.phase, DZW_PHASE_MOVEMENT)
    }

    func testTankShockMovesVehicle() {
        guard let game = game_create_demo(5) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        XCTAssertTrue(game_tank_shock_unit(game, 7, 4))

        let firefly = unitView(withID: 7, in: game)
        XCTAssertTrue(firefly.moved_this_turn)
        XCTAssertNotEqual(Float(firefly.x), 20.0)
    }

    func testOrdnanceVehicleCanShoot() {
        guard let game = game_create_demo(6) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        game_advance_phase(game)
        XCTAssertTrue(game_shoot_unit(game, 7, 4))

        let firefly = unitView(withID: 7, in: game)
        XCTAssertTrue(firefly.shot_this_turn)
    }

    func testWeaponDestroyedAllowsExplicitVehicleWeaponChoice() {
        var foundSelectableHullGunLoss = false

        for seed in 1000...1600 {
            guard let game = prepareShermanFireflyDamageScenario() else {
                XCTFail("Failed to prepare weapon-destroyed choice scenario")
                return
            }

            game_seed(game, UInt32(seed))
            guard game_assault_unit(game, 11, 7, DZW_FOLLOW_UP_ADVANCE) else {
                game_destroy(game)
                continue
            }

            let pending = game_pending_weapon_destroy_view(game)
            if !pending.active {
                game_destroy(game)
                continue
            }

            let options = (0..<Int(game_pending_weapon_destroy_option_count(game))).map { index in
                game_pending_weapon_destroy_option_view(game, Int32(index))
            }
            guard let hullGun = options.first(where: {
                $0.name.map { String(cString: $0) } == "Hull Browning M1919A4"
            }) else {
                game_destroy(game)
                continue
            }

            XCTAssertTrue(game_choose_pending_weapon_destroy(game, hullGun.weapon_index))

            let logLines = (0..<Int(game_log_count(game))).map { index in
                String(cString: game_log_line(game, Int32(index)))
            }
            XCTAssertTrue(logLines.contains(where: { $0.contains("chooses Hull Browning M1919A4 on Sherman Firefly") }))
            XCTAssertFalse(logLines.contains(where: { $0.contains("chooses 17-pounder Anti-Tank Gun on Sherman Firefly") }))
            foundSelectableHullGunLoss = true
            game_destroy(game)
            break
        }

        XCTAssertTrue(foundSelectableHullGunLoss)
    }

    func testBarrageIgnoresBlockedLineOfSight() {
        guard let game = game_create_demo(7) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        game_advance_phase(game)
        XCTAssertTrue(game_shoot_unit(game, 8, 5))

        let mortar = unitView(withID: 8, in: game)
        XCTAssertTrue(mortar.shot_this_turn)
    }

    func testBarrageCanCausePinnedState() {
        var pinned = false

        for seed in 8...128 {
            guard let game = game_create_demo(UInt32(seed)) else {
                XCTFail("Failed to create demo game")
                return
            }

            game_advance_phase(game)
            _ = game_shoot_unit(game, 8, 5)
            let italians = unitView(withID: 5, in: game)
            if italians.pinned {
                pinned = true
                game_destroy(game)
                break
            }
            game_destroy(game)
        }

        XCTAssertTrue(pinned)
    }

    func testEmbarkingRequiresNearbyTransport() {
        guard let game = game_create_demo(129) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        XCTAssertFalse(game_embark_unit(game, 2, 10))
        XCTAssertFalse(String(cString: game_last_error(game)).isEmpty)
    }

    func testTransportCanMoveAfterPassengerEmbarks() {
        guard let game = game_create_demo(130) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        XCTAssertTrue(game_embark_unit(game, 9, 10))
        XCTAssertTrue(game_move_unit(game, 10, 24, 33))

        let transport = unitView(withID: 10, in: game)
        let command = unitView(withID: 9, in: game)
        XCTAssertEqual(Int(transport.embarked_unit_id), 9)
        XCTAssertTrue(command.embarked)
    }

    func testEmbarkedUnitCanFireFromTransport() {
        guard let game = game_create_demo(136) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        XCTAssertTrue(game_embark_unit(game, 9, 10))
        game_advance_phase(game)
        XCTAssertTrue(game_fire_passenger(game, 10, 11))

        let command = unitView(withID: 9, in: game)
        XCTAssertTrue(command.shot_this_turn)
    }

    func testMultiWoundUnitCanTakePartialDamageWithoutLosingModel() {
        var foundPartialWound = false

        for seed in 360...430 {
            guard let game = game_create_demo(UInt32(seed)) else {
                XCTFail("Failed to create demo game")
                return
            }

            game_advance_phase(game)
            XCTAssertTrue(game_shoot_unit(game, 3, 13))

            let sovietGuards = unitView(withID: 13, in: game)
            if sovietGuards.models == 3 && sovietGuards.lead_model_wounds == 1 && sovietGuards.total_wounds_remaining == 5 {
                foundPartialWound = true
                game_destroy(game)
                break
            }

            game_destroy(game)
        }

        XCTAssertTrue(foundPartialWound)
    }

    func testMultiWoundUnitCanLoseModelFromAccumulatedUnsavedWounds() {
        var foundModelLoss = false

        for seed in 431...500 {
            guard let game = game_create_demo(UInt32(seed)) else {
                XCTFail("Failed to create demo game")
                return
            }

            game_advance_phase(game)
            XCTAssertTrue(game_shoot_unit(game, 3, 13))

            let sovietGuards = unitView(withID: 13, in: game)
            if sovietGuards.models < 3 {
                foundModelLoss = true
                XCTAssertLessThan(Int(sovietGuards.total_wounds_remaining), 6)
                game_destroy(game)
                break
            }

            game_destroy(game)
        }

        XCTAssertTrue(foundModelLoss)
    }

    func testMixedToughnessAllocationRemovesScreeningModelsFirst() {
        var foundSingleUnsavedWound = false

        for seed in 700...820 {
            guard let game = game_create_demo(UInt32(seed)) else {
                XCTFail("Failed to create demo game")
                return
            }

            game_advance_phase(game)
            XCTAssertTrue(game_shoot_unit(game, 3, 14))
            XCTAssertTrue(resolveAllPendingHitAllocations(in: game))

            let bersaglieri = unitView(withID: 14, in: game)
            if bersaglieri.total_wounds_remaining == 3 && bersaglieri.models == 2 {
                foundSingleUnsavedWound = true
                game_destroy(game)
                break
            }

            game_destroy(game)
        }

        XCTAssertTrue(foundSingleUnsavedWound)
    }

    func testMixedProfileViewsExposeCasualtyGroups() {
        guard let game = game_create_demo(1) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        let count = Int(game_unit_profile_group_count(game, 14))
        XCTAssertEqual(count, 2)

        let groups = (0..<count).map { index in
            game_unit_profile_group_view(game, 14, Int32(index))
        }
        let names = groups.compactMap { raw in
            raw.name.map { String(cString: $0) }
        }

        XCTAssertEqual(Set(names), Set(["Bersaglieri Riflemen", "Bersaglieri NCO"]))
        XCTAssertFalse(groups.contains(where: { $0.preferred_casualty_group }))
    }

    func testPreferredMixedProfileCasualtyGroupCanAbsorbFirstShootingWound() {
        var foundControlledAllocation = false

        for seed in 700...900 {
            guard let automaticGame = game_create_demo(UInt32(seed)),
                  let preferredGame = game_create_demo(UInt32(seed)) else {
                XCTFail("Failed to create demo game")
                return
            }

            let profileCount = Int(game_unit_profile_group_count(preferredGame, 14))
            let ncoIndex = (0..<profileCount).first { index in
                game_unit_profile_group_view(preferredGame, 14, Int32(index)).name.map { String(cString: $0) } == "Bersaglieri NCO"
            }
            guard let ncoIndex else {
                game_destroy(automaticGame)
                game_destroy(preferredGame)
                XCTFail("Bersaglieri NCO profile group was missing")
                return
            }

            game_advance_phase(automaticGame)
            game_advance_phase(preferredGame)

            XCTAssertTrue(game_set_preferred_casualty_group(preferredGame, 14, Int32(ncoIndex)))
            XCTAssertTrue(game_shoot_unit(automaticGame, 3, 14))
            XCTAssertTrue(game_shoot_unit(preferredGame, 3, 14))
            XCTAssertTrue(resolveAllPendingHitAllocations(in: automaticGame))
            XCTAssertTrue(resolveAllPendingHitAllocations(prioritizing: "Bersaglieri NCO", in: preferredGame))

            let automaticBersaglieri = unitView(withID: 14, in: automaticGame)
            let preferredBersaglieri = unitView(withID: 14, in: preferredGame)
            let preferredNCO = game_unit_profile_group_view(preferredGame, 14, Int32(ncoIndex))

            if automaticBersaglieri.total_wounds_remaining == 3 && automaticBersaglieri.models == 2 &&
                preferredBersaglieri.total_wounds_remaining == 3 && preferredBersaglieri.models == 3 {
                foundControlledAllocation = true
                XCTAssertEqual(preferredNCO.lead_model_wounds, 1)
                XCTAssertTrue(preferredNCO.preferred_casualty_group)
                game_destroy(automaticGame)
                game_destroy(preferredGame)
                break
            }

            game_destroy(automaticGame)
            game_destroy(preferredGame)
        }

        XCTAssertTrue(foundControlledAllocation)
    }

    func testMixedProfileShootingCanPauseForManualHitAllocation() {
        var foundPendingAllocation = false

        for seed in 1...512 {
            guard let game = game_create_demo(UInt32(seed)) else {
                XCTFail("Failed to create demo game")
                return
            }

            guard game_move_unit(game, 12, 28.3, 16.5) else {
                game_destroy(game)
                continue
            }
            game_advance_phase(game)

            guard game_shoot_unit(game, 12, 14) else {
                game_destroy(game)
                continue
            }

            let pending = game_pending_hit_allocation_view(game)
            if !pending.active {
                game_destroy(game)
                continue
            }

            foundPendingAllocation = true
            XCTAssertEqual(pending.attacker_name.map { String(cString: $0) }, "Royal Engineers Flamethrower Team")
            XCTAssertEqual(pending.source_name.map { String(cString: $0) }, "Flamethrower")
            XCTAssertEqual(pending.target_name.map { String(cString: $0) }, "Italian Bersaglieri Squad")
            XCTAssertGreaterThan(Int(pending.total_hits), 0)
            XCTAssertEqual(Int(pending.hits_assigned), 0)
            XCTAssertEqual(Int(pending.hits_remaining), Int(pending.total_hits))

            let phaseBeforeBlockedAdvance = game_view(game).phase
            game_advance_phase(game)
            XCTAssertEqual(game_view(game).phase, phaseBeforeBlockedAdvance)
            XCTAssertTrue(String(cString: game_last_error(game)).contains("mixed-profile hit allocation"))
            game_destroy(game)
            break
        }

        XCTAssertTrue(foundPendingAllocation)
    }

    func testManualHitAllocationCanChangeWhoTakesSingleFlamerHit() {
        var foundManualDifference = false

        func resolvePendingHits(prioritizing preferredGroupName: String, in game: OpaquePointer) {
            while game_pending_hit_allocation_view(game).active {
                let targetID = game_pending_hit_allocation_view(game).target_id
                let count = Int(game_unit_profile_group_count(game, targetID))
                let groups = (0..<count).map { index in
                    game_unit_profile_group_view(game, targetID, Int32(index))
                }

                let preferred = groups.first { raw in
                    raw.name.map { String(cString: $0) } == preferredGroupName
                }
                let fallback = groups.first { raw in
                    Int(raw.models) > 0
                }

                if let preferred, Int(preferred.models) > 0,
                   game_choose_pending_hit_allocation(game, preferred.index) {
                    continue
                }

                guard let fallback else {
                    XCTFail("No live mixed-profile group remained for pending allocation")
                    return
                }
                XCTAssertTrue(game_choose_pending_hit_allocation(game, fallback.index))
            }
        }

        for seed in 1...512 {
            guard let riflemenGame = game_create_demo(UInt32(seed)),
                  let ncoGame = game_create_demo(UInt32(seed)) else {
                XCTFail("Failed to create demo game")
                return
            }

            guard game_move_unit(riflemenGame, 12, 28.3, 16.5),
                  game_move_unit(ncoGame, 12, 28.3, 16.5) else {
                game_destroy(riflemenGame)
                game_destroy(ncoGame)
                continue
            }
            game_advance_phase(riflemenGame)
            game_advance_phase(ncoGame)

            guard game_shoot_unit(riflemenGame, 12, 14),
                  game_shoot_unit(ncoGame, 12, 14) else {
                game_destroy(riflemenGame)
                game_destroy(ncoGame)
                continue
            }

            let pendingRiflemen = game_pending_hit_allocation_view(riflemenGame)
            let pendingNCO = game_pending_hit_allocation_view(ncoGame)
            if !pendingRiflemen.active || !pendingNCO.active || pendingRiflemen.total_hits != 1 || pendingNCO.total_hits != 1 {
                game_destroy(riflemenGame)
                game_destroy(ncoGame)
                continue
            }

            resolvePendingHits(prioritizing: "Bersaglieri Riflemen", in: riflemenGame)
            resolvePendingHits(prioritizing: "Bersaglieri NCO", in: ncoGame)

            let riflemenAfterRiflemen = profileGroupView(named: "Bersaglieri Riflemen", unitID: 14, in: riflemenGame)
            let riflemenAfterNCO = profileGroupView(named: "Bersaglieri Riflemen", unitID: 14, in: ncoGame)
            if Int(riflemenAfterRiflemen.models) == 1 && Int(riflemenAfterNCO.models) == 2 {
                foundManualDifference = true
                game_destroy(riflemenGame)
                game_destroy(ncoGame)
                break
            }

            game_destroy(riflemenGame)
            game_destroy(ncoGame)
        }

        XCTAssertTrue(foundManualDifference)
    }

    func testVehicleFollowOnFireWaitsForMixedAllocationBeforeResolvingNextWeapon() {
        var foundPausedVehicleFire = false

        for seed in 1...1024 {
            guard let game = game_create_demo_with_armies(UInt32(seed), DZW_ARMY_AUSTRALIAN, DZW_ARMY_ITALIAN) else {
                XCTFail("Failed to create army demo game")
                return
            }

            let carrier = unitView(named: "Australian Carrier", owner: DZW_PLAYER_ONE, in: game)
            let bersaglieri = unitView(named: "Italian Bersaglieri Squad", owner: DZW_PLAYER_TWO, in: game)
            game_advance_phase(game)

            guard game_shoot_unit(game, carrier.id, bersaglieri.id) else {
                game_destroy(game)
                continue
            }

            let firstPending = game_pending_hit_allocation_view(game)
            if !firstPending.active || firstPending.source_name.map({ String(cString: $0) }) != "Vickers HMG" {
                game_destroy(game)
                continue
            }

            let logsBeforeResolution = (0..<Int(game_log_count(game))).map { index in
                String(cString: game_log_line(game, Int32(index)))
            }
            if logsBeforeResolution.contains(where: { $0.contains("Bren LMG") }) {
                game_destroy(game)
                continue
            }

            foundPausedVehicleFire = true
            XCTAssertTrue(resolveAllPendingHitAllocations(prioritizing: "Bersaglieri Riflemen", in: game))
            XCTAssertFalse(game_pending_hit_allocation_view(game).active)
            game_destroy(game)
            break
        }

        XCTAssertTrue(foundPausedVehicleFire)
    }

    func testMixedProfileCloseCombatRemovesScreeningModelsFirst() {
        var foundSingleUnsavedWound = false

        for seed in 1200...1320 {
            guard let game = game_create_demo(UInt32(seed)) else {
                XCTFail("Failed to create demo game")
                return
            }

            guard game_move_unit(game, 12, 30.4, 13.0) else {
                game_destroy(game)
                continue
            }
            game_advance_phase(game)
            game_advance_phase(game)
            guard game_assault_unit(game, 12, 14, DZW_FOLLOW_UP_ADVANCE) else {
                game_destroy(game)
                continue
            }
            guard resolveAllPendingHitAllocations(in: game) else {
                game_destroy(game)
                continue
            }

            let bersaglieri = unitView(withID: 14, in: game)
            if bersaglieri.total_wounds_remaining == 3 && bersaglieri.models == 2 {
                foundSingleUnsavedWound = true
                game_destroy(game)
                break
            }

            game_destroy(game)
        }

        XCTAssertTrue(foundSingleUnsavedWound)
    }

    func testMixedProfileCloseCombatPausesForManualAllocationBeforeContinuing() {
        var foundPendingMeleeAllocation = false

        for seed in 1200...1320 {
            guard let game = game_create_demo(UInt32(seed)) else {
                XCTFail("Failed to create demo game")
                return
            }

            game_advance_phase(game)
            game_advance_phase(game)
            game_advance_phase(game)
            guard game_move_unit(game, 14, 32.0, 15.0) else {
                game_destroy(game)
                continue
            }
            game_advance_phase(game)
            game_advance_phase(game)
            game_advance_phase(game)
            game_advance_phase(game)
            game_advance_phase(game)
            guard game_assault_unit(game, 12, 14, DZW_FOLLOW_UP_ADVANCE) else {
                game_destroy(game)
                continue
            }

            let pending = game_pending_hit_allocation_view(game)
            guard pending.active else {
                game_destroy(game)
                continue
            }

            foundPendingMeleeAllocation = true
            XCTAssertEqual(pending.target_id, 14)
            XCTAssertEqual(pending.attacker_name.map { String(cString: $0) }, "Royal Engineers Flamethrower Team")
            XCTAssertTrue((pending.source_name.map { String(cString: $0) } ?? "").contains("Royal Engineers Flamethrower Team"))

            XCTAssertTrue(resolveAllPendingHitAllocations(in: game))
            XCTAssertFalse(game_pending_hit_allocation_view(game).active)

            let logLines = (0..<Int(game_log_count(game))).map { index in
                String(cString: game_log_line(game, Int32(index)))
            }
            XCTAssertTrue(logLines.contains(where: { $0.contains("Initiative") && $0.contains("Royal Engineers Flamethrower Team") }))

            game_destroy(game)
            break
        }

        XCTAssertTrue(foundPendingMeleeAllocation)
    }

    func testMixedProfileCloseCombatFromCoverPausesForManualAllocationBeforeContinuing() {
        var foundPendingMeleeAllocation = false

        for seed in 1200...1320 {
            guard let game = game_create_demo(UInt32(seed)) else {
                XCTFail("Failed to create demo game")
                return
            }

            guard game_move_unit(game, 12, 30.4, 13.0) else {
                game_destroy(game)
                continue
            }
            game_advance_phase(game)
            game_advance_phase(game)
            guard game_assault_unit(game, 12, 14, DZW_FOLLOW_UP_ADVANCE) else {
                game_destroy(game)
                continue
            }

            let pending = game_pending_hit_allocation_view(game)
            guard pending.active else {
                game_destroy(game)
                continue
            }

            foundPendingMeleeAllocation = true
            XCTAssertEqual(pending.target_id, 14)
            XCTAssertEqual(pending.attacker_name.map { String(cString: $0) }, "Royal Engineers Flamethrower Team")

            let beforeResolveLogLines = (0..<Int(game_log_count(game))).map { index in
                String(cString: game_log_line(game, Int32(index)))
            }
            XCTAssertTrue(beforeResolveLogLines.contains(where: { $0.contains("strikes first from cover") }))

            XCTAssertTrue(resolveAllPendingHitAllocations(in: game))
            XCTAssertFalse(game_pending_hit_allocation_view(game).active)

            let afterResolveLogLines = (0..<Int(game_log_count(game))).map { index in
                String(cString: game_log_line(game, Int32(index)))
            }
            XCTAssertTrue(afterResolveLogLines.contains(where: { $0.contains("Royal Engineers Flamethrower Team inflicts") }))

            game_destroy(game)
            break
        }

        XCTAssertTrue(foundPendingMeleeAllocation)
    }

    func testMixedProfileSimultaneousCloseCombatPausesForManualAllocationBeforeContinuing() {
        var foundPendingMeleeAllocation = false

        for seed in 1...512 {
            guard let game = game_create_demo_with_armies(UInt32(seed), DZW_ARMY_AUSTRALIAN, DZW_ARMY_ITALIAN) else {
                XCTFail("Failed to create army demo game")
                return
            }

            let command = unitView(named: "Australian Platoon HQ", owner: DZW_PLAYER_ONE, in: game)
            let bersaglieri = unitView(named: "Italian Bersaglieri Squad", owner: DZW_PLAYER_TWO, in: game)

            guard game_move_unit(game, command.id, 25.0, 33.0) else {
                game_destroy(game)
                continue
            }
            game_advance_phase(game)
            game_advance_phase(game)
            game_advance_phase(game)

            guard game_move_unit(game, bersaglieri.id, 37.0, 34.0) else {
                game_destroy(game)
                continue
            }
            game_advance_phase(game)
            game_advance_phase(game)
            game_advance_phase(game)

            guard game_move_unit(game, command.id, 31.0, 33.0) else {
                game_destroy(game)
                continue
            }
            game_advance_phase(game)
            game_advance_phase(game)

            guard game_assault_unit(game, command.id, bersaglieri.id, DZW_FOLLOW_UP_ADVANCE) else {
                game_destroy(game)
                continue
            }

            let pending = game_pending_hit_allocation_view(game)
            guard pending.active else {
                game_destroy(game)
                continue
            }

            foundPendingMeleeAllocation = true
            XCTAssertEqual(pending.target_id, bersaglieri.id)
            XCTAssertEqual(pending.attacker_name.map { String(cString: $0) }, "Australian Platoon HQ")

            let beforeResolveLogLines = (0..<Int(game_log_count(game))).map { index in
                String(cString: game_log_line(game, Int32(index)))
            }
            XCTAssertFalse(beforeResolveLogLines.contains(where: { $0.contains("Initiative 3 is simultaneous") }))

            XCTAssertTrue(resolveAllPendingHitAllocations(prioritizing: "Bersaglieri Riflemen", in: game))
            XCTAssertFalse(game_pending_hit_allocation_view(game).active)

            let afterResolveLogLines = (0..<Int(game_log_count(game))).map { index in
                String(cString: game_log_line(game, Int32(index)))
            }
            XCTAssertTrue(afterResolveLogLines.contains(where: { $0.contains("Initiative 3 is simultaneous") }))

            game_destroy(game)
            break
        }

        XCTAssertTrue(foundPendingMeleeAllocation)
    }

    func testCloseCombatFrontageCapLimitsInfantryModelsBroughtToBear() {
        guard let game = game_create_demo(1600) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        XCTAssertTrue(game_move_unit(game, 1, 15.0, 32.0))
        game_advance_phase(game)
        game_advance_phase(game)
        game_advance_phase(game)

        XCTAssertTrue(game_move_unit(game, 13, 20.0, 26.0))
        game_advance_phase(game)
        game_advance_phase(game)
        game_advance_phase(game)

        XCTAssertTrue(game_move_unit(game, 1, 18.0, 29.5))
        game_advance_phase(game)
        game_advance_phase(game)

        XCTAssertTrue(game_assault_unit(game, 1, 13, DZW_FOLLOW_UP_ADVANCE))

        let logLines = (0..<Int(game_log_count(game))).map { index in
            String(cString: game_log_line(game, Int32(index)))
        }
        XCTAssertTrue(logLines.contains(where: { $0.contains("British Rifle Section can only bring 8 of 10 models to bear on Soviet Guards SMG Squad at Initiative 4.") }))
    }

    func testMixedProfileAttackerUsesProfileGroupStatsInCloseCombat() {
        guard let game = game_create_demo(1500) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        XCTAssertTrue(game_move_unit(game, 12, 26, 15))
        game_advance_phase(game)
        game_advance_phase(game)
        game_advance_phase(game)
        game_advance_phase(game)
        game_advance_phase(game)

        XCTAssertTrue(game_assault_unit(game, 14, 12, DZW_FOLLOW_UP_ADVANCE))

        let logLines = (0..<Int(game_log_count(game))).map { index in
            String(cString: game_log_line(game, Int32(index)))
        }
        XCTAssertTrue(logLines.contains(where: { $0.contains("Bersaglieri NCO in Italian Bersaglieri Squad") }))
    }

    func testMixedProfileCloseCombatResolvesHigherInitiativeGroupFirst() {
        guard let game = game_create_demo(1500) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        XCTAssertTrue(game_move_unit(game, 12, 26, 15))
        game_advance_phase(game)
        game_advance_phase(game)
        game_advance_phase(game)
        game_advance_phase(game)
        game_advance_phase(game)

        XCTAssertTrue(game_assault_unit(game, 14, 12, DZW_FOLLOW_UP_ADVANCE))

        let logLines = (0..<Int(game_log_count(game))).map { index in
            String(cString: game_log_line(game, Int32(index)))
        }
        guard let ncoLine = logLines.firstIndex(where: { $0.contains("Bersaglieri NCO in Italian Bersaglieri Squad") }),
              let riflemenLine = logLines.firstIndex(where: { $0.contains("Bersaglieri Riflemen in Italian Bersaglieri Squad") }) else {
            XCTFail("Expected mixed-profile melee logs were missing")
            return
        }

        XCTAssertLessThan(ncoLine, riflemenLine)
    }

    func testStrengthDoubleCausesInstantDeathOnMultiWoundModels() {
        var foundInstantDeath = false

        for seed in 900...1100 {
            guard let game = game_create_demo(UInt32(seed)) else {
                XCTFail("Failed to create demo game")
                return
            }

            guard game_move_unit(game, 7, 20, 11),
                  game_rotate_unit(game, 7, 45) else {
                game_destroy(game)
                continue
            }
            game_advance_phase(game)
            guard game_shoot_unit(game, 7, 13) else {
                game_destroy(game)
                continue
            }

            let sovietGuards = unitView(withID: 13, in: game)
            if sovietGuards.total_wounds_remaining < 6 {
                foundInstantDeath = true
                XCTAssertEqual(Int(sovietGuards.models), 2)
                XCTAssertEqual(Int(sovietGuards.total_wounds_remaining), 4)
                game_destroy(game)
                break
            }

            game_destroy(game)
        }

        XCTAssertTrue(foundInstantDeath)
    }

    func testAssaultGunCanMoveAndShootInSameTurn() {
        guard let game = game_create_demo(131) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        game_advance_phase(game)
        game_advance_phase(game)
        game_advance_phase(game)

        XCTAssertTrue(game_move_unit(game, 11, 21, 24))
        game_advance_phase(game)
        XCTAssertTrue(game_shoot_unit(game, 11, 2))

        let assaultGun = unitView(withID: 11, in: game)
        XCTAssertTrue(assaultGun.shot_this_turn)
    }

    func testInfantryCanAssaultVehicleWithoutLockingCombat() {
        guard let game = game_create_demo(132) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        XCTAssertTrue(game_move_unit(game, 3, 28, 14))
        game_advance_phase(game)
        game_advance_phase(game)
        game_advance_phase(game)

        game_advance_phase(game)
        game_advance_phase(game)
        XCTAssertTrue(game_assault_unit(game, 4, 3, DZW_FOLLOW_UP_ADVANCE))

        let italians = unitView(withID: 4, in: game)
        let reconVehicle = unitView(withID: 3, in: game)
        XCTAssertTrue(italians.assaulted_this_turn)
        XCTAssertFalse(italians.locked_in_assault)
        XCTAssertFalse(reconVehicle.locked_in_assault)
    }

    func testAssaultGunCanBeAssaultedInCloseCombat() {
        guard let game = game_create_demo(133) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        XCTAssertTrue(game_move_unit(game, 2, 19, 28))
        game_advance_phase(game)
        game_advance_phase(game)
        XCTAssertTrue(game_assault_unit(game, 2, 11, DZW_FOLLOW_UP_ADVANCE))

        let rifleSection = unitView(withID: 2, in: game)
        XCTAssertTrue(rifleSection.assaulted_this_turn)
    }

    func testWinnerConsolidatesAfterDestroyingEnemyInCloseCombat() {
        var foundSuccessfulWipeout = false

        for seed in 1...512 {
            guard let game = game_create_demo(UInt32(seed)) else {
                XCTFail("Failed to create demo game")
                return
            }

            game_advance_phase(game)
            game_advance_phase(game)
            game_advance_phase(game)

            guard game_move_unit(game, 11, 25.0, 20.0) else {
                game_destroy(game)
                continue
            }

            game_advance_phase(game)
            game_advance_phase(game)

            guard game_assault_unit(game, 11, 12, DZW_FOLLOW_UP_CONSOLIDATE) else {
                game_destroy(game)
                continue
            }

            let flamer = unitView(withID: 12, in: game)
            if !flamer.destroyed {
                game_destroy(game)
                continue
            }

            let assaultGun = unitView(withID: 11, in: game)
            let logLines = (0..<Int(game_log_count(game))).map { index in
                String(cString: game_log_line(game, Int32(index)))
            }

            guard logLines.contains(where: { $0.contains("Semovente 75/18 consolidates 3\" after destroying Royal Engineers Flamethrower Team in close combat.") }) else {
                game_destroy(game)
                continue
            }

            foundSuccessfulWipeout = true
            XCTAssertLessThan(Double(assaultGun.y), 15.0)
            XCTAssertFalse(assaultGun.locked_in_assault)
            game_destroy(game)
            break
        }

        XCTAssertTrue(foundSuccessfulWipeout)
    }

    func testConsolidationStopsShortOfNewEnemyUnit() {
        var foundBlockedConsolidation = false

        for seed in 1...512 {
            guard let game = game_create_demo(UInt32(seed)) else {
                XCTFail("Failed to create demo game")
                return
            }

            guard game_move_unit(game, 3, 25.0, 10.5) else {
                game_destroy(game)
                continue
            }
            game_advance_phase(game)
            game_advance_phase(game)
            game_advance_phase(game)

            guard game_move_unit(game, 11, 25.0, 20.0) else {
                game_destroy(game)
                continue
            }
            game_advance_phase(game)
            game_advance_phase(game)

            guard game_assault_unit(game, 11, 12, DZW_FOLLOW_UP_CONSOLIDATE) else {
                game_destroy(game)
                continue
            }

            let flamer = unitView(withID: 12, in: game)
            if !flamer.destroyed {
                game_destroy(game)
                continue
            }

            let assaultGun = unitView(withID: 11, in: game)
            let reconVehicle = unitView(withID: 3, in: game)
            let edgeDistance = hypot(Double(assaultGun.x - reconVehicle.x), Double(assaultGun.y - reconVehicle.y)) - Double(assaultGun.footprint_radius + reconVehicle.footprint_radius)
            let logLines = (0..<Int(game_log_count(game))).map { index in
                String(cString: game_log_line(game, Int32(index)))
            }

            guard logLines.contains(where: { $0.contains("stopping short of a new combat") }) else {
                game_destroy(game)
                continue
            }

            foundBlockedConsolidation = true
            XCTAssertGreaterThanOrEqual(edgeDistance, 0.99)
            game_destroy(game)
            break
        }

        XCTAssertTrue(foundBlockedConsolidation)
    }

    func testChargeFailsWhenAnotherEnemyBlocksLegalContact() {
        var foundBlockedCharge = false

        for seed in 1...512 {
            guard let game = game_create_demo(UInt32(seed)) else {
                XCTFail("Failed to create demo game")
                return
            }

            guard game_move_unit(game, 2, 20.0, 24.0) else {
                game_destroy(game)
                continue
            }
            game_advance_phase(game)
            game_advance_phase(game)
            game_advance_phase(game)

            guard game_move_unit(game, 14, 28.0, 22.0),
                  game_move_unit(game, 13, 24.9, 22.0) else {
                game_destroy(game)
                continue
            }
            game_advance_phase(game)
            game_advance_phase(game)
            game_advance_phase(game)
            game_advance_phase(game)
            game_advance_phase(game)

            XCTAssertFalse(game_assault_unit(game, 2, 14, DZW_FOLLOW_UP_ADVANCE))
            let error = String(cString: game_last_error(game))
            if !error.contains("legal way to contact") {
                game_destroy(game)
                continue
            }

            let assault = unitView(withID: 2, in: game)
            foundBlockedCharge = true
            XCTAssertEqual(Double(assault.x), 20.0, accuracy: 0.01)
            XCTAssertEqual(Double(assault.y), 24.0, accuracy: 0.01)
            game_destroy(game)
            break
        }

        XCTAssertTrue(foundBlockedCharge)
    }

    func testTransportCannotDisembarkInSameTurnItEmbarked() {
        guard let game = game_create_demo(134) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        XCTAssertTrue(game_embark_unit(game, 9, 10))
        XCTAssertFalse(game_disembark_unit(game, 10))
        XCTAssertFalse(String(cString: game_last_error(game)).isEmpty)
    }

    func testDisembarkCanUseOuterPartOfTwoInchZone() {
        guard let game = game_create_demo_with_armies(601, DZW_ARMY_BRITISH, DZW_ARMY_ITALIAN) else {
            XCTFail("Failed to create army preset demo")
            return
        }
        defer { game_destroy(game) }

        let transport = unitView(named: "Universal Carrier Transport", owner: DZW_PLAYER_ONE, in: game)
        let command = unitView(named: "British Platoon HQ", owner: DZW_PLAYER_ONE, in: game)
        let reconVehicle = unitView(named: "Universal Carrier", owner: DZW_PLAYER_ONE, in: game)
        let mortar = unitView(named: "3-inch Mortar Battery", owner: DZW_PLAYER_ONE, in: game)
        let assault = unitView(named: "British Commando Section", owner: DZW_PLAYER_ONE, in: game)
        let tactical = unitView(named: "British Rifle Section", owner: DZW_PLAYER_ONE, in: game)
        XCTAssertTrue(command.embarked)

        let innerRadius = Double(transport.footprint_radius + command.footprint_radius) + 1.0
        let facing = Double(transport.facing_degrees)
        func point(offset degrees: Double) -> (Float, Float) {
            let radians = (facing + degrees) * .pi / 180.0
            return (
                Float(Double(transport.x) + cos(radians) * innerRadius),
                Float(Double(transport.y) + sin(radians) * innerRadius)
            )
        }

        let right = point(offset: 0)
        let top = point(offset: 90)
        let bottom = point(offset: -90)
        let left = point(offset: 180)

        XCTAssertTrue(game_move_unit(game, Int32(reconVehicle.id), right.0, right.1))
        XCTAssertTrue(game_move_unit(game, Int32(mortar.id), top.0, top.1))
        XCTAssertTrue(game_move_unit(game, Int32(assault.id), bottom.0, bottom.1))
        XCTAssertTrue(game_move_unit(game, Int32(tactical.id), left.0, left.1))

        XCTAssertTrue(game_disembark_unit(game, Int32(transport.id)))

        let transportAfter = unitView(named: "Universal Carrier Transport", owner: DZW_PLAYER_ONE, in: game)
        let commandAfter = unitView(named: "British Platoon HQ", owner: DZW_PLAYER_ONE, in: game)
        XCTAssertFalse(commandAfter.embarked)

        let edgeDistance = hypot(Double(commandAfter.x - transportAfter.x), Double(commandAfter.y - transportAfter.y)) - Double(commandAfter.footprint_radius + transportAfter.footprint_radius)
        XCTAssertGreaterThan(edgeDistance, 1.0)
        XCTAssertLessThanOrEqual(edgeDistance, 2.05)
    }

    func testDisembarkAfterTransportMovePreventsExtraMove() {
        guard let game = game_create_demo(135) else {
            XCTFail("Failed to create demo game")
            return
        }
        defer { game_destroy(game) }

        XCTAssertTrue(game_embark_unit(game, 9, 10))
        game_advance_phase(game)
        game_advance_phase(game)
        game_advance_phase(game)
        game_advance_phase(game)
        game_advance_phase(game)
        game_advance_phase(game)

        XCTAssertTrue(game_move_unit(game, 10, 24, 33))
        XCTAssertTrue(game_disembark_unit(game, 10))
        XCTAssertFalse(game_move_unit(game, 9, 31, 33))

        let command = unitView(withID: 9, in: game)
        XCTAssertFalse(command.embarked)
        XCTAssertEqual(Int(command.embarked_in_transport_id), 0)
        XCTAssertFalse(String(cString: game_last_error(game)).isEmpty)
    }

    func testDestroyedTransportCanWoundPassengersBeforeEmergencyDisembark() {
        var foundDestroyedTransport = false
        var foundPassengerDamage = false

        for seed in 520...620 {
            guard let game = game_create_demo(UInt32(seed)) else {
                XCTFail("Failed to create demo game")
                return
            }

            XCTAssertTrue(game_embark_unit(game, 9, 10))
            XCTAssertTrue(game_move_unit(game, 10, 18.5, 28.5))
            for _ in 0..<5 {
                game_advance_phase(game)
            }

            XCTAssertTrue(game_assault_unit(game, 11, 10, DZW_FOLLOW_UP_ADVANCE))

            let transport = unitView(withID: 10, in: game)
            let command = unitView(withID: 9, in: game)
            if transport.destroyed {
                foundDestroyedTransport = true
                XCTAssertFalse(command.embarked)
                if command.models < 5 {
                    foundPassengerDamage = true
                    game_destroy(game)
                    break
                }
            }

            game_destroy(game)
        }

        XCTAssertTrue(foundDestroyedTransport)
        XCTAssertTrue(foundPassengerDamage)
    }

    func testDestroyedTransportPinsSurvivingPassengersUntilTheirNextTurn() {
        var foundPinnedSurvivor = false

        for seed in 520...700 {
            guard let game = game_create_demo(UInt32(seed)) else {
                XCTFail("Failed to create demo game")
                return
            }

            XCTAssertTrue(game_embark_unit(game, 9, 10))
            XCTAssertTrue(game_move_unit(game, 10, 18.5, 28.5))
            for _ in 0..<5 {
                game_advance_phase(game)
            }

            XCTAssertTrue(game_assault_unit(game, 11, 10, DZW_FOLLOW_UP_ADVANCE))

            let transport = unitView(withID: 10, in: game)
            let commandAfterCrash = unitView(withID: 9, in: game)
            if !transport.destroyed || commandAfterCrash.destroyed || commandAfterCrash.embarked {
                game_destroy(game)
                continue
            }

            game_advance_phase(game)

            let commandPinned = unitView(withID: 9, in: game)
            if !commandPinned.pinned {
                game_destroy(game)
                continue
            }

            foundPinnedSurvivor = true
            XCTAssertFalse(game_move_unit(game, 9, 22, 33))
            XCTAssertFalse(String(cString: game_last_error(game)).isEmpty)
            game_destroy(game)
            break
        }

        XCTAssertTrue(foundPinnedSurvivor)
    }

    func testDestroyedTransportCanSlewBeforePassengerPlacement() {
        var foundSlewedWreck = false

        for seed in 520...900 {
            guard let game = game_create_demo(UInt32(seed)) else {
                XCTFail("Failed to create demo game")
                return
            }

            XCTAssertTrue(game_embark_unit(game, 9, 10))
            XCTAssertTrue(game_move_unit(game, 10, 18.5, 28.5))
            for _ in 0..<5 {
                game_advance_phase(game)
            }

            XCTAssertTrue(game_assault_unit(game, 11, 10, DZW_FOLLOW_UP_ADVANCE))

            let transport = unitView(withID: 10, in: game)
            let command = unitView(withID: 9, in: game)
            let logLines = (0..<Int(game_log_count(game))).map { index in
                String(cString: game_log_line(game, Int32(index)))
            }

            if transport.destroyed,
               (!transport.embarked),
               !command.embarked,
               logLines.contains(where: { $0.contains("wreck slews") }) {
                foundSlewedWreck = true
                XCTAssertTrue(abs(transport.x - 18.5) > 0.05 || abs(transport.y - 28.5) > 0.05)
                game_destroy(game)
                break
            }

            game_destroy(game)
        }

        XCTAssertTrue(foundSlewedWreck)
    }

    func testSlewingWreckMakesNearbyModelsLeapAside() {
        var foundLeapAside = false

        for seed in 520...1400 {
            guard let game = game_create_demo(UInt32(seed)) else {
                XCTFail("Failed to create demo game")
                return
            }

            guard game_move_unit(game, 2, 14.0, 26.0),
                  game_embark_unit(game, 9, 10),
                  game_move_unit(game, 10, 18.5, 28.5) else {
                game_destroy(game)
                continue
            }
            let assaultBefore = unitView(withID: 2, in: game)

            for _ in 0..<5 {
                game_advance_phase(game)
            }

            guard game_assault_unit(game, 11, 10, DZW_FOLLOW_UP_ADVANCE) else {
                game_destroy(game)
                continue
            }

            let transport = unitView(withID: 10, in: game)
            let assaultAfter = unitView(withID: 2, in: game)
            let logLines = (0..<Int(game_log_count(game))).map { index in
                String(cString: game_log_line(game, Int32(index)))
            }

            if !transport.destroyed ||
                !logLines.contains(where: { $0.contains("Universal Carrier Transport's wreck slews") }) ||
                !logLines.contains(where: { $0.contains("British Commando Section leaps aside from Universal Carrier Transport's slewing wreck") }) {
                game_destroy(game)
                continue
            }

            foundLeapAside = true
            XCTAssertTrue(abs(assaultAfter.x - assaultBefore.x) > 0.05 || abs(assaultAfter.y - assaultBefore.y) > 0.05)
            let separation = hypot(Double(assaultAfter.x - transport.x), Double(assaultAfter.y - transport.y)) - Double(assaultAfter.footprint_radius + transport.footprint_radius)
            XCTAssertGreaterThanOrEqual(separation, -0.01)
            game_destroy(game)
            break
        }

        XCTAssertTrue(foundLeapAside)
    }

    func testCrewStunnedTransportCannotDisembark() {
        var foundCrewStunnedTransport = false

        for seed in 520...1000 {
            guard let game = game_create_demo(UInt32(seed)) else {
                XCTFail("Failed to create demo game")
                return
            }

            XCTAssertTrue(game_embark_unit(game, 9, 10))
            XCTAssertTrue(game_move_unit(game, 10, 18.5, 28.5))
            for _ in 0..<5 {
                game_advance_phase(game)
            }

            XCTAssertTrue(game_assault_unit(game, 11, 10, DZW_FOLLOW_UP_ADVANCE))

            let transportAfterAssault = unitView(withID: 10, in: game)
            let commandAfterAssault = unitView(withID: 9, in: game)
            if transportAfterAssault.destroyed || !commandAfterAssault.embarked {
                game_destroy(game)
                continue
            }

            game_advance_phase(game)

            if game_disembark_unit(game, 10) {
                game_destroy(game)
                continue
            }

            let error = String(cString: game_last_error(game))
            if error.contains("crew stunned") {
                foundCrewStunnedTransport = true
                game_destroy(game)
                break
            }

            game_destroy(game)
        }

        XCTAssertTrue(foundCrewStunnedTransport)
    }

    func testCrewStunnedFromDeathOrGloryPersistsUntilVehicleNextTurn() {
        var foundPersistentCrewStun = false

        for seed in 1...2048 {
            guard let game = game_create_demo(UInt32(seed)) else {
                XCTFail("Failed to create demo game")
                return
            }

            XCTAssertTrue(game_move_unit(game, 3, 27.0, 14.0))

            for _ in 0..<6 {
                game_advance_phase(game)
            }

            let sovietGuards = unitView(named: "Soviet Guards SMG Squad", owner: DZW_PLAYER_TWO, in: game)
            let reconVehicleBeforeShock = unitView(withID: 3, in: game)
            game_seed(game, UInt32(seed))

            guard game_tank_shock_unit(game, Int32(reconVehicleBeforeShock.id), Int32(sovietGuards.id)) else {
                game_destroy(game)
                continue
            }

            let reconVehicleAfterShock = unitView(withID: 3, in: game)
            let logLines = (0..<Int(game_log_count(game))).map { index in
                String(cString: game_log_line(game, Int32(index)))
            }

            if reconVehicleAfterShock.destroyed ||
                !logLines.contains(where: { $0.contains("Universal Carrier suffers Crew Stunned") }) {
                game_destroy(game)
                continue
            }

            for _ in 0..<6 {
                game_advance_phase(game)
            }

            foundPersistentCrewStun = true

            let reconVehicleNextTurn = unitView(withID: 3, in: game)
            XCTAssertFalse(reconVehicleNextTurn.can_move_now)
            XCTAssertFalse(game_move_unit(game, Int32(reconVehicleNextTurn.id), reconVehicleNextTurn.x - 1.0, reconVehicleNextTurn.y))
            let error = String(cString: game_last_error(game))
            XCTAssertTrue(error.contains("crew stunned"))
            game_destroy(game)
            break
        }

        XCTAssertTrue(foundPersistentCrewStun)
    }

    func testImmobilizedVehicleCannotTurnInPlace() {
        var foundImmobilizedTransport = false

        for seed in 520...1200 {
            guard let game = game_create_demo(UInt32(seed)) else {
                XCTFail("Failed to create demo game")
                return
            }

            XCTAssertTrue(game_move_unit(game, 10, 18.5, 28.5))
            for _ in 0..<5 {
                game_advance_phase(game)
            }

            XCTAssertTrue(game_assault_unit(game, 11, 10, DZW_FOLLOW_UP_ADVANCE))

            let transportAfterAssault = unitView(withID: 10, in: game)
            if transportAfterAssault.destroyed {
                game_destroy(game)
                continue
            }

            game_advance_phase(game)

            if game_rotate_unit(game, 10, 90) {
                game_destroy(game)
                continue
            }

            let error = String(cString: game_last_error(game))
            if error.contains("may not turn in place") {
                let transportAfterFailedPivot = unitView(withID: 10, in: game)
                foundImmobilizedTransport = true
                XCTAssertEqual(transportAfterFailedPivot.facing_degrees, transportAfterAssault.facing_degrees, accuracy: 0.01)
                game_destroy(game)
                break
            }

            game_destroy(game)
        }

        XCTAssertTrue(foundImmobilizedTransport)
    }

    func testSecondImmobilizedResultJamsTurretToLastFiredDirection() {
        var firstImmobilizeSeed: UInt32?
        for assaultSeed in 1...512 {
            guard let game = prepareShermanFireflyDamageScenario() else {
                XCTFail("Failed to prepare jam test scenario")
                return
            }

            game_seed(game, UInt32(assaultSeed))
            guard game_assault_unit(game, 11, 7, DZW_FOLLOW_UP_ADVANCE) else {
                game_destroy(game)
                continue
            }

            let firefly = unitView(withID: 7, in: game)
            let logLines = (0..<Int(game_log_count(game))).map { index in
                String(cString: game_log_line(game, Int32(index)))
            }
            if !firefly.destroyed,
               !game_pending_weapon_destroy_view(game).active,
               logLines.contains(where: { $0.contains("Sherman Firefly is immobilized") }),
               !logLines.contains(where: { $0.contains("Sherman Firefly loses 17-pounder Anti-Tank Gun") }),
               !logLines.contains(where: { $0.contains("jams in place") }) {
                firstImmobilizeSeed = UInt32(assaultSeed)
                game_destroy(game)
                break
            }

            game_destroy(game)
        }

        guard let firstImmobilizeSeed else {
            XCTFail("Could not find a deterministic first immobilized assault seed")
            return
        }

        var foundJammedTurret = false

        for secondAssaultSeed in 1...512 {
            guard let game = prepareShermanFireflyDamageScenario() else {
                XCTFail("Failed to prepare jam test scenario")
                return
            }

            game_seed(game, firstImmobilizeSeed)
            guard game_assault_unit(game, 11, 7, DZW_FOLLOW_UP_ADVANCE) else {
                game_destroy(game)
                continue
            }

            let fireflyAfterFirstAssault = unitView(withID: 7, in: game)
            let firstAssaultLogs = (0..<Int(game_log_count(game))).map { index in
                String(cString: game_log_line(game, Int32(index)))
            }
            if fireflyAfterFirstAssault.destroyed ||
                game_pending_weapon_destroy_view(game).active ||
                !firstAssaultLogs.contains(where: { $0.contains("Sherman Firefly is immobilized") }) ||
                firstAssaultLogs.contains(where: { $0.contains("Sherman Firefly loses 17-pounder Anti-Tank Gun") }) ||
                firstAssaultLogs.contains(where: { $0.contains("jams in place") }) {
                game_destroy(game)
                continue
            }

            for _ in 0..<6 {
                game_advance_phase(game)
            }

            game_seed(game, UInt32(secondAssaultSeed))
            guard game_assault_unit(game, 11, 7, DZW_FOLLOW_UP_ADVANCE) else {
                game_destroy(game)
                continue
            }

            let fireflyAfterSecondAssault = unitView(withID: 7, in: game)
            let logLines = (0..<Int(game_log_count(game))).map { index in
                String(cString: game_log_line(game, Int32(index)))
            }
            if fireflyAfterSecondAssault.destroyed || !logLines.contains(where: { $0.contains("Sherman Firefly's 17-pounder Anti-Tank Gun jams in place") }) {
                game_destroy(game)
                continue
            }

            foundJammedTurret = true

            game_advance_phase(game)
            game_advance_phase(game)

            let sovietGuards = unitView(withID: 13, in: game)
            XCTAssertFalse(sovietGuards.destroyed)
            XCTAssertFalse(game_shoot_unit(game, 7, 13))
            let error = String(cString: game_last_error(game))
            XCTAssertFalse(error.isEmpty)
            game_destroy(game)
            break
        }

        XCTAssertTrue(foundJammedTurret)
    }

    func testCrewStunnedAssaultGunCannotLaunchAssaultOnFollowingTurn() {
        var foundCrewStunnedAssaultGun = false

        for shootingSeed in 1...512 {
            guard let game = game_create_demo(1) else {
                XCTFail("Failed to create demo game")
                return
            }

            XCTAssertTrue(game_move_unit(game, 2, 18.2, 24.0))
            game_advance_phase(game)
            game_seed(game, UInt32(shootingSeed))

            guard game_shoot_unit(game, 7, 11) else {
                game_destroy(game)
                continue
            }

            let logLines = (0..<Int(game_log_count(game))).map { index in
                String(cString: game_log_line(game, Int32(index)))
            }
            if !logLines.contains(where: { $0.contains("Semovente 75/18 suffers Crew Stunned") }) {
                game_destroy(game)
                continue
            }

            foundCrewStunnedAssaultGun = true

            for _ in 0..<5 {
                game_advance_phase(game)
            }

            let assaultGun = unitView(withID: 11, in: game)
            XCTAssertFalse(assaultGun.can_assault_now)
            XCTAssertFalse(game_assault_unit(game, 11, 2, DZW_FOLLOW_UP_ADVANCE))
            let error = String(cString: game_last_error(game))
            XCTAssertFalse(error.isEmpty)
            game_destroy(game)
            break
        }

        XCTAssertTrue(foundCrewStunnedAssaultGun)
    }

    func testCrewStunnedAssaultGunDoesNotStrikeBackWhileLockedInContinuingCombat() {
        func prepareScenario() -> OpaquePointer? {
            guard let game = game_create_demo_with_forces(3, DZW_ARMY_AMERICAN, 1, DZW_ARMY_ITALIAN, 0) else {
                return nil
            }

            let americanTankDestroyer = unitView(named: "M10 Tank Destroyer", owner: DZW_PLAYER_ONE, in: game)
            let italianAssaultGun = unitView(named: "Semovente 75/18", owner: DZW_PLAYER_TWO, in: game)

            guard game_move_unit(game, Int32(americanTankDestroyer.id), 26.0, 10.0) else {
                game_destroy(game)
                return nil
            }
            game_advance_phase(game)
            game_advance_phase(game)
            game_advance_phase(game)

            guard game_move_unit(game, Int32(italianAssaultGun.id), 45.0, 10.0) else {
                game_destroy(game)
                return nil
            }
            game_advance_phase(game)
            game_advance_phase(game)
            game_advance_phase(game)

            guard game_move_unit(game, Int32(americanTankDestroyer.id), 32.0, 10.0) else {
                game_destroy(game)
                return nil
            }
            game_advance_phase(game)
            game_advance_phase(game)
            game_advance_phase(game)

            guard game_move_unit(game, Int32(italianAssaultGun.id), 39.0, 10.0) else {
                game_destroy(game)
                return nil
            }
            game_advance_phase(game)
            game_advance_phase(game)
            game_advance_phase(game)
            game_advance_phase(game)
            game_advance_phase(game)
            return game
        }

        var foundStunnedContinuingCombat = false

        for assaultSeed in 1...512 {
            guard let game = prepareScenario() else {
                XCTFail("Failed to prepare continuing assault-gun combat scenario")
                return
            }

            var americanTankDestroyer = unitView(named: "M10 Tank Destroyer", owner: DZW_PLAYER_ONE, in: game)
            var italianAssaultGun = unitView(named: "Semovente 75/18", owner: DZW_PLAYER_TWO, in: game)

            let firstAssaultLogStart = Int(game_log_count(game))
            game_seed(game, UInt32(assaultSeed))
            guard game_assault_unit(game, Int32(americanTankDestroyer.id), Int32(italianAssaultGun.id), DZW_FOLLOW_UP_ADVANCE) else {
                game_destroy(game)
                continue
            }

            americanTankDestroyer = unitView(named: "M10 Tank Destroyer", owner: DZW_PLAYER_ONE, in: game)
            italianAssaultGun = unitView(named: "Semovente 75/18", owner: DZW_PLAYER_TWO, in: game)
            let firstAssaultLogs = (firstAssaultLogStart..<Int(game_log_count(game))).map { index in
                String(cString: game_log_line(game, Int32(index)))
            }
            if americanTankDestroyer.destroyed ||
                italianAssaultGun.destroyed ||
                !americanTankDestroyer.locked_in_assault ||
                !italianAssaultGun.locked_in_assault ||
                !firstAssaultLogs.contains("Semovente 75/18 suffers Crew Stunned.") {
                game_destroy(game)
                continue
            }

            game_advance_phase(game)
            game_advance_phase(game)
            game_advance_phase(game)

            let tankDestroyerStatusBeforeContinuingCombat = unitView(named: "M10 Tank Destroyer", owner: DZW_PLAYER_ONE, in: game)
            americanTankDestroyer = unitView(named: "M10 Tank Destroyer", owner: DZW_PLAYER_ONE, in: game)
            italianAssaultGun = unitView(named: "Semovente 75/18", owner: DZW_PLAYER_TWO, in: game)
            let logStart = Int(game_log_count(game))
            game_seed(game, 1)
            guard game_assault_unit(game, Int32(italianAssaultGun.id), Int32(americanTankDestroyer.id), DZW_FOLLOW_UP_ADVANCE) else {
                game_destroy(game)
                continue
            }

            americanTankDestroyer = unitView(named: "M10 Tank Destroyer", owner: DZW_PLAYER_ONE, in: game)
            let newLogs = (logStart..<Int(game_log_count(game))).map { index in
                String(cString: game_log_line(game, Int32(index)))
            }

            guard newLogs.contains("Semovente 75/18 is crew stunned and cannot fight in close combat this turn.") else {
                game_destroy(game)
                continue
            }

            foundStunnedContinuingCombat = true
            XCTAssertFalse(newLogs.contains(where: { $0.contains("Semovente 75/18 attacks M10 Tank Destroyer in close combat") }))
            XCTAssertEqual(Int(americanTankDestroyer.models), Int(tankDestroyerStatusBeforeContinuingCombat.models))
            XCTAssertEqual(Int(americanTankDestroyer.total_wounds_remaining), Int(tankDestroyerStatusBeforeContinuingCombat.total_wounds_remaining))
            game_destroy(game)
            break
        }

        XCTAssertTrue(foundStunnedContinuingCombat)
    }

    func testCrewStunnedReconVehicleCoastsOnFollowingMovementPhase() {
        var foundCrewStunnedReconVehicle = false

        for shootingSeed in 1...512 {
            guard let game = game_create_demo(1) else {
                XCTFail("Failed to create demo game")
                return
            }

            for _ in 0..<4 {
                game_advance_phase(game)
            }

            let reconVehicleBeforeShoot = unitView(withID: 3, in: game)
            game_seed(game, UInt32(shootingSeed))

            guard game_shoot_unit(game, 13, 3) else {
                game_destroy(game)
                continue
            }

            let postShotLogs = (0..<Int(game_log_count(game))).map { index in
                String(cString: game_log_line(game, Int32(index)))
            }
            if !postShotLogs.contains(where: { $0.contains("Universal Carrier suffers Crew Stunned") }) {
                game_destroy(game)
                continue
            }

            foundCrewStunnedReconVehicle = true
            let reconVehicleAfterShoot = unitView(withID: 3, in: game)
            XCTAssertEqual(reconVehicleAfterShoot.x, reconVehicleBeforeShoot.x, accuracy: 0.01)
            XCTAssertEqual(reconVehicleAfterShoot.y, reconVehicleBeforeShoot.y, accuracy: 0.01)

            game_advance_phase(game)
            game_advance_phase(game)

            let reconVehicleAfterCoast = unitView(withID: 3, in: game)
            let coastDistance = hypot(Double(reconVehicleAfterCoast.x - reconVehicleAfterShoot.x), Double(reconVehicleAfterCoast.y - reconVehicleAfterShoot.y))
            let coastLogs = (0..<Int(game_log_count(game))).map { index in
                String(cString: game_log_line(game, Int32(index)))
            }

            XCTAssertFalse(reconVehicleAfterCoast.destroyed)
            XCTAssertTrue(reconVehicleAfterCoast.moved_this_turn)
            XCTAssertFalse(reconVehicleAfterCoast.can_move_now)
            XCTAssertEqual(reconVehicleAfterCoast.facing_degrees, reconVehicleAfterShoot.facing_degrees, accuracy: 0.01)
            XCTAssertGreaterThan(coastDistance, 0.1)
            XCTAssertTrue(coastLogs.contains(where: { $0.contains("Universal Carrier coasts") }))

            XCTAssertFalse(game_move_unit(game, 3, reconVehicleAfterCoast.x + 1.0, reconVehicleAfterCoast.y))
            let error = String(cString: game_last_error(game))
            XCTAssertTrue(error.contains("crew stunned"))
            game_destroy(game)
            break
        }

        XCTAssertTrue(foundCrewStunnedReconVehicle)
    }

    func testWeaponDestroyedResultWaitsForAttackerChoice() {
        var foundPendingChoice = false

        for assaultSeed in 1...512 {
            guard let game = prepareShermanFireflyDamageScenario() else {
                XCTFail("Failed to prepare weapon-destroyed choice scenario")
                return
            }

            game_seed(game, UInt32(assaultSeed))
            guard game_assault_unit(game, 11, 7, DZW_FOLLOW_UP_ADVANCE) else {
                game_destroy(game)
                continue
            }

            let pending = game_pending_weapon_destroy_view(game)
            if !pending.active {
                game_destroy(game)
                continue
            }

            let optionCount = Int(game_pending_weapon_destroy_option_count(game))
            let options = (0..<optionCount).map { index in
                game_pending_weapon_destroy_option_view(game, Int32(index))
            }
            let optionNames = options.compactMap { $0.name.map(String.init(cString:)) }
            guard optionNames.contains("17-pounder Anti-Tank Gun"), optionNames.contains("Hull Browning M1919A4") else {
                game_destroy(game)
                continue
            }

            foundPendingChoice = true
            XCTAssertEqual(pending.chooser_name.map { String(cString: $0) }, "Semovente 75/18")
            XCTAssertEqual(pending.target_name.map { String(cString: $0) }, "Sherman Firefly")
            XCTAssertEqual(optionCount, 2)

            let phaseBeforeBlockedAdvance = game_view(game).phase
            game_advance_phase(game)
            XCTAssertEqual(game_view(game).phase, phaseBeforeBlockedAdvance)
            XCTAssertTrue(String(cString: game_last_error(game)).contains("weapon-destroyed choice"))

            guard let hullGun = options.first(where: {
                $0.name.map { String(cString: $0) } == "Hull Browning M1919A4"
            }) else {
                XCTFail("Hull Browning M1919A4 was not offered as a pending damage choice")
                game_destroy(game)
                return
            }

            XCTAssertTrue(game_choose_pending_weapon_destroy(game, hullGun.weapon_index))
            XCTAssertFalse(game_pending_weapon_destroy_view(game).active)

            let logLines = (0..<Int(game_log_count(game))).map { index in
                String(cString: game_log_line(game, Int32(index)))
            }
            XCTAssertTrue(logLines.contains(where: { $0.contains("Semovente 75/18 chooses Hull Browning M1919A4 on Sherman Firefly") }))

            let phaseBeforeResolvedAdvance = game_view(game).phase
            game_advance_phase(game)
            XCTAssertNotEqual(game_view(game).phase, phaseBeforeResolvedAdvance)

            game_destroy(game)
            break
        }

        XCTAssertTrue(foundPendingChoice)
    }

    private var playableArmies: [army_list_t] {
        [
            DZW_ARMY_BRITISH,
            DZW_ARMY_AMERICAN,
            DZW_ARMY_AUSTRALIAN,
            DZW_ARMY_SOVIET,
            DZW_ARMY_GERMAN,
            DZW_ARMY_ITALIAN,
        ]
    }

    private func opposingArmy(for army: army_list_t) -> army_list_t {
        switch army {
        case DZW_ARMY_BRITISH, DZW_ARMY_AMERICAN, DZW_ARMY_AUSTRALIAN, DZW_ARMY_SOVIET:
            return DZW_ARMY_GERMAN
        case DZW_ARMY_GERMAN:
            return DZW_ARMY_BRITISH
        case DZW_ARMY_ITALIAN:
            return DZW_ARMY_AMERICAN
        default:
            return DZW_ARMY_GERMAN
        }
    }

    private func cString(_ value: UnsafePointer<CChar>?) -> String {
        value.map { String(cString: $0) } ?? ""
    }

    private func weaponProfile(named weaponName: String, file: StaticString = #filePath, line: UInt = #line) -> weapon_profile_view_t {
        for index in 0..<Int(wwii_weapon_profile_count()) {
            let profile = wwii_weapon_profile_view(Int32(index))
            if cString(profile.name) == weaponName {
                return profile
            }
        }
        XCTFail("Could not find weapon profile \(weaponName)", file: file, line: line)
        return weapon_profile_view_t()
    }

    private func unitView(withID unitID: Int32, in game: OpaquePointer) -> unit_view_t {
        let count = Int(game_unit_count(game))
        for index in 0..<count {
            let view = game_unit_view(game, Int32(index))
            if view.id == unitID {
                return view
            }
        }
        XCTFail("Could not find unit \(unitID)")
        return unit_view_t()
    }

    private func objectiveView(withID objectiveID: Int32, in game: OpaquePointer) -> objective_view_t {
        let count = Int(game_objective_count(game))
        for index in 0..<count {
            let view = game_objective_view(game, Int32(index))
            if view.id == objectiveID {
                return view
            }
        }
        XCTFail("Could not find objective \(objectiveID)")
        return objective_view_t()
    }

    private func zoneView(withID zoneID: Int32, in game: OpaquePointer) -> zone_view_t {
        let count = Int(game_zone_count(game))
        for index in 0..<count {
            let view = game_zone_view(game, Int32(index))
            if view.id == zoneID {
                return view
            }
        }
        XCTFail("Could not find zone \(zoneID)")
        return zone_view_t()
    }

    private func unitView(named unitName: String, owner: player_t? = nil, in game: OpaquePointer) -> unit_view_t {
        let count = Int(game_unit_count(game))
        for index in 0..<count {
            let view = game_unit_view(game, Int32(index))
            guard let name = view.name.map({ String(cString: $0) }), name == unitName else {
                continue
            }
            if let owner, view.owner != owner {
                continue
            }
            return view
        }
        XCTFail("Could not find unit named \(unitName)")
        return unit_view_t()
    }

    private func orderDiceEligibleUnitCount(in game: OpaquePointer) -> Int {
        let count = Int(game_unit_count(game))
        var eligible = 0
        for index in 0..<count {
            let view = game_unit_view(game, Int32(index))
            if orderDiceUnitCanReceiveDie(view) {
                eligible += 1
            }
        }
        return eligible
    }

    private func orderDiceUnitCanReceiveDie(_ unit: unit_view_t) -> Bool {
        !unit.destroyed &&
        Int(unit.models) > 0 &&
        unit.owner != DZW_PLAYER_NONE &&
        !unit.embarked &&
        !unit.falling_back &&
        !unit.locked_in_assault &&
        !unit.acted_this_turn &&
        !unit.retained_order &&
        unit.current_order == DZW_ORDER_NONE
    }

    private func firstOrderAssignableUnit(owner: player_t, in game: OpaquePointer) -> unit_view_t {
        let count = Int(game_unit_count(game))
        for index in 0..<count {
            let view = game_unit_view(game, Int32(index))
            if view.owner == owner && orderDiceUnitCanReceiveDie(view) {
                return view
            }
        }
        XCTFail("Could not find an order-assignable unit for owner \(owner)")
        return unit_view_t()
    }

    private func drawUntilCurrentDie(owner: player_t, in game: OpaquePointer) -> Bool {
        var attemptsRemaining = Int(game_order_dice_remaining_count(game)) + 1
        while attemptsRemaining > 0 {
            attemptsRemaining -= 1
            let current = game_current_order_die_view(game)
            if current.available {
                if current.owner == owner {
                    return true
                }
                let filler = firstOrderAssignableUnit(owner: current.owner, in: game)
                if !game_assign_order(game, filler.id, DZW_ORDER_DOWN) {
                    return false
                }
                continue
            }
            if !game_draw_order_die(game) {
                return false
            }
        }
        return false
    }

    private func profileGroupView(named groupName: String, unitID: Int32, in game: OpaquePointer) -> profile_group_view_t {
        let count = Int(game_unit_profile_group_count(game, unitID))
        for index in 0..<count {
            let view = game_unit_profile_group_view(game, unitID, Int32(index))
            if view.name.map({ String(cString: $0) }) == groupName {
                return view
            }
        }
        XCTFail("Could not find profile group named \(groupName) on unit \(unitID)")
        return profile_group_view_t()
    }

    private func prepareShermanFireflyDamageScenario() -> OpaquePointer? {
        guard let game = game_create_demo(1) else {
            return nil
        }

        game_advance_phase(game)
        guard game_shoot_unit(game, 7, 4) else {
            game_destroy(game)
            return nil
        }
        game_advance_phase(game)
        game_advance_phase(game)
        guard game_move_unit(game, 11, 22.2, 18.8) else {
            game_destroy(game)
            return nil
        }
        game_advance_phase(game)
        game_advance_phase(game)
        return game
    }

    @discardableResult
    private func resolveCurrentPendingHitAllocation(prioritizing preferredGroupName: String? = nil, in game: OpaquePointer) -> Bool {
        let initialSource = game_pending_hit_allocation_view(game).source_name.map { String(cString: $0) }
        while game_pending_hit_allocation_view(game).active {
            let pending = game_pending_hit_allocation_view(game)
            let sourceName = pending.source_name.map { String(cString: $0) }
            if sourceName != initialSource && pending.hits_assigned == 0 {
                return true
            }

            let count = Int(game_unit_profile_group_count(game, pending.target_id))
            let groups = (0..<count).map { index in
                game_unit_profile_group_view(game, pending.target_id, Int32(index))
            }

            if let preferredGroupName {
                if let preferred = groups.first(where: { raw in
                    raw.name.map { String(cString: $0) } == preferredGroupName && Int(raw.models) > 0
                }), game_choose_pending_hit_allocation(game, preferred.index) {
                    continue
                }
            }

            var resolved = false
            for group in groups where Int(group.models) > 0 {
                if game_choose_pending_hit_allocation(game, group.index) {
                    resolved = true
                    break
                }
            }

            if !resolved {
                return false
            }
        }
        return true
    }

    @discardableResult
    private func resolveAllPendingHitAllocations(prioritizing preferredGroupName: String? = nil, in game: OpaquePointer) -> Bool {
        while game_pending_hit_allocation_view(game).active {
            let before = game_pending_hit_allocation_view(game)
            if !resolveCurrentPendingHitAllocation(prioritizing: preferredGroupName, in: game) {
                return false
            }
            let after = game_pending_hit_allocation_view(game)
            let beforeSource = before.source_name.map { String(cString: $0) }
            let afterSource = after.source_name.map { String(cString: $0) }
            if after.active && after.target_id == before.target_id && afterSource == beforeSource && after.hits_remaining == before.hits_remaining {
                return false
            }
        }
        return true
    }

    private func unitNames(in game: OpaquePointer) -> [String] {
        let count = Int(game_unit_count(game))
        return (0..<count).map { index in
            let view = game_unit_view(game, Int32(index))
            return view.name.map { String(cString: $0) } ?? ""
        }
    }
}
