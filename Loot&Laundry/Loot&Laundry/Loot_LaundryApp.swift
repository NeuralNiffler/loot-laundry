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
            MainTabView()
        }
        .modelContainer(for: [
            PlayerCharacter.self,
            QuestTemplate.self,
            QuestInstance.self,
        ])
    }
}
