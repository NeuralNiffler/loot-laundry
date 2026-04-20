import SwiftUI
import SwiftData

struct TaskListView: View {

    @Environment(\.modelContext)    private var context
    @Query(sort: \QuestTemplate.createdAt, order: .reverse)
    private var allTemplates: [QuestTemplate]

    @Query(sort: \QuestInstance.createdAt, order: .forward)
    private var allInstances: [QuestInstance]

    @Query
    private var characters: [PlayerCharacter]

    @State private var viewModel           = TaskListViewModel()
    @State private var showAddSheet        = false
    @State private var templateToEdit:     QuestTemplate? = nil

    var characterViewModel: CharacterViewModel

    private var openInstances:      [QuestInstance] { allInstances.filter { !$0.isCompleted } }

    /// Sortierung: Fälligkeit aufsteigend (überfällige zuerst), sonst Erstellzeit.
    private var openInstancesSorted: [QuestInstance] {
        openInstances.sorted { a, b in
            switch (a.dueDate, b.dueDate) {
            case let (da?, db?):
                if da != db { return da < db }
                return a.createdAt < b.createdAt
            case (nil, nil):
                return a.createdAt < b.createdAt
            case (nil, _?):
                return false
            case (_?, nil):
                return true
            }
        }
    }

    private var completedToday:     [QuestInstance] { allInstances.filter { $0.isCompletedToday } }
    private var character: PlayerCharacter?          { characters.first }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Theme.background.ignoresSafeArea()

