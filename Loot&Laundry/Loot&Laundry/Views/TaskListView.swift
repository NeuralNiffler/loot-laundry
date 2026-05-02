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

    @State private var templateSearchText       = ""
    @State private var templateSearchExpanded   = false
    @State private var openQuestSearchText      = ""
    @State private var completedTodaySearchText = ""
    @State private var openQuestSearchExpanded      = false
    @State private var completedTodaySearchExpanded = false
    @State private var difficultyFilter       = QuestDifficultyFilter.all
    @State private var recurrenceFilter       = QuestRecurrenceFilter.all
    @State private var dueFilter              = QuestDueFilter.all

    var characterViewModel: CharacterViewModel

    private var openInstances:      [QuestInstance] { allInstances.filter { !$0.isCompleted } }

    private var filteredTemplates: [QuestTemplate] {
        allTemplates.filter { QuestListFilter.matchesTemplate($0, searchText: templateSearchText) }
    }

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

    private var filteredOpenInstancesSorted: [QuestInstance] {
        openInstancesSorted.filter {
            QuestListFilter.matchesOpenInstance(
                $0,
                searchText: openQuestSearchText,
                difficulty: difficultyFilter,
                recurrence: recurrenceFilter,
                due: dueFilter
            )
        }
    }

    private var completedToday:     [QuestInstance] { allInstances.filter { $0.isCompletedToday } }

    private var filteredCompletedToday: [QuestInstance] {
        completedToday.filter { QuestListFilter.matchesCompletedInstance($0, searchText: completedTodaySearchText) }
    }

    private var openInstanceFiltersActive: Bool {
        QuestListFilter.openInstancesFiltersActive(
            difficulty: difficultyFilter,
            recurrence: recurrenceFilter,
            due: dueFilter
        )
    }

    private var templateSearchActive: Bool {
        templateSearchExpanded || !QuestListFilter.trimmedSearch(templateSearchText).isEmpty
    }

    private var openQuestSearchShowsActiveIndicator: Bool {
        openQuestSearchExpanded || !QuestListFilter.trimmedSearch(openQuestSearchText).isEmpty
    }

    private var completedTodaySearchShowsActiveIndicator: Bool {
        completedTodaySearchExpanded || !QuestListFilter.trimmedSearch(completedTodaySearchText).isEmpty
    }

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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
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
                    if templateSearchExpanded {
                        templateSearchField
                            .listRowBackground(Theme.cardBackground)
                    }
                    if filteredTemplates.isEmpty {
                        Text("Keine Vorlagen für diese Suche.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                            .listRowBackground(Theme.cardBackground)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(filteredTemplates) { template in
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
                        .listRowBackground(Theme.cardBackground)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    }
                } header: {
                    sectionHeader("Vorlagen", count: filteredTemplates.count, icon: "books.vertical") {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { templateSearchExpanded.toggle() }
                        } label: {
                            Image(systemName: templateSearchActive ? "magnifyingglass.circle.fill" : "magnifyingglass")
                                .foregroundStyle(Theme.gold)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(templateSearchExpanded ? "Vorlagensuche ausblenden" : "Vorlagen durchsuchen")
                    }
                }
            }

            // -- Offene Instanzen --
            if !openInstances.isEmpty {
                Section {
                    if openQuestSearchExpanded {
                        openQuestExpandedSearchRow
                            .listRowBackground(Theme.cardBackground)
                    }
                    if filteredOpenInstancesSorted.isEmpty {
                        Text("Keine offenen Quests für Suche oder Filter.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                            .listRowBackground(Theme.cardBackground)
                    } else {
                        ForEach(filteredOpenInstancesSorted) { instance in
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
                    }
                } header: {
                    sectionHeader("Offene Quests", count: filteredOpenInstancesSorted.count, icon: "scroll") {
                        openInstancesFilterMenu
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { openQuestSearchExpanded.toggle() }
                        } label: {
                            Image(systemName: openQuestSearchShowsActiveIndicator ? "magnifyingglass.circle.fill" : "magnifyingglass")
                                .foregroundStyle(Theme.gold)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(openQuestSearchExpanded ? "Suche ausblenden" : "Offene Quests durchsuchen")
                    }
                }
                .listRowBackground(Theme.cardBackground)
            }

            // -- Heute erledigt --
            if !completedToday.isEmpty {
                Section {
                    if completedTodaySearchExpanded {
                        completedTodayExpandedSearchRow
                            .listRowBackground(Theme.cardBackground.opacity(0.6))
                    }
                    if filteredCompletedToday.isEmpty {
                        Text("Keine erledigten Quests für diese Suche.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                            .listRowBackground(Theme.cardBackground.opacity(0.6))
                    } else {
                        ForEach(filteredCompletedToday) { instance in
                            CompletedInstanceRowView(instance: instance)
                        }
                    }
                } header: {
                    sectionHeader("Heute erledigt", count: filteredCompletedToday.count, icon: "checkmark.seal.fill") {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { completedTodaySearchExpanded.toggle() }
                        } label: {
                            Image(systemName: completedTodaySearchShowsActiveIndicator ? "magnifyingglass.circle.fill" : "magnifyingglass")
                                .foregroundStyle(Theme.gold)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(completedTodaySearchExpanded ? "Suche ausblenden" : "Erledigte Quests durchsuchen")
                    }
                }
                .listRowBackground(Theme.cardBackground.opacity(0.6))
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
    }

    private func sectionHeader<Trailing: View>(
        _ title: String,
        count: Int,
        icon: String,
        @ViewBuilder trailingActions: () -> Trailing
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
            Spacer()
            trailingActions()
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

    private func sectionHeader(_ title: String, count: Int, icon: String) -> some View {
        sectionHeader(title, count: count, icon: icon) { EmptyView() }
    }

    private var templateSearchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.textSecondary)
            TextField("Vorlagen durchsuchen …", text: $templateSearchText)
                .foregroundStyle(Theme.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    templateSearchExpanded = false
                }
            } label: {
                Image(systemName: "chevron.up.circle.fill")
                    .foregroundStyle(Theme.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Vorlagensuche ausblenden")
        }
        .padding(.vertical, 6)
    }

    private var openInstancesFilterMenu: some View {
        Menu {
            Section("Schwierigkeit") {
                ForEach(QuestDifficultyFilter.allCases, id: \.self) { option in
                    Button {
                        difficultyFilter = option
                    } label: {
                        if difficultyFilter == option {
                            Label(option.menuTitle, systemImage: "checkmark")
                        } else {
                            Text(option.menuTitle)
                        }
                    }
                }
            }
            Section("Art") {
                ForEach(QuestRecurrenceFilter.allCases, id: \.self) { option in
                    Button {
                        recurrenceFilter = option
                    } label: {
                        if recurrenceFilter == option {
                            Label(option.menuTitle, systemImage: "checkmark")
                        } else {
                            Text(option.menuTitle)
                        }
                    }
                }
            }
            Section("Fälligkeit") {
                ForEach(QuestDueFilter.allCases, id: \.self) { option in
                    Button {
                        dueFilter = option
                    } label: {
                        if dueFilter == option {
                            Label(option.menuTitle, systemImage: "checkmark")
                        } else {
                            Text(option.menuTitle)
                        }
                    }
                }
            }
            if openInstanceFiltersActive {
                Section {
                    Button("Filter zurücksetzen") {
                        difficultyFilter = .all
                        recurrenceFilter = .all
                        dueFilter = .all
                    }
                }
            }
        } label: {
            Image(systemName: openInstanceFiltersActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .font(.title3)
                .foregroundStyle(Theme.gold)
        }
        .accessibilityLabel("Filter für offene Quests")
    }

    private var openQuestExpandedSearchRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.textSecondary)
            TextField("Offene Quests durchsuchen …", text: $openQuestSearchText)
                .foregroundStyle(Theme.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    openQuestSearchExpanded = false
                }
            } label: {
                Image(systemName: "chevron.up.circle.fill")
                    .foregroundStyle(Theme.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Suchfeld ausblenden")
        }
        .padding(.vertical, 6)
    }

    private var completedTodayExpandedSearchRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.textSecondary)
            TextField("Erledigte Quests durchsuchen …", text: $completedTodaySearchText)
                .foregroundStyle(Theme.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    completedTodaySearchExpanded = false
                }
            } label: {
                Image(systemName: "chevron.up.circle.fill")
                    .foregroundStyle(Theme.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Suchfeld ausblenden")
        }
        .padding(.vertical, 6)
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
