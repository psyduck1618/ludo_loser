import SwiftUI

/// Renders the board, paths, markers and token layers.
struct LudoBoardView: View {
    @ObservedObject var game: Game
    let size: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let s = min(proxy.size.width, proxy.size.height)
            let inner = s - 24
            let step = inner / 13.0
            let origin = CGPoint(x: (s - inner)/2, y: (s - inner)/2)

            ZStack {
                // Background board
                boardBase(size: s)
                boardRing(origin: origin, step: step)
                boardPaths(origin: origin, step: step)
                centerMedallion(size: s)

                // Yard zones
                yard(for: 0, origin: origin, step: step)
                yard(for: 1, origin: origin, step: step)

                // Safe star markers, portals and tokens
                safeStars(origin: origin, step: step)
                portalMarkers(origin: origin, step: step)
                tokenLayer(origin: origin, step: step)
                targetsLayer(origin: origin, step: step)
                pathsLayer(origin: origin, step: step)

                // Origin highlights for selectable tokens (less distracting than pulsing ring)
                sourceHighlights(origin: origin, step: step)
            }
            .frame(width: s, height: s)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Components
    /// Wood base, inset border. Background only, non‑interactive.
    private func boardBase(size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(boardBaseColor)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius - 8)
                        .inset(by: 6)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 10)
        }
    }

    @AppStorage("woodTheme") private var woodTheme: Bool = Settings.woodTheme
    private var boardBaseColor: Color { woodTheme ? Theme.boardWood : Theme.boardDark }

    /// Outer rounded border path (cosmetic)
    private func boardRing(origin: CGPoint, step: CGFloat) -> some View {
        let stroke = RoundedRectangle(cornerRadius: 8)
            .stroke(Color.white.opacity(0.35), lineWidth: 1)
        return ZStack {
            // Draw outer ring paths (visual only)
            Path { p in
                let rect = CGRect(x: origin.x, y: origin.y, width: step*13, height: step*13)
                p.addRoundedRect(in: rect.insetBy(dx: step*0.5, dy: step*0.5), cornerSize: CGSize(width: 12, height: 12))
            }.stroke(Color.black.opacity(0.25), lineWidth: 2)
            stroke
        }
    }

    /// Marks safe tiles (★) on the ring
    private func safeStars(origin: CGPoint, step: CGFloat) -> some View {
        let ring = ringPoints(origin: origin, step: step)
        let safeIdx: [Int] = [0,6,13,27,32,39]
        return ZStack {
            ForEach(safeIdx, id: \.self) { i in
                if i < ring.count {
                    StarShape(points: 5)
                        .fill(Theme.accent.opacity(0.85))
                        .frame(width: step * 0.5, height: step * 0.5)
                        .position(x: ring[i].x, y: ring[i].y)
                        .shadow(color: Theme.accent.opacity(0.4), radius: 3)
                }
            }
        }
        .allowsHitTesting(false)
    }

    /// Renders portals, jump +5/−5 tiles; overlays ignore touches
    private func portalMarkers(origin: CGPoint, step: CGFloat) -> some View {
        let ring = ringPoints(origin: origin, step: step)
        let entries = Set(game.portalEntrances)
        let exits = Set(game.portalExits)
        let jPlus = Set(game.jumpPlus)
        let jMinus = Set(game.jumpMinus)
        return ZStack {
            ForEach(0..<ring.count, id: \.self) { i in
                if entries.contains(i) {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.blue.opacity(0.7), lineWidth: 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.blue.opacity(0.18)))
                        .frame(width: step * 0.6, height: step * 0.6)
                        .position(x: ring[i].x, y: ring[i].y)
                } else if exits.contains(i) {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.mint.opacity(0.7), lineWidth: 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.mint.opacity(0.18)))
                        .frame(width: step * 0.6, height: step * 0.6)
                        .position(x: ring[i].x, y: ring[i].y)
                } else if jPlus.contains(i) {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.purple.opacity(0.8), lineWidth: 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.purple.opacity(0.18)))
                        .overlay(Text("+5").font(.caption2).bold().foregroundColor(.white).opacity(0.9))
                        .frame(width: step * 0.6, height: step * 0.6)
                        .position(x: ring[i].x, y: ring[i].y)
                } else if jMinus.contains(i) {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.red.opacity(0.8), lineWidth: 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.red.opacity(0.18)))
                        .overlay(Text("-5").font(.caption2).bold().foregroundColor(.white).opacity(0.9))
                        .frame(width: step * 0.6, height: step * 0.6)
                        .position(x: ring[i].x, y: ring[i].y)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func centerMedallion(size: CGFloat) -> some View {
        Circle()
            .strokeBorder(Theme.accent.opacity(0.6), lineWidth: 3)
            .frame(width: size * 0.18, height: size * 0.18)
    }

    private func yard(for playerIndex: Int, origin: CGPoint, step: CGFloat) -> some View {
        // Yard square 2x2 inset from corners so it never overlaps the ring
        let yardSize = step * 3
        let tl = yardTopLeft(for: playerIndex, origin: origin, step: step)
        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.accent.opacity(0.4), lineWidth: 1))
                .frame(width: yardSize, height: yardSize)
                .position(x: tl.x + yardSize/2, y: tl.y + yardSize/2)

            // Four token placeholders always visible
            let tokens = game.tokens.filter { tokenOwnerIndex($0) == playerIndex && $0.position == .yard }
            ForEach(Array(tokens.enumerated()), id: \.element.id) { idx, t in
                let (dx, dy) = yardSlotCenterOffset(slot: idx, step: step)
                tokenView(token: t, highlighted: game.selectableTokenIDs.contains(t.id))
                    .position(x: tl.x + dx, y: tl.y + dy)
                    .onTapGesture { game.handleTap(tokenID: t.id) }
            }
        }
    }

    /// Draws traversable ring tiles, inner spiral, and extended inner lanes
    private func boardPaths(origin: CGPoint, step: CGFloat) -> some View {
        // Visualize the full path to home: ring tiles and home lanes
        let ring = ringPoints(origin: origin, step: step)
        return ZStack {
            // Ring tiles
            ForEach(0..<ring.count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.accent.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.15), lineWidth: 1))
                    .frame(width: step * 0.7, height: step * 0.7)
                    .position(x: ring[i].x, y: ring[i].y)
            }
            // Home lanes (both players)
            // Top -> center (extended zigzag lane)
            ForEach(0..<6, id: \.self) { i in
                let pt = homeLanePoint(for: 0, laneIndex: i, origin: origin, step: step)
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.accent.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.18), lineWidth: 1))
                    .frame(width: step * 0.7, height: step * 0.7)
                    .position(x: pt.x, y: pt.y)
            }
            // Bottom -> center
            ForEach(0..<6, id: \.self) { i in
                let pt = homeLanePoint(for: 1, laneIndex: i, origin: origin, step: step)
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.accent.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.18), lineWidth: 1))
                    .frame(width: step * 0.7, height: step * 0.7)
                    .position(x: pt.x, y: pt.y)
            }
        }
        .allowsHitTesting(false)
    }

    /// Paints tokens on the ring, inner lanes, spiral and home
    private func tokenLayer(origin: CGPoint, step: CGFloat) -> some View {
        let ring = ringPoints(origin: origin, step: step)
        let spiral = innerSpiralPoints(origin: origin, step: step)
        return ZStack {
            ForEach(game.tokens, id: \.id) { tok in
                switch tok.position {
                case .yard:
                    EmptyView()
                case let .mainTrack(i):
                    let group = game.tokens.filter {
                        if case let .mainTrack(j) = $0.position { return j == i } else { return false }
                    }
                    let indexInGroup = group.firstIndex(where: { $0.id == tok.id }) ?? 0
                    let offset = clusterOffset(at: indexInGroup, count: group.count, radius: step * 0.18)
                    tokenView(token: tok, highlighted: game.selectableTokenIDs.contains(tok.id))
                        .position(x: ring[i].x + offset.x, y: ring[i].y + offset.y)
                        .onTapGesture { game.handleTap(tokenID: tok.id) }
                case let .homeLane(idx):
                    let pt = homeLanePoint(for: tokenOwnerIndex(tok), laneIndex: idx, origin: origin, step: step)
                    tokenView(token: tok, highlighted: game.selectableTokenIDs.contains(tok.id))
                        .position(x: pt.x, y: pt.y)
                        .onTapGesture { game.handleTap(tokenID: tok.id) }
                case let .innerTrack(i):
                    let p = spiral[max(0, min(i, spiral.count-1))]
                    tokenView(token: tok, highlighted: false)
                        .position(x: p.x, y: p.y)
                case .home:
                    let pt = homePoint(for: tokenOwnerIndex(tok), origin: origin, step: step)
                    tokenView(token: tok, highlighted: false)
                        .position(x: pt.x, y: pt.y)
                }
            }
        }
    }

    /// Destination markers for currently possible moves
    private func targetsLayer(origin: CGPoint, step: CGFloat) -> some View {
        let ring = ringPoints(origin: origin, step: step)
        return ZStack {
            ForEach(Array(game.moveTargets.keys), id: \.self) { id in
                if let target = game.moveTargets[id] {
                    switch target {
                    case let .mainTrack(i):
                        if i < ring.count {
                            destinationMarker().position(x: ring[i].x, y: ring[i].y)
                        }
                    case let .homeLane(idx):
                        let pt = homeLanePoint(for: game.currentPlayerIndex, laneIndex: idx, origin: origin, step: step)
                        destinationMarker().position(x: pt.x, y: pt.y)
                    case .home:
                        let pt = homePoint(for: game.currentPlayerIndex, origin: origin, step: step)
                        destinationMarker().position(x: pt.x, y: pt.y)
                    case .yard:
                        EmptyView()
                    case .innerTrack(_):
                        EmptyView()
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
    /// Gold ring used for destination highlighting
    private func destinationMarker() -> some View {
        Circle()
            .strokeBorder(Theme.accent, lineWidth: 3)
            .background(Circle().fill(Theme.accent.opacity(0.12)))
            .frame(width: Theme.tokenSize * 1.5, height: Theme.tokenSize * 1.5)
            .shadow(color: Theme.accent.opacity(0.5), radius: 4)
            .transition(.scale)
            .animation(.easeInOut(duration: 0.25), value: game.moveTargets.count)
    }

    /// Token visuals with highlight/selection rings
    private func tokenView(token: Token, highlighted: Bool) -> some View {
        let style: TokenChip.Style = tokenOwnerIndex(token) == 0 ? .black : .white
        let isSelected = game.selectedTokenID == token.id
        return TokenChip(style: style)
            .overlay(
                ZStack {
                    if highlighted {
                        Circle().stroke(Theme.accent, lineWidth: 3)
                    }
                    if isSelected {
                        Circle().stroke(Color.blue, lineWidth: 2)
                    }
                }
                .scaleEffect((highlighted || isSelected) ? 1.25 : 1)
                .animation(.easeInOut(duration: 0.25), value: highlighted || isSelected)
            )
            .accessibilityLabel("Token")
    }

    /// Gold halos under currently movable tokens
    private func sourceHighlights(origin: CGPoint, step: CGFloat) -> some View {
        let ring = ringPoints(origin: origin, step: step)
        let movable = game.tokens.filter { game.selectableTokenIDs.contains($0.id) }
        return ZStack {
            ForEach(movable, id: \.id) { tok in
                switch tok.position {
                case .yard:
                    if let pt = yardPoint(for: tok, origin: origin, step: step) {
                        tileHighlight().position(x: pt.x, y: pt.y)
                    }
                case let .mainTrack(i):
                    if i < ring.count { tileHighlight().position(x: ring[i].x, y: ring[i].y) }
                case let .homeLane(idx):
                    let pt = homeLanePoint(for: tokenOwnerIndex(tok), laneIndex: idx, origin: origin, step: step)
                    tileHighlight().position(x: pt.x, y: pt.y)
                case .home:
                    EmptyView()
                case .innerTrack(_):
                    EmptyView()
                }
            }
        }
        .allowsHitTesting(false)
    }
    /// Gold halo visual for tile under movable token
    private func tileHighlight() -> some View {
        Circle()
            .strokeBorder(Theme.accent, lineWidth: 2.5)
            .background(Circle().fill(Theme.accent.opacity(0.10)))
            .frame(width: Theme.tokenSize * 2.0, height: Theme.tokenSize * 2.0)
            .shadow(color: Theme.accent.opacity(0.45), radius: 3)
    }

    // MARK: - Geometry helpers
    /// 52 ring points around the board
    private func ringPoints(origin: CGPoint, step: CGFloat) -> [CGPoint] {
        // 13 cells per side, 52 total
        var pts: [CGPoint] = []
        let topY = origin.y + step/2
        let leftX = origin.x + step/2
        let rightX = origin.x + step*13 - step/2
        let bottomY = origin.y + step*13 - step/2
        // Top left -> top right (13)
        for i in 0..<13 { pts.append(CGPoint(x: leftX + CGFloat(i)*step, y: topY)) }
        // Right top -> right bottom (13)
        for i in 0..<13 { pts.append(CGPoint(x: rightX, y: topY + CGFloat(i)*step)) }
        // Bottom right -> bottom left (13)
        for i in 0..<13 { pts.append(CGPoint(x: rightX - CGFloat(i)*step, y: bottomY)) }
        // Left bottom -> left top (13)
        for i in 0..<13 { pts.append(CGPoint(x: leftX, y: bottomY - CGFloat(i)*step)) }
        return pts
    }

    /// 12‑step inner spiral used for detours
    private func innerSpiralPoints(origin: CGPoint, step: CGFloat) -> [CGPoint] {
        // A simple 12-step inward spiral approximated with offsets from center
        let cx = origin.x + step*6.5
        let cy = origin.y + step*6.5
        let offs: [(CGFloat, CGFloat)] = [
            (-2.5,-2.5), (-1.5,-2.5), (-1.5,-1.5), (-2.5,-1.5),
            (-2.5, 0.5), (-1.5, 0.5), (-0.5,0.5), (-0.5,-0.5),
            (0.5,-0.5), (0.5,0.5), (1.5,0.5), (1.5,-0.5)
        ]
        return offs.map { (dx, dy) in CGPoint(x: cx + dx*step, y: cy + dy*step) }
    }

    private func startCorner(for playerIndex: Int, origin: CGPoint, step: CGFloat) -> CGPoint {
        // 0: top-left, 1: bottom-right (opposite corners)
        if playerIndex == 0 { return CGPoint(x: origin.x + step*0.5, y: origin.y + step*0.5) }
        return CGPoint(x: origin.x + step*10.5, y: origin.y + step*10.5)
    }

    private func yardSlotCenterOffset(slot: Int, step: CGFloat) -> (CGFloat, CGFloat) {
        let col = slot % 2
        let row = slot / 2
        // Centers within a 3x3 yard grid (two tokens per row)
        return (step * (CGFloat(col) + 0.75), step * (CGFloat(row) + 0.75))
    }

    private func homeLanePoint(for playerIndex: Int, laneIndex idx: Int, origin: CGPoint, step: CGFloat) -> CGPoint {
        // Simple vertical inner lane with 6 steps to center for clarity
        let x = origin.x + step * 6.5
        if playerIndex == 0 {
            // from top edge downwards
            let y = origin.y + step * (1.5 + CGFloat(idx))
            return CGPoint(x: x, y: y)
        } else {
            // from bottom edge upwards
            let y = origin.y + step * (11.5 - CGFloat(idx))
            return CGPoint(x: x, y: y)
        }
    }

    private func homePoint(for playerIndex: Int, origin: CGPoint, step: CGFloat) -> CGPoint {
        CGPoint(x: origin.x + step*6.5, y: origin.y + step*6.5)
    }

    private func tokenOwnerIndex(_ token: Token) -> Int {
        game.players.firstIndex(where: { $0.color == token.owner }) ?? 0
    }
    private func yardPoint(for token: Token, origin: CGPoint, step: CGFloat) -> CGPoint? {
        let pIdx = tokenOwnerIndex(token)
        let tl = yardTopLeft(for: pIdx, origin: origin, step: step)
        // Determine slot by ordering yard tokens for owner by stable id
        let yardTokens = game.tokens.filter { $0.owner == token.owner && $0.position == .yard }.sorted { $0.id.uuidString < $1.id.uuidString }
        guard let slotIndex = yardTokens.firstIndex(where: { $0.id == token.id }) else { return nil }
        let (dx, dy) = yardSlotCenterOffset(slot: slotIndex, step: step)
        return CGPoint(x: tl.x + dx, y: tl.y + dy)
    }

    private func yardTopLeft(for playerIndex: Int, origin: CGPoint, step: CGFloat) -> CGPoint {
        // Use a fractional inset so yard never overlaps ring/star markers
        let inset: CGFloat = 1.2
        let yardCells: CGFloat = 3.0
        let maxCells: CGFloat = 13.0
        if playerIndex == 0 {
            return CGPoint(x: origin.x + step * inset,
                           y: origin.y + step * inset)
        } else {
            // Place bottom-right yard using symmetric inset from the far edge
            let x = origin.x + step * (maxCells - yardCells - inset)
            let y = origin.y + step * (maxCells - yardCells - inset)
            return CGPoint(x: x, y: y)
        }
    }

    private func pathsLayer(origin: CGPoint, step: CGFloat) -> some View {
        let ring = ringPoints(origin: origin, step: step)
        // Show path only for the selected token if any, else for <=2 possible moves
        let keys: [UUID] = {
            if let sel = game.selectedTokenID { return [sel] }
            return Array(game.moveTargets.keys)
        }()
        return ZStack {
            if keys.count <= 2 {
                ForEach(keys, id: \.self) { id in
                    if let tok = game.tokens.first(where: { $0.id == id }), let target = game.moveTargets[id] {
                        let owner = tokenOwnerIndex(tok)
                        let positions = game.path(for: tok, to: target)
                        ForEach(Array(positions.enumerated()), id: \.offset) { _, pos in
                            if let pt = point(for: pos, ownerIndex: owner, origin: origin, step: step, ring: ring) {
                                pathDot().position(x: pt.x, y: pt.y)
                            }
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func point(for pos: BoardPosition, ownerIndex: Int, origin: CGPoint, step: CGFloat, ring: [CGPoint]) -> CGPoint? {
        switch pos {
        case let .mainTrack(i):
            guard i < ring.count else { return nil }
            return ring[i]
        case let .homeLane(idx):
            return homeLanePoint(for: ownerIndex, laneIndex: idx, origin: origin, step: step)
        case .home:
            return homePoint(for: ownerIndex, origin: origin, step: step)
        case .yard:
            return nil
        case let .innerTrack(i):
            let spiral = innerSpiralPoints(origin: origin, step: step)
            guard i >= 0 && i < spiral.count else { return nil }
            return spiral[i]
        }
    }

    private func pathDot() -> some View {
        Circle()
            .fill(Color.blue.opacity(0.22))
            .overlay(Circle().stroke(Color.blue.opacity(0.55), lineWidth: 1))
            .frame(width: Theme.tokenSize * 0.9, height: Theme.tokenSize * 0.9)
            .shadow(color: Color.blue.opacity(0.35), radius: 2)
            .transition(.opacity)
    }
}

private func clusterOffset(at index: Int, count: Int, radius: CGFloat) -> CGPoint {
    guard count > 1 else { return .zero }
    let angle = (Double(index) / Double(max(count, 2))) * 2 * Double.pi
    return CGPoint(x: CGFloat(cos(angle)) * radius, y: CGFloat(sin(angle)) * radius)
}

struct StarShape: Shape {
    let points: Int
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r1 = min(rect.width, rect.height) / 2
        let r2 = r1 * 0.5
        let count = max(points, 3) * 2
        for i in 0..<count {
            let r = (i % 2 == 0) ? r1 : r2
            let a = (Double(i) / Double(count)) * 2 * Double.pi - Double.pi/2
            let pt = CGPoint(x: center.x + CGFloat(cos(a)) * r, y: center.y + CGFloat(sin(a)) * r)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}

private struct CheckeredGrid: View {
    let rows = 8
    let cols = 8

    var body: some View {
        GeometryReader { proxy in
            let cellW = proxy.size.width / CGFloat(cols)
            let cellH = proxy.size.height / CGFloat(rows)
            let minCell = min(cellW, cellH)
            ForEach(0..<rows, id: \.self) { r in
                ForEach(0..<cols, id: \.self) { c in
                    Rectangle()
                        .fill(((r + c) % 2 == 0) ? Theme.boardLight : Theme.boardDark)
                        .frame(width: cellW, height: cellH)
                        .position(x: cellW * (CGFloat(c) + 0.5), y: cellH * (CGFloat(r) + 0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: minCell * 0.08)
                                .stroke(Color.black.opacity(0.05), lineWidth: 1)
                        )
                }
            }
        }
    }
}

struct TokenChip: View {
    enum Style { case black, white }
    let style: Style
    var body: some View {
        Circle()
            .fill(style == .black ? Theme.tokenBlack : Theme.tokenWhite)
            .overlay(Circle().stroke(Color.white.opacity(style == .black ? 0.2 : 0.6), lineWidth: 1))
            .overlay(
                Circle()
                    .fill(.white.opacity(0.12))
                    .blur(radius: 0.5)
                    .padding(8)
                    .blendMode(.plusLighter)
            )
            .frame(width: Theme.tokenSize, height: Theme.tokenSize)
            .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
            .accessibilityElement(children: .ignore)
    }
}
