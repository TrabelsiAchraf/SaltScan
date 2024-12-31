//
//  ResultView.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 29/12/2024.
//

import SwiftUI

struct ResultView: View {
    @Binding var scannedCode: String?
    @StateObject private var resultViewModel = ResultViewModel()
    private let buttonTapImpactFeedback = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        VStack(spacing: 16) {
            Text("result.product.name")
                .font(.headline)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 8) {
                if let product = resultViewModel.product {
                    Text(product.product.productName ?? "Unknown")
                        .font(.headline)
                    if let sodium = product.product.nutriments?.sodium100g {
                        Text(
                            String(
                                format: "result.product.sodiumPer100g".localize,
                                String(format: "%.2f", sodium)
                            )
                        )
                        let evaluation = evaluateSodiumContent(sodium100g: sodium)
                        Text(
                            String(
                                format: "result.product.saltEval".localize,
                                evaluation.text
                            )
                        )
                        HStack {
                            Spacer()
                            Image(systemName: evaluation.icon.iconName)
                                .font(.largeTitle)
                                .bold()
                                .foregroundStyle(evaluation.icon.iconColor)
                            Spacer()
                        }
                    } else {
                        Text("result.product.unknown")
                    }
                } else if let errorMessage = resultViewModel.errorMessage {
                    Text(
                        String(format: "result.product.error", errorMessage)
                    )
                    .foregroundColor(.red)
                } else {
                    ProgressView("result.product.loading")
                }
            }
            
            PrimaryButton(
                content: "result.product.button.rescan",
                action: {
                    buttonTapImpactFeedback.impactOccurred()
                    scannedCode = nil
                }
            )
        }
        .padding(.all, 16)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.cardOver.opacity(0.95))
                .shadow(radius: 5)
        )
        .padding(.horizontal)
        .transition(.move(edge: .bottom))
        .task {
            prepareHaptic()
            guard let scannedCode else { return }
            await resultViewModel.fetchProduct(scannedCode: scannedCode)
        }
    }
    
    // MARK: - Private
    
    private func prepareHaptic() {
        buttonTapImpactFeedback.prepare()
    }
    
    private func evaluateSodiumContent(sodium100g: Double) -> EvaluationResult {
        let saltContent = sodium100g * 2.5 // Conversion of sodium to salt
        return if saltContent > 1.5 {
            EvaluationResult(
                text: "result.product.highEval".localize,
                icon: ("arrow.up.forward.circle.dotted", .red)
            )
        } else if saltContent >= 0.5 && saltContent <= 1.5 {
            EvaluationResult(
                text: "result.product.mediumEval".localize,
                icon: ("arrow.right.circle.dotted", .orange)
            )
        } else {
            EvaluationResult(
                text: "result.product.lowEval".localize,
                icon: ("arrow.down.forward.circle.dotted", .green)
            )
        }
    }
    
    private struct EvaluationResult {
        let text: String
        let icon: (iconName: String, iconColor: Color)
    }
}

#Preview {
    ResultView(
        scannedCode: .constant("8000500310427")
    )
    .environment(\.locale, Locale(identifier: "en"))
}

#Preview {
    ResultView(
        scannedCode: .constant("8000500310427")
    )
    .preferredColorScheme(.dark)
    .environment(\.locale, Locale(identifier: "en"))
}
