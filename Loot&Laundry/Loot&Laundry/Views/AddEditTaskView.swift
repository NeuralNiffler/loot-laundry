import SwiftUI
import SwiftData

struct AddEditTaskView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    let viewModel: TaskListViewModel

    /// Optionales Template zum Bearbeiten – nil = neues Template
    var templateToEdit: QuestTemplate? = nil

    @State private var title:          String           = ""
    @State private var difficulty:     TaskDifficulty   = .medium
    @State private var isRecurring:    Bool             = false
    @State private var recurrenceRule: RecurrenceRule   = .daily

    private var isEditing: Bool { templateToEdit != nil }
    private var isValid:   Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                Form {
                    // -- Titel --
                    Section {
                        TextField("z.B. Geschirrspüler ausräumen", text: $title)
                            .foregroundStyle(Theme.textPrimary)
                    } header: {
                        Text("Quest-Name")
                            .foregroundStyle(Theme.gold)
                            .font(.caption.bold())
                    }
                    .listRowBackground(Theme.cardBackground)

                    // -- Schwierigkeit --
                    Section {
                        ForEach(TaskDifficulty.allCases, id: \.self) { level in
                            HStack {
                                DifficultyBadge(difficulty: level)
                                Spacer()
                                Text("+\(level.expReward) EXP")
                                    .font(.caption.bold())
                                    .foregroundStyle(Theme.expColor)
                                if difficulty == level {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Theme.gold)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { difficulty = level }
                        }
                    } header: {
                        Text("Schwierigkeit")
                            .foregroundStyle(Theme.gold)
                            .font(.caption.bold())
                    }
                    .listRowBackground(Theme.cardBackground)

                    // -- Wiederholung --
                    Section {
                        Toggle(isOn: $isRecurring) {
                            Label("Wiederkehrende Quest", systemImage: "arrow.clockwise")
                                .foregroundStyle(Theme.textPrimary)
                        }
                        .tint(Theme.gold)

                        if isRecurring {
                            Picker("Intervall", selection: $recurrenceRule) {
                                ForEach(RecurrenceRule.allCases, id: \.self) { rule in
                                    Text(rule.rawValue).tag(rule)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    } header: {
                        Text("Wiederholung")
                            .foregroundStyle(Theme.gold)
                            .font(.caption.bold())
                    }
                    .listRowBackground(Theme.cardBackground)

                    // -- Hinweis bei neuen Templates --
                    if !isEditing {
                        Section {
                            HStack(spacing: 10) {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(Theme.gold.opacity(0.7))
                                Text("Eine neue Quest-Instanz wird sofort zur Liste hinzugefügt. Weitere Instanzen kannst du über die Vorlage in der Bibliothek starten.")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .listRowBackground(Theme.cardBackground.opacity(0.5))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isEditing ? "Vorlage bearbeiten" : "Neue Quest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.cardBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Speichern" : "Hinzufügen") {
                        save()
                    }
                    .foregroundStyle(isValid ? Theme.gold : Theme.textSecondary)
                    .disabled(!isValid)
                    .bold()
                }
            }
        }
        .onAppear { prefillIfEditing() }
    }

    // MARK: - Aktionen

    private func prefillIfEditing() {
        guard let template = templateToEdit else { return }
        title          = template.title
        difficulty     = template.difficulty
        isRecurring    = template.isRecurring
        recurrenceRule = template.recurrenceRule ?? .daily
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        if let template = templateToEdit {
            viewModel.updateTemplate(
                template,
                title: trimmed,
                difficulty: difficulty,
                isRecurring: isRecurring,
                recurrenceRule: isRecurring ? recurrenceRule : nil
            )
        } else {
            viewModel.addTemplate(
                title: trimmed,
                difficulty: difficulty,
                isRecurring: isRecurring,
                recurrenceRule: isRecurring ? recurrenceRule : nil,
                context: context
            )
        }
        dismiss()
    }
}
