//
//  JournalView.swift
//  SaltScan
//
//  The portions of any day: move with the header chevrons or the calendar,
//  swipe to delete, tap to edit, "+" to add a portion to the day shown.
//

import SwiftUI
import SwiftData
import SaltScanCore

struct JournalView: View {
    @State private var day: Date
    @State private var showCalendar = false
    @State private var showPicker = false
    @Environment(\.locale) private var locale

    init(day: Date = .now) {
        _day = State(initialValue: Calendar.current.startOfDay(for: day))
    }

    var body: some View {
        JournalDayList(day: day, onAdd: { showPicker = true })
            .id(day)
            .safeAreaInset(edge: .top, spacing: 0) { dayHeader }
            .navigationTitle("journal.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showPicker = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(Text("journal.add"))
                }
            }
            .sheet(isPresented: $showPicker) {
                ProductPickerView(day: day)
            }
            .sheet(isPresented: $showCalendar) {
                calendarSheet
            }
    }

    // MARK: - Day header

    private var dayHeader: some View {
        HStack {
            Button { shift(by: -1) } label: {
                Image(systemName: "chevron.backward")
                    .font(.headline)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(Text("journal.day.previous"))

            Spacer()

            Button { showCalendar = true } label: {
                HStack(spacing: SSSpacing.xxs) {
                    Text(dayTitle)
                        .font(SSFont.headline())
                    Image(systemName: "calendar")
                        .font(.subheadline)
                }
            }
            .accessibilityHint(Text("journal.day.pickHint"))

            Spacer()

            Button { shift(by: 1) } label: {
                Image(systemName: "chevron.forward")
                    .font(.headline)
                    .frame(width: 44, height: 44)
            }
            .disabled(!JournalDay.canGoForward(from: day))
            .accessibilityLabel(Text("journal.day.next"))
        }
        .padding(.horizontal, SSSpacing.sm)
        .background(.bar)
    }

    private var dayTitle: String {
        switch JournalDay.relative(day) {
        case .today: "history.day.today".localize
        case .yesterday: "history.day.yesterday".localize
        case .earlier: day.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(locale))
        }
    }

    private func shift(by days: Int) {
        withAnimation { day = DayRange(containing: day).shifted(byDays: days).start }
    }

    private var calendarSheet: some View {
        NavigationStack {
            DatePicker(
                "journal.day.pick",
                selection: Binding(
                    get: { day },
                    set: { newValue in
                        day = Calendar.current.startOfDay(for: newValue)
                        showCalendar = false
                    }
                ),
                in: ...Date.now,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding(SSSpacing.md)
            .navigationTitle("journal.day.pick")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("journal.day.done") { showCalendar = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Day content

/// One `@Query` per day, built from the same `DayRange` the Home ring uses.
private struct JournalDayList: View {
    let day: Date
    let onAdd: () -> Void

    @Query private var lines: [IntakeLine]
    @AppStorage("dailySaltGoalGrams") private var goalGrams: Double = 5.0
    @Environment(\.saltFormatter) private var formatter
    @Environment(\.modelContext) private var context
    @State private var editing: IntakeLine?
    @State private var showDeleteError = false

    init(day: Date, onAdd: @escaping () -> Void) {
        self.day = day
        self.onAdd = onAdd
        let range = DayRange(containing: day)
        let start = range.start
        let end = range.end
        _lines = Query(
            filter: #Predicate<IntakeLine> { $0.addedAt >= start && $0.addedAt < end },
            sort: [SortDescriptor(\IntakeLine.addedAt, order: .reverse)]
        )
    }

    private var totalSodium: Double { lines.reduce(0) { $0 + $1.sodiumGrams } }
    private var totalSalt: Double { SaltMath.salt(fromSodiumGrams: totalSodium) }

    var body: some View {
        List {
            Section { summary }

            if lines.isEmpty {
                Section {
                    VStack(spacing: SSSpacing.sm) {
                        SSEmptyState(icon: "fork.knife", title: "journal.empty.title", message: "journal.empty.message")
                        SSButton(title: "journal.add", icon: "plus.circle.fill", size: .compact, action: onAdd)
                    }
                    .padding(.vertical, SSSpacing.sm)
                }
            } else {
                Section {
                    ForEach(lines) { line in
                        Button { editing = line } label: {
                            JournalLineRow(line: line)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                do {
                                    try JournalStore(context: context).delete(line)
                                } catch {
                                    showDeleteError = true
                                }
                            } label: {
                                Label("journal.line.delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.ssGroupedBackground)
        .sheet(item: $editing) { line in
            PortionSheet(mode: .edit(line))
                .presentationDetents([.large])
        }
        .alert("journal.portion.saveFailed.title", isPresented: $showDeleteError) {
            Button("journal.portion.saveFailed.ok", role: .cancel) {}
        } message: {
            Text("journal.portion.saveFailed.message")
        }
    }

    private var summary: some View {
        HStack(spacing: SSSpacing.lg) {
            SSScoreRing(
                progress: goalGrams > 0 ? totalSalt / goalGrams : 0,
                value: formatter.amount(sodiumGrams: totalSodium, precision: .total),
                color: totalSalt > goalGrams ? .ssSeverityHigh : .ssPrimary,
                lineWidth: 10,
                size: 96
            )
            VStack(alignment: .leading, spacing: SSSpacing.xxs) {
                Text(formatter.unit == .sodiumMilligrams ? LocalizedStringKey("journal.total.sodium") : LocalizedStringKey("journal.total.salt"))
                    .font(SSFont.headline())
                Text(String(format: "home.dailyIntake.goal".localize, formatter.goal(saltGrams: goalGrams)))
                    .font(SSFont.subheadline())
                    .foregroundStyle(Color.ssTextSecondary)
                Text(String(format: "journal.total.count".localize, locale: .current, lines.count))
                    .font(SSFont.caption())
                    .foregroundStyle(Color.ssTextSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, SSSpacing.xs)
    }
}
