import SwiftUI

enum MatchOutcomeKind {
    case victory
    case defeat
    case complete

    init(result: MatchResult) {
        if result.playerWon {
            self = .victory
        } else if result.winner == nil {
            self = .complete
        } else {
            self = .defeat
        }
    }

    var title: String {
        switch self {
        case .victory: "Victory"
        case .defeat: "Defeat"
        case .complete: "Complete"
        }
    }

    var symbol: String {
        switch self {
        case .victory: "trophy.fill"
        case .defeat: "xmark.circle.fill"
        case .complete: "checkmark.seal.fill"
        }
    }

    var titleColor: Color {
        switch self {
        case .victory: CupClashTheme.gold
        case .defeat: CupClashTheme.textPrimary
        case .complete: CupClashTheme.cyan
        }
    }

    var glow: Color {
        switch self {
        case .victory: CupClashTheme.gold
        case .defeat: CupClashTheme.warning
        case .complete: CupClashTheme.cyan
        }
    }
}

struct WinnerCelebrationView: View {
    let result: MatchResult
    var reduceMotion: Bool
    @State private var showBurst = false
    @State private var glow = false
    @State private var titleReady = false

    private var outcome: MatchOutcomeKind { MatchOutcomeKind(result: result) }

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: outcome.symbol)
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(outcome == .victory ? AnyShapeStyle(CupClashTheme.goldGradient()) : AnyShapeStyle(outcome.titleColor))
                .symbolEffect(.bounce, value: titleReady)
                .scaleEffect(titleReady ? 1 : 0.35)
                .rotationEffect(.degrees(titleReady ? 0 : -12))
                .shadow(color: outcome.glow.opacity(glow ? 0.85 : 0.15), radius: glow ? 18 : 4)
                .accessibilityHidden(true)

            Text(outcome.title)
                .font(CupClashTheme.titleFont)
                .foregroundStyle(outcome.titleColor)
                .scaleEffect(titleReady ? 1 : 0.68)
                .opacity(titleReady ? 1 : 0)
                .shadow(color: outcome.glow.opacity(outcome == .victory && glow ? 0.55 : 0), radius: 12)

            Text(winnerLine)
                .font(CupClashTheme.subtitleFont)
                .foregroundStyle(CupClashTheme.textSecondary)
                .opacity(titleReady ? 1 : 0)
                .offset(y: titleReady ? 0 : 10)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 208)
        .background {
            Circle()
                .fill(outcome.glow.opacity(glow ? 0.38 : 0.10))
                .frame(width: 230, height: 230)
                .blur(radius: reduceMotion ? 8 : 30)
                .scaleEffect(glow ? 1.08 : 0.82)
                .opacity(titleReady ? 1 : 0)
        }
        .overlay {
            if outcome == .victory && !reduceMotion {
                WinnerConfettiBurst(active: showBurst)
                WinnerConfettiRain()
            }
        }
        .onAppear { start() }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel("\(outcome.title), \(winnerLine)")
    }

    private var winnerLine: String {
        if result.playerWon { return result.configuration.playerName }
        if let winner = result.winner {
            return winner == .player ? result.configuration.playerName : result.configuration.opponentName
        }
        return "No winner"
    }

    private func start() {
        if reduceMotion {
            showBurst = true
            titleReady = true
            glow = true
            return
        }
        withAnimation(.spring(duration: 0.58, bounce: 0.36)) {
            titleReady = true
        }
        withAnimation(.easeOut(duration: 0.45)) {
            showBurst = true
        }
        withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
            glow = true
        }
    }
}

struct WinnerConfettiBurst: View {
    var active: Bool

    private let pieces: [ConfettiPiece] = (0..<34).map { index in
        let angle = (Double(index) / 34.0) * .pi * 2 + 0.18
        return ConfettiPiece(
            id: index,
            angle: angle,
            distance: 88 + CGFloat(index % 8) * 17,
            size: CGFloat(5 + (index % 6)),
            style: index % 5 == 0 ? .cup : (index % 3 == 0 ? .ball : .spark),
            hue: index % 4,
            delay: Double(index % 9) * 0.035
        )
    }

    var body: some View {
        ZStack {
            ForEach(pieces) { piece in
                ConfettiShard(piece: piece, active: active)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct ConfettiPiece: Identifiable {
    enum Style { case spark, ball, cup }
    let id: Int
    let angle: Double
    let distance: CGFloat
    let size: CGFloat
    let style: Style
    let hue: Int
    let delay: Double
}

private struct ConfettiShard: View {
    let piece: ConfettiPiece
    var active: Bool

    var body: some View {
        shard
            .offset(
                x: active ? CGFloat(cos(piece.angle)) * piece.distance : 0,
                y: active ? CGFloat(sin(piece.angle)) * piece.distance + 28 : 0
            )
            .opacity(active ? 0.12 : 1)
            .rotationEffect(.degrees(active ? Double(piece.hue) * 70 : 0))
            .animation(.easeOut(duration: 1.15).delay(piece.delay), value: active)
    }

    @ViewBuilder
    private var shard: some View {
        switch piece.style {
        case .ball:
            Circle()
                .fill(Color.white)
                .frame(width: piece.size + 2, height: piece.size + 2)
                .shadow(color: CupClashTheme.cyan, radius: 3)
        case .cup:
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(CupClashTheme.cyan.opacity(0.95))
                .frame(width: piece.size, height: piece.size + 4)
        case .spark:
            Capsule()
                .fill(color)
                .frame(width: piece.size * 0.55, height: piece.size + 5)
        }
    }

    private var color: Color {
        switch piece.hue {
        case 0: CupClashTheme.gold
        case 1: CupClashTheme.cyan
        case 2: CupClashTheme.violet
        default: CupClashTheme.neonGreen
        }
    }
}

struct WinnerConfettiRain: View {
    @State private var started = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 36)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(started)
            Canvas { context, size in
                guard elapsed < 2.8 else { return }
                let fade = max(0, 1 - (elapsed - 1.8) / 1.0)
                for index in 0..<36 {
                    let drift = sin((elapsed + Double(index)) * (1.4 + Double(index % 5) * 0.11))
                    let x = ((Double(index) * 47.3).truncatingRemainder(dividingBy: Double(size.width))) + drift * 18
                    let speed = 70 + Double(index % 8) * 22
                    let y = (elapsed * speed + Double(index) * 29).truncatingRemainder(dividingBy: Double(size.height + 30)) - 12
                    let hue = index % 4
                    let color: Color = {
                        switch hue {
                        case 0: CupClashTheme.gold
                        case 1: CupClashTheme.cyan
                        case 2: CupClashTheme.violet
                        default: Color.white
                        }
                    }()
                    let rect = CGRect(x: x, y: y, width: index % 5 == 0 ? 8 : 4, height: index % 5 == 0 ? 11 : 7)
                    context.opacity = fade
                    context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(color))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct CountingNumberText: View {
    var value: Double
    var prefix: String = "+"
    var color: Color = CupClashTheme.cyan

    var body: some View {
        Text("\(prefix)\(Int(value.rounded()))")
            .foregroundStyle(color)
            .fontWeight(.bold)
            .monospacedDigit()
            .contentTransition(.numericText())
    }
}
