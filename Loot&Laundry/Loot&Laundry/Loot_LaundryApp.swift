//
//  Loot_LaundryApp.swift
//  Loot&Laundry
//
//  Created by Robin Schmid on 17.04.2026.
//

import SwiftUI
import SwiftData

@main
struct Loot_LaundryApp: App {

    var body: some Scene {
        WindowGroup {
            AppNotificationRoot()
        }
        .modelContainer(for: [
            PlayerCharacter.self,
            QuestTemplate.self,
            QuestInstance.self,
        ])
    }
}

// MARK: - Benachrichtigungen (Lokale Reminder, siehe NotificationSyncService)

private struct AppNotificationRoot: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        MainTabView()
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task {
                        await NotificationSyncService.shared.onSceneBecameActive(context: modelContext)
                    }
                }
            }
    }
}
