import SwiftUI

struct BattlefieldViewport<Content: View>: View {
    @Binding var zoom: CGFloat
    let boardWidth: CGFloat
    let boardHeight: CGFloat
    let pointsPerBoardUnit: CGFloat
    let content: Content

    init(
        zoom: Binding<CGFloat>,
        boardWidth: CGFloat,
        boardHeight: CGFloat,
        pointsPerBoardUnit: CGFloat = 22,
        @ViewBuilder content: () -> Content
    ) {
        _zoom = zoom
        self.boardWidth = boardWidth
        self.boardHeight = boardHeight
        self.pointsPerBoardUnit = pointsPerBoardUnit
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                content
                    .frame(width: canvasSize.width, height: canvasSize.height)
                    .padding(24)
                    .frame(
                        minWidth: geometry.size.width,
                        minHeight: geometry.size.height,
                        alignment: .topLeading
                    )
            }
            .background(BattlePalette.shellBackground)
        }
    }

    private var canvasSize: CGSize {
        CGSize(
            width: boardWidth * pointsPerBoardUnit * zoom,
            height: boardHeight * pointsPerBoardUnit * zoom
        )
    }
}