                if allTemplates.isEmpty && allInstances.isEmpty {
                    emptyState
                } else {
                    questList
                }

                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundStyle(Theme.background)
                        .frame(width: 56, height: 56)
                        .background(Theme.gold)
                        .clipShape(Circle())
                        .shadow(color: Theme.gold.opacity(0.5), radius: 12, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 24)
            }
            .navigationTitle("Quests")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Theme.cardBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(isPresented: $showAddSheet) {
            AddEditTaskView(viewModel: viewModel)
        }
        .sheet(item: $templateToEdit) { template in
            AddEditTaskView(viewModel: viewModel, templateToEdit: template)
        }
        .onChange(of: viewModel.triggeredEvolution) { _, newEvo in
            if let evo = newEvo {
                characterViewModel.triggerEvolutionAnimation(newEvolution: evo)
                viewModel.clearTriggeredEvolution()
            }
        }
    }

    // MARK: - Haupt-Liste

    private var questList: some View {
        List {
            // -- Vorlagen-Bibliothek --
            if !allTemplates.isEmpty {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(allTemplates) { template in
                                TemplateCard(template: template) {
                                    withAnimation(.spring(response: 0.3)) {
                                        viewModel.spawnInstance(from: template, context: context)
                                    }
                                } onEdit: {
                                    templateToEdit = template
                                } onDelete: {
                                    viewModel.deleteTemplate(template, context: context)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                    }
                } header: {
                    sectionHeader("Vorlagen", count: allTemplates.count, icon: "books.vertical")
                }
                .listRowBackground(Theme.cardBackground)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }

            // -- Offene Instanzen --
            if !openInstances.isEmpty {
                Section {
                    ForEach(openInstancesSorted) { instance in
                        InstanceRowView(instance: instance) {
                            if let char = character {
                                withAnimation(.spring(response: 0.4)) {
                                    viewModel.completeInstance(instance, character: char, context: context)
                                }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                viewModel.deleteInstance(instance, context: context)
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    sectionHeader("Offene Quests", count: openInstances.count, icon: "scroll")
                }
                .listRowBackground(Theme.cardBackground)
            }

            // -- Heute erledigt --
            if !completedToday.isEmpty {
                Section {
                    ForEach(completedToday) { instance in
                        CompletedInstanceRowView(instance: instance)
                    }
                } header: {
                    sectionHeader("Heute erledigt", count: completedToday.count, icon: "checkmark.seal.fill")
                }
                .listRowBackground(Theme.cardBackground.opacity(0.6))
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
    }

    private func sectionHeader(_ title: String, count: Int, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
            Spacer()
            Text("\(count)")
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Theme.gold.opacity(0.2))
                .foregroundStyle(Theme.gold)
                .clipShape(Capsule())
        }
        .foregroundStyle(Theme.gold)
        .font(.caption.bold())
        .textCase(nil)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "scroll")
                .font(.system(size: 60))
                .foregroundStyle(Theme.gold.opacity(0.4))
            Text("Keine Quests vorhanden")
                .font(.title3.bold())
                .foregroundStyle(Theme.textPrimary)
            Text("Tippe auf +, um deine erste Quest-Vorlage hinzuzufügen.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - TemplateCard

private struct TemplateCard: View {
    let template: QuestTemplate
    let onAdd: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Titel + Wiederholung
            VStack(alignment: .leading, spacing: 4) {
                Text(template.title)
                    .font(.body.bold())
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    if template.isRecurring {
                        Label(template.recurrenceRule?.rawValue ?? "Wiederkehrend", systemImage: "arrow.clockwise")
                            .font(.caption2)
                            .foregroundStyle(Theme.gold)
                    } else {
                        Label("Einmalig", systemImage: "scroll")
                            .font(.caption2)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }

            Spacer()

            // Buttons
            HStack(spacing: 10) {
                // Löschen Button
                Menu {
                    Button {
                        onEdit()
                    } label: {
                        Label("Bearbeiten", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption.bold())
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Theme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Theme.textSecondary.opacity(0.2), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Hinzufügen Button
                Button(action: onAdd) {
                    Text("Hinzufügen")
                        .font(.caption.bold())
                        .foregroundStyle(Theme.background)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(Theme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .frame(width: 160)
        .padding(12)
        .background(Theme.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.gold.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - InstanceRowView

private struct InstanceRowView: View {
    let instance: QuestInstance
    let onComplete: () -> Void

    @State private var pressed = false

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onComplete) {
                Image(systemName: "circle")
                    .font(.title3)
                    .foregroundStyle(Theme.gold)
                    .scaleEffect(pressed ? 1.3 : 1.0)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in withAnimation(.spring(response: 0.2)) { pressed = true } }
                    .onEnded   { _ in withAnimation(.spring(response: 0.2)) { pressed = false } }
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(instance.title)
                    .font(.body.bold())
                    .foregroundStyle(titleColor(for: instance))

                HStack(spacing: 8) {
                    DifficultyBadge(difficulty: instance.difficulty)

                    if instance.isRecurring, let rule = instance.recurrenceRule {
                        Label(rule.rawValue, systemImage: "arrow.clockwise")
                            .font(.caption2)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }

            Spacer()

            Text("+\(instance.difficulty.expReward) EXP")
                .font(.caption.bold())
                .foregroundStyle(Theme.expColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.expColor.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }

    /// Titelfarbe nach Fälligkeit (ohne Text-Badge).
    private func titleColor(for instance: QuestInstance) -> Color {
        guard instance.dueDate != nil else { return Theme.textPrimary }
        if instance.isOverdue { return Color(red: 1.0, green: 0.38, blue: 0.38) }
        if instance.isDueToday { return Theme.gold }
        return Color(red: 0.58, green: 0.72, blue: 0.95)
    }
}

// MARK: - CompletedInstanceRowView

private struct CompletedInstanceRowView: View {
    let instance: QuestInstance

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Theme.success)

            VStack(alignment: .leading, spacing: 4) {
                Text(instance.title)
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
                    .strikethrough(true, color: Theme.textSecondary)

                DifficultyBadge(difficulty: instance.difficulty)
            }

            Spacer()

            Text("+\(instance.expEarned) EXP")
                .font(.caption.bold())
                .foregroundStyle(Theme.success.opacity(0.7))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - DifficultyBadge (Shared Component)

struct DifficultyBadge: View {
    let difficulty: TaskDifficulty

    var color: Color {
        switch difficulty {
        case .easy:   return .green
        case .medium: return .orange
        case .hard:   return .red
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: difficulty.symbolName)
            Text(difficulty.rawValue)
        }
        .font(.caption2.bold())
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}
