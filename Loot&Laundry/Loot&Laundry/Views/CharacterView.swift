import SwiftUI
import SwiftData

struct CharacterView: View {

    @Query private var characters: [PlayerCharacter]
    @Query private var completedInstances: [QuestInstance]

    var characterViewModel: CharacterViewModel

    private var character: PlayerCharacter? { characters.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if let char = character {
                    ScrollView {
                        VStack(spacing: 20) {
                            characterPortrait(char)
                            evolutionInfo(char)
                            expSection(char)
                            evolutionRoadmap(char)
                            statsSection(char)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .padding(.bottom, 40)
                    }
                } else {
                    ProgressView()
                        .tint(Theme.gold)
                }

                // Evolution Overlay
                if characterViewModel.showEvolutionOverlay {
                    evolutionOverlay
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.cardBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Charakter Portrait

    private func characterPortrait(_ char: PlayerCharacter) -> some View {
        ZStack {
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Theme.gold, Theme.expColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )

            Image(char.currentEvolution.assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
        }
        .frame(width: 300, height: 300)
        .background {
            Circle()
                .fill(Theme.expColor.opacity(0.12))
                .frame(width: 380, height: 380)
                .blur(radius: 24)
        }
    }

    // MARK: - Evolution & Name

    private func evolutionInfo(_ char: PlayerCharacter) -> some View {
        VStack(spacing: 8) {
            Text(char.currentEvolution.displayName)
                .font(.title.bold())
                .foregroundStyle(Theme.textPrimary)

            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.gold)
                Text("Stufe \(char.currentEvolution.rawValue)")
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.gold)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Theme.gold.opacity(0.15))
            .clipShape(Capsule())
        }
    }

    // MARK: - EXP Section

    private func expSection(_ char: PlayerCharacter) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Erfahrung", systemImage: "sparkles")
                    .font(.headline.bold())
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(char.totalEXP) EXP gesamt")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            // EXP Progress Bar
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.expColor.opacity(0.2))
                            .frame(height: 14)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.expColor, Theme.gold],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * char.progressToNextLevel, height: 14)
                            .animation(.spring(response: 0.6), value: char.progressToNextLevel)
                    }
                }
                .frame(height: 14)

                HStack {
                    Text("\(char.expInCurrentLevel) EXP")
                        .font(.caption2.bold())
                        .foregroundStyle(Theme.expColor)

                    Spacer()

                    if let required = char.expRequiredForNextLevel {
                        Text("\(required) EXP bis \(char.currentEvolution.nextEvolution?.displayName ?? "")")
                            .font(.caption2)
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        Text("Maximale Stufe erreicht!")
                            .font(.caption2.bold())
                            .foregroundStyle(Theme.gold)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Evolution Roadmap

    private func evolutionRoadmap(_ char: PlayerCharacter) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Evolutionsweg", systemImage: "map.fill")
                .font(.headline.bold())
                .foregroundStyle(Theme.textPrimary)

            HStack(spacing: 0) {
                ForEach(CharacterEvolution.allCases, id: \.self) { evo in
                    let isReached  = char.totalEXP >= evo.expThreshold
                    let isCurrent  = char.currentEvolution == evo

                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(isReached ? Theme.gold : Theme.textSecondary.opacity(0.2))
                                .frame(width: 36, height: 36)

                            if isCurrent {
                                Circle()
                                    .strokeBorder(Theme.gold, lineWidth: 2)
                                    .frame(width: 44, height: 44)
                            }

                            Text("\(evo.rawValue)")
                                .font(.caption.bold())
                                .foregroundStyle(isReached ? Theme.background : Theme.textSecondary)
                        }

                        Text(shortName(evo))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(isReached ? Theme.gold : Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(width: 52)
                    }
                    .frame(maxWidth: .infinity)

                    if evo != .meister {
                        Rectangle()
                            .fill(char.totalEXP >= (evo.nextEvolution?.expThreshold ?? 0)
                                  ? Theme.gold : Theme.textSecondary.opacity(0.2))
                            .frame(height: 2)
                            .offset(y: -14)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func shortName(_ evo: CharacterEvolution) -> String {
        switch evo {
        case .novize:   return "Novize"
        case .gelehrte: return "Gelehrte"
        case .magier:   return "Magier"
        case .arkanist: return "Arkanist"
        case .meister:  return "Meister"
        }
    }

    // MARK: - Stats Section

    private var todayCompletionCount: Int {
        completedInstances.filter { $0.isCompletedToday }.count
    }

    private func statsSection(_ char: PlayerCharacter) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Statistiken", systemImage: "chart.bar.fill")
                .font(.headline.bold())
                .foregroundStyle(Theme.textPrimary)

            HStack(spacing: 12) {
                StatCard(
                    title: "Heute",
                    value: "\(todayCompletionCount)",
                    subtitle: "erledigt",
                    icon: "checkmark.seal.fill",
                    color: Theme.success
                )
                StatCard(
                    title: "Gesamt",
                    value: "\(completedInstances.filter { $0.isCompleted }.count)",
                    subtitle: "Quests",
                    icon: "scroll.fill",
                    color: Theme.gold
                )
                StatCard(
                    title: "EXP",
                    value: "\(char.totalEXP)",
                    subtitle: "gesammelt",
                    icon: "sparkles",
                    color: Theme.expColor
                )
            }
        }
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Evolution Overlay

    private var evolutionOverlay: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture {
                    characterViewModel.dismissEvolutionOverlay()
                }

            EvolutionCelebrationLayer(isActive: characterViewModel.showEvolutionOverlay)

            RadialGradient(
                colors: [
                    Theme.gold.opacity(0.18),
                    Theme.expColor.opacity(0.06),
                    Color.clear,
                ],
                center: .center,
                startRadius: 20,
                endRadius: 320
            )
            .ignoresSafeArea()
            .blendMode(.plusLighter)
            .allowsHitTesting(false)

            VStack(spacing: 24) {
                // Glow Ring Animation
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .strokeBorder(Theme.gold.opacity(0.3 - Double(i) * 0.08), lineWidth: 2)
                            .frame(width: CGFloat(180 + i * 30), height: CGFloat(180 + i * 30))
                            .scaleEffect(characterViewModel.showEvolutionOverlay ? 1.0 : 0.3)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.5)
                                    .delay(Double(i) * 0.1),
                                value: characterViewModel.showEvolutionOverlay
                            )
                    }

                    if let evo = characterViewModel.displayedEvolution {
                        Image(evo.assetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140, height: 140)
                            .scaleEffect(characterViewModel.showEvolutionOverlay ? 1.0 : 0.3)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: characterViewModel.showEvolutionOverlay)
                    }
                }

                VStack(spacing: 8) {
                    Text("Stufenaufstieg!")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Theme.gold)

                    if let evo = characterViewModel.displayedEvolution {
                        Text(evo.displayName)
                            .font(.title2)
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                .scaleEffect(characterViewModel.showEvolutionOverlay ? 1.0 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.15), value: characterViewModel.showEvolutionOverlay)

                Button("Weiter") {
                    characterViewModel.dismissEvolutionOverlay()
                }
                .font(.headline.bold())
                .foregroundStyle(Theme.background)
                .frame(width: 160, height: 48)
                .background(Theme.gold)
                .clipShape(Capsule())
            }
        }
        .transition(.opacity)
    }
}

// MARK: - StatCard

private struct StatCard: View {
    let title:    String
    let value:    String
    let subtitle: String
    let icon:     String
    let color:    Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)

            Text(title)
                .font(.caption.bold())
                .foregroundStyle(color)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
