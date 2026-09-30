//
//  PortionSheet.swift
//  SaltScan
//
//  Add a portion to a day, or edit, move or delete one. Servings in ½ steps
//  when the label gives a serving size, otherwise (or on demand) a typed mass
//  with one-tap shortcuts. The journal stores grams either way.
//

import SwiftUI
import SwiftData
import SaltScanCore

struct PortionSheet: View {
    enum Mode {
        case add(ScanEntry, day: Date)
        case edit(IntakeLine)
    }

    let mode: Mode
    /// Called after a successful add, save or delete, before the sheet closes.
    var onFinished: () -> Void = {}

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.saltFormatter) private var formatter
    @Environment(\.locale) private var locale
    @AppStorage("dailySaltGoalGrams") private var goalGrams: Double = 5.0

    @State private var inputMode: PortionMode
    @State private var servings: Double
    @State private var gramsText: String
    @State private var day: Date
    @State private var showSaveError = false
    @FocusState private var gramsFieldFocused: Bool

    private let productName: String
    private let servingGrams: Double?
    private let servingLabel: String?
    private let sodium100g: Double?

    init(mode: Mode, onFinished: @escaping () -> Void = {}) {
        self.mode = mode
        self.onFinished = onFinished

        let scan: ScanEntry?
        let editingGrams: Double?
        let startDay: Date
        switch mode {
        case .add(let entry, let day):
            scan = entry
            editingGrams = nil
            startDay = day
            productName = entry.productName
            sodium100g = entry.sodium100g
        case .edit(let line):
            scan = line.scan
            editingGrams = line.grams
            startDay = line.addedAt
            productName = line.displayName
            sodium100g = line.effectiveSodium100g
        }

        let serving = PortionInput.usableServing(scan?.servingQuantityGrams)
        servingGrams = serving
        servingLabel = scan?.servingSize
        let grams = editingGrams ?? serving ?? PortionInput.fallbackGrams
        _inputMode = State(initialValue: PortionInput.initialMode(editingGrams: editingGrams, servingGrams: serving))
        _servings = State(initialValue: serving.map { PortionInput.nearestServings(grams: grams, servingGrams: $0) } ?? 1)
        _gramsText = State(initialValue: PortionInput.formatGrams(grams))
        _day = State(initialValue: startDay)
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    /// The mass that will be saved, nil when the typed value is not usable.
    private var currentGrams: Double? {
        switch inputMode {
        case .servings:
            guard let servingGrams else { return nil }
            return PortionInput.grams(servings: servings, servingGrams: servingGrams)
        case .grams:
            let value = PortionInput.parseGrams(gramsText, locale: locale)
            return PortionInput.isValid(grams: value) ? value : nil
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section { estimateHeader }

                if servingGrams != nil {
                    Section {
                        Picker("journal.portion.mode", selection: $inputMode) {
                            Text("journal.portion.mode.servings").tag(PortionMode.servings)
                            Text("journal.portion.mode.grams").tag(PortionMode.grams)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                    .listRowBackground(Color.clear)
                }

                Section {
                    if inputMode == .servings {
                        servingsInput
                    } else {
                        gramsInput
                    }
                }

                Section {
                    DatePicker("journal.portion.day", selection: $day, in: ...Date.now, displayedComponents: .date)
                }

                if isEditing {
                    Section {
                        Button("journal.portion.delete", role: .destructive) { deleteLine() }
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(isEditing ? "journal.portion.editTitle" : "journal.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("journal.portion.cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                SSButton(
                    title: isEditing ? "journal.portion.save" : "journal.addPortion",
                    icon: "checkmark.circle.fill",
                    isEnabled: currentGrams != nil
                ) { save() }
                .padding(SSSpacing.md)
                .background(.bar)
            }
            .onChange(of: inputMode) { oldMode, newMode in
                carryAmount(from: oldMode, to: newMode)
            }
            .alert("journal.portion.saveFailed.title", isPresented: $showSaveError) {
                Button("journal.portion.saveFailed.ok", role: .cancel) {}
            } message: {
                Text("journal.portion.saveFailed.message")
            }
        }
    }

    // MARK: - Pieces

    private var estimateHeader: some View {
        VStack(spacing: SSSpacing.xs) {
            Text(productName)
                .font(SSFont.title3())
                .multilineTextAlignment(.center)
            if let sodium100g {
                let sodium = sodium100g * (currentGrams ?? 0) / 100
                let key = formatter.unit == .sodiumMilligrams ? "journal.portion.sodiumEstimate" : "journal.portion.saltEstimate"
                Text(String(format: key.localize, formatter.amount(sodiumGrams: sodium)))
                    .font(SSFont.headline())
                    .foregroundStyle(Color.ssPrimary)
                    .contentTransition(.numericText())
                Text(String(format: "journal.portion.goalShare".localize, goalShare(sodiumGrams: sodium)))
                    .font(SSFont.subheadline())
                    .foregroundStyle(Color.ssTextSecondary)
            } else {
                Label("journal.portion.noSodium", systemImage: "exclamationmark.triangle.fill")
                    .font(SSFont.subheadline())
                    .foregroundStyle(Color.ssSeverityMedium)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var servingsInput: some View {
        VStack(spacing: SSSpacing.xs) {
            HStack(spacing: SSSpacing.lg) {
                stepButton(systemImage: "minus", delta: -1, label: "journal.portion.less")
                VStack(spacing: 0) {
                    Text(PortionInput.formatServings(servings, locale: locale))
                        .font(SSFont.largeTitle())
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("journal.portion.servingsCaption")
                        .font(SSFont.caption())
                        .foregroundStyle(Color.ssTextSecondary)
                }
                .frame(minWidth: 88)
                .accessibilityElement(children: .combine)
                stepButton(systemImage: "plus", delta: 1, label: "journal.portion.more")
            }
            if let grams = currentGrams {
                Text(servingEquivalent(grams))
                    .font(SSFont.subheadline())
                    .foregroundStyle(Color.ssTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SSSpacing.xs)
    }

    private func stepButton(systemImage: String, delta: Int, label: LocalizedStringKey) -> some View {
        let atLimit = delta < 0
            ? servings <= PortionInput.servingRange.lowerBound
            : servings >= PortionInput.servingRange.upperBound
        return Button {
            withAnimation { servings = PortionInput.step(servings, by: delta) }
        } label: {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .frame(width: 48, height: 48)
                .background(Color.ssPrimary.opacity(atLimit ? 0.05 : 0.12))
                .foregroundStyle(atLimit ? Color.ssTextTertiary : Color.ssPrimary)
                .clipShape(Circle())
        }
        // Borderless: in a Form row, default buttons would all fire on a row tap.
        .buttonStyle(.borderless)
        .disabled(atLimit)
        .accessibilityLabel(Text(label))
    }

    private var gramsInput: some View {
        VStack(alignment: .leading, spacing: SSSpacing.sm) {
            HStack {
                TextField("journal.portion.gramsPlaceholder", text: $gramsText)
                    .keyboardType(.decimalPad)
                    .font(SSFont.title2())
                    .monospacedDigit()
                    .focused($gramsFieldFocused)
                Text("unit.gram")
                    .foregroundStyle(Color.ssTextSecondary)
            }
            if currentGrams == nil, !gramsText.isEmpty {
                Text("journal.portion.gramsRange")
                    .font(SSFont.caption())
                    .foregroundStyle(Color.ssSeverityHigh)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: SSSpacing.xs) {
                    ForEach(PortionInput.shortcuts(servingGrams: servingGrams), id: \.self) { shortcut in
                        Button {
                            gramsText = PortionInput.formatGrams(shortcut.grams, locale: locale)
                            gramsFieldFocused = false
                        } label: {
                            Text(shortcutLabel(shortcut))
                                .font(SSFont.caption().weight(.semibold))
                                .padding(.vertical, SSSpacing.xxs)
                                .padding(.horizontal, SSSpacing.xs)
                                .background(Color.ssPrimary.opacity(0.12))
                                .foregroundStyle(Color.ssPrimary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
    }

    // MARK: - Text

    private func mass(_ grams: Double) -> String {
        PortionInput.formatGrams(grams, locale: locale) + " " + "unit.gram".localize
    }

    private func servingEquivalent(_ grams: Double) -> String {
        if let servingLabel, !servingLabel.isEmpty {
            return String(format: "journal.portion.equivalentWithLabel".localize, mass(grams), servingLabel)
        }
        return String(format: "journal.portion.equivalent".localize, mass(grams))
    }

    private func shortcutLabel(_ shortcut: PortionShortcut) -> String {
        shortcut.isServing
            ? String(format: "journal.portion.shortcut.serving".localize, mass(shortcut.grams))
            : mass(shortcut.grams)
    }

    private func goalShare(sodiumGrams: Double) -> Int {
        guard goalGrams > 0 else { return 0 }
        return Int((SaltMath.salt(fromSodiumGrams: sodiumGrams) / goalGrams * 100).rounded())
    }

    // MARK: - Actions

    /// Keeps the amount when switching between servings and grams.
    private func carryAmount(from oldMode: PortionMode, to newMode: PortionMode) {
        guard let servingGrams else { return }
        switch (oldMode, newMode) {
        case (.servings, .grams):
            gramsText = PortionInput.formatGrams(PortionInput.grams(servings: servings, servingGrams: servingGrams), locale: locale)
        case (.grams, .servings):
            if let grams = PortionInput.parseGrams(gramsText, locale: locale) {
                servings = PortionInput.nearestServings(grams: grams, servingGrams: servingGrams)
            }
        default:
            break
        }
    }

    private func save() {
        guard let grams = currentGrams else { return }
        let store = JournalStore(context: context)
        do {
            switch mode {
            case .add(let scan, _):
                try store.add(scan: scan, grams: grams, day: day)
            case .edit(let line):
                try store.update(line, grams: grams, day: day)
            }
        } catch {
            showSaveError = true
            return
        }
        onFinished()
        dismiss()
    }

    private func deleteLine() {
        guard case .edit(let line) = mode else { return }
        do {
            try JournalStore(context: context).delete(line)
        } catch {
            showSaveError = true
            return
        }
        onFinished()
        dismiss()
    }
}
