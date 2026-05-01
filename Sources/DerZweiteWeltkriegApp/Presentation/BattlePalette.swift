import SwiftUI

enum BattlePalette {
    static let playerOneAccent = Color(red: 0.18, green: 0.31, blue: 0.57)
    static let playerTwoAccent = Color(red: 0.55, green: 0.20, blue: 0.14)
    static let sidebarBackground = Color(red: 0.96, green: 0.94, blue: 0.88)
    static let sidebarPrimaryText = Color(red: 0.12, green: 0.10, blue: 0.08)
    static let sidebarSecondaryText = Color(red: 0.27, green: 0.24, blue: 0.18)
    static let sidebarWarningText = Color(red: 0.57, green: 0.29, blue: 0.03)
    static let sidebarErrorText = Color(red: 0.61, green: 0.13, blue: 0.10)
    static let neutralButtonTint = Color(red: 0.42, green: 0.39, blue: 0.33)
    static let selectedButtonTint = Color(red: 0.24, green: 0.40, blue: 0.24)
    static let missionHighlight = Color(red: 0.98, green: 0.89, blue: 0.64)
    static let legendBadgeGold = Color(red: 0.96, green: 0.85, blue: 0.52)
    static let legendBadgeGreen = Color(red: 0.79, green: 0.84, blue: 0.73)
    static let assaultGunBadge = Color(red: 0.76, green: 0.82, blue: 0.71)
    static let transportBadge = Color(red: 0.96, green: 0.85, blue: 0.52)
    static let woundBadge = Color(red: 0.98, green: 0.82, blue: 0.58)
    static let terrainLabelBackground = Color.black.opacity(0.58)
    static let objectiveLabelBackground = Color.black.opacity(0.68)

    static var shellBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.22, green: 0.24, blue: 0.18),
                Color(red: 0.12, green: 0.15, blue: 0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
