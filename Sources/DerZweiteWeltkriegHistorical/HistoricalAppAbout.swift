import Foundation
import SwiftUI

public struct HistoricalAppAboutContent: Codable, Hashable, Sendable {
    public let appName: String
    public let releaseVersion: String
    public let buildLabel: String
    public let contactLine: String
    public let developmentParagraphs: [String]
    public let credits: [String]

    public init(
        appName: String,
        releaseVersion: String,
        buildLabel: String,
        contactLine: String,
        developmentParagraphs: [String],
        credits: [String]
    ) {
        self.appName = appName
        self.releaseVersion = releaseVersion
        self.buildLabel = buildLabel
        self.contactLine = contactLine
        self.developmentParagraphs = developmentParagraphs
        self.credits = credits
    }

    public func displayVersion(
        bundleInfo: [String: Any] = Bundle.main.infoDictionary ?? [:]
    ) -> String {
        guard let bundleVersion = bundleInfo["CFBundleShortVersionString"] as? String else {
            return releaseVersion
        }

        let trimmed = bundleVersion.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || trimmed == "1.0" || trimmed.contains("$(") ? releaseVersion : trimmed
    }
}

public struct HistoricalAppAboutView: View {
    private let content: HistoricalAppAboutContent
    private let icon: Image?
    private let width: CGFloat

    public init(
        content: HistoricalAppAboutContent,
        icon: Image? = nil,
        width: CGFloat = 620
    ) {
        self.content = content
        self.icon = icon
        self.width = width
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                if let icon {
                    icon
                        .resizable()
                        .frame(width: 72, height: 72)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(content.appName)
                        .font(.largeTitle.weight(.semibold))
                    Text("Version \(content.displayVersion())")
                        .font(.headline.monospacedDigit())
                    Text(content.buildLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                ForEach(content.developmentParagraphs.indices, id: \.self) { index in
                    Text(content.developmentParagraphs[index])
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .font(.callout)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                ForEach(content.credits.indices, id: \.self) { index in
                    Label(content.credits[index], systemImage: "checkmark.circle")
                        .labelStyle(.titleAndIcon)
                }
                Text(content.contactLine)
                    .padding(.top, 4)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: width)
    }
}
