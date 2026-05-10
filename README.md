# Loot & Laundry

> **Makes Laundry Chores a Charm**

Eine gamifizierte Haushalts-App für iOS, die alltägliche Aufgaben in ein RPG-Erlebnis verwandelt. Erledigte Haushaltstätigkeiten belohnen den Spieler mit Erfahrungspunkten (EXP), die den eigenen Charakter wachsen und evolvieren lassen.

---

## Quickstart

### Projektstart

```bash
# Repository klonen
git clone <repo-url>

# Xcode öffnen
open "Loot&Laundry/Loot&Laundry.xcodeproj"

# Simulator oder echtes Gerät wählen, dann starten (Cmd + R)
```

### Mindestanforderungen:
 **Xcode 16+**, **iOS 17+**

 --- 

## Features (MVP)

| Feature | Beschreibung |
|---|---|
| **Quest-Liste** | Aufgaben anlegen, abhaken und als wiederkehrend markieren (täglich / wöchentlich) |
| **Schwierigkeitsgrade** | Leicht (+5 EXP), Mittel (+10 EXP), Schwer (+20 EXP) |
| **Charakter-Screen** | Anzeige der aktuellen Evolutionsstufe, EXP-Fortschrittsbalken und Statistiken |
| **Charakter-Evolution** | 5 Evolutionsstufen mit eigenen Grafiken, automatisch ausgelöst durch EXP-Schwellen |
| **Evolutions-Animation** | Feier-Overlay bei jedem Stufenaufstieg |
| **Lokale Benachrichtigungen** | Automatische Reminder für offene Quests/ inaktivität |
| **Vordefinierte Aufgaben** | Seed-Daten mit typischen Haushalts-Quests beim ersten App-Start |

---

## Technischer Stack

| Bereich | Technologie |
|---|---|
| Plattform | iOS (SwiftUI) |
| Sprache | Swift |
| Persistenz | SwiftData |
| Architektur | MVVM |
| Tests | XCTest (Unit-Tests, TDD) |
| IDE | Xcode/Cursor |

---

## Tests

Die gesamte Kernlogik ist durch Unit-Tests abgedeckt. 

Tests befinden sich im Target `Loot&LaundryTests` und können über `Cmd + U` in Xcode ausgeführt werden.


---

## Architektur

Das Projekt folgt einer strikten **MVVM-Schichtentrennung**:

```
Views (SwiftUI)
  └── ViewModels (@Observable)
        └── Services (reine Geschäftslogik, ohne UI-Abhängigkeiten)
              └── Models (SwiftData @Model)
```

### Detaillierte Ordnerstruktur

```
Loot&Laundry/
├── Models/
│   ├── PlayerCharacter.swift       – SwiftData-Modell des Spielers
│   ├── QuestTemplate.swift         – Vorlage für eine Aufgabe (wiederkehrend / einmalig)
│   ├── QuestInstance.swift         – Konkrete Aufgaben-Instanz (offen / erledigt)
│   ├── CharacterEvolution.swift    – Enum: 5 Stufen mit EXP-Schwellen
│   ├── QuestEnums.swift            – TaskDifficulty, RecurrenceRule
│   └── QuestListFilter.swift       – Filter-Logik für die Quest-Ansicht
├── ViewModels/
│   ├── CharacterViewModel.swift    – Charakter-Daten, Evolutions-Trigger
│   └── TaskListViewModel.swift     – Aufgaben-Liste, Quest abschließen
├── Views/
│   ├── MainTabView.swift           – Tab-Navigation (Charakter / Quests)
│   ├── CharacterView.swift         – Charakter-Bild, EXP-Balken
│   ├── TaskListView.swift          – Quest-Übersicht mit Filter
│   ├── AddEditTaskView.swift       – Formular: neue Quest anlegen / bearbeiten
│   ├── EvolutionCelebrationLayer.swift – Animations-Overlay bei Stufenaufstieg
│   └── Theme.swift                 – Farben & Typografie (RPG-Look)
├── Services/
│   ├── ProgressionService.swift    – EXP-Berechnung, Evolutions-Logik (testbar)
│   ├── QuestSchedulingService.swift– Wiederkehrende Instanzen erzeugen
│   ├── NotificationSyncService.swift – Benachrichtigungen bei App-Aktivierung synchronisieren
│   ├── NotificationPlanner.swift   – Zeitplanung für Reminder
│   ├── NotificationContent.swift   – Texte & Payload der Benachrichtigungen
│   └── SeedDataService.swift       – Vordefinierte Aufgaben & Spieler beim Erststart
└── Loot_LaundryApp.swift           – App-Entry, SwiftData ModelContainer
```

---


*Erstellt von Robin Schmid – April 2026*
