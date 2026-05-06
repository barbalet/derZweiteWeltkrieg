import Foundation

public enum GuderianModuleBoundaryContract {
    public static let decision = "DerZweiteWeltkriegGuderian remains the local embedded dzw content module for Guderian scenario data."
    public static let reusableEngineTarget = "DerZweiteWeltkriegCore"
    public static let guderianContentTarget = "DerZweiteWeltkriegGuderian"
    public static let reusableAppTarget = "DerZweiteWeltkriegAppUI"
    public static let topLevelGameTarget = "GuderianCore"

    public static let allowedLocalDependencyEdges = [
        "DerZweiteWeltkriegGuderian -> DerZweiteWeltkriegCore",
        "DerZweiteWeltkriegAppUI -> DerZweiteWeltkriegGuderian",
        "GuderianCore -> DerZweiteWeltkriegGuderian",
    ]

    public static let forbiddenReusableTargetImports = [
        "DerZweiteWeltkriegCore -> DerZweiteWeltkriegGuderian",
        "DerZweiteWeltkriegCore -> GuderianCore",
        "DerZweiteWeltkriegCore -> GuderianAppUI",
    ]

    public static var rationale: String {
        "The local Guderian checkout keeps scenario catalogs, campaign automation, and Guderian-specific playable-board adapters in \(guderianContentTarget) so the reusable C engine target can stay content-agnostic while the top-level app can still consume the local integration package."
    }
}
