import SwiftUI
import UIKit

struct GlassDiceView: View {
    @Binding var value: Int?
    let size: CGFloat
    let onRoll: () -> Void

    @State private var isRolling = false

    var body: some View {
        Button(action: roll) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.glassHighlight)
                            .opacity(0.35)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 8)

                DicePips(value: value ?? 1)
                    .foregroundStyle(Theme.boardDark)
                    .padding(size * 0.25)
            }
            .frame(width: size, height: size)
            .rotation3DEffect(.degrees(isRolling ? 360 : 0), axis: (x: 0.5, y: 1, z: 0), perspective: 0.6)
            .animation(.easeInOut(duration: 0.6), value: isRolling)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Roll Dice")
    }

    private func roll() {
        guard !isRolling else { return }
        isRolling = true
        Haptics.light()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            onRoll()
            isRolling = false
        }
    }
}

private struct DicePips: View {
    let value: Int
    var body: some View {
        GeometryReader { proxy in
            let s = min(proxy.size.width, proxy.size.height)
            let r = s / 12
            let pos: (Int, Int) -> CGPoint = { x, y in
                CGPoint(x: CGFloat(x) * (s/3) + (s/6), y: CGFloat(y) * (s/3) + (s/6))
            }
            let dots: [CGPoint] = {
                switch value {
                case 1: return [pos(1,1)]
                case 2: return [pos(0,0), pos(2,2)]
                case 3: return [pos(0,0), pos(1,1), pos(2,2)]
                case 4: return [pos(0,0), pos(2,0), pos(0,2), pos(2,2)]
                case 5: return [pos(0,0), pos(2,0), pos(1,1), pos(0,2), pos(2,2)]
                default: return [pos(0,0), pos(2,0), pos(0,1), pos(2,1), pos(0,2), pos(2,2)]
                }
            }()
            ForEach(0..<dots.count, id: \.self) { i in
                Circle()
                    .fill(Theme.boardDark)
                    .frame(width: r*2, height: r*2)
                    .position(dots[i])
            }
        }
    }
}

enum Haptics {
    static func light() {
        if Settings.sfxEnabled {
            let gen = UIImpactFeedbackGenerator(style: .light)
            gen.impactOccurred()
        }
    }
}
