import SwiftUI

public enum HistoricalBattleSidePickerDefaults {
    public static let title = "Play as"
    public static let accessibilityIdentifier = "battle-side-selector"
    public static let optionAccessibilityIDPrefix = "battle-side-option"
}

public struct HistoricalBattleSidePicker<ID: HistoricalBattleID>: View {
    private let scenario: HistoricalBattleScenario<ID>
    @Binding private var selectedSideID: String
    private let title: String
    private let accessibilityIdentifier: String
    private let optionAccessibilityIDPrefix: String
    private let isEnabled: Bool
    private let showsBriefing: Bool

    public init(
        scenario: HistoricalBattleScenario<ID>,
        selectedSideID: Binding<String>,
        title: String = HistoricalBattleSidePickerDefaults.title,
        accessibilityIdentifier: String = HistoricalBattleSidePickerDefaults.accessibilityIdentifier,
        optionAccessibilityIDPrefix: String = HistoricalBattleSidePickerDefaults.optionAccessibilityIDPrefix,
        isEnabled: Bool = true,
        showsBriefing: Bool = true
    ) {
        self.scenario = scenario
        _selectedSideID = selectedSideID
        self.title = title
        self.accessibilityIdentifier = accessibilityIdentifier
        self.optionAccessibilityIDPrefix = optionAccessibilityIDPrefix
        self.isEnabled = isEnabled
        self.showsBriefing = showsBriefing
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 12) {
                Label(title, systemImage: "person.crop.circle.badge.checkmark")
                    .font(.headline)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Picker(title, selection: $selectedSideID) {
                    ForEach(scenario.sideOptions) { side in
                        Text(side.title)
                            .tag(side.id)
                            .accessibilityIdentifier("\(optionAccessibilityIDPrefix)-\(side.id)")
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(minWidth: 190, alignment: .trailing)
            }

            if let selectedSide {
                Text("\(selectedSide.title) under human control")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if showsBriefing {
                    Text(selectedSide.playerBriefing)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .disabled(!isEnabled)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private var selectedSide: HistoricalSideOption? {
        scenario.sideOption(id: selectedSideID)
    }
}
