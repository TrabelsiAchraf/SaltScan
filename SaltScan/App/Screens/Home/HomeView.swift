//
//  HomeView.swift
//  SaltScan
//

import SwiftUI
import SwiftData
import SaltScanCore

struct HomeView: View {
    var onScanTapped: () -> Void = {}

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @AppStorage("dailySaltGoalGrams") private var goalGrams: Double = 5.0
    @Environment(\.modelContext) private var context
    @Environment(\.saltFormatter) private var formatter
    @State private var showOnboarding = false
    @State private var showSearch = false
    @State private var currentIndex = 0
    @StateObject private var articlesViewModel = ArticleViewModel()

    @Query(
        sort: [SortDescriptor(\ScanEntry.scannedAt, order: .reverse)]
    ) private var allScans: [ScanEntry]

    // Query individual lines (not the parent bucket) so the @Query
    // invalidates as soon as a new portion is added.
    @Query private var allLines: [IntakeLine]

    private let timer = Timer.publish(every: 5.0, on: .main, in: .common).autoconnect()

    /// Today's sodium in grams; salt is derived from it for the goal ring.
    private var todaySodium: Double {
        let cal = Calendar.current
        return allLines
            .filter { cal.isDateInToday($0.addedAt) }
            .reduce(0) { $0 + $1.sodiumGrams }
    }

    private var todaySalt: Double { SaltMath.salt(fromSodiumGrams: todaySodium) }

    private var intakeTitleKey: LocalizedStringKey {
        formatter.unit == .sodiumMilligrams ? "home.dailyIntake.title.sodium" : "home.dailyIntake.title"
    }

    private var latestScans: [ScanEntry] { Array(allScans.prefix(3)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SSSpacing.lg) {
                header
                dailyRingCard
                latestScansSection
                articlesSection
                Spacer(minLength: SSSpacing.xl)
            }
            .padding(SSSpacing.md)
            .ssReadableWidth()
        }
        .background(Color.ssGroupedBackground)
        .navigationTitle("main.title")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.ssPrimary)
                }
                .accessibilityLabel(Text("home.search.button"))
            }
        }
        .sheet(isPresented: $showOnboarding) { OnboardingView() }
        .sheet(isPresented: $showSearch) { ProductSearchView() }
        .onAppear {
            setHasSeenOnboardingFlag()
            articlesViewModel.loadArticles()
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("home.greeting")
                .font(SSFont.title2())
            Text("home.subtitle")
                .font(SSFont.subheadline())
                .foregroundStyle(Color.ssTextSecondary)
        }
    }

    private var dailyRingCard: some View {
        SSCard {
            HStack(spacing: SSSpacing.lg) {
                SSScoreRing(
                    progress: goalGrams > 0 ? todaySalt / goalGrams : 0,
                    value: formatter.amount(sodiumGrams: todaySodium, precision: .total),
                    caption: "home.dailyIntake.caption",
                    color: todaySalt > goalGrams ? .ssSeverityHigh : .ssPrimary,
                    size: 130
                )
                VStack(alignment: .leading, spacing: SSSpacing.xs) {
                    Text(intakeTitleKey)
                        .font(SSFont.headline())
                    Text(String(format: "home.dailyIntake.goal".localize, formatter.goal(saltGrams: goalGrams)))
                        .font(SSFont.subheadline())
                        .foregroundStyle(Color.ssTextSecondary)
                    SSButton(
                        title: "home.scanProduct.button.start",
                        icon: "barcode.viewfinder",
                        size: .compact
                    ) { onScanTapped() }
                    SSButton(
                        title: "home.search.button",
                        icon: "magnifyingglass",
                        style: .ghost,
                        size: .compact
                    ) { showSearch = true }
                }
            }
        }
    }

    @ViewBuilder
    private var latestScansSection: some View {
        if !latestScans.isEmpty {
            VStack(alignment: .leading, spacing: SSSpacing.sm) {
                SSSectionHeader(title: "home.latestScans.title")
                VStack(spacing: SSSpacing.xs) {
                    ForEach(latestScans) { entry in
                        NavigationLink {
                            ProductDetailView(barcode: entry.barcode, preloadedEntry: entry)
                        } label: {
                            SSCard(padding: SSSpacing.sm, elevated: false) {
                                HStack(spacing: SSSpacing.sm) {
                                    Image(systemName: "barcode")
                                        .foregroundStyle(Color.ssPrimary)
                                    VStack(alignment: .leading) {
                                        Text(entry.productName)
                                            .font(SSFont.subheadline().weight(.semibold))
                                            .foregroundStyle(Color.ssTextPrimary)
                                            .lineLimit(1)
                                        if let sodium = entry.sodium100g {
                                            Text(formatter.amount(sodiumGrams: sodium) + " / 100g")
                                                .font(SSFont.caption())
                                                .foregroundStyle(Color.ssTextSecondary)
                                        }
                                    }
                                    Spacer()
                                    if let severity = entry.severity {
                                        SSBadge(severity: severity)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var articlesSection: some View {
        VStack(alignment: .leading, spacing: SSSpacing.sm) {
            SSSectionHeader(title: "home.healthSection.title")
            TabView(selection: $currentIndex) {
                ForEach(articlesViewModel.articles.indices, id: \.self) { index in
                    ArticleCard(article: articlesViewModel.articles[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 200)
            .onReceive(timer) { _ in
                withAnimation {
                    guard !articlesViewModel.articles.isEmpty else { return }
                    currentIndex = (currentIndex + 1) % articlesViewModel.articles.count
                }
            }
        }
    }

    // MARK: - Private

    private func setHasSeenOnboardingFlag() {
#if DEBUG
        showOnboarding = false
#else
        if !hasSeenOnboarding {
            showOnboarding = true
            hasSeenOnboarding = true
        }
#endif
    }
}
