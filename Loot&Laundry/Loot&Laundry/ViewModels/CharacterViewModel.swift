import Foundation
import SwiftUI

@Observable
final class CharacterViewModel {

    var showEvolutionOverlay: Bool = false
    var displayedEvolution: CharacterEvolution? = nil

    /// Wird von TaskListViewModel aufgerufen wenn ein Stufenaufstieg stattfand.
    func triggerEvolutionAnimation(newEvolution: CharacterEvolution) {
        displayedEvolution = newEvolution
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            showEvolutionOverlay = true
        }
    }

    func dismissEvolutionOverlay() {
        withAnimation(.easeOut(duration: 0.4)) {
            showEvolutionOverlay = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.displayedEvolution = nil
        }
    }
}
