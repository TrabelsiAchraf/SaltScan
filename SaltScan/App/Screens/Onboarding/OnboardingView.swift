//
//  OnboardingView.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 29/12/2024.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    private let buttonTapImpactFeedback = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("onboarding.title")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.bottom, 22)
            
            OnboardingItem(
                icon: "cart.fill",
                title: "onboarding.tuto.item0.title",
                description: "onboarding.tuto.item0.description"
            )
            OnboardingItem(
                icon: "waveform.path.ecg",
                title: "onboarding.tuto.item1.title",
                description: "onboarding.tuto.item1.description"
            )
            OnboardingItem(
                icon: "star.fill",
                title: "onboarding.tuto.item2.title",
                description: "onboarding.tuto.item2.description"
            )
            
            Spacer()
            
            PrimaryButton(
                content: "onboarding.button.start",
                action: {
                    buttonTapImpactFeedback.impactOccurred()
                    dismiss()
                }
            )
            .padding()
        }
        .onAppear {
            prepareHaptic()
        }
    }
    
    // MARK: - Private
    
    private func prepareHaptic() {
        buttonTapImpactFeedback.prepare()
    }
}

// MARK: - OnboardingItem

struct OnboardingItem: View {
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title)
                .padding(.trailing)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.vertical)
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

#Preview {
    OnboardingView()
        .environment(\.locale, Locale(identifier: "en"))
}

#Preview {
    OnboardingView()
        .preferredColorScheme(.dark)
        .environment(\.locale, Locale(identifier: "en"))
}
