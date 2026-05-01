import Foundation

enum BattleDisplayLabels {
    static let demoGuide: [(String, String)] = [
        ("1", "Use Prev/Next to pick a friendly unit, then drag it on the board and rotate it to show movement and facing."),
        ("2", "Hit Next Phase, snap to the nearest enemy, and fire with a fast vehicle, flame team, artillery piece, or tank to show different weapon rules."),
        ("3", "Select a transport with a starting passenger, move it, then disembark or fire the embarked unit on a later turn."),
        ("4", "Finish with an assault: infantry into a vehicle or an assault gun to demonstrate close combat and follow-up moves.")
    ]

    static let tokenLegend: [(String, String)] = [
        ("AG", "Assault gun or tank destroyer using vehicle armour and close-assault rules."),
        ("TR", "Transport currently carrying an embarked unit."),
        ("W", "Partial wound marker for a damaged multi-wound model."),
        ("Smoke", "Dashed ring means smoke launchers are active this turn.")
    ]

    static func tokenName(for unit: UnitSnapshot) -> String {
        tokenName(for: unit.name)
    }

    static func tokenName(for name: String) -> String {
        name
    }
}
