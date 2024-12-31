//
//  HomeView.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 30/12/2024.
//

import SwiftUI

struct HomeView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var scannedCode: String?
    @State private var showOnboarding = false
    @State private var showScan = false
    @State private var currentIndex = 0
    @StateObject private var articlesViewModel = ArticleViewModel()
    private let timer = Timer.publish(every: 4.0, on: .main, in: .common).autoconnect()
    private let buttonTapImpactFeedback = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text("home.healthSection.title")
                    .font(.headline)
                    .fontWeight(.bold)
                
                TabView(selection: $currentIndex) {
                    ForEach(articlesViewModel.articles.indices, id: \.self) { index in
                        ArticleCard(article: articlesViewModel.articles[index])
                            .padding(.horizontal, 2)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 200)
                .onReceive(timer) { _ in
                    withAnimation {
                        currentIndex = (currentIndex + 1) % articlesViewModel.articles.count
                    }
                }
            }
            Spacer()
            
            Text("home.scanProduct.description")
                .font(.body)
                .foregroundColor(.gray)
            
            PrimaryButton(
                content: "home.scanProduct.button.start",
                action: {
                    buttonTapImpactFeedback.impactOccurred()
                    showScan = true
                }
            )
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 16)
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .fullScreenCover(isPresented: $showScan) {
            ProductScannerView()
        }
        .onAppear {
            prepareHaptic()
            setHasSeenOnboardingFlag()
            articlesViewModel.loadArticles()
        }
    }
    
    // MARK: - Private
    
    private func prepareHaptic() {
        buttonTapImpactFeedback.prepare()
    }
    
    private func setHasSeenOnboardingFlag() {
#if DEBUG
        showOnboarding = true
#else
        if !hasSeenOnboarding {
            showOnboarding = true
            hasSeenOnboarding = true
        }
#endif
    }
}

#Preview {
    HomeView()
        .environment(\.locale, Locale(identifier: "en"))
}

#Preview {
    HomeView()
        .preferredColorScheme(.dark)
        .environment(\.locale, Locale(identifier: "en"))
}
