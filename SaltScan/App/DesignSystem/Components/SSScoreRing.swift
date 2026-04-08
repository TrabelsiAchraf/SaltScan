//
//  SSScoreRing.swift
//  SaltScan
//
//  Circular ring used for Nutriscore display and daily salt progress.
//

import SwiftUI

struct SSScoreRing: View {
    /// Progress in 0...1.
    var progress: Double
    /// Main label shown inside the ring (large).
    var value: String
    /// Secondary label shown under `value`.
    var caption: LocalizedStringKey? = nil
    var color: Color = .ssPrimary
    var lineWidth: CGFloat = 14
    var size: CGFloat = 140

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.7, dampingFraction: 0.8), value: progress)

            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                if let caption {
                    Text(caption)
                        .font(SSFont.caption())
                        .foregroundStyle(Color.ssTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Nutriscore helper

struct SSNutriscoreBadge: View {
    let grade: String? // "a".."e"

    var body: some View {
        let letter = (grade ?? "?").uppercased()
        let color = color(for: grade?.lowercased() ?? "")
        return Text(letter)
            .font(.system(size: 28, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 52, height: 52)
            .background(color)
            .clipShape(Circle())
            .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 2))
            .ssShadow(.soft)
    }

    private func color(for grade: String) -> Color {
        switch grade {
        case "a": .ssNutriA
        case "b": .ssNutriB
        case "c": .ssNutriC
        case "d": .ssNutriD
        case "e": .ssNutriE
        default: Color.gray
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        SSScoreRing(progress: 0.62, value: "3.1g", caption: "home.dailyIntake.caption", color: .ssSeverityMedium)
        HStack { SSNutriscoreBadge(grade: "a"); SSNutriscoreBadge(grade: "c"); SSNutriscoreBadge(grade: "e"); SSNutriscoreBadge(grade: nil) }
    }
    .padding()
}
