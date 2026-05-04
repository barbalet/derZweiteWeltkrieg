import SwiftUI

struct BattleHeaderPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black.opacity(0.40))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.20), lineWidth: 1)
                    )
            )
    }
}

struct BattleSidebarPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            content
                .foregroundStyle(BattlePalette.sidebarPrimaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
        }
        .accessibilityIdentifier("battle-sidebar-scroll")
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(BattlePalette.sidebarBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.black.opacity(0.24), lineWidth: 1)
                )
        )
    }
}

struct BattleSidebarSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(BattlePalette.sidebarPrimaryText)
            content
        }
    }
}

struct BattleTintedPanel<Content: View>: View {
    let accent: Color
    @ViewBuilder var content: Content

    init(accent: Color, @ViewBuilder content: () -> Content) {
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        content
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(accent.opacity(0.14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(accent.opacity(0.55), lineWidth: 1.2)
                    )
            )
    }
}

struct BattleFloatingWindow<Content: View>: View {
    let title: String
    let systemImage: String
    let width: CGFloat
    let maxHeight: CGFloat
    let scrollIdentifier: String
    let onClose: () -> Void
    let content: Content

    @State private var settledOffset: CGSize = .zero
    @GestureState private var dragOffset: CGSize = .zero

    init(
        title: String,
        systemImage: String,
        width: CGFloat,
        maxHeight: CGFloat,
        scrollIdentifier: String,
        onClose: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.width = width
        self.maxHeight = maxHeight
        self.scrollIdentifier = scrollIdentifier
        self.onClose = onClose
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            titleBar

            ScrollView(.vertical, showsIndicators: true) {
                content
                    .foregroundStyle(BattlePalette.sidebarPrimaryText)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityIdentifier(scrollIdentifier)
        }
        .frame(width: width)
        .frame(maxHeight: maxHeight)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(BattlePalette.sidebarBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black.opacity(0.24), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.28), radius: 22, x: 0, y: 12)
        .offset(
            x: settledOffset.width + dragOffset.width,
            y: settledOffset.height + dragOffset.height
        )
    }

    private var titleBar: some View {
        HStack(spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.86))
            .accessibilityLabel("Hide \(title)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.black.opacity(0.72))
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation
                }
                .onEnded { value in
                    settledOffset.width += value.translation.width
                    settledOffset.height += value.translation.height
                }
        )
    }
}
