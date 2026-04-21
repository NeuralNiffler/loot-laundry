import SwiftUI

@Observable
final class CharacterViewModel {
    var showEvolutionOverlay = false
    var displayedEvolution: CharacterEvolution?

    func triggerEvolutionAnimation(newEvolution: CharacterEvolution) {
        displayedEvolution = newEvolution
        withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
            showEvolutionOverlay = true
        }
    }

    func dismissEvolutionOverlay() {
        withAnimation(.easeOut(duration: 0.28)) {
            showEvolutionOverlay = false
        }
    }
}
