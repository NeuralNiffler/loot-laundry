import SwiftUI

/// Magischer Konfetti- und Funkenregen für Stufenaufstiege (Gold, EXP-Lila, helle Akzente).
struct EvolutionCelebrationLayer: View {
    var isActive: Bool

    @State private var particles: [CelebrationParticle] = []
    @State private var startDate = Date()

    var body: some View {
        Group {
            if isActive {
                TimelineView(.animation(minimumInterval: 1 / 50)) { timeline in
                    Canvas { baseContext, size in
                        let elapsed = timeline.date.timeIntervalSince(startDate)
                        let origin = CGPoint(x: size.width * 0.5, y: size.height * 0.28)

                        for p in particles {
                            var context = baseContext
                            switch p.kind {
                            case .falling:
                                drawFalling(p, elapsed: elapsed, size: size, context: &context)
                            case .burst:
                                drawBurst(p, elapsed: elapsed, origin: origin, context: &context)
                            }
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, active in
            if active { regenerate() }
        }
        .onAppear {
            if isActive { regenerate() }
        }
    }

    private func regenerate() {
        startDate = Date()
        var rng = LCG(seed: UInt64.random(in: 1 ... UInt64.max))
        particles = CelebrationParticle.makeField(count: 68, rng: &rng)
            + CelebrationParticle.makeBurst(count: 28, rng: &rng)
    }

    private func drawFalling(
        _ p: CelebrationParticle,
        elapsed: TimeInterval,
        size: CGSize,
        context: inout GraphicsContext
    ) {
        let t = max(0, elapsed - p.delay)
        let progress = min(1, t / p.duration)
        let x = p.anchorX * size.width + sin(t * p.swayPhase) * p.swayPixels
        let y = -40 + progress * (size.height + 120)
        let rotation = Angle.degrees(t * p.spinPerSecond * 360 / max(p.duration, 0.01))
        let opacity = 0.2 + 0.8 * (1 - progress * 0.35)

        context.translateBy(x: x, y: y)
        context.rotate(by: rotation)
        let rect = CGRect(
            x: -p.width * 0.5,
            y: -p.height * 0.5,
            width: p.width,
            height: p.height
        )
        let paint = p.color.opacity(opacity)
        if p.isStrip {
            context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(paint))
        } else {
            context.fill(Path(ellipseIn: rect), with: .color(paint))
        }
    }

    private func drawBurst(
        _ p: CelebrationParticle,
        elapsed: TimeInterval,
        origin: CGPoint,
        context: inout GraphicsContext
    ) {
        let t = max(0, elapsed - p.delay)
        guard t < p.duration + 0.2 else { return }
        let progress = min(1, t / p.duration)
        let ease = 1 - pow(1 - progress, 2)
        let dist = ease * p.burstDistance
        let x = origin.x + cos(p.burstAngle) * dist
        let y = origin.y + sin(p.burstAngle) * dist + t * t * 120
        let fade = max(0, 1 - progress * 1.15)
        let opacity = fade * 0.95

        context.translateBy(x: x, y: y)
        context.rotate(by: .degrees(t * p.spinPerSecond * 40))
        let rect = CGRect(x: -p.width * 0.5, y: -p.height * 0.5, width: p.width, height: p.height)
        context.fill(Path(ellipseIn: rect), with: .color(p.color.opacity(opacity)))
    }
}

// MARK: - Partikel

private enum ParticleKind {
    case falling
    case burst
}

private struct CelebrationParticle {
    let kind: ParticleKind
    let color: Color
    let delay: TimeInterval
    let duration: TimeInterval
    let width: CGFloat
    let height: CGFloat
    let spinPerSecond: CGFloat
    let swayPhase: CGFloat
    let swayPixels: CGFloat
    let anchorX: CGFloat
    let isStrip: Bool
    let burstAngle: CGFloat
    let burstDistance: CGFloat

    static func makeField(count: Int, rng: inout LCG) -> [CelebrationParticle] {
        let palette: [Color] = [
            Theme.gold,
            Theme.expColor,
            Color(red: 0.95, green: 0.95, blue: 1.0),
            Color(red: 0.45, green: 0.85, blue: 1.0),
            Theme.success,
        ]
        return (0 ..< count).map { _ in
            let color = palette[Int(rng.nextUnit() * CGFloat(palette.count)) % palette.count]
            return CelebrationParticle(
                kind: .falling,
                color: color,
                delay: TimeInterval(rng.nextUnit() * 1.4),
                duration: 2.4 + TimeInterval(rng.nextUnit() * 1.8),
                width: 5 + rng.nextUnit() * 9,
                height: 7 + rng.nextUnit() * 14,
                spinPerSecond: -1.5 + rng.nextUnit() * 3,
                swayPhase: 2.2 + rng.nextUnit() * 3,
                swayPixels: 18 + rng.nextUnit() * 36,
                anchorX: rng.nextUnit(),
                isStrip: rng.nextUnit() > 0.45,
                burstAngle: 0,
                burstDistance: 0
            )
        }
    }

    static func makeBurst(count: Int, rng: inout LCG) -> [CelebrationParticle] {
        let palette: [Color] = [Theme.gold, Theme.expColor, .white]
        return (0 ..< count).map { i in
            let color = palette[i % palette.count]
            let angle = CGFloat(i) / CGFloat(max(count, 1)) * (.pi * 2) + rng.nextUnit() * 0.35
            return CelebrationParticle(
                kind: .burst,
                color: color,
                delay: TimeInterval(rng.nextUnit() * 0.12),
                duration: 0.55 + TimeInterval(rng.nextUnit() * 0.35),
                width: 4 + rng.nextUnit() * 6,
                height: 4 + rng.nextUnit() * 6,
                spinPerSecond: -2 + rng.nextUnit() * 4,
                swayPhase: 0,
                swayPixels: 0,
                anchorX: 0,
                isStrip: false,
                burstAngle: angle,
                burstDistance: 90 + rng.nextUnit() * 160
            )
        }
    }
}

// MARK: - Einfacher PRNG (deterministisch pro Seed, keine Foundation-Abhängigkeit)

private struct LCG {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0xDEADBEEF : seed
    }

    mutating func nextUnit() -> CGFloat {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat(state & 0xFFFF_FFFF) / CGFloat(0xFFFF_FFFF)
    }
}
