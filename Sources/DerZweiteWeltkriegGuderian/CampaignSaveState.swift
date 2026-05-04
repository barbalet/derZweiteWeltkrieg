import Foundation

public struct CampaignSaveState: Codable, Hashable, Sendable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let selectedScenarioID: GuderianBattleID
    public let playMode: CampaignPlayMode
    public let progress: CampaignProgress
    public let savedAt: Date

    public init(
        selectedScenarioID: GuderianBattleID,
        playMode: CampaignPlayMode,
        progress: CampaignProgress,
        savedAt: Date = Date(),
        schemaVersion: Int = CampaignSaveState.currentSchemaVersion
    ) {
        self.schemaVersion = schemaVersion
        self.selectedScenarioID = selectedScenarioID
        self.playMode = playMode
        self.progress = progress
        self.savedAt = savedAt
    }

    public var isCurrentSchema: Bool {
        schemaVersion == CampaignSaveState.currentSchemaVersion
    }
}

public enum CampaignSaveCodec {
    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    public static func encode(_ state: CampaignSaveState) throws -> Data {
        try makeEncoder().encode(state)
    }

    public static func decode(_ data: Data) throws -> CampaignSaveState {
        try makeDecoder().decode(CampaignSaveState.self, from: data)
    }

    public static func decodeIfCurrent(_ data: Data) -> CampaignSaveState? {
        guard !data.isEmpty, let state = try? decode(data), state.isCurrentSchema else {
            return nil
        }
        return state
    }
}
