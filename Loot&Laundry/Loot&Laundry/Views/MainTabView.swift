import SwiftUI
import SwiftData

struct MainTabView: View {

    @Environment(\.modelContext) private var context
    @State private var characterViewModel = CharacterViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CharacterView(characterViewModel: characterViewModel)
                .tabItem {
                    Label("Charakter", systemImage: "person.fill")
                }
                .tag(0)

            TaskListView(characterViewModel: characterViewModel)
                .tabItem {
                    Label("Quests", systemImage: "scroll.fill")
                }
                .tag(1)
        }
        .tint(Theme.gold)
        .onAppear {
            configureTabBarAppearance()
            SeedDataService.seedPlayerIfNeeded(context: context)
            SeedDataService.seedTemplatesIfNeeded(context: context)
            QuestSchedulingService.ensureRecurringInstances(context: context)
        }
        // Wenn eine Evolution getriggert wurde, zur Charakter-Ansicht wechseln
        .onChange(of: characterViewModel.showEvolutionOverlay) { _, isShowing in
            if isShowing {
                withAnimation { selectedTab = 0 }
            }
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.cardBackground)

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor   = UIColor(Theme.textSecondary)
        itemAppearance.normal.titleTextAttributes   = [.foregroundColor: UIColor(Theme.textSecondary)]
        itemAppearance.selected.iconColor = UIColor(Theme.gold)
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Theme.gold)]

        appearance.stackedLayoutAppearance = itemAppearance
        UITabBar.appearance().standardAppearance   = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
