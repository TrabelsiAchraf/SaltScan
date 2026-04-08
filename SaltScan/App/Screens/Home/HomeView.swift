//
//  HomeView.swift
//  SaltScan
//

import SwiftUI
import SwiftData

struct HomeView: View {
    var onScanTapped: () -> Void = {}

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @AppStorage("dailySaltGoalGrams") private var goalGrams: Double = 5.0
    @Environment(\.modelContext) private var context
    @State private var showOnboarding = false
    @State private var currentIndex = 0
    @StateObject private var articlesViewModel = ArticleViewModel()

    @Query(
        sort: [SortDescriptor(\ScanEntry.scannedAt, order: .reverse)]
    ) private var allScans: [ScanEntry]

    @Query private var allIntakes: [DailyIntake]

    private let timer = Timer.publish(every: 5.0, on: .main, in: .common).autoconnect()

    private var todaySalt: Double {
        let today = Calendar.current.startOfDay(for: .now)
        return allIntakes.first { $0.day == today }?.totalSaltGrams ?? 0
    }

    private var latestScans: [ScanEntry] { Array(allScans.prefix(3)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SSSpacing.lg) {
                header
                dailyRingCard
                latestScansSection
                articlesSection
                BannerContentView()
                    .frame(maxWidth: .infinity)
                Spacer(minLength: SSSpacing.xl)
            }
            .padding(SSSpacing.md)
        }
        .background(Color.ssGroupedBackground)
        .navigationTitle("main.title")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showOnboarding) { OnboardingView() }
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
                    value: String(format: "%.1fg", todaySalt),
                    caption: "home.dailyIntake.caption",
                    color: todaySalt > goalGrams ? .ssSeverityHigh : .ssPrimary,
                    size: 130
                )
                VStack(alignment: .leading, spacing: SSSpacing.xs) {
                    Text("home.dailyIntake.title")
                        .font(SSFont.headline())
                    Text(String(format: "home.dailyIntake.goal".localize, goalGrams))
                        .font(SSFont.subheadline())
                        .foregroundStyle(Color.ssTextSecondary)
                    SSButton(
                        title: "home.scanProduct.button.start",
                        icon: "barcode.viewfinder",
                        size: .compact
                    ) { onScanTapped() }
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
                                        if let salt = entry.saltPer100g {
                                            Text(String(format: "%.2f g / 100g", salt))
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
