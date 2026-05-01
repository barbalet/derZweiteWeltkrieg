import SwiftUI
#if SWIFT_PACKAGE
import DerZweiteWeltkriegCore
#endif

struct BattleBoardView: View {
    @ObservedObject var controller: GameController
    @Binding var dragPreview: [Int: CGPoint]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.52, green: 0.50, blue: 0.35),
                                Color(red: 0.31, green: 0.32, blue: 0.24)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                grid(in: geometry.size)
                    .stroke(Color.black.opacity(0.18), lineWidth: 1)

                ForEach(controller.zones) { zone in
                    terrainShape(for: zone, in: geometry.size)
                }

                ForEach(controller.objectiveStates) { objective in
                    objectiveMarker(objective, in: geometry.size)
                }

                ForEach(controller.renderableUnits) { unit in
                    unitToken(unit, in: geometry.size)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
        .aspectRatio(GameController.boardWidth / GameController.boardHeight, contentMode: .fit)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("battle-board")
        .accessibilityLabel("Battle board")
    }

    private func grid(in size: CGSize) -> Path {
        var path = Path()
        let columns = Int(GameController.boardWidth)
        let rows = Int(GameController.boardHeight)

        for column in 0...columns {
            let x = size.width * CGFloat(column) / GameController.boardWidth
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
        }

        for row in 0...rows {
            let y = size.height * CGFloat(row) / GameController.boardHeight
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
        }

        return path
    }

    private func terrainShape(for zone: ZoneSnapshot, in size: CGSize) -> some View {
        let rect = boardRect(zone.rect, in: size)
        let fill: Color = {
            switch zone.kind {
            case TE_TERRAIN_DIFFICULT:
                return Color(red: 0.36, green: 0.27, blue: 0.18).opacity(0.65)
            case TE_TERRAIN_IMPASSABLE:
                return Color(red: 0.28, green: 0.15, blue: 0.16).opacity(0.8)
            default:
                return Color(red: 0.55, green: 0.56, blue: 0.46).opacity(0.45)
            }
        }()

        return RoundedRectangle(cornerRadius: 18)
            .fill(fill)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .overlay(alignment: .topLeading) {
                Text(zone.name)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(BattlePalette.terrainLabelBackground))
                    .padding(8)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: zone.blocksLineOfSight ? [6, 4] : []))
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            )
    }

    private func objectiveMarker(_ objective: ObjectiveSnapshot, in size: CGSize) -> some View {
        let position = boardPoint(CGPoint(x: objective.x, y: objective.y), in: size)
        let boardScale = size.width / GameController.boardWidth
        let radius = objective.radius * boardScale
        let markerColor: Color = {
            if objective.isContested {
                return Color.orange
            }
            switch objective.controller {
            case TE_PLAYER_ONE?:
                return BattlePalette.playerOneAccent
            case TE_PLAYER_TWO?:
                return Color(red: 0.63, green: 0.23, blue: 0.16)
            default:
                return Color(red: 0.93, green: 0.89, blue: 0.72)
            }
        }()

        return ZStack {
            Circle()
                .stroke(markerColor.opacity(0.7), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                .frame(width: radius * 2, height: radius * 2)

            Circle()
                .fill(markerColor)
                .frame(width: 24, height: 24)
                .overlay(
                    Text("\(objective.id)")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.white)
                )

            Text(objective.name)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(BattlePalette.objectiveLabelBackground)
                )
                .offset(y: radius + 14)
        }
        .position(position)
    }

    @ViewBuilder
    private func unitToken(_ unit: UnitSnapshot, in size: CGSize) -> some View {
        let gamePoint = dragPreview[unit.id] ?? CGPoint(x: unit.x, y: unit.y)
        let position = boardPoint(gamePoint, in: size)
        let radius = max(18, unit.footprintRadius * (size.width / GameController.boardWidth) * 0.9)
        let isSelected = controller.selectedUnitID == unit.id || controller.selectedTargetID == unit.id
        let ownerColor = unit.owner == TE_PLAYER_ONE ? BattlePalette.playerOneAccent : Color(red: 0.63, green: 0.23, blue: 0.16)
        let selectionStroke = isSelected ? Color.white.opacity(0.98) : Color.white.opacity(0.35)

        ZStack {
            if unit.usesVehicleRules {
                RoundedRectangle(cornerRadius: 10)
                    .fill(ownerColor)
                    .frame(width: radius * 2.4, height: radius * 1.6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selectionStroke, lineWidth: isSelected ? 3.5 : 1)
                    )
            } else {
                Circle()
                    .fill(ownerColor)
                    .frame(width: radius * 2, height: radius * 2)
                    .overlay(
                        Circle()
                            .stroke(selectionStroke, lineWidth: isSelected ? 3.5 : 1)
                    )
            }

            VStack(spacing: 2) {
                Text(BattleDisplayLabels.tokenName(for: unit))
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .frame(width: radius * 2.2)
                    .lineLimit(2)
                Text("\(unit.models)")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white)
            }

            if unit.usesVehicleRules {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: radius * 0.15, height: radius * 0.9)
                    .offset(y: -radius * 1.05)
                    .rotationEffect(.degrees(unit.facingDegrees))
            }

            if unit.kind == TE_UNIT_ASSAULT_GUN {
                Text("AG")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(BattlePalette.assaultGunBadge))
                    .offset(x: -radius * 0.85, y: -radius * 0.9)
            }

            if unit.smokeActive {
                Circle()
                    .stroke(Color.white.opacity(0.8), style: StrokeStyle(lineWidth: 3, dash: [6, 3]))
                    .frame(width: radius * 3.1, height: radius * 3.1)
            }

            if unit.transportCapacity > 0 && unit.embarkedUnitID > 0 {
                Text("TR")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(BattlePalette.transportBadge))
                    .offset(x: radius * 0.75, y: -radius * 0.9)
            }

            if unit.hasPartialLeadingWound {
                Text("\(unit.leadModelWounds)/\(unit.woundsPerModel)W")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(BattlePalette.woundBadge))
                    .offset(x: 0, y: radius * 0.95)
            }
        }
        .position(position)
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 6)
        .shadow(color: isSelected ? ownerColor.opacity(0.45) : .clear, radius: 12, x: 0, y: 0)
        .opacity(unit.destroyed ? 0.35 : 1)
        .onTapGesture {
            controller.selectUnit(unit)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    guard controller.canManipulate(unit) else { return }
                    controller.selectUnit(unit)
                    dragPreview[unit.id] = gameCoordinates(for: value.location, in: size)
                }
                .onEnded { value in
                    guard controller.canManipulate(unit) else {
                        dragPreview[unit.id] = nil
                        return
                    }
                    controller.selectUnit(unit)
                    let point = gameCoordinates(for: value.location, in: size)
                    dragPreview[unit.id] = nil
                    controller.moveUnit(id: unit.id, to: point)
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("unit-token-\(unit.id)")
        .accessibilityLabel(unit.name)
        .accessibilityValue(unit.ownerName)
    }

    private func boardPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: point.x / GameController.boardWidth * size.width,
            y: point.y / GameController.boardHeight * size.height
        )
    }

    private func boardRect(_ rect: CGRect, in size: CGSize) -> CGRect {
        CGRect(
            x: rect.origin.x / GameController.boardWidth * size.width,
            y: rect.origin.y / GameController.boardHeight * size.height,
            width: rect.width / GameController.boardWidth * size.width,
            height: rect.height / GameController.boardHeight * size.height
        )
    }

    private func gameCoordinates(for location: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(0, location.x / size.width * GameController.boardWidth), GameController.boardWidth),
            y: min(max(0, location.y / size.height * GameController.boardHeight), GameController.boardHeight)
        )
    }
}
